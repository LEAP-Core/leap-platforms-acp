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
    STATE_init,
    STATE_ready,

    STATE_h2f_start_read,
    STATE_h2f_cont_read,
    STATE_h2f_write,

    STATE_f2h_read,
    STATE_f2h_start_write,
    STATE_f2h_cont_write
}
STATE
    deriving (Bits, Eq);

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
    Reg#(STATE) state <- mkReg(STATE_init);

    // link to nallatech driver
    NALLATECH_EDGE_DRIVER edgeDriver = drivers.nallatechEdgeDriver;

    // data (de)marshallers
    NPC_MARSHALLER#(NALLATECH_FIFO_DATA, UMF_CHUNK)   dataFromHost <- mkNPCMarshaller();
    NPC_DEMARSHALLER#(UMF_CHUNK, NALLATECH_FIFO_DATA) dataToHost   <- mkNPCDeMarshaller();

    // buffers
    FIFOF#(UMF_CHUNK)  readBuffer <- mkFIFOF();
    FIFOF#(UMF_CHUNK) writeBuffer <- mkFIFOF();

    // other state
    Reg#(UMF_MSG_LENGTH) chunksRemaining     <- mkReg(0);
    Reg#(UMF_MSG_LENGTH) dataChunksRemaining <- mkReg(0);

    //
    // Initialization
    //
    
    rule cmd_init (state == STATE_init);
        
        state <= STATE_ready;
        
    endrule
    
    //
    // Attach Marshaller and DeMarshaller
    //
    
    rule marshall_from_device (True);
        
        dataFromHost.enq(edgeDriver.first());
        edgeDriver.deq();
        
    endrule
    
    rule demarshall_to_device (True);
        
        edgeDriver.enq(dataToHost.first());
        dataToHost.deq();
        
    endrule

    //
    // Accept a new request from software
    //
 
    rule accept_request (state == STATE_ready);
        
        let cmd = dataFromHost.first();
        dataFromHost.deq();
        
        case (cmd)
            
            `CHANNEL_REQUEST_H2F : state <= STATE_h2f_start_read;
            `CHANNEL_REQUEST_F2H : state <= STATE_f2h_read;
            
        endcase
        
        chunksRemaining <= `NALLATECH_TRANSFER_SIZE - 1;
        
    endrule
    
    //
    // Host to FPGA transfer. Read Stage transfers the real data + pad,
    // Write stage writes out an ACK + pad.
    //

    rule h2f_start_read (state == STATE_h2f_start_read);
        
        UMF_CHUNK header = dataFromHost.first();
        dataFromHost.deq();
        
        UMF_PACKET packet = tagged UMF_PACKET_header unpack(header);
        
        readBuffer.enq(header);

        dataChunksRemaining  <= packet.UMF_PACKET_header.numChunks;
        
        chunksRemaining <= chunksRemaining - 1;
        state <= STATE_h2f_cont_read;
        
    endrule
        
    rule h2f_cont_read (state == STATE_h2f_cont_read);
        
        UMF_CHUNK chunk = dataFromHost.first();
        dataFromHost.deq();
        
        if (dataChunksRemaining != 0)
        begin
                
            readBuffer.enq(chunk);
            dataChunksRemaining <= dataChunksRemaining - 1;
            
        end

        if (chunksRemaining == 1)
        begin
    
            dataToHost.enq(`CHANNEL_RESPONSE_ACK);
            state <= STATE_h2f_write;
            chunksRemaining <= `NALLATECH_TRANSFER_SIZE - 1;
            
        end
        else
        begin
        
            chunksRemaining <= chunksRemaining - 1;
            
        end
        
    endrule
    
    rule h2f_write (state == STATE_h2f_write);
        
        dataToHost.enq(0);
        
        if (chunksRemaining == 1)
        begin
            
            state <= STATE_ready;
            
        end

        chunksRemaining <= chunksRemaining - 1;
        
    endrule
        
    //
    // FPGA to Host transfer. Read Stage transfers the padding,
    // Write stage writes out the message + pad.
    //

    rule f2h_read (state == STATE_f2h_read);
        
        dataFromHost.deq();
        
        if (chunksRemaining == 1)
        begin
                
            chunksRemaining <= `NALLATECH_TRANSFER_SIZE - 1;

            if (writeBuffer.notEmpty())
            begin
                
                dataToHost.enq(`CHANNEL_RESPONSE_DATA);
                state <= STATE_f2h_start_write;
                
            end
            else
            begin
                
                dataToHost.enq(`CHANNEL_RESPONSE_NODATA);
                dataChunksRemaining <= 0;
                state <= STATE_f2h_cont_write;
                
            end
            
        end
        else
        begin

            chunksRemaining <= chunksRemaining - 1;
            
        end
        
    endrule
        
    rule f2h_start_write (state == STATE_f2h_start_write);

        UMF_CHUNK header = writeBuffer.first();
        writeBuffer.deq();
        
        UMF_PACKET packet = tagged UMF_PACKET_header unpack(header);
        
        dataToHost.enq(header);

        dataChunksRemaining  <= packet.UMF_PACKET_header.numChunks;
        
        chunksRemaining <= chunksRemaining - 1;
        state <= STATE_f2h_cont_write;

    endrule

    rule f2h_cont_write (state == STATE_f2h_cont_write);
        
        if (dataChunksRemaining != 0)
        begin
        
            dataToHost.enq(writeBuffer.first());
            writeBuffer.deq();
            
            dataChunksRemaining <= dataChunksRemaining - 1;
            
        end
        else
        begin
                
            dataToHost.enq(0);
            
        end

        if (chunksRemaining == 1)
        begin
    
            state <= STATE_ready;
            
        end
        else
        begin
        
            chunksRemaining <= chunksRemaining - 1;
            
        end
        
    endrule
    
    //
    // Methods
    //
    
    // read
    method ActionValue#(UMF_CHUNK) read();
        
        UMF_CHUNK chunk = readBuffer.first();
        readBuffer.deq();
        
        return chunk;
        
    endmethod

    // write
    method Action write(UMF_CHUNK chunk);
        
        writeBuffer.enq(chunk);
        
    endmethod

endmodule
