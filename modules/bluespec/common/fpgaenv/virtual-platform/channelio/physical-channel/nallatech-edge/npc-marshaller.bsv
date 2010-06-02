//
// Copyright (C) 2010 Intel Corporation
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

import Vector::*;
import FIFO::*;
import SpecialFIFOs::*;

`include "asim/provides/librl_bsv_base.bsh"


// MARSHALLER

// A marshaller takes one larger value and breaks it into a stream of n output chunks.
// Chunks are sent out starting from the LS chunk and ending with the MS chunk

interface NPC_MARSHALLER#(parameter type t_IN, parameter type t_OUT);
    // Enq a new value
    method Action enq(t_IN val);

    // Look the next chunk.
    method t_OUT  first();

    // Deq the the chunk.
    method Action deq();

    // An error was seen in a chunk.  The error state will remain set until
    // the resetErrorFlag method is invoked.
    method Bool errorDetected();
    method Action resetErrorFlag();
endinterface


//
// mkNPCMarshaller --
//     Marshall in type to out type.  Assumes that the out type tiles evenly
//     inside the in type.
//
module mkNPCMarshaller
    // interface:
    (NPC_MARSHALLER#(t_IN, t_OUT))
    provisos
        (Bits#(t_IN, t_IN_SZ),
         Bits#(t_OUT, t_OUT_SZ),
         NumAlias#(TDiv#(t_IN_SZ, t_OUT_SZ), n_OUT_PER_IN),
         Alias#(Bit#(TLog#(n_OUT_PER_IN)), t_IDX),

         // Assert that the output tiles evenly into the input
         Mul#(n_OUT_PER_IN, t_OUT_SZ, t_IN_SZ));

    // The absolute maximum index into our chunks
    let maxIdx = valueOf(TSub#(n_OUT_PER_IN, 1));

    // An index telling which chunk is next.
    Reg#(t_IDX) idx <- mkReg(0);

    // Incoming data
    FIFO#(t_IN) inQ <- mkBypassFIFO();

    // Outbound data
    FIFO#(t_OUT) outQ <- mkFIFO();

    //
    // Marshall incoming data stream to output stream
    //
    rule marshallData (True);
        let val = inQ.first();

        Vector#(n_OUT_PER_IN, t_OUT) new_chunks = unpack(pack(val));

        // Write the next value to the output queue
        outQ.enq(new_chunks[idx]);

        // Done with the input entry?
        if (idx == fromInteger(maxIdx))
        begin
            // Yes
            inQ.deq();
            idx <= 0;
        end
        else
        begin
            // No
            idx <= idx + 1;
        end
    endrule


    //
    // Methods
    //

    method Action enq(t_IN val);
        inQ.enq(val);
    endmethod

    method t_OUT first() = outQ.first();

    method Action deq();
        outQ.deq();
    endmethod

    method Bool errorDetected() = False;

    method Action resetErrorFlag();
    endmethod
endmodule


//
// mkNPCErrorDetectingMarshaller --
//     Extend the marshaller to add a protocol for detecting errors.  The last
//     output chunk is a checksum of all other chunks in a single input value.
//     The checksum output chunk is dropped from the data stream.  Success
//     of the checksum is indicated by the errorDetected method.
//
module mkNPCErrorDetectingMarshaller
    // interface:
    (NPC_MARSHALLER#(t_IN, t_OUT))
    provisos
        (Bits#(t_IN, t_IN_SZ),
         Bits#(t_OUT, t_OUT_SZ),
         NumAlias#(TDiv#(t_IN_SZ, t_OUT_SZ), n_OUT_PER_IN),
         Alias#(Bit#(TLog#(n_OUT_PER_IN)), t_IDX),

         // Assert that the output tiles evenly into the input
         Mul#(n_OUT_PER_IN, t_OUT_SZ, t_IN_SZ));

    let maxDataIdx = valueOf(TSub#(n_OUT_PER_IN, 2));
    let maxIdx = valueOf(TSub#(n_OUT_PER_IN, 1));

    // An index telling which chunk is next.
    Reg#(t_IDX) idx <- mkReg(0);

    // Incoming data
    FIFO#(t_IN) inQ <- mkBypassFIFO();

    // Outbound data
    FIFO#(t_OUT) outQ <- mkFIFO();

    // Found a data error?  State is persistent until resetErrorFlag() is called.
    Reg#(Bool) error <- mkReg(False);
    Wire#(Bool) resetError <- mkDWire(False);

    //
    // Marshall incoming data stream to output stream
    //
    rule marshallData (! resetError);
        let val = inQ.first();

        Vector#(n_OUT_PER_IN, t_OUT) new_chunks = unpack(pack(val));

        // Check for data errors using a simple checksum
        Bit#(t_OUT_SZ) sum = 0;
        for (Integer i = 0; i < valueOf(n_OUT_PER_IN) - 1; i = i + 1)
        begin
            sum = sum + pack(new_chunks[i]);
        end
        error <= error || (sum != pack(new_chunks[valueOf(n_OUT_PER_IN) - 1]));

        // Write the next value to the output queue
        outQ.enq(new_chunks[idx]);

        // Done with the input entry?
        if (idx == fromInteger(maxDataIdx))
        begin
            // Yes
            inQ.deq();
            idx <= 0;
        end
        else
        begin
            // No
            idx <= idx + 1;
        end
    endrule


    //
    // Methods
    //

    method Action enq(t_IN val);
        inQ.enq(val);
    endmethod

    method t_OUT first() = outQ.first();

    method Action deq();
        outQ.deq();
    endmethod

    method Bool errorDetected() = error;

    method Action resetErrorFlag();
        error <= False;
        resetError <= True;
    endmethod
endmodule
