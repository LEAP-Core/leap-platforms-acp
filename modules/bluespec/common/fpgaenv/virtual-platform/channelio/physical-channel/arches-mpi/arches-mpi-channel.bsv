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

`include "arches_mpi_device.bsh"
`include "physical_platform.bsh"
`include "umf.bsh"

// TODO: move these to AWB
`define HOST_RANK          8'h0
`define MY_RANK            8'h2
`define MSG_SIZE_ZERO     22'h0
`define MSG_SIZE_ONE      22'h1

`define C_MPE_ANY_TAG     32'hFFFFFFF0
`define C_MPE_DATA_TAG    32'hCAFECAFE
`define C_MPE_ACK_TAG     32'hDEADBEEF
`define C_MPE_SEND_OPCODE  2'h1
`define C_MPE_RECV_OPCODE  2'h2

//
// Types
//

typedef enum
{
    STATE_init,
    STATE_ready
}
STATE
    deriving (Bits, Eq);

typedef enum
{
    SERVER_STATE_idle,
    SERVER_STATE_busy
}
SERVER_STATE
    deriving (Bits, Eq);

typedef enum
{
    OWNER_none,
    OWNER_send,
    OWNER_recv
}
OWNER
    deriving (Bits, Eq);

// physical channel interface
interface PHYSICAL_CHANNEL;
    
    method ActionValue#(UMF_CHUNK) read();
    method Action                  write(UMF_CHUNK chunk);

endinterface

// physical channel module
module mkPhysicalChannel#(PHYSICAL_DRIVERS drivers)
    // interface
                  (PHYSICAL_CHANNEL);
    
    // channel state
    Reg#(STATE) state <- mkReg(STATE_init);

    Reg#(Bit#(3)) initStage     <- mkReg(0);
    Reg#(Bit#(3)) recvReqStage  <- mkReg(0);
    Reg#(Bit#(3)) recvRespStage <- mkReg(0);
    Reg#(Bit#(3)) sendStage     <- mkReg(0);    
    
    Reg#(SERVER_STATE) sendServerState <- mkReg(SERVER_STATE_idle);
    Reg#(SERVER_STATE) recvServerState <- mkReg(SERVER_STATE_idle);

    Reg#(OWNER) queueOwner <- mkReg(OWNER_none);
    
    // link to arches driver
    ARCHES_MPI_DRIVER mpiDriver = drivers.archesMPIDriver;

    // my MPI rank
    Reg#(Bit#(8)) myRank <- mkReg(2);
    
    // buffers
    FIFOF#(UMF_CHUNK)  readBuffer <- mkFIFOF();
    FIFOF#(UMF_CHUNK) writeBuffer <- mkFIFOF();

    //
    // Scheduling: since the init, recv, and send rules share the same
    // command FIFO, we'll specify an explicit urgency (althouth init
    // never conflicts with send or recv.
    //
    
    (* descending_urgency = "cmd_init, cmd_recv_req, cmd_send" *)
    
    //
    // Initialization: we need to send a single MPI_Recv() request
    // which will return our rank etc.
    //
    
    rule cmd_init (state == STATE_init);
        
        case (initStage)
            
            0: mpiDriver.cmd_enq({ `C_MPE_RECV_OPCODE, `HOST_RANK, `MSG_SIZE_ZERO }, 1, False);
        
            1: mpiDriver.cmd_enq(`C_MPE_ANY_TAG, 0, False);
            
            2: begin
                   
                   MPI_DATA resp = mpiDriver.cmd_value();
                   mpiDriver.cmd_deq();
                   
                   myRank <= resp[23:16];

               end
            
            3: begin
                   
                   MPI_DATA resp = mpiDriver.cmd_value();
                   mpiDriver.cmd_deq();
                   
                   state <= STATE_ready;
                   
               end

        endcase
        
        initStage <= initStage + 1;
        
    endrule
    
    //
    // We will speculatively initiate recv() requests to the MPI
    // infrastructure and have incoming data ready to stream in.
    //
    // As a first implementation, we will only transfer 1
    // UMF_CHUNK at a time.
    //

    rule cmd_recv_req (state == STATE_ready && recvServerState == SERVER_STATE_idle && queueOwner != OWNER_send);

        case (recvReqStage)
            
            0: begin
                   
                   mpiDriver.cmd_enq({ `C_MPE_RECV_OPCODE, `HOST_RANK, `MSG_SIZE_ONE }, 1, False);
                   recvReqStage <= 1;

                   // lock the queue
                   queueOwner <= OWNER_recv;
                   
               end
        
            1: begin

                   mpiDriver.cmd_enq(`C_MPE_ANY_TAG, 0, False);
                   recvReqStage <= 0;
                   
                   // recv server is now busy and cannot accept any more
                   // recv requests
                   recvServerState <= SERVER_STATE_busy;
                   
                   // unlock the queue
                   queueOwner <= OWNER_none;
                   
               end
            
        endcase
        
    endrule
    
    //
    // Process Recv responses (this is the only rule that reads the CMD-in FIFOs)
    //
    
    rule cmd_recv_resp (state == STATE_ready && recvServerState == SERVER_STATE_busy);
        
        case (recvRespStage)
            
            0: begin
                   
                   // ignore the header
                   mpiDriver.cmd_deq();                   
                   recvRespStage <= 1;
                   
               end
            
            1: begin
                   
                   // get the tag
                   MPI_DATA tag = mpiDriver.cmd_value();
                   mpiDriver.cmd_deq();
                   
                   // Also dequeue the Data. Since we use the same Recv request
                   // format to get Send-Acks, we need to piggyback a dummy payload
                   // with the send Acks. We drop this payload on the floor for
                   // Send-Acks, and enqueue it into the Read buffer for real data.
                   MPI_DATA data = mpiDriver.data_value();
                   mpiDriver.data_deq();
                   
                   // check if this is a data recv or a send-ack
                   if (tag == `C_MPE_ACK_TAG)
                   begin
                           
                       // send server can now accept requests again
                       sendServerState <= SERVER_STATE_idle;
                           
                   end
                   else // `C_MPE_DATA_TAG
                   begin
                       
                       // real data
                       readBuffer.enq(data);
                       
                   end
                   
                   // reset loop
                   recvRespStage <= 0;
                   
                   // recv server can now accept requests again
                   recvServerState <= SERVER_STATE_idle;

               end
            
        endcase
        
    endrule

    //
    // Send
    //
    
    rule cmd_send (state == STATE_ready && sendServerState == SERVER_STATE_idle && queueOwner != OWNER_recv);
       
        case (sendStage)
            
            0: begin
                   
                   mpiDriver.cmd_enq({ `C_MPE_SEND_OPCODE, `HOST_RANK, `MSG_SIZE_ONE }, 1, True);

                   mpiDriver.data_enq(writeBuffer.first(), 0);
                   writeBuffer.deq();        

                   sendStage  <= 1;
                   
                   // lock the queue
                   queueOwner <= OWNER_send;

               end
        
            1: begin

                   mpiDriver.cmd_enq(`C_MPE_DATA_TAG, 0, False);

                   // send server is now busy and cannot accept any more requests
                   // until we get an ACK from software
                   sendServerState <= SERVER_STATE_busy;

                   sendStage <= 0;
                   
                   // unlock the queue
                   queueOwner <= OWNER_none;
                   
               end
        
        endcase
        
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
