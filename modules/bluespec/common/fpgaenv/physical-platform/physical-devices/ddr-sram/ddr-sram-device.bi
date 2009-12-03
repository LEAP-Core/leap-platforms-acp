signature ¶ddr-sram-device¶ where {
import ¶FIFOF_®¶;
		
import ¶FIFOF®¶;
	       
import ¶FIFO®¶;
	      
import ¶List®¶;
	      
import ¶Clocks®¶;
		
import ¶PrimArray®¶;
		   
import ¶RWire®¶;
	       
import ¶Vector®¶;
		
import ¶ddr-sram-vhdl-import¶;
			     
interface (¶ddr-sram-device¶.DDR_SRAM_DRIVER :: *) = {
    ¶ddr-sram-device¶.readReq :: ¶ddr-sram-vhdl-import¶.FPGA_SRAM_ADDRESS ->
				 ¶Prelude®¶.¶Action®¶ {-# arg_names = [addr] #-};
    ¶ddr-sram-device¶.readRsp :: ¶Prelude®¶.¶ActionValue®¶
				 ¶ddr-sram-vhdl-import¶.FPGA_SRAM_DUALEDGE_DATA {-# arg_names = [] #-};
    ¶ddr-sram-device¶.writeReq :: ¶ddr-sram-vhdl-import¶.FPGA_SRAM_ADDRESS ->
				  ¶Prelude®¶.¶Action®¶ {-# arg_names = [addr] #-};
    ¶ddr-sram-device¶.writeData :: ¶ddr-sram-vhdl-import¶.FPGA_SRAM_DUALEDGE_DATA ->
				   ¶ddr-sram-vhdl-import¶.FPGA_SRAM_DUALEDGE_DATA_MASK ->
				   ¶Prelude®¶.¶Action®¶ {-# arg_names = [¡data¡, mask] #-}
};
 
instance ¶ddr-sram-device¶ ¶Prelude®¶.¶PrimMakeUndefined®¶ ¶ddr-sram-device¶.DDR_SRAM_DRIVER;
											    
instance ¶ddr-sram-device¶ ¶Prelude®¶.¶PrimMakeUninitialized®¶ ¶ddr-sram-device¶.DDR_SRAM_DRIVER;
												
instance ¶ddr-sram-device¶ ¶Prelude®¶.¶PrimDeepSeqCond®¶ ¶ddr-sram-device¶.DDR_SRAM_DRIVER;
											  
interface (¶ddr-sram-device¶.DDR_SRAM_DEVICE :: *) = {
    ¶ddr-sram-device¶.sram_driver :: ¶ddr-sram-device¶.DDR_SRAM_DRIVER;
    ¶ddr-sram-device¶.wires :: ¶ddr-sram-vhdl-import¶.DDR_SRAM_WIRES
};
 
instance ¶ddr-sram-device¶ ¶Prelude®¶.¶PrimMakeUndefined®¶ ¶ddr-sram-device¶.DDR_SRAM_DEVICE;
											    
instance ¶ddr-sram-device¶ ¶Prelude®¶.¶PrimMakeUninitialized®¶ ¶ddr-sram-device¶.DDR_SRAM_DEVICE;
												
instance ¶ddr-sram-device¶ ¶Prelude®¶.¶PrimDeepSeqCond®¶ ¶ddr-sram-device¶.DDR_SRAM_DEVICE;
											  
¶ddr-sram-device¶.mkDDRSRAMDevice :: (¶Prelude®¶.¶IsModule®¶ _m__ _c__) =>
				     _m__ ¶ddr-sram-device¶.DDR_SRAM_DEVICE
}
