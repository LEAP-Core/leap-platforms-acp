//
// Copyright (C) 2008 Intel Corporation
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//

import FIFOF::*;
import Vector::*;

`include "nallatech_edge_device.bsh"
`include "physical_platform.bsh"
`include "umf.bsh"

//
// Types
//

typedef enum
{
    RSTATE_READY,

    RSTATE_H2F_START_READ0,
    RSTATE_H2F_START_READ1,
    RSTATE_H2F_CONT_READ,
    RSTATE_H2F_READ_DONE,

    RSTATE_F2H_READ0,
    RSTATE_F2H_READ1,
    RSTATE_F2H_READ_DUMMY,
    RSTATE_F2H_READ_DONE
}
READ_STATE
    deriving (Bits, Eq);

typedef enum
{
    WSTATE_READY,

    WSTATE_H2F_WRITE,
    WSTATE_H2F_WRITE_LAST,

    WSTATE_F2H_TRY_WRITE,
    WSTATE_F2H_START_WRITE,
    WSTATE_F2H_CONT_WRITE,
    WSTATE_F2H_DONE
}
WRITE_STATE
    deriving (Bits, Eq);


//
// Nallatech edge channel buffer index.
//
typedef Bit#(TLog#(TAdd#(TDiv#(`NALLATECH_MAX_MSG_BYTES, `UMF_CHUNK_BYTES), 1))) NALLATECH_BUF_IDX;

function NALLATECH_BUF_IDX chunkToBufIdx(UMF_CHUNK c) = truncate(c);
function UMF_CHUNK bufIdxToChunk(NALLATECH_BUF_IDX i) = zeroExtend(i);


// physical channel interface
interface PHYSICAL_CHANNEL;
    
    method ActionValue#(UMF_CHUNK) read();
    method Action                  write(UMF_CHUNK chunk);

endinterface

//
// This implementation uses a relatively large Write buffer to make sure that
// the entire message is buffered up before being sent out onto the device.
// This simplifies the implementation, as well as makes it a little more
// efficient (because software can get the entire message in one AAL transaction),
// but uses more hardware. Once AAL supports de-coupled transactions, we should
// re-think the channel logic.
//

// physical channel module
module mkPhysicalChannel#(PHYSICAL_DRIVERS drivers)
    // interface
    (PHYSICAL_CHANNEL);
    
    // channel state
    Reg#(READ_STATE) readState <- mkReg(RSTATE_READY);
    Reg#(WRITE_STATE) writeState <- mkReg(WSTATE_READY);

    // link to nallatech driver
    NALLATECH_EDGE_DRIVER edgeDriver = drivers.nallatechEdgeDriver;


    // ====================================================================
    //
    // Marshaller and DeMarshaller
    //
    // ====================================================================
    
    NPC_MARSHALLER#(NALLATECH_FIFO_DATA, UMF_CHUNK)   dataFromHost <- mkNPCMarshaller();
    NPC_DEMARSHALLER#(UMF_CHUNK, NALLATECH_FIFO_DATA) dataToHost   <- mkNPCDeMarshaller();

    rule marshall_from_device (True);
        
        dataFromHost.enq(edgeDriver.first());
        edgeDriver.deq();
        
    endrule
    
    rule demarshall_to_device (True);
        
        edgeDriver.enq(dataToHost.first());
        dataToHost.deq();
        
    endrule


    // ====================================================================
    //
    // Accept a new request from software that starts a transfer.
    //
    // ====================================================================
 
    rule accept_request (readState == RSTATE_READY);

        let cmd = dataFromHost.first();
        dataFromHost.deq();

        case (cmd)

            `CHANNEL_REQUEST_H2F :
            begin
                readState <= RSTATE_H2F_START_READ0;
            end

            `CHANNEL_REQUEST_F2H :
            begin
                readState <= RSTATE_F2H_READ0;
            end

        endcase

    endrule
    

    // ====================================================================
    //
    // Host to FPGA transfer. Read Stage transfers the real data + pad,
    // Write stage writes out an ACK + pad.
    //
    // ====================================================================

    Reg#(NALLATECH_BUF_IDX) rawReadChunksRemaining <- mkReg(0);
    Reg#(UMF_MSG_LENGTH) readDataChunksRemaining <- mkReg(0);

    Reg#(NALLATECH_BUF_IDX) dummyWriteChunksRemaining <- mkReg(0);

    FIFOF#(UMF_CHUNK) readBuffer <- mkFIFOF();

    // First stage -- read size of remaining raw message
    rule h2f_start_read0 (readState == RSTATE_H2F_START_READ0);
        
        rawReadChunksRemaining <= chunkToBufIdx(dataFromHost.first());
        dataFromHost.deq();
        
        readState <= RSTATE_H2F_START_READ1;
        
    endrule

    // Second stage -- read the message header
    rule h2f_start_read1 ((readState == RSTATE_H2F_START_READ1) &&
                          (writeState == WSTATE_READY));
        
        UMF_CHUNK header = dataFromHost.first();
        dataFromHost.deq();
        
        UMF_PACKET packet = tagged UMF_PACKET_header unpack(header);
        
        readBuffer.enq(header);

        readDataChunksRemaining  <= packet.UMF_PACKET_header.numChunks;
        
        rawReadChunksRemaining <= rawReadChunksRemaining - 1;
        readState <= RSTATE_H2F_CONT_READ;

        // Prepare required response
        dataToHost.enq(`CHANNEL_RESPONSE_ACK);
        dummyWriteChunksRemaining <= (`NALLATECH_MIN_MSG_BYTES / `UMF_CHUNK_BYTES) - 1;
        writeState <= WSTATE_H2F_WRITE;
        
    endrule
        
    // Iterate over incoming message data
    rule h2f_cont_read (readState == RSTATE_H2F_CONT_READ);
        
        UMF_CHUNK chunk = dataFromHost.first();
        dataFromHost.deq();
        
        if (readDataChunksRemaining != 0)
        begin
                
            readBuffer.enq(chunk);
            readDataChunksRemaining <= readDataChunksRemaining - 1;
            
        end

        if (rawReadChunksRemaining == 1)
        begin
    
            readState <= RSTATE_H2F_READ_DONE;
            
        end

        rawReadChunksRemaining <= rawReadChunksRemaining - 1;
        
    endrule
    
    // Iterate, emitting the dummy write message
    rule h2f_write (writeState == WSTATE_H2F_WRITE);
        
        dataToHost.enq(0);
        
        if (dummyWriteChunksRemaining == 2)
        begin
            
            writeState <= WSTATE_H2F_WRITE_LAST;
            
        end

        dummyWriteChunksRemaining <= dummyWriteChunksRemaining - 1;
        
    endrule
        
    // Last write.  Make sure it happens after last read.
    rule h2f_done ((writeState == WSTATE_H2F_WRITE_LAST) &&
                   (readState == RSTATE_H2F_READ_DONE));
        
        dataToHost.enq(0);
        
        writeState <= WSTATE_READY;
        readState <= RSTATE_READY;
        
    endrule
        

    // ====================================================================
    //
    // FPGA to Host transfer. Read Stage transfers the padding,
    // Write stage writes out the message + pad.
    //
    // ====================================================================

    Reg#(NALLATECH_BUF_IDX) writeBufferSize <- mkRegU();
    Reg#(UMF_MSG_LENGTH) writeDataChunksRemaining <- mkReg(0);

    Reg#(NALLATECH_BUF_IDX) dummyReadChunksRemaining <- mkRegU();

    // The last chunk of every buffer returned to the software holds a pointer
    // to the last useful chunk in the message.  This helps the software avoid
    // searching through an array of NODATA messages.
    Reg#(NALLATECH_BUF_IDX) numUsefulWriteChunks <- mkRegU();
    Reg#(NALLATECH_BUF_IDX) numWrittenChunks <- mkRegU();

    // Spin for some time waiting for a message to arrive for the host
    Reg#(Bit#(24)) spinCycles <- mkRegU();

    // Outbound data arriving from the write() method below
    FIFOF#(UMF_CHUNK) writeDataQ <- mkFIFOF();

    // First stage -- get the length of the outgoing write buffer.
    rule f2h_read0 (readState == RSTATE_F2H_READ0);

        writeBufferSize <= chunkToBufIdx(dataFromHost.first());
        dataFromHost.deq();
        readState <= RSTATE_F2H_READ1;

    endrule

    // Second stage -- find out how many spin cycles are permitted
    rule f2h_read1 ((readState == RSTATE_F2H_READ1) &&
                    (writeState == WSTATE_READY));

        spinCycles <= truncate(dataFromHost.first());
        dataFromHost.deq();

        // Ready to try writing
        writeState <= WSTATE_F2H_TRY_WRITE;

        // No more interesting read data
        dummyReadChunksRemaining <= (`NALLATECH_MIN_MSG_BYTES / `UMF_CHUNK_BYTES) - 3;
        readState <= RSTATE_F2H_READ_DUMMY;

    endrule


    // Dispatch to write states depending on available data
    rule f2h_try_write (writeState == WSTATE_F2H_TRY_WRITE);

        // Any data left over from the last message?
        if (writeDataChunksRemaining != 0)
        begin

            // Yes.  Keep writing.
            writeState <= WSTATE_F2H_CONT_WRITE;

        end
        else if (writeDataQ.notEmpty())
        begin

            // Start a new message.
            writeState <= WSTATE_F2H_START_WRITE;

        end
        else if (spinCycles == 0)
        begin

            // Give up: no message.  Must fill the buffer to respond.
            writeState <= WSTATE_F2H_CONT_WRITE;

        end

        numWrittenChunks <= 0;
        // The software side requires at least one significant chunk.
        // That is guaranteed, even if they are all NODATA chunks.
        numUsefulWriteChunks <= 1;

        spinCycles <= spinCycles - 1;

    endrule

    // Consume the rest of the useless read request.  This can be done in
    // parallel with the write.
    rule f2h_read_dummy (readState == RSTATE_F2H_READ_DUMMY);

        dataFromHost.deq();

        if (dummyReadChunksRemaining == 1)
        begin
            readState <= RSTATE_F2H_READ_DONE;
        end

        dummyReadChunksRemaining <= dummyReadChunksRemaining - 1;

    endrule
        
    // Start a new message
    rule f2h_start_write (writeState == WSTATE_F2H_START_WRITE);

        UMF_PACKET_HEADER header = unpack(pack(writeDataQ.first()));
        writeDataQ.deq();
        
        // Guarantee that the header is non-zero to differentiate it from
        // a no-data message.
        header.phyChannelPvt = 1;

        dataToHost.enq(unpack(pack(header)));

        writeDataChunksRemaining <= header.numChunks;
        
        let written_chunks = numWrittenChunks + 1;
        if (writeBufferSize == written_chunks)
        begin

            // No more room in this packet for the rest of the message.  The
            // rest will go in the next packet.
            writeState <= WSTATE_F2H_DONE;

        end
        else
        begin

            writeState <= WSTATE_F2H_CONT_WRITE;

        end

        numUsefulWriteChunks <= written_chunks;
        numWrittenChunks <= written_chunks;

    endrule

    // Emit write data or fill the write buffer with NODATA messages
    rule f2h_cont_write (writeState == WSTATE_F2H_CONT_WRITE);
        
        if ((writeDataChunksRemaining == 0) && writeDataQ.notEmpty())
        begin

            // Not doing anything useful here and there is a new message
            // ready.  Start the new message.
            writeState <= WSTATE_F2H_START_WRITE;

        end
        else
        begin

            let written_chunks = numWrittenChunks + 1;

            if (writeDataChunksRemaining != 0)
            begin

                // Keep writing the current message
                dataToHost.enq(writeDataQ.first());
                writeDataQ.deq();

                writeDataChunksRemaining <= writeDataChunksRemaining - 1;
                numUsefulWriteChunks <= written_chunks;

            end
            else
            begin

                // No data to write.  Fill the response buffer and give
                // control back to the host.
                dataToHost.enq(`CHANNEL_RESPONSE_NODATA);

            end

            if (writeBufferSize == written_chunks)
            begin

                writeState <= WSTATE_F2H_DONE;

            end

            numWrittenChunks <= written_chunks;

        end

    endrule


    // Final write stage -- emit a pointer to the last useful chunk in the message
    rule f2h_complete_write ((writeState == WSTATE_F2H_DONE) &&
                             (readState == RSTATE_F2H_READ_DONE));

        dataToHost.enq(bufIdxToChunk(numUsefulWriteChunks));
        writeState <= WSTATE_READY;
        readState <= RSTATE_READY;

    endrule
    
    // ====================================================================
    //
    // Methods
    //
    // ====================================================================
    
    // read
    method ActionValue#(UMF_CHUNK) read();
        
        UMF_CHUNK chunk = readBuffer.first();
        readBuffer.deq();
        
        return chunk;
        
    endmethod

    // write
    method Action write(UMF_CHUNK chunk);
        
        writeDataQ.enq(chunk);
        
    endmethod

endmodule
