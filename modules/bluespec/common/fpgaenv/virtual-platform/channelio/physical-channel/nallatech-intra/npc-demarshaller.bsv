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

// DeMarshaller

// A de-marshaller takes n input "chunks" and produces one larger value.
// Chunks are received starting from the LS chunk and ending with the MS chunk

// interface
interface NPC_DEMARSHALLER#(parameter type t_IN, parameter type t_OUT);
    // insert a chunk
    method Action enq(t_IN chunk);
        
    // read the whole completed value
    method t_OUT first();

    // dequeue the completed value
    method Action deq();
endinterface


//
// mkNPCDeMarshaller --
//     The demarshaller assumes that t_IN tiles evenly into t_OUT.
//
module mkNPCDeMarshaller
    // interface:
    (NPC_DEMARSHALLER#(t_IN, t_OUT))
    provisos
        (Bits#(t_IN, t_IN_SZ),
         Bits#(t_OUT, t_OUT_SZ),
         NumAlias#(TDiv#(t_OUT_SZ, t_IN_SZ), n_IN_PER_OUT),
         Alias#(Bit#(TLog#(n_IN_PER_OUT)), t_IDX),
         
         // Assert that the input tiles evenly into the output
         Mul#(n_IN_PER_OUT, t_IN_SZ, t_OUT_SZ));
    
    // =============== state ================
    
    // degree (max number of chunks) of our shift register
    let maxIdx = valueOf(TSub#(n_IN_PER_OUT, 1));

    // Current partial out value
    Reg#(t_OUT) collectOut <- mkRegU();

    // number of chunks remaining in current sequence
    Reg#(t_IDX) idx <- mkReg(0);
    
    // Output FIFO.
    FIFO#(t_OUT) outQ <- mkBypassFIFO();

    // =============== methods ===============

    method Action enq(t_IN new_chunk);
        Vector#(n_IN_PER_OUT, t_IN) in_vec = unpack(pack(collectOut));
        in_vec[idx] = new_chunk;

        t_OUT out_val = unpack(pack(in_vec));
        collectOut <= out_val;

        if (idx == fromInteger(maxIdx))
        begin
            outQ.enq(out_val);
            idx <= 0;
        end
        else
        begin
            idx <= idx + 1;
        end
    endmethod

    method Action deq();
        outQ.deq();
    endmethod

    method t_OUT first() = outQ.first();
endmodule
