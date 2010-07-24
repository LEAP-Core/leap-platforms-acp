

typedef struct {
   
  Bit#(64) payload;
  Bit#(64) fpga0Timestamp;
  Bit#(64) fpga1Timestamp;
  Bit#(64) payload2;

} IntraTestStruct deriving (Bits,Eq);