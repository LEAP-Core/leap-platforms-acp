import Vector::*;
import FIFO::*;


// DeMarshaller

// A de-marshaller takes n input "chunks" and produces one larger value.
// Chunks are received starting from the LS chunk and ending with the MS chunk

// interface
interface NPC_DEMARSHALLER#(parameter type in_T, parameter type out_T);
    
    // insert a chunk
    method Action enq(in_T chunk);
        
    // read the whole completed value
    method out_T first();

    // dequeue the completed value
    method Action deq();
    
    // fill the entire output width with the given data
    method Action fill(out_T data);
        
    // if the demarshaller already has some data, pad it out
    // and prepare the output
    method Action flush();

endinterface

// module
module mkNPCDeMarshaller
    // interface:
        (NPC_DEMARSHALLER#(in_T, out_T))
    provisos
        (Bits#(in_T, in_SZ),
         Bits#(out_T, out_SZ),
         Div#(out_SZ, in_SZ, k__),
         Log#(k__, idx_SZ),
         PrimSelectable#(out_T, Bit#(1)));
    
    // =============== state ================
    
    // degree (max number of chunks) of our shift register
    Integer degree = valueof(k__);
    
    // shift register we fill up as chunks come in.
    Vector#(k__, Reg#(Bit#(in_SZ))) chunks = newVector();
    
    // fill in the vector
    for (Integer x = degree - 1; x >= 0; x = x - 1)
    begin
        chunks[x] <- mkReg(0);
    end
    
    // number of chunks remaining in current sequence
    Reg#(Bit#(TAdd#(idx_SZ, 1))) chunksRemaining <- mkReg(fromInteger(degree));
    
    // demarshaller state
    Reg#(Bool) flushing <- mkReg(False);
    
    // =============== rules ===============
    
    rule do_flush (flushing && chunksRemaining != 0);
        
        // newer chunks are closer to the MSB.
        if (degree != 0)
        begin
            chunks[degree-1] <= 0;
        end
      
        // Do the shift with a for loop
        for (Integer x = 0; x < degree-1; x = x+1)
        begin
            chunks[x] <= chunks[x+1];
        end
        
        // decrement chunks remaining
        chunksRemaining <= chunksRemaining - 1;        
        
        if (chunksRemaining == 1)
        begin
        
            flushing <= False;
            
        end
        
    endrule


    // =============== methods ===============
    
    // add the chunk to the first place in the vector and
    // shift the other elements.
    method Action enq(in_T chunk) if (!flushing && chunksRemaining != 0);
    
        // newer chunks are closer to the MSB.
        if (degree != 0)
        begin
            chunks[degree-1] <= pack(chunk);
        end
      
        // Do the shift with a for loop
        for (Integer x = 0; x < degree-1; x = x+1)
        begin
            chunks[x] <= chunks[x+1];
        end
        
        // decrement chunks remaining
        chunksRemaining <= chunksRemaining - 1;
        
    endmethod
    
    // dequeue the output register and prepare to accept a new sequence
    method Action deq() if (chunksRemaining == 0);
    
        chunksRemaining <= fromInteger(degree);
    
    endmethod

    // return the entire vector
    method out_T first() if (chunksRemaining == 0);
    
        Bit#(out_SZ) final_val = 0;
      
        // this is where the good stuff happens
        // fill in the result one bit at a time
        for (Integer x = 0; x < valueof(out_SZ); x = x + 1)
        begin
        
            Integer j = x / valueof(in_SZ);
            Integer k = x % valueof(in_SZ);
            final_val[x] = chunks[j][k];
      
        end
        
        // return
        return unpack(final_val);
    
    endmethod

    // fill the entire output width with the given data
    method Action fill(out_T data) if (!flushing && chunksRemaining == fromInteger(degree));
    
        // split input data into chunks
        Vector#(k__, Bit#(in_SZ)) split = newVector();
    
        // fill in the vector
        for (Integer x = 0; x < valueof(out_SZ); x = x + 1)
        begin
        
            Integer j = x / valueof(in_SZ);
            Integer k = x % valueof(in_SZ);
            split[j][k] = data[x];
      
        end
        
        // copy the split into the chunks register
        for (Integer x = degree - 1; x >= 0; x = x - 1)
        begin
            chunks[x] <= split[x];
        end
    
        chunksRemaining <= 0;

    endmethod
        
    // if the demarshaller already has some data, pad it out
    // and prepare the output
    method Action flush();
        
        if (chunksRemaining != 0 && chunksRemaining != fromInteger(degree))
        begin
                
            flushing <= True;

        end
        
    endmethod

endmodule
