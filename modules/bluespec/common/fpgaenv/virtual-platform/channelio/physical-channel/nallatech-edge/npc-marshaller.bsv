import Vector::*;
import FIFO::*;
import SpecialFIFOs::*;

// MARSHALLER

// A marshaller takes one larger value and breaks it into a stream of n output chunks.
// Chunks are sent out starting from the LS chunk and ending with the MS chunk

interface NPC_MARSHALLER#(parameter type in_T, parameter type out_T);

    // Enq a new value
    method Action enq(in_T val);

    // Look the next chunk.
    method out_T  first();

    // Deq the the chunk.
    method Action deq();

endinterface

module mkNPCMarshaller
    // interface:
        (NPC_MARSHALLER#(in_T, out_T))
    provisos
        (Bits#(in_T, in_SZ),
         Bits#(out_T, out_SZ),
         Div#(in_SZ, out_SZ, k__),
         Log#(k__, idx_SZ));

    // The absolute maximum index into our chunks
    Integer maxIdx = valueof(k__) - 1;
    
    // An index telling which chunk is next.
    Reg#(Bit#(idx_SZ)) idx <- mkReg(0);
    
    // Incoming data
    FIFO#(in_T) inQ <- mkBypassFIFO();
    
    // Outbound data
    FIFO#(out_T) outQ <- mkFIFO();

    //
    // Marshall incoming data stream to output stream
    //
    rule marshallData (True);
        let val = inQ.first();

        Bit#(in_SZ) pval = pack(val);
        Vector#(k__, Bit#(out_SZ)) new_chunks = newVector();
    
        for (Integer x = 0; x < valueof(k__); x = x + 1)
        begin
         
            Bit#(out_SZ) chunk = 0;
            
            for (Integer y = 0; y < valueof(out_SZ); y = y + 1)
            begin
          
                Integer z = x * valueof(out_SZ) + y;
                chunk[y] = (z < valueof(in_SZ)) ? pval[z] : 0;
          
            end
      
            new_chunks[x] = chunk;

        end

        // Write the next value to the output queue
        outQ.enq(unpack(new_chunks[idx]));

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


    // enq
    
    method Action enq(in_T val);

        inQ.enq(val);

    endmethod
    

    method out_T first() = outQ.first();
    

    method Action deq();

        outQ.deq();

    endmethod

endmodule
