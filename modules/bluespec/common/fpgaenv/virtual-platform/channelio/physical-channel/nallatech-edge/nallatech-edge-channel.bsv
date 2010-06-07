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
// Command from host to FPGA.  The command depends on chunks being at least
// 64 bits.
//

typedef Bit#(24) F2H_SPIN_CYCLES;

//
// Request (host -> FPGA) control message
//
typedef struct
{
    // Cycles the FPGA to host path may wait for data to arrive before returning.
    F2H_SPIN_CYCLES waitForF2HSpinCycles;

    // Can data be returned to the host or is this just a host to FPGA message.
    Bit#(1) f2hDataPermitted;

    // Raw size of host to FPGA data buffer, excluding the leading cmd chunk.
    Bit#(16) rawH2FChunks;

    // Raw size of FPGA to host buffer, excluding the final chunk emitted
    // at the end pointing to the last chunk with data.
    Bit#(16) rawF2HChunks;
}
H2F_CMD
    deriving (Bits, Eq);

//
// Response (FPGA -> host) control message
//
typedef struct
{
    // The number of write (FPGA -> host) chunks with data.
    Bit#(16) numF2HChunks;

    // The number of read (host -> FPGA) chunks NOT read due to data errors.
    // If non-zero the host is expected to retransmit the entire buffer.
    Bit#(16) h2fError;
}
F2H_CMD
    deriving (Bits, Eq);


//
// Internal types
//

typedef enum
{
    RSTATE_READY,
    RSTATE_START,
    RSTATE_CONT,
    RSTATE_DONE,

    RSTATE_ERROR,
    RSTATE_RECOVER
}
READ_STATE
    deriving (Bits, Eq);

typedef enum
{
    WSTATE_READY,
    WSTATE_TRY,
    WSTATE_START,
    WSTATE_CONT,
    WSTATE_DUMMY,
    WSTATE_LAST
}
WRITE_STATE
    deriving (Bits, Eq);


//
// State for restarting a read following a transmission error and buffer
// resend.
//
typedef struct
{
    READ_STATE readState;
    UMF_MSG_LENGTH dataChunksRemaining;
    NALLATECH_BUF_IDX rawChunksRemaining;
}
READ_RECOVERY_STATE
    deriving (Bits, Eq);


//
// Nallatech edge channel buffer index.
//
typedef Bit#(TLog#(TAdd#(TDiv#(`NALLATECH_MAX_MSG_BYTES, `UMF_CHUNK_BYTES), 1))) NALLATECH_BUF_IDX;

function NALLATECH_BUF_IDX chunkToBufIdx(UMF_CHUNK c) = truncate(c);


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

    // Raw read/write counters
    Reg#(NALLATECH_BUF_IDX) rawReadChunksRemaining <- mkRegU();
    Reg#(NALLATECH_BUF_IDX) rawWriteChunksRemaining <- mkRegU();

    // Spin for some time waiting for a message to arrive for the host
    Reg#(Bit#(24)) spinCycles <- mkRegU();

    // Host -> FPGA data error detection/correction
    Reg#(Maybe#(READ_RECOVERY_STATE)) h2fErrRecovery <- mkReg(tagged Invalid);

    // Debug state
    Reg#(UMF_CHUNK) lastReqHeader <- mkRegU();


    // ====================================================================
    //
    // Marshaller and DeMarshaller
    //
    // ====================================================================

    //
    // Some ACP version suffer from data errors in host to FPGA messages.
    // Optionally add error detection and retry to the host to FPGA channel.
    //
    NPC_MARSHALLER#(NALLATECH_FIFO_DATA, UMF_CHUNK) dataFromHost <-
`ifdef CHANNEL_H2F_FIX_ERRORS_Z
        mkNPCMarshaller();
`else
        mkNPCErrorDetectingMarshaller();
`endif

    NPC_DEMARSHALLER#(UMF_CHUNK, NALLATECH_FIFO_DATA) dataToHost   <- mkNPCDeMarshaller();

    rule marshallFromDevice (True);
        dataFromHost.enq(edgeDriver.first());
        edgeDriver.deq();
    endrule
    
    rule demarshallToDevice (True);
        edgeDriver.enq(dataToHost.first());
        dataToHost.deq();
    endrule


    // ====================================================================
    //
    // Accept a new request from software that starts a transfer.
    //
    // ====================================================================
 
    rule acceptRequest ((readState == RSTATE_READY) &&
                         (writeState == WSTATE_READY));
        H2F_CMD cmd = unpack(truncate(pack(dataFromHost.first())));
        lastReqHeader <= dataFromHost.first();
        dataFromHost.deq();

        //
        // We don't check for errors here.  Knowing the buffer sizes is crucial
        // for the protocol and without a way to correct an errant message
        // the FPGA would not know how many chunks to read or write.
        //
        // It appears that the first chunk is never corrupt.  If that turns
        // out not to be the case, we will have to change the code to send
        // enough state to recover the command word.
        //
        rawReadChunksRemaining <= truncate(cmd.rawH2FChunks);
        rawWriteChunksRemaining <= truncate(cmd.rawF2HChunks);
        spinCycles <= cmd.waitForF2HSpinCycles;

        if (! isValid(h2fErrRecovery))
            readState <= RSTATE_START;
        else
            readState <= RSTATE_RECOVER;

        if (cmd.f2hDataPermitted == 1)
            writeState <= WSTATE_TRY;
        else
            writeState <= WSTATE_DUMMY;
    endrule
    

    // ====================================================================
    //
    // Host to FPGA transfer. Read Stage transfers the real data + pad,
    // Write stage writes out an ACK + pad.
    //
    // ====================================================================

    Reg#(UMF_MSG_LENGTH) readDataChunksRemaining <- mkRegU();

    FIFOF#(UMF_CHUNK) readBuffer <- mkFIFOF();

    Reg#(Bool) noMoreReadData <- mkReg(False);

    //
    // Read the message header
    //
    rule h2fStart (readState == RSTATE_START);
        UMF_PACKET_HEADER header = unpack(pack(dataFromHost.first()));
        dataFromHost.deq();

        if (rawReadChunksRemaining == 1)
        begin
            // Last chunk in the buffer.  H2F messages can't span buffers, so
            // this chunk had better not be a packet header or data will be lost.
            readState <= RSTATE_DONE;
            noMoreReadData <= False;
        end
        else if (! noMoreReadData)
        begin
            if (dataFromHost.errorDetected())
            begin
                //
                // Data error!  Stop parsing this message and request retransmission.
                //
                readState <= RSTATE_ERROR;

                h2fErrRecovery <= tagged Valid READ_RECOVERY_STATE {
                                      readState: RSTATE_START,
                                      dataChunksRemaining: readDataChunksRemaining,
                                      rawChunksRemaining: rawReadChunksRemaining };
            end
            else if (header.phyChannelPvt != 0)
            begin
                //
                // Start of a new message
                //
                readBuffer.enq(unpack(pack(header)));

                let msg_len = header.numChunks;
                readDataChunksRemaining <= msg_len;

                if (msg_len != 0)
                begin
                    readState <= RSTATE_CONT;
                end
            end
            else
            begin
                // Once a header chunk indicates no message the rest of the
                // buffer must be ignored.  This allows the software side
                // to mark the buffer end with a single chunk instead of having
                // to pad the entire buffer with no-message flags.
                noMoreReadData <= True;
            end
        end

        rawReadChunksRemaining <= rawReadChunksRemaining - 1;
    endrule
        
    //
    // Iterate over incoming message data
    //
    rule h2fContRead (readState == RSTATE_CONT);
        UMF_CHUNK chunk = dataFromHost.first();
        dataFromHost.deq();
        
        if (! dataFromHost.errorDetected())
        begin
            // Forward the data
            readBuffer.enq(chunk);

            if (rawReadChunksRemaining == 1)
            begin
                // End of the buffer.  The message better be done, too.
                readState <= RSTATE_DONE;
            end
            else if (readDataChunksRemaining == 1)
            begin
                // End of message.  Is there another in the buffer?
                readState <= RSTATE_START;
            end
        end
        else
        begin
            //
            // Data error!  Stop parsing this message and request retransmission.
            //
            if (rawReadChunksRemaining == 1)
                readState <= RSTATE_DONE;
            else
                readState <= RSTATE_ERROR;

            h2fErrRecovery <= tagged Valid READ_RECOVERY_STATE {
                                  readState: RSTATE_CONT,
                                  dataChunksRemaining: readDataChunksRemaining,
                                  rawChunksRemaining: rawReadChunksRemaining };
        end

        readDataChunksRemaining <= readDataChunksRemaining - 1;
        rawReadChunksRemaining <= rawReadChunksRemaining - 1;
    endrule
        

    // ====================================================================
    //
    // FPGA to Host transfer. Read Stage transfers the padding,
    // Write stage writes out the message + pad.
    //
    // ====================================================================

    // Data chunks left in the current message.  This may be left over from
    // the last packet.
    Reg#(UMF_MSG_LENGTH) writeDataChunksRemaining <- mkReg(0);

    // The last chunk of every buffer returned to the software holds a pointer
    // to the last useful chunk in the message.  This helps the software avoid
    // searching through an array of NODATA messages.
    Reg#(NALLATECH_BUF_IDX) numUsefulWriteChunks <- mkRegU();
    Reg#(NALLATECH_BUF_IDX) numWrittenChunks <- mkRegU();

    // Outbound data arriving from the write() method below
    FIFOF#(UMF_CHUNK) writeDataQ <- mkFIFOF();


    //
    // Dispatch to write states depending on available data
    //
    rule f2hTryWrite (writeState == WSTATE_TRY);
        // Any data left over from the last message?
        if (writeDataChunksRemaining != 0)
        begin
            // Yes.  Keep writing.
            writeState <= WSTATE_CONT;
        end
        else if (writeDataQ.notEmpty())
        begin
            // Start a new message.
            writeState <= WSTATE_START;
        end
        else if (spinCycles == 0)
        begin
            // Give up: no message.  Must fill the buffer to respond.
            writeState <= WSTATE_CONT;
        end

        numWrittenChunks <= 0;
        numUsefulWriteChunks <= 0;

        spinCycles <= spinCycles - 1;
    endrule

        
    //
    // Start a new message
    //
    rule f2hStartWrite (writeState == WSTATE_START);
        UMF_PACKET_HEADER header = unpack(pack(writeDataQ.first()));
        writeDataQ.deq();
        
        // Guarantee that the header is non-zero to differentiate it from
        // a no-data message.
        header.phyChannelPvt = 1;

        dataToHost.enq(unpack(pack(header)));

        writeDataChunksRemaining <= header.numChunks;
        
        if (rawWriteChunksRemaining == 1)
        begin
            // No more room in this packet for the rest of the message.  The
            // rest will go in the next packet.
            writeState <= WSTATE_LAST;
        end
        else
        begin
            writeState <= WSTATE_CONT;
        end

        rawWriteChunksRemaining <= rawWriteChunksRemaining - 1;

        let written_chunks = numWrittenChunks + 1;
        numUsefulWriteChunks <= written_chunks;
        numWrittenChunks <= written_chunks;
    endrule


    //
    // Emit write data or fill the write buffer with NODATA messages
    //
    rule f2hContWrite (writeState == WSTATE_CONT);
        if ((writeDataChunksRemaining == 0) && writeDataQ.notEmpty())
        begin
            // Not doing anything useful here and there is a new message
            // ready.  Start the new message.
            writeState <= WSTATE_START;
        end
        else
        begin
            let written_chunks = numWrittenChunks + 1;
            numWrittenChunks <= written_chunks;

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

            if (rawWriteChunksRemaining == 1)
            begin
                writeState <= WSTATE_LAST;
            end

            rawWriteChunksRemaining <= rawWriteChunksRemaining - 1;
        end
    endrule


    //
    // Dummy write to host when no write data is permitted.
    //
    rule h2fWriteDummy (writeState == WSTATE_DUMMY);
        dataToHost.enq(0);
        
        if (rawWriteChunksRemaining == 1)
        begin
            writeState <= WSTATE_LAST;
        end

        numUsefulWriteChunks <= 0;
        rawWriteChunksRemaining <= rawWriteChunksRemaining - 1;
    endrule


    //
    // Final write stage -- emit a pointer to the last useful chunk in the
    // message.
    //
    rule f2hCompleteWrite ((writeState == WSTATE_LAST) &&
                           (readState == RSTATE_DONE));
        F2H_CMD cmd;
        cmd.numF2HChunks = zeroExtend(numUsefulWriteChunks);

        //
        // Host -> FPGA error?
        //
        if (h2fErrRecovery matches tagged Valid .err)
            cmd.h2fError = zeroExtend(err.rawChunksRemaining);
        else
            cmd.h2fError = 0;
        dataFromHost.resetErrorFlag();

        dataToHost.enq(zeroExtend(pack(cmd)));

        writeState <= WSTATE_READY;
        readState <= RSTATE_READY;
    endrule

    
    // ====================================================================
    //
    // Error recovery
    //
    // ====================================================================
    
    //
    // consumeErrantReadData --
    //     An error was detected in the current host -> FPGA data stream.
    //     Consume the remaining of the buffer.  It will be resent.
    //
    rule consumeErrantReadData (readState == RSTATE_ERROR);
        dataFromHost.deq();

        if (rawReadChunksRemaining == 1)
        begin
            readState <= RSTATE_DONE;
        end

        rawReadChunksRemaining <= rawReadChunksRemaining - 1;
    endrule
    

    //
    // recoverFromErrantReadData --
    //     The previous host -> FPGA message was transmitted incorrectly and
    //     has been resent.  This rule consumes the part of the resent data
    //     that has already been consumed correctly.
    //
    rule recoverFromErrantReadData (readState == RSTATE_RECOVER);
        let r_state = validValue(h2fErrRecovery);
        if (r_state.rawChunksRemaining == rawReadChunksRemaining)
        begin
            readState <= r_state.readState;
            readDataChunksRemaining <= r_state.dataChunksRemaining;

            h2fErrRecovery <= tagged Invalid;
        end
        else
        begin
            dataFromHost.deq();
            rawReadChunksRemaining <= rawReadChunksRemaining - 1;
        end
    endrule


    // ====================================================================
    //
    // Debug (register) interface
    //
    // ====================================================================

    //
    // dbgRegWrite --
    //     The host may request updates of state here.  This is not currently
    //     used.  A dummy bit is written (and readable in dbgRegRead below)
    //     to force preservation of the syncFIFOs used for writing and keep
    //     the synthesis tools from complaining about the TIG on them being
    //     optimized away.
    //
    Reg#(Bit#(1)) regWriteDummy <- mkReg(0);

    rule dbgRegWrite (True);
        match {.addr, .data} <- edgeDriver.regWrite();
        regWriteDummy <= data[0];
    endrule


    //
    // dbgRegRead --
    //     Export current state using a side channel.  The side channel
    //     isn't perfect.  It can only be used when no ACP_MemCopy()
    //     is in flight.
    //
    //     Results flow through a FIFO to avoid reading and writing a syncFIFO
    //     in the same rule, which seems to be difficult for timing.
    //
    FIFO#(NALLATECH_REG_DATA) regReadQ <- mkFIFO();

    rule dbgRegRead (True);
        let addr <- edgeDriver.regReadReq();

        Bit#(64) last_cmd = zeroExtend(pack(lastReqHeader));

        NALLATECH_REG_DATA r = ?;
        case (addr)
            // 3-0 holds the most recent command
            0: r = last_cmd[15:0];
            1: r = last_cmd[31:16];
            2: r = last_cmd[47:32];
            3: r = last_cmd[63:48];

            // Current read/write states
            4: r = zeroExtend(pack(readState));
            5: r = zeroExtend(pack(writeState));

            // Number of chunks left to process
            6: r = zeroExtend(pack(rawReadChunksRemaining));
            7: r = zeroExtend(pack(rawWriteChunksRemaining));

            // Model I/O FIFO states
            8: r = zeroExtend(pack({ pack(writeDataQ.notEmpty()),
                                     pack(readBuffer.notFull()) }));

            // Check value (make sure register reads are returning correct values)
          100: r ='h5309;
          101: r = zeroExtend(regWriteDummy);
        endcase
        
        regReadQ.enq(r);
    endrule
         
    rule dbgRegReadRsp (True);
        let r = regReadQ.first();
        regReadQ.deq();

        edgeDriver.regReadRsp(r);
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
