import Vector::*;
import FIFO::*;

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
        
    // Reset the marshaller and drop the unread data on the floor
    method Action clear();

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
    
    // A vector to store the current chunks we're marshalling
    Reg#(Vector#(k__, Bit#(out_SZ))) chunks <- mkReg(Vector::replicate(0));
    
    // An index telling which chunk is next.
    Reg#(Bit#(idx_SZ)) idx <- mkReg(0);
    
    // Are we done with the current value?
    Reg#(Bool) done <- mkReg(True);

    // enq
    
    // Add the chunk to the first place in the vector and
    // shift the other elements. Also set the max number of chunks
    // for the next operation.
    
    method Action enq(in_T val) if (done);
    
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
    
        chunks <= new_chunks;        
        done <= False;
      
    endmethod
    
    // first
    
    // Return the next chunk
    
    method out_T first() if (!done);
    
        Bit#(out_SZ) final_value = chunks[idx];
      
        return unpack(final_value);
    
    endmethod
    
    // deq
    
    // Increment the index.
    
    method Action deq() if (!done);
    
        if (idx == fromInteger(maxIdx))
        begin
            done <= True;
            idx <= 0;
        end
        else
        begin
            idx <= idx + 1;
        end
    
    endmethod

    // Reset the marshaller and drop the unread data on the floor
    
    method Action clear();
        
        done <= True;
        idx <= 0;
        
    endmethod

endmodule
