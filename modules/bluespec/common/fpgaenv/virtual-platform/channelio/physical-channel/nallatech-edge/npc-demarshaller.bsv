import Vector::*;
import FIFO::*;
import SpecialFIFOs::*;


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

endinterface

// module
module mkNPCDeMarshaller
    // interface:
        (NPC_DEMARSHALLER#(in_T, out_T))
    provisos
        (Bits#(in_T, in_SZ),
         Bits#(out_T, out_SZ),
         Div#(out_SZ, in_SZ, n_CHUNKS),
         Log#(n_CHUNKS, idx_SZ),
         PrimSelectable#(out_T, Bit#(1)));
    
    // =============== state ================
    
    // degree (max number of chunks) of our shift register
    Integer degree = valueof(n_CHUNKS);
    
    // shift register we fill up as chunks come in.
    Reg#(Vector#(n_CHUNKS, Bit#(in_SZ))) partialData <- mkRegU();
    
    // number of chunks remaining in current sequence
    Reg#(Bit#(idx_SZ)) nextChunk <- mkReg(0);
    
    // Output FIFO.
    FIFO#(out_T) outQ <- mkBypassFIFO();

    // =============== methods ===============
    
    // add the chunk to the first place in the vector and
    // shift the other elements.

    method Action enq(in_T new_chunk);
    
        // newer chunks are closer to the MSB.
        Vector#(n_CHUNKS, Bit#(in_SZ)) chunks = partialData;
        chunks[nextChunk] = pack(new_chunk);

        if (nextChunk == fromInteger(valueOf(TSub#(n_CHUNKS, 1))))
        begin
            // Output chunk is ready
            Bit#(out_SZ) final_val = 0;

            // this is where the good stuff happens
            // fill in the result one bit at a time
            for (Integer x = 0; x < valueof(out_SZ); x = x + 1)
            begin

                Integer j = x / valueof(in_SZ);
                Integer k = x % valueof(in_SZ);
                final_val[x] = chunks[j][k];

            end

            outQ.enq(unpack(final_val));
            nextChunk <= 0;
        end
        else
        begin
            // More chunks to collect remain
            partialData <= chunks;
            nextChunk <= nextChunk + 1;
        end
        
    endmethod
    

    method Action deq();

        outQ.deq();

    endmethod


    method out_T first() = outQ.first();

endmodule
