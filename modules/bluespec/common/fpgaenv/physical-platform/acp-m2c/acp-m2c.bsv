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

import FIFO::*;
import Clocks::*;

// htg-v5-pcie-enabled

// The Physical Platform for the HTG Virtex 5 with PCI Express.

`include "clocks_device.bsh"
`include "arches_mpi_device.bsh"

// PHYSICAL_DRIVERS

// This represents the collection of all platform capabilities which the
// rest of the FPGA uses to interact with the outside world.
// We use other modules to actually do the work.

interface PHYSICAL_DRIVERS;

    interface CLOCKS_DRIVER     clocksDriver;
    interface ARCHES_MPI_DRIVER archesMPIDriver;

endinterface

// TOP_LEVEL_WIRES

// The TOP_LEVEL_WIRES is the datatype which gets passed to the top level
// and output as input/output wires. These wires are then connected to
// physical pins on the FPGA as specified in the accompanying UCF file.
// These wires are defined in the individual devices.

interface TOP_LEVEL_WIRES;

    (* prefix = "" *)
    interface ARCHES_MPI_WIRES archesMPIWires;
    
endinterface

// PHYSICAL_PLATFORM

// The platform is the aggregation of wires and drivers.

interface PHYSICAL_PLATFORM;

    interface PHYSICAL_DRIVERS physicalDrivers;
    interface TOP_LEVEL_WIRES  topLevelWires;

endinterface

// mkPhysicalPlatform

// This is a convenient way for the outside world to instantiate all the devices
// and an aggregation of all the wires.

module mkPhysicalPlatform
       //interface: 
                    (PHYSICAL_PLATFORM);

    // The Platform is instantiated inside a NULL clock domain. Our first course of
    // action should be to instantiate the Clocks Physical Device and obtain interfaces
    // to clock and reset the other devices with.
    
    // The ACP infrastructure is currently organized in a monolithic hierarchy comprising
    // of all top-level wires. We will re-factor this in future, but for now, we simply
    // instantiate the entire infrastructure as part of the "ARCHES-MPI" device, and
    // derive the drivers and wires for all "physical devices" from it.
    
    // Soft reset will be handled internally in the ARCHES-MPI device. The reset that
    // the device hands to us will have soft-reset wired-in.
    
    ARCHES_MPI_DEVICE arches_mpi_device <- mkArchesMPIDevice();
    
    // Instantiate all other physical devices
    
    // Aggregate the drivers
    
    interface PHYSICAL_DRIVERS physicalDrivers;
    
        interface clocksDriver    = arches_mpi_device.clocks_driver;
        interface archesMPIDriver = arches_mpi_device.mpi_driver;
    
    endinterface
    
    // Aggregate the wires
    
    interface TOP_LEVEL_WIRES topLevelWires;
    
        interface archesMPIWires  = arches_mpi_device.wires;

    endinterface
               
endmodule
