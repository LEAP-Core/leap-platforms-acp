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
import Vector::*;
import List::*;

`include "asim/provides/librl_bsv_base.bsh"


//
// DDR properties, computed from device specific properties...
//

typedef `DRAM_NUM_BANKS FPGA_DDR_BANKS;
typedef `DRAM_MAX_OUTSTANDING_READS FPGA_DDR_MAX_OUTSTANDING_READS;

// The smallest addressable word:
typedef Bit#(FPGA_DDR_WORD_SZ) FPGA_DDR_WORD;

// The DRAM controller uses both clock edges to pass data, which appears to
// be 2 words per cycle.  Addresses are little endian, so the low address
// goes in the low bits.  Most of the interfaces in this module pass:
typedef TMul#(`SRAM_BURST_LENGTH, FPGA_DDR_WORD_SZ) FPGA_DDR_DUALEDGE_BEAT_SZ;
typedef Bit#(FPGA_DDR_DUALEDGE_BEAT_SZ) FPGA_DDR_DUALEDGE_BEAT;

typedef TDiv#(FPGA_DDR_DUALEDGE_BEAT_SZ, FPGA_DDR_WORD_SZ) FPGA_DDR_WORDS_PER_BEAT;
typedef TDiv#(FPGA_DDR_DUALEDGE_BEAT_SZ, 8) FPGA_DDR_BYTES_PER_BEAT;
typedef TDiv#(FPGA_DDR_WORD_SZ, 8) FPGA_DDR_BYTES_PER_WORD;

// Each byte in a write may be disabled for writes using a bit mask.
// !!! NOTE: to conform to the controller, a mask bit is 0 to request a write !!!
typedef Bit#(FPGA_DDR_BYTES_PER_WORD) FPGA_DDR_WORD_MASK;
typedef Bit#(TDiv#(FPGA_DDR_DUALEDGE_BEAT_SZ, 8)) FPGA_DDR_DUALEDGE_BEAT_MASK;

// Capacity of the memory (addressing FPGA_DDR_WORDs):
typedef Bit#(FPGA_DDR_ADDRESS_SZ) FPGA_DDR_ADDRESS;

// The controller may expect multiple data messages per address request,
// called a burst.  Define a container large enough to hold a 1-based
// counter for bursts.
typedef Bit#(TLog#(TAdd#(FPGA_DDR_BURST_LENGTH, 1))) FPGA_DDR_BURST_IDX;
// Convenience definition for the maximum 0-based burst index.
typedef TSub#(FPGA_DDR_BURST_LENGTH, 1) FPGA_DDR_LAST_BURST_IDX;


//
// DDR_DRIVER
//
// Interface to SRAM
//
interface DDR_DRIVER;
    method Action readReq(FPGA_DDR_ADDRESS addr);
    method ActionValue#(FPGA_DDR_DUALEDGE_BEAT) readRsp();
    method Action writeReq(FPGA_DDR_ADDRESS addr);
    method Action writeData(FPGA_DDR_DUALEDGE_BEAT data, FPGA_DDR_DUALEDGE_BEAT_MASK mask);
    method List#(Tuple2#(String, Bool)) debugScanState();

`ifndef DRAM_DEBUG_Z
    // Methods enabled only for debugging the controller:

    // Get status.  Should never block.
    method Bit#(64) statusCheck();
    // Set the maximum number of outstanding reads permitted.  Useful for
    // calibrating sync buffer sizes.
    method Action setMaxReads(Bit#(TLog#(TAdd#(`DRAM_MAX_OUTSTANDING_READS, 1))) maxReads);
`endif
endinterface


//
// DDR_DEVICE exports both the driver interface and the top level wires.
//
interface DDR_DEVICE;
    interface DDR_DRIVER driver;
    interface DDR_WIRES  wires;
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
    STATE_INIT,
    STATE_READY
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
    (DDR_DEVICE);

    // Clock the glue logic with the output clock.
    Clock modelClock <- exposeCurrentClock();
    Reset modelReset <- exposeCurrentReset();

    // Instantiate the primitive device.
    PRIMITIVE_DDR_SRAM_DEVICE prim_device <- mkPrimitiveDDRSRAMDevice(ramClk0, ramClk200, ramClk270, ramClkLocked, topLevelReset);

    // State
    Reg#(FPGA_DDR_STATE) state <- mkReg(STATE_INIT);

    // Clock the glue logic with the Controller's clock
    Clock controllerClock = prim_device.clk_out;
    Reset controllerReset = prim_device.rst_out;

    //
    // Synchronizers from Controller to Model
    //

    // Read buffer (size this buffer to sustain as many DRAM bursts as needed)
    // We need 2 independent queues to read in the raw data from the 2 controllers
    SyncFIFOIfc#(FPGA_DDR_DUALEDGE_BEAT) syncReadDataQ <-
        mkSyncFIFO(`DRAM_MAX_OUTSTANDING_READS * valueOf(FPGA_DDR_BURST_LENGTH),
                   controllerClock, controllerReset, modelClock);

    //
    // Synchronizers from Model to Controller
    //

    // Request queue
    SyncFIFOIfc#(FPGA_DDR_REQUEST) syncRequestQ <- mkSyncFIFO(8, modelClock, modelReset, controllerClock);

    // Write data queue
    SyncFIFOIfc#(Tuple2#(FPGA_DDR_DUALEDGE_BEAT, FPGA_DDR_DUALEDGE_BEAT_MASK))
        syncWriteDataQ <- mkSyncFIFO(8, modelClock, modelReset, controllerClock);
    
    // Keep track of the number of reads in flight
    COUNTER#(TLog#(TAdd#(`DRAM_MAX_OUTSTANDING_READS, 1))) nInflightReads <- mkLCounter(0);
    Reg#(FPGA_DDR_BURST_IDX) readBurstCnt <- mkReg(fromInteger(valueOf(FPGA_DDR_LAST_BURST_IDX)));


    //
    // Extra buffering using the simplest FIFO to mitigate timing errors for
    // the DDR (high speed) code communicating with compilated sync FIFOs.
    // The buffering presents a simple register to the client.
    //
    FIFO#(FPGA_DDR_DUALEDGE_BEAT)
        readBuffer <- mkLFIFO(clocked_by controllerClock, reset_by controllerReset);

    FIFO#(Tuple2#(FPGA_DDR_DUALEDGE_BEAT, FPGA_DDR_DUALEDGE_BEAT_MASK))
        writeBuffer <- mkLFIFO(clocked_by controllerClock, reset_by controllerReset);


    //
    // On ACP it appears that ECC bits are interleaved among the data
    // bits.  The problem is mask bits cover 9 bits each, not 8!  We aren't
    // using ECC, but must be careful to spread the data bits out so
    // they will be masked correctly.
    //
    function Bit#(TMul#(FPGA_DDR_BYTES_PER_WORD, 9)) insertSpaceForECC(FPGA_DDR_WORD w);
        Vector#(FPGA_DDR_BYTES_PER_WORD, Bit#(8)) v_in = unpack(w);
        Vector#(FPGA_DDR_BYTES_PER_WORD, Bit#(9)) v_out = map(zeroExtend, v_in);
        return pack(v_out);
    endfunction

    function FPGA_DDR_WORD removeSpaceForECC(Bit#(TMul#(FPGA_DDR_BYTES_PER_WORD, 9)) w);
        Vector#(FPGA_DDR_BYTES_PER_WORD, Bit#(9)) v_in = unpack(w);
        Vector#(FPGA_DDR_BYTES_PER_WORD, Bit#(8)) v_out = map(truncate, v_in);
        return pack(v_out);
    endfunction


    //
    // ===== Rules =====
    //
    
    // Rules for synchronizing from Controller to Model
    
    //
    // The timing path from the controller to the sync FIFO is often tight.
    // Sacrifice a cycle to simplify placement.  We should probably solve this
    // by hard wiring the position of the sync FIFO and controller, but we haven't.
    //
    (* fire_when_enabled *)
    rule readRAMDataToBuffer (prim_device.ram.dequeue_data_RDY());
        let d1 = removeSpaceForECC(prim_device.ram.dequeue_data_rise());
        let d2 = removeSpaceForECC(prim_device.ram.dequeue_data_fall());
        readBuffer.enq({d1, d2});
    endrule
    
    rule readRAMBufferToModel (True);
        let d = readBuffer.first();
        readBuffer.deq();

        syncReadDataQ.enq(d);
    endrule
    

    // 
    // Rules for synchronizing from Model to Controller
    //

    rule processReadRequest (prim_device.ram.enqueue_address_RDY() &&&
                             prim_device.ram.ddr_device_RDY() &&&
                             syncRequestQ.first() matches tagged DRAM_READ .address);
        syncRequestQ.deq();
        prim_device.ram.enqueue_address(address, READ);
    endrule

    
    //
    // Writes come in as two data messages and a control message.  They
    // must be forwarded with precise timing to the DRAM.  Timing of reading
    // directly from the sync FIFO seems to be unreliable.  The code here
    // avoids timing problems by copying an entire write request into
    // registers within the DRAM clock domain before forwarding a request.
    //

    Reg#(Vector#(FPGA_DDR_BURST_LENGTH, FPGA_DDR_DUALEDGE_BEAT)) writeValue <- mkRegU(clocked_by controllerClock, reset_by controllerReset);
    Reg#(Vector#(FPGA_DDR_BURST_LENGTH, FPGA_DDR_DUALEDGE_BEAT_MASK)) writeValueMask <- mkRegU(clocked_by controllerClock, reset_by controllerReset);
    Reg#(Bool) writePending <- mkReg(False, clocked_by controllerClock, reset_by controllerReset);
    Reg#(FPGA_DDR_BURST_IDX) writeBurstIdx <- mkReg(0, clocked_by controllerClock, reset_by controllerReset);

    //
    // writeDataToBuffer --
    //     Extra buffering to simplify timing.
    //
    rule writeDataToBuffer (True);
        let wd = syncWriteDataQ.first();
        syncWriteDataQ.deq();        

        writeBuffer.enq(wd);
    endrule

    //
    // copyWriteData --
    //     Copy incoming write data from the sync FIFO to local registers.
    //
    rule copyWriteData (writeBurstIdx != fromInteger(valueOf(FPGA_DDR_BURST_LENGTH)) &&
                        ! writePending);
        match {.data, .mask} = writeBuffer.first();
        writeBuffer.deq();

        writeValue[writeBurstIdx] <= data;
        writeValueMask[writeBurstIdx] <= mask;
        
        writeBurstIdx <= writeBurstIdx + 1;
    endrule


    //
    // processWriteRequest0 --
    //     Stage 0 of write request.  Send control message and first chunk of data
    //     to the memory controller.
    //
    rule processWriteRequest0 (prim_device.ram.enqueue_address_RDY() &&&
                               ! writePending &&&
                               (writeBurstIdx == fromInteger(valueOf(FPGA_DDR_BURST_LENGTH))) &&&
                               syncRequestQ.first() matches tagged DRAM_WRITE .address);
        syncRequestQ.deq();

        // address + command
        prim_device.ram.enqueue_address(address, WRITE);
        
        // Data + mask
        Tuple2#(FPGA_DDR_WORD, FPGA_DDR_WORD) tup = unpack(writeValue[0]);
        Tuple2#(FPGA_DDR_WORD_MASK, FPGA_DDR_WORD_MASK) tup2 = unpack(writeValueMask[0]);
        match {.d1, .d2} = tup;
        match {.m1, .m2} = tup2;
        prim_device.ram.enqueue_data(insertSpaceForECC(d1), m1,
                                     insertSpaceForECC(d2), m2);

        if (valueOf(FPGA_DDR_LAST_BURST_IDX) == 0)
        begin
            // Burst is only one message
            writeBurstIdx <= 0;
        end
        else
        begin
            // Write the rest of the burst
            writeBurstIdx <= 1;
            writePending <= True;
        end
    endrule

    
    //
    // processWriteRequest 1--
    //   Stage two of write request.  Forward remainder of data to the memory.
    //   This rule *MUST* fire in the cycle immediately after the previous rule.
    //
    (* fire_when_enabled *)
    rule processWriteRequest1 (writePending);
        // Data + mask
        Tuple2#(FPGA_DDR_WORD, FPGA_DDR_WORD) tup = unpack(writeValue[writeBurstIdx]);
        Tuple2#(FPGA_DDR_WORD_MASK, FPGA_DDR_WORD_MASK) tup2 = unpack(writeValueMask[writeBurstIdx]);
        match {.d1, .d2} = tup;
        match {.m1, .m2} = tup2;
        prim_device.ram.enqueue_data(insertSpaceForECC(d1), m1,
                                     insertSpaceForECC(d2), m2);
        
        if (writeBurstIdx == fromInteger(valueOf(FPGA_DDR_LAST_BURST_IDX)))
        begin
            // Burst complete
            writeBurstIdx <= 0;
            writePending <= False;
        end
        else
        begin
            // Write the rest of the burst
            writeBurstIdx <= writeBurstIdx + 1;
        end
    endrule    


    // ====================================================================
    //
    // Initialization
    //
    // ====================================================================

    Reg#(Bit#(1)) initPhase <- mkReg(0);

    //
    // initPhase0 --
    //     Keep read sync FIFO from being eliminated by issuing a loopback
    //     read to write.
    //
    Reg#(Bit#(2)) init0Stage <- mkReg(0);
    Reg#(FPGA_DDR_BURST_IDX) initBurstIdx <- mkReg(0);
    
    rule initPhase0 ((state == STATE_INIT) &&
                     (initPhase == 0) &&
                     (ramClkLocked == 1));
        case (init0Stage)
        0:  begin
                syncRequestQ.enq(tagged DRAM_READ 0);
                init0Stage <= 1;
            end
        1:  begin
                syncRequestQ.enq(tagged DRAM_WRITE 0);
                init0Stage <= 2;
            end
        2:  begin
                let d = syncReadDataQ.first();
                syncReadDataQ.deq();

                syncWriteDataQ.enq(tuple2(d, 0));

                if (initBurstIdx == fromInteger(valueOf(FPGA_DDR_LAST_BURST_IDX)))
                begin
                    initBurstIdx <= 0;
                    initPhase <= 1;
                end
                else
                begin
                    initBurstIdx <= initBurstIdx + 1;
                end
            end
        endcase
    endrule


    //
    // initPhase1 --
    //     Write a constant pattern to initialize memory.
    //
    Reg#(FPGA_DDR_ADDRESS) initAddr <- mkReg(0);
    
    rule initPhase1 ((state == STATE_INIT) && (initPhase == 1));
        // Data to write
        Vector#(FPGA_DDR_BYTES_PER_BEAT, Bit#(8)) init_data = replicate('haa);

        // Write request on first burst
        if (initBurstIdx == 0)
        begin
            syncRequestQ.enq(tagged DRAM_WRITE initAddr);
        end

        syncWriteDataQ.enq(tuple2(pack(init_data), 0));

        // Update address at the end of a burst
        if (initBurstIdx == fromInteger(valueOf(FPGA_DDR_LAST_BURST_IDX)))
        begin
            // Point to next dual-edge data address
            let next_addr = initAddr + fromInteger(valueOf(TMul#(FPGA_DDR_BURST_LENGTH, FPGA_DDR_WORDS_PER_BEAT)));
            initAddr <= next_addr;

            if (next_addr == 0)
            begin
                state <= STATE_READY;
            end

            initBurstIdx <= 0;
        end
        else
        begin
            initBurstIdx <= initBurstIdx + 1;
        end
    endrule


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
    
    rule forwardIncomingReq (state == STATE_READY);
        let r = mergeReqQ.first();
        mergeReqQ.deq();

        syncRequestQ.enq(r);
    endrule


`ifndef DRAM_DEBUG_Z
    //
    // Debugging...
    //

    // Useful for calibrating the optimal size of DRAM_MAX_OUTSTANDING_READS
    Reg#(Bit#(TLog#(TAdd#(`DRAM_MAX_OUTSTANDING_READS, 1)))) calibrateMaxReads <-
        mkReg(`DRAM_MAX_OUTSTANDING_READS);

    // Status from the RAM controller clock domain
    Reg#(Bit#(64)) syncStatus <- mkSyncReg(0, controllerClock, controllerReset, modelClock);

    rule statusUpd (True);
        Bit#(64) status = 0;
        
        status[0]  = pack(prim_device.ram.enqueue_address_RDY());
        status[1]  = pack(prim_device.ram.enqueue_data_RDY());
        status[2]  = pack(prim_device.ram.dequeue_data_RDY());
        status[7]  = pack(syncReadDataQ.notFull());
        status[8]  = 0;
        status[10] = pack(syncRequestQ.notEmpty());
        status[12] = pack(syncWriteDataQ.notEmpty());
        status[14] = 0;
        status[15] = 0;
        status[18] = pack(writeBurstIdx == 0);

        syncStatus <= status;
    endrule
`endif


    // Drivers visible to upper layers
    interface DDR_DRIVER driver;
    
`ifndef DRAM_DEBUG_Z
        method Bit#(64) statusCheck();
            Bit#(64) status = 0;
            status[3]  = pack(mergeReqQ.notEmpty());
            status[4]  = pack(mergeReqQ.ports[0].notFull());
            status[5]  = pack(mergeReqQ.ports[1].notFull());
            status[6]  = pack(syncReadDataQ.notEmpty());
            status[9]  = 0;
            status[11] = pack(syncRequestQ.notFull());
            status[13] = pack(syncWriteDataQ.notFull());
            status[16] = pack(nInflightReads.value() == 0);
            status[17] = pack(readBurstCnt == 0);
            status[19] = pack(state);

            return status | syncStatus;
        endmethod

        //
        // setMaxReads --
        //     Set a maximum number of outstanding reads that may be lower than
        //     the available buffer size.  Useful for building one time and
        //     finding the optimal buffer size.
        //
        method Action setMaxReads(Bit#(TLog#(TAdd#(`DRAM_MAX_OUTSTANDING_READS, 1))) maxReads);
            calibrateMaxReads <= maxReads;
        endmethod
`endif

        method Action readReq(FPGA_DDR_ADDRESS addr) if ((state == STATE_READY) &&
`ifndef DRAM_DEBUG_Z
                                                         (nInflightReads.value() < calibrateMaxReads) &&
`endif
                                                         (nInflightReads.value() < `DRAM_MAX_OUTSTANDING_READS));
            mergeReqQ.ports[0].enq(tagged DRAM_READ addr);
            nInflightReads.up();
        endmethod

        method ActionValue#(FPGA_DDR_DUALEDGE_BEAT) readRsp() if (state == STATE_READY);
            let d = syncReadDataQ.first();
            syncReadDataQ.deq();

            if (readBurstCnt == 0)
            begin
                nInflightReads.down();
                readBurstCnt <= fromInteger(valueOf(FPGA_DDR_LAST_BURST_IDX));
            end
            else
            begin
                readBurstCnt <= readBurstCnt - 1;
            end

            return d;
        endmethod


        method Action writeReq(FPGA_DDR_ADDRESS addr) if (state == STATE_READY);
            mergeReqQ.ports[1].enq(tagged DRAM_WRITE addr);
        endmethod
        
        method Action writeData(FPGA_DDR_DUALEDGE_BEAT data, FPGA_DDR_DUALEDGE_BEAT_MASK mask) if (state == STATE_READY);
            syncWriteDataQ.enq(tuple2(data, mask));
        endmethod

        method List#(Tuple2#(String, Bool)) debugScanState();
            return List::nil;
        endmethod
    endinterface


    // Pass through the wires interface
    interface wires = prim_device.wires;
endmodule
