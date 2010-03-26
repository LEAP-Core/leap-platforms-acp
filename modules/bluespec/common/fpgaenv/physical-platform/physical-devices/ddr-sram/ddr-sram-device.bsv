//
// Copyright (C) 2009 Intel Corporation
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

import Clocks::*;
import FIFO::*;
import FIFOF::*;
import Vector::*;
import RWire::*;

`include "asim/provides/librl_bsv_base.bsh"

// DDR_SRAM_DRIVER

// Inspired by our DDR2_DRAM_DRIVER

interface DDR2_DRIVER;

    method Bit#(32) statusCheck();
    method Action readReq(FPGA_DDR_ADDRESS addr);
    method ActionValue#(FPGA_DDR_DUALEDGE_DATA) readRsp();
    method Action writeReq(FPGA_DDR_ADDRESS addr);
    method Action writeData(FPGA_DDR_DUALEDGE_DATA data, FPGA_DDR_DUALEDGE_DATA_MASK mask);

endinterface

// DDR_SRAM_WIRES

// DDR SRAM Wires are defined in the primitive device

// DDR_SRAM_DEVICE

// By convention a Device is a Driver and a Wires

interface DDR2_DEVICE;

    interface DDR2_DRIVER driver;
    interface DDR2_WIRES  wires;
        
endinterface

//
// A DRAM Request is either a read or write with an address
//
typedef union tagged
{
    FPGA_DDR_ADDRESS DRAM_READ;
    FPGA_DDR_ADDRESS DRAM_WRITE;
}
FPGA_DDR_REQUEST
    deriving (Bits, Eq);


// State
typedef enum
{
    STATE_init,
    STATE_ready
}
FPGA_DDR_STATE
    deriving (Bits, Eq);


//
// mkDDR2SRAMDevice
//
// Wrap the primitive device and deal with DDR.

module mkDDR2SRAMDevice
    #(Clock ramClk0,
      Clock ramClk200,
      Clock ramClk270,
      Bit#(1) ramClkLocked,
      Reset topLevelReset)
    // interface:
    (DDR2_DEVICE);

    // Clock the glue logic with the output clock.
    Clock modelClock <- exposeCurrentClock();
    Reset modelReset <- exposeCurrentReset();

    // Instantiate the primitive device.
    PRIMITIVE_DDR_SRAM_DEVICE prim_device <- mkPrimitiveDDRSRAMDevice(ramClk0, ramClk200, ramClk270, ramClkLocked, topLevelReset);

    // State
    Reg#(FPGA_DDR_STATE) state <- mkReg(STATE_ready);

    // Clock the glue logic with the Controller's clock
    Clock controllerClock = prim_device.clk_out;
    Reset controllerReset = prim_device.rst_out;

    //
    // Synchronizers from Controller to Model
    //

    // Read buffer (size this buffer to sustain as many DRAM bursts as needed)
    // We need 2 independent queues to read in the raw data from the 2 controllers
    SyncFIFOIfc#(FPGA_DDR_DUALEDGE_DATA) syncReadDataQ <-
        mkSyncFIFO(`SRAM_MAX_OUTSTANDING_READS * valueOf(FPGA_DDR_BURST_LENGTH),
                   controllerClock, controllerReset, modelClock);
    
    FIFO#(FPGA_DDR_DUALEDGE_DATA) readDataTimingQ <- mkFIFO();

    //
    // Synchronizers from Model to Controller
    //
    // Model requests a reset
    SyncFIFOIfc#(Bool) syncResetQ <- mkSyncFIFO(2, modelClock, modelReset, controllerClock);

    // Request queue
    SyncFIFOIfc#(FPGA_DDR_REQUEST) syncRequestQ <- mkSyncFIFO(2, modelClock, modelReset, controllerClock);

    // Write data queue
    SyncFIFOIfc#(Tuple2#(FPGA_DDR_DUALEDGE_DATA, FPGA_DDR_DUALEDGE_DATA_MASK))
        syncWriteDataQ <- mkSyncFIFO(2, modelClock, modelReset, controllerClock);
    
    // Status queue
    Reg#(Bit#(32)) syncStatus <- mkSyncReg(0, controllerClock, controllerReset, modelClock);

    // Keep track of the number of reads in flight
    COUNTER#(TLog#(TAdd#(`SRAM_MAX_OUTSTANDING_READS, 1))) nInflightReads <- mkLCounter(0);
    Reg#(Bit#(TLog#(TAdd#(FPGA_DDR_BURST_LENGTH, 1)))) readBurstCnt <- mkReg(fromInteger(valueOf(TSub#(FPGA_DDR_BURST_LENGTH, 1))));

    //
    // ===== Rules =====
    //
    
    // Rules for synchronizing from Controller to Model
    
    // Push incoming read data from the controller into the sync FIFO to cross
    // the clock boundary.
    (* fire_when_enabled *)
    rule readRAMDataToBuffer (prim_device.ram.dequeue_data_RDY());
        FPGA_DDR_WORD d1 = truncate(prim_device.ram.dequeue_data_rise());
        FPGA_DDR_WORD d2 = truncate(prim_device.ram.dequeue_data_fall());
        syncReadDataQ.enq({d1, d2});
    endrule
    
    rule forwardSyncReadData (True);
        readDataTimingQ.enq(syncReadDataQ.first());
        syncReadDataQ.deq();
    endrule
    

    // 
    // Rules for synchronizing from Model to Controller
    //
    
    rule processReadRequest (! syncResetQ.notEmpty() &&&
                             prim_device.ram.enqueue_address_RDY() &&&
                             syncRequestQ.first() matches tagged DRAM_READ .address);
        syncRequestQ.deq();
        prim_device.ram.enqueue_address(zeroExtend(address), READ);
        // Angshu prim_device.ram2.enqueue_address(zeroExtend(address), READ);

    endrule

    
    //
    // Writes come in as two data messages and a control message.  They
    // must be forwarded with precise timing to the DRAM.  Timing of reading
    // directly from the sync FIFO seems to be unreliable.  The code here
    // avoids timing problems by copying an entire write request into
    // registers within the DRAM clock domain before forwarding a request.
    //

    Reg#(Vector#(FPGA_DDR_BURST_LENGTH, FPGA_DDR_DUALEDGE_DATA)) writeValue <- mkRegU(clocked_by controllerClock, reset_by controllerReset);
    Reg#(Vector#(FPGA_DDR_BURST_LENGTH, FPGA_DDR_DUALEDGE_DATA_MASK)) writeValueMask <- mkRegU(clocked_by controllerClock, reset_by controllerReset);
    Reg#(Bit#(TLog#(TAdd#(1, FPGA_DDR_BURST_LENGTH)))) writeBurstIdx <- mkReg(0, clocked_by controllerClock, reset_by controllerReset);

    //
    // copyWriteData --
    //     Copy incoming write data from the sync FIFO to local registers.
    //
    rule copyWriteData (writeBurstIdx != fromInteger(valueOf(FPGA_DDR_BURST_LENGTH)) &&
                        ! syncResetQ.notEmpty());
        match {.data, .mask} = syncWriteDataQ.first();
        syncWriteDataQ.deq();        

        writeValue[writeBurstIdx] <= data;
        writeValueMask[writeBurstIdx] <= mask;
        
        writeBurstIdx <= writeBurstIdx + 1;

    endrule

    //
    // processWriteRequest0 --
    //     Stage 0 of write request.  Send control message and first half of data
    //     to the memory controller.
    //
    // FIXME: this code only works for BURST_LENGTH == 1. We need one processWriteRequest method
    //        for each item in the burst
    //
    rule processWriteRequest0 (! syncResetQ.notEmpty() &&&
                               prim_device.ram.enqueue_address_RDY() &&&
                               (writeBurstIdx == fromInteger(valueOf(FPGA_DDR_BURST_LENGTH))) &&&
                               syncRequestQ.first() matches tagged DRAM_WRITE .address);

        syncRequestQ.deq();

        // address + command
        prim_device.ram.enqueue_address(zeroExtend(address), WRITE);
        // Angshu prim_device.ram2.enqueue_address(zeroExtend(address), WRITE);
        
        // Data + mask
        // ICK  match {.d1, .d2} = unpack(writeValue[0]);
        Tuple2#(FPGA_DDR_WORD, FPGA_DDR_WORD) tup = unpack(writeValue[0]);
        Tuple2#(FPGA_DDR_WORD_MASK, FPGA_DDR_WORD_MASK) tup2 = unpack(writeValueMask[0]);
        match {.d1, .d2} = tup;
        match {.m1, .m2} = tup2;
        prim_device.ram.enqueue_data(zeroExtend(d1), zeroExtend(m1), zeroExtend(d2), zeroExtend(m2));

        writeBurstIdx <= 0;

    endrule
    
    //
    // processModelReset --
    //     Model reset needs to clear out partial writes.
    //
    rule processModelReset (True);
        syncResetQ.deq();

        writeBurstIdx <= 0;

        if (syncRequestQ.notEmpty())
            syncRequestQ.deq();

        if (syncWriteDataQ.notEmpty())
            syncWriteDataQ.deq();
    endrule

/*
    // ====================================================================
    //
    // Initialization
    //
    // ====================================================================

    Reg#(Bit#(2)) initPhase <- mkReg(0);

    Reg#(Bit#(10)) init0Loop <- mkReg(0);

    //
    // initPhase0 --
    //     A delay loop to make sure reset settles.  Also, the DDR2 low level
    //     driver is not reset by a soft reset.  There may be some reads left
    //     over from the last run.  Sync them.
    //
    rule initPhase0 ((state == STATE_init) && (initPhase == 0));
        if (syncReadDataQ.notEmpty())
        begin
            syncReadDataQ.deq();
        end

        // Reset partial store state in the DDR clock domain.  Send a few times
        // so the incoming request queue is guaranteed empty.
        if (init0Loop < 8)
            syncResetQ.enq(?);

        if (init0Loop == maxBound)
            initPhase <= 1;
        
        init0Loop <= init0Loop + 1;
    endrule


    Reg#(Bit#(2)) init1Loop <- mkReg(0);
    Reg#(Bit#(1)) datasink  <- mkReg(0);

    // UGLY HACK
    // Initialization rules: write and read some junk into the DRAM so that
    // the Sync FIFOs don't get optimized away by the synthesis tools. If the
    // Sync FIFOs get optimized away, then the TIG constraints in the UCF
    // file become invalid and ngdbuild complains.
    rule initPhase1 ((state == STATE_init) && (initPhase == 1));
        case (init1Loop) matches
            0: syncRequestQ.enq(tagged DRAM_READ 0);
            1: begin
                   datasink <= syncReadDataQ.first()[0];
                   syncReadDataQ.deq();
               end
            2: begin
                   syncRequestQ.enq(tagged DRAM_WRITE 0);
                   syncWriteDataQ.enq(tuple2(zeroExtend(datasink), 0));

                   datasink <= syncReadDataQ.first()[0];
                   syncReadDataQ.deq();
               end
            3: begin
                   syncWriteDataQ.enq(tuple2(zeroExtend(datasink), 0));
                   initPhase <= 2;
               end
        endcase

        init1Loop <= init1Loop + 1;
    endrule

    //
    // initPhase2 --
    //     Write a constant pattern to initialize memory.
    //
    Reg#(FPGA_DDR_ADDRESS) initAddr <- mkReg(0);
    Reg#(Bit#(1)) initPart <- mkReg(0);
    
    rule initPhase2 ((state == STATE_init) && (initPhase == 2));
        // Data to write
        Vector#(TDiv#(FPGA_DDR_DUALEDGE_DATA_SZ, 8), Bit#(8)) init_data = replicate('haa);

        if (initPart == 0)
        begin
            // First stage write.  Write the control message and the first
            // half of the data.
            syncWriteDataQ.enq(tuple2(pack(init_data), 0));
        end
        else
        begin
            // Second stage write.  Write the rest of the data and check whether
            // initialization is done.
            syncRequestQ.enq(tagged DRAM_WRITE initAddr);
            syncWriteDataQ.enq(tuple2(pack(init_data), 0));

            // Point to next dual-edge data address
            let next_addr = initAddr + fromInteger(valueOf(TMul#(FPGA_DDR_BURST_LENGTH, TDiv#(FPGA_DDR_DUALEDGE_DATA_SZ, FPGA_DDR_WORD_SZ))));
            initAddr <= next_addr;

            if (next_addr == 0)
            begin
                state <= STATE_ready;
            end
        end

        initPart <= initPart + 1;
    endrule
*/

    // ====================================================================
    //
    // Incoming read and write synchronization
    //
    // ====================================================================

    //
    // The sync fifos for the clock crossing are very temperamental.
    // These FIFOs both merge incoming read and write requests temporally
    // and isolate the synchronization from logic calling the read and
    // write methods in the interface.
    //

    MERGE_FIFOF#(2, FPGA_DDR_REQUEST) mergeReqQ <- mkMergeFIFOF();
    
    rule forwardIncomingReq (state == STATE_ready);
        let r = mergeReqQ.first();
        mergeReqQ.deq();

        syncRequestQ.enq(r);
    endrule


    rule statusUpd (True);

        Bit#(32) status = 0;
        
        status[0]  = pack(prim_device.ram.enqueue_address_RDY());
        status[1]  = pack(prim_device.ram.enqueue_data_RDY());
        status[2]  = pack(prim_device.ram.dequeue_data_RDY());
        status[7]  = pack(syncReadDataQ.notFull());
        status[8]  = pack(syncResetQ.notEmpty());
        status[10] = pack(syncRequestQ.notEmpty());
        status[12] = pack(syncWriteDataQ.notEmpty());
        status[14] = 0;
        status[15] = 0;
        status[18] = pack(writeBurstIdx == 0);

        syncStatus <= status;

    endrule

    // Drivers visible to upper layers
    interface DDR2_DRIVER driver;
    
        method Bit#(32) statusCheck();

            Bit#(32) status = 0;
            
            status[3]  = pack(mergeReqQ.notEmpty());
            status[4]  = pack(mergeReqQ.ports[0].notFull());
            status[5]  = pack(mergeReqQ.ports[1].notFull());
            status[6]  = pack(syncReadDataQ.notEmpty());
            status[9]  = pack(syncResetQ.notFull());
            status[11] = pack(syncRequestQ.notFull());
            status[13] = pack(syncWriteDataQ.notFull());
            status[16] = pack(nInflightReads.value() == 0);
            status[17] = pack(readBurstCnt == 0);

            status = status | syncStatus;

            return status;

        endmethod

        method Action readReq(FPGA_DDR_ADDRESS addr) if ((state == STATE_ready) &&
                                                         (nInflightReads.value() < `SRAM_MAX_OUTSTANDING_READS));
            mergeReqQ.ports[0].enq(tagged DRAM_READ addr);
            nInflightReads.up();
        endmethod

        method ActionValue#(FPGA_DDR_DUALEDGE_DATA) readRsp() if (state == STATE_ready);
            let d = readDataTimingQ.first();
            readDataTimingQ.deq();

            if (readBurstCnt == 0)
            begin
                nInflightReads.down();
                readBurstCnt <= fromInteger(valueOf(FPGA_DDR_BURST_LENGTH)) - 1;
            end
            else
            begin
                readBurstCnt <= readBurstCnt - 1;
            end

            return d;
        endmethod


        method Action writeReq(FPGA_DDR_ADDRESS addr) if (state == STATE_ready);
            mergeReqQ.ports[1].enq(tagged DRAM_WRITE addr);
        endmethod
        
        method Action writeData(FPGA_DDR_DUALEDGE_DATA data, FPGA_DDR_DUALEDGE_DATA_MASK mask) if (state == STATE_ready);
            syncWriteDataQ.enq(tuple2(data, mask));
        endmethod

    endinterface

    // Pass through the wires interface
    
    interface wires = prim_device.wires;
        
endmodule
