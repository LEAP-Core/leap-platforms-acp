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
`include "asim/provides/fpga_components.bsh"
`include "asim/provides/clocks_device.bsh"

// ARCHES_MPI_DRIVER

interface ARCHES_MPI_DRIVER;

    method MPI_DATA    data_value();
    method MPI_CONTROL data_control();                          
    method Action      data_deq();
        
    method MPI_DATA    cmd_value();
    method MPI_CONTROL cmd_control();
    method Action      cmd_deq();
    
    method Action      data_enq(MPI_DATA data, MPI_CONTROL control);
    method Action      cmd_enq (MPI_DATA data, MPI_CONTROL control);
        
endinterface

// ARCHES_MPI_WIRES

// Arches MPI Wires are defined in the primitive device

// ARCHES_MPI_DEVICE

// By convention a Device is a Driver and a Wires

interface ARCHES_MPI_DEVICE;

    interface ARCHES_MPI_DRIVER mpi_driver;
    interface ARCHES_MPI_WIRES  wires;
    
    interface CLOCKS_DRIVER     clocks_driver;
        
endinterface


// mkArchesMPIDevice

// Take the primitive device import and cross the clock domains into the
// default bluespec domain. Also wrap the raw driver interfaces into
// more structured and readable interfaces.

module mkArchesMPIDevice
    // interface:
                 (ARCHES_MPI_DEVICE);

    // Instantiate the primitive device.

    PRIMITIVE_ARCHES_MPI_DEVICE prim_device <- mkPrimitiveArchesMPIDevice();

    // Get the Clock and Reset, and do the required multiplication/division
    
    Clock mpeClock = prim_device.clock;
    Reset mpeReset = prim_device.reset;
    
    Clock rawClock = prim_device.rawClock;
    Reset rawReset = prim_device.rawReset;
    
    let userClockPackage <- mkUserClock(`CRYSTAL_CLOCK_FREQ,
                                        `MODEL_CLOCK_MULTIPLIER,
                                        `MODEL_CLOCK_DIVIDER,
                                        clocked_by rawClock,
                                        reset_by   rawReset);
    
    Clock modelClock = userClockPackage.clk;

    Reset transReset <- mkAsyncReset(0, mpeReset, modelClock);
    Reset modelReset <- mkResetEither(transReset, userClockPackage.rst, clocked_by modelClock);

    // Synchronizers
    
    SyncFIFOIfc#(Tuple2#(MPI_DATA, MPI_CONTROL)) sync_data_in_q
                                              <- mkSyncFIFO(2, mpeClock, mpeReset, modelClock);
        
    SyncFIFOIfc#(Tuple2#(MPI_DATA, MPI_CONTROL)) sync_cmd_in_q
                                              <- mkSyncFIFO(2, mpeClock, mpeReset, modelClock);
        
    SyncFIFOIfc#(Tuple2#(MPI_DATA, MPI_CONTROL)) sync_data_out_q
                                              <- mkSyncFIFO(2, modelClock, modelReset, mpeClock);
    
    SyncFIFOIfc#(Tuple2#(MPI_DATA, MPI_CONTROL)) sync_cmd_out_q
                                              <- mkSyncFIFO(2, modelClock, modelReset, mpeClock);
    

    //
    // Rules for synchronizing from Arches to Model domain
    //
        
    rule sync_data_in (True);
            
        sync_data_in_q.enq(tuple2(prim_device.data_value(), prim_device.data_control()));
        prim_device.data_deq();
        
    endrule

    rule sync_cmd_in (True);
            
        sync_cmd_in_q.enq(tuple2(prim_device.cmd_value(), prim_device.cmd_control()));
        prim_device.cmd_deq();
        
    endrule

    //
    // Rules for synchronizing from Model to Arches domain
    //
    
    // WARNING: see warning note below.
    
    rule sync_data_out (True);
            
        match { .v, .c } = sync_data_out_q.first();
        sync_data_out_q.deq();
        prim_device.data_enq(v, c);
        
    endrule
        
    rule sync_cmd_out (True);
            
        match { .v, .c } = sync_cmd_out_q.first();
        sync_cmd_out_q.deq();
        prim_device.cmd_enq(v, c);
        
    endrule
        
    //
    // Drivers
    //
    
    interface ARCHES_MPI_DRIVER mpi_driver;
        
        method MPI_DATA data_value();
            
            match { .v, .c } = sync_data_in_q.first();
            return v;
            
        endmethod
            
        method MPI_CONTROL data_control();
            
            match { .v, .c } = sync_data_in_q.first();
            return c;
            
        endmethod
            
        method Action data_deq();
            
            sync_data_in_q.deq();
            
        endmethod
        
        method MPI_DATA cmd_value();
            
            match { .v, .c } = sync_cmd_in_q.first();
            return v;
            
        endmethod
            
        method MPI_CONTROL cmd_control();
            
            match { .v, .c } = sync_cmd_in_q.first();
            return c;
            
        endmethod
            
        method Action cmd_deq();
            
            sync_cmd_in_q.deq();
            
        endmethod
        
        //
        // WARNING WARNING WARNING
        //
        // We've observed that there might be an ordering requirement between
        // the enqueuing of the Command and Data words into the Primitive
        // Device's FIFOs. We'll assume that the Sync FIFOs preserve the
        // relative sequencing between the Command and the Data.
        //
        
        method Action data_enq(MPI_DATA data, MPI_CONTROL control);
            
            sync_data_out_q.enq(tuple2(data, control));
            
        endmethod

        method Action cmd_enq (MPI_DATA data, MPI_CONTROL control);
            
            sync_cmd_out_q.enq(tuple2(data, control));
            
        endmethod
        
    endinterface
    
    // The Arches MPI device currently also provides the Clocks driver
    
    interface CLOCKS_DRIVER clocks_driver;
        
        interface Clock clock = modelClock;
        interface Reset reset = modelReset;
            
        interface Clock rawClock = rawClock;
        interface Reset rawReset = rawReset;
            
    endinterface
    
    // Pass through the wires interface
    
    interface wires = prim_device.wires;
        
endmodule
