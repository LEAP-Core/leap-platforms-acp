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
    interface ARCHES_MPI_WIRES  mpi_wires;
    
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

    // Pass through the drivers interface
    
    interface ARCHES_MPI_DRIVER mpi_driver;
        
        method data_value   = prim_device.data_value;
        method data_control = prim_device.data_control;
        method data_deq     = prim_device.data_deq;
        
        method cmd_value    = prim_device.cmd_value;
        method cmd_control  = prim_device.cmd_control;
        method cmd_deq      = prim_device.cmd_deq;
    
        method data_enq     = prim_device.data_enq;
        method cmd_enq      = prim_device.cmd_enq;
        
    endinterface
    
    // The Arches MPI device currently also provides the Clocks driver
    
    interface CLOCKS_DRIVER clocks_driver;
        
        interface Clock clock = prim_device.clock;
        interface Reset reset = prim_device.reset;
            
        interface Clock rawClock = prim_device.clock;
        interface Reset rawReset = prim_device.reset;
            
    endinterface
    
    // Pass through the wires interface
    
    interface mpi_wires = prim_device.wires;
        
endmodule
