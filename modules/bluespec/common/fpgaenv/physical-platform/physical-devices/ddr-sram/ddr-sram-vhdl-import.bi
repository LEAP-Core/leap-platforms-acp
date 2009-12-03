signature ¶ddr-sram-vhdl-import¶ where {
type (¶ddr-sram-vhdl-import¶.FPGA_SRAM_DUALEDGE_DATA_SZ :: #) = ¶Prelude®¶.¶TMul®¶ 2 36;
										       
type (¶ddr-sram-vhdl-import¶.FPGA_SRAM_DUALEDGE_DATA :: *) =
  ¶Prelude®¶.¶Bit®¶ ¶ddr-sram-vhdl-import¶.FPGA_SRAM_DUALEDGE_DATA_SZ;
								     
type (¶ddr-sram-vhdl-import¶.FPGA_SRAM_BURST_LENGTH :: #) = 2;
							     
type (¶ddr-sram-vhdl-import¶.FPGA_SRAM_WORD_MASK_SZ :: #) = 4;
							     
type (¶ddr-sram-vhdl-import¶.FPGA_SRAM_DUALEDGE_DATA_MASK :: *) =
  ¶Prelude®¶.¶Bit®¶ ¶ddr-sram-vhdl-import¶.FPGA_SRAM_WORD_MASK_SZ;
								 
type (¶ddr-sram-vhdl-import¶.FPGA_SRAM_ADDRESS_SZ :: #) = 21;
							    
type (¶ddr-sram-vhdl-import¶.FPGA_SRAM_ADDRESS :: *) =
  ¶Prelude®¶.¶Bit®¶ ¶ddr-sram-vhdl-import¶.FPGA_SRAM_ADDRESS_SZ;
							       
interface (¶ddr-sram-vhdl-import¶.DDR_SRAM_WIRES :: *) = {
    ¶ddr-sram-vhdl-import¶.w_ddrii_dq :: ¶Prelude®¶.¶Inout®¶
					 (¶Prelude®¶.¶Bit®¶ 36) {-# prefixs = "" #-};
    ¶ddr-sram-vhdl-import¶.w_ddrii_sa :: ¶Prelude®¶.¶Bit®¶ 21 {-# arg_names = [],
								  result = "ddrii_sa" #-};
    ¶ddr-sram-vhdl-import¶.w_ddrii_ld_n :: ¶Prelude®¶.¶Bit®¶ 1 {-# arg_names = [],
								   result = "ddrii_ln_n" #-};
    ¶ddr-sram-vhdl-import¶.w_ddrii_rw_n :: ¶Prelude®¶.¶Bit®¶ 1 {-# arg_names = [],
								   result = "ddrii_rw_n" #-};
    ¶ddr-sram-vhdl-import¶.w_ddrii_dll_off_n :: ¶Prelude®¶.¶Bit®¶ 1 {-# arg_names = [],
									result = "ddrii_dll_off_n" #-};
    ¶ddr-sram-vhdl-import¶.w_ddrii_bw_n :: ¶Prelude®¶.¶Bit®¶ 4 {-# arg_names = [],
								   result = "ddrii_bw_n" #-};
    ¶ddr-sram-vhdl-import¶.w_masterbank_sel_pin :: ¶Prelude®¶.¶Bit®¶ 1 ->
						   ¶Prelude®¶.¶Action®¶ {-# arg_names = [masterbank_sel_pin],
									    prefixs = "" #-};
    ¶ddr-sram-vhdl-import¶.w_cal_done :: ¶Prelude®¶.¶Bit®¶ 1 {-# arg_names = [],
								 result = "cal_done" #-};
    ¶ddr-sram-vhdl-import¶.w_ddrii_cq :: ¶Prelude®¶.¶Bit®¶ 1 ->
					 ¶Prelude®¶.¶Action®¶ {-# arg_names = [ddrii_cq], prefixs = "" #-};
    ¶ddr-sram-vhdl-import¶.w_ddrii_cq_n :: ¶Prelude®¶.¶Bit®¶ 1 ->
					   ¶Prelude®¶.¶Action®¶ {-# arg_names = [ddrii_cq], prefixs = "" #-};
    ¶ddr-sram-vhdl-import¶.w_ddrii_k :: ¶Prelude®¶.¶Bit®¶ 1 {-# arg_names = [], result = "ddrii_k" #-};
    ¶ddr-sram-vhdl-import¶.w_ddrii_k_n :: ¶Prelude®¶.¶Bit®¶ 1 {-# arg_names = [],
								  result = "ddrii_k_n" #-};
    ¶ddr-sram-vhdl-import¶.w_ddrii_c :: ¶Prelude®¶.¶Bit®¶ 1 {-# arg_names = [], result = "ddrii_c" #-};
    ¶ddr-sram-vhdl-import¶.w_ddrii_c_n :: ¶Prelude®¶.¶Bit®¶ 1 {-# arg_names = [],
								  result = "ddrii_c_n" #-}
};
 
instance ¶ddr-sram-vhdl-import¶ ¶Prelude®¶.¶PrimMakeUndefined®¶
				¶ddr-sram-vhdl-import¶.DDR_SRAM_WIRES;
								     
instance ¶ddr-sram-vhdl-import¶ ¶Prelude®¶.¶PrimMakeUninitialized®¶
				¶ddr-sram-vhdl-import¶.DDR_SRAM_WIRES;
								     
instance ¶ddr-sram-vhdl-import¶ ¶Prelude®¶.¶PrimDeepSeqCond®¶ ¶ddr-sram-vhdl-import¶.DDR_SRAM_WIRES;
												   
interface (¶ddr-sram-vhdl-import¶.PRIMITIVE_DDR_SRAM_DEVICE :: *) = {
    ¶ddr-sram-vhdl-import¶.wires :: ¶ddr-sram-vhdl-import¶.DDR_SRAM_WIRES {-# prefixs = "" #-};
    ¶ddr-sram-vhdl-import¶.enqueue_address :: ¶Prelude®¶.¶Bit®¶ 21 ->
					      ¶Prelude®¶.¶Bit®¶ 1 -> ¶Prelude®¶.¶Action®¶ {-# arg_names = [addr,
													   cmd] #-};
    ¶ddr-sram-vhdl-import¶.enqueue_data :: ¶Prelude®¶.¶Bit®¶ 36 ->
					   ¶Prelude®¶.¶Bit®¶ 4 ->
					   ¶Prelude®¶.¶Bit®¶ 36 ->
					   ¶Prelude®¶.¶Bit®¶ 4 -> ¶Prelude®¶.¶Action®¶ {-# arg_names = [data_rise,
													bw_mask_rise_n,
													data_fall,
													bw_mask_fall_n] #-};
    ¶ddr-sram-vhdl-import¶.dequeue_data_rise :: ¶Prelude®¶.¶Bit®¶ 36 {-# arg_names = [] #-};
    ¶ddr-sram-vhdl-import¶.dequeue_data_fall :: ¶Prelude®¶.¶Bit®¶ 36 {-# arg_names = [] #-}
};
 
instance ¶ddr-sram-vhdl-import¶ ¶Prelude®¶.¶PrimMakeUndefined®¶
				¶ddr-sram-vhdl-import¶.PRIMITIVE_DDR_SRAM_DEVICE;
										
instance ¶ddr-sram-vhdl-import¶ ¶Prelude®¶.¶PrimMakeUninitialized®¶
				¶ddr-sram-vhdl-import¶.PRIMITIVE_DDR_SRAM_DEVICE;
										
instance ¶ddr-sram-vhdl-import¶ ¶Prelude®¶.¶PrimDeepSeqCond®¶
				¶ddr-sram-vhdl-import¶.PRIMITIVE_DDR_SRAM_DEVICE;
										
¶ddr-sram-vhdl-import¶.mkPrimitiveDDRSRAMDevice :: (¶Prelude®¶.¶IsModule®¶ _m__ _c__) =>
						   ¶Prelude®¶.¶Clock®¶ ->
						   ¶Prelude®¶.¶Clock®¶ ->
						   ¶Prelude®¶.¶Clock®¶ ->
						   ¶Prelude®¶.¶Reset®¶ ->
						   ¶Prelude®¶.¶Reset®¶ ->
						   _m__ ¶ddr-sram-vhdl-import¶.PRIMITIVE_DDR_SRAM_DEVICE;
													
interface (¶ddr-sram-vhdl-import©¶.¶_ddr-sram-vhdl-import.PRIMITIVE_DDR_SRAM_DEVICE128©¶ :: # -> *)
	    _n0 = {
    ¶ddr-sram-vhdl-import¶.wires_w_ddrii_dq :: ¶Prelude®¶.¶Inout_®¶ 36 {-# prefixs = "w_ddrii_dq",
									   result = "w_ddrii_dq",
									   ready = "RDY_w_ddrii_dq",
									   enable = "EN_w_ddrii_dq" #-};
    ¶ddr-sram-vhdl-import¶.wires_w_ddrii_sa :: ¶Prelude®¶.¶Bit®¶ 21 {-# prefixs = "w_ddrii_sa",
									result = "w_ddrii_sa",
									ready = "RDY_w_ddrii_sa",
									enable = "EN_w_ddrii_sa" #-};
    ¶ddr-sram-vhdl-import¶.wires_w_ddrii_ld_n :: ¶Prelude®¶.¶Bit®¶ 1 {-# prefixs = "w_ddrii_ld_n",
									 result = "w_ddrii_ld_n",
									 ready = "RDY_w_ddrii_ld_n",
									 enable = "EN_w_ddrii_ld_n" #-};
    ¶ddr-sram-vhdl-import¶.wires_w_ddrii_rw_n :: ¶Prelude®¶.¶Bit®¶ 1 {-# prefixs = "w_ddrii_rw_n",
									 result = "w_ddrii_rw_n",
									 ready = "RDY_w_ddrii_rw_n",
									 enable = "EN_w_ddrii_rw_n" #-};
    ¶ddr-sram-vhdl-import¶.wires_w_ddrii_dll_off_n :: ¶Prelude®¶.¶Bit®¶
						      1 {-# prefixs = "w_ddrii_dll_off_n",
							    result = "w_ddrii_dll_off_n",
							    ready = "RDY_w_ddrii_dll_off_n",
							    enable = "EN_w_ddrii_dll_off_n" #-};
    ¶ddr-sram-vhdl-import¶.wires_w_ddrii_bw_n :: ¶Prelude®¶.¶Bit®¶ 4 {-# prefixs = "w_ddrii_bw_n",
									 result = "w_ddrii_bw_n",
									 ready = "RDY_w_ddrii_bw_n",
									 enable = "EN_w_ddrii_bw_n" #-};
    ¶ddr-sram-vhdl-import¶.wires_w_masterbank_sel_pin :: ¶Prelude®¶.¶Bit®¶ 1 ->
							 ¶Prelude®¶.¶ActionValue_®¶
							 _n0 {-# prefixs = "w_masterbank_sel_pin",
								 result = "w_masterbank_sel_pin",
								 ready = "RDY_w_masterbank_sel_pin",
								 enable = "EN_w_masterbank_sel_pin" #-};
    ¶ddr-sram-vhdl-import¶.wires_w_cal_done :: ¶Prelude®¶.¶Bit®¶ 1 {-# prefixs = "w_cal_done",
								       result = "w_cal_done",
								       ready = "RDY_w_cal_done",
								       enable = "EN_w_cal_done" #-};
    ¶ddr-sram-vhdl-import¶.wires_w_ddrii_cq :: ¶Prelude®¶.¶Bit®¶ 1 ->
					       ¶Prelude®¶.¶ActionValue_®¶ _n0 {-# prefixs = "w_ddrii_cq",
										  result = "w_ddrii_cq",
										  ready = "RDY_w_ddrii_cq",
										  enable = "EN_w_ddrii_cq" #-};
    ¶ddr-sram-vhdl-import¶.wires_w_ddrii_cq_n :: ¶Prelude®¶.¶Bit®¶ 1 ->
						 ¶Prelude®¶.¶ActionValue_®¶ _n0 {-# prefixs = "w_ddrii_cq_n",
										    result = "w_ddrii_cq_n",
										    ready = "RDY_w_ddrii_cq_n",
										    enable = "EN_w_ddrii_cq_n" #-};
    ¶ddr-sram-vhdl-import¶.wires_w_ddrii_k :: ¶Prelude®¶.¶Bit®¶ 1 {-# prefixs = "w_ddrii_k",
								      result = "w_ddrii_k",
								      ready = "RDY_w_ddrii_k",
								      enable = "EN_w_ddrii_k" #-};
    ¶ddr-sram-vhdl-import¶.wires_w_ddrii_k_n :: ¶Prelude®¶.¶Bit®¶ 1 {-# prefixs = "w_ddrii_k_n",
									result = "w_ddrii_k_n",
									ready = "RDY_w_ddrii_k_n",
									enable = "EN_w_ddrii_k_n" #-};
    ¶ddr-sram-vhdl-import¶.wires_w_ddrii_c :: ¶Prelude®¶.¶Bit®¶ 1 {-# prefixs = "w_ddrii_c",
								      result = "w_ddrii_c",
								      ready = "RDY_w_ddrii_c",
								      enable = "EN_w_ddrii_c" #-};
    ¶ddr-sram-vhdl-import¶.wires_w_ddrii_c_n :: ¶Prelude®¶.¶Bit®¶ 1 {-# prefixs = "w_ddrii_c_n",
									result = "w_ddrii_c_n",
									ready = "RDY_w_ddrii_c_n",
									enable = "EN_w_ddrii_c_n" #-};
    ¶ddr-sram-vhdl-import¶.enqueue_address :: ¶Prelude®¶.¶Bit®¶ 21 ->
					      ¶Prelude®¶.¶Bit®¶ 1 ->
					      ¶Prelude®¶.¶ActionValue_®¶ _n0 {-# prefixs = "enqueue_address",
										 result = "enqueue_address",
										 ready = "RDY_enqueue_address",
										 enable = "EN_enqueue_address" #-};
    ¶ddr-sram-vhdl-import¶.¡RDY_enqueue_address¡ :: ¶Prelude®¶.¶Bit®¶ 1;
    ¶ddr-sram-vhdl-import¶.enqueue_data :: ¶Prelude®¶.¶Bit®¶ 36 ->
					   ¶Prelude®¶.¶Bit®¶ 4 ->
					   ¶Prelude®¶.¶Bit®¶ 36 ->
					   ¶Prelude®¶.¶Bit®¶ 4 ->
					   ¶Prelude®¶.¶ActionValue_®¶ _n0 {-# prefixs = "enqueue_data",
									      result = "enqueue_data",
									      ready = "RDY_enqueue_data",
									      enable = "EN_enqueue_data" #-};
    ¶ddr-sram-vhdl-import¶.¡RDY_enqueue_data¡ :: ¶Prelude®¶.¶Bit®¶ 1;
    ¶ddr-sram-vhdl-import¶.dequeue_data_rise :: ¶Prelude®¶.¶Bit®¶ 36 {-# prefixs = "dequeue_data_rise",
									 result = "dequeue_data_rise",
									 ready = "RDY_dequeue_data_rise",
									 enable = "EN_dequeue_data_rise" #-};
    ¶ddr-sram-vhdl-import¶.¡RDY_dequeue_data_rise¡ :: ¶Prelude®¶.¶Bit®¶ 1;
    ¶ddr-sram-vhdl-import¶.dequeue_data_fall :: ¶Prelude®¶.¶Bit®¶ 36 {-# prefixs = "dequeue_data_fall",
									 result = "dequeue_data_fall",
									 ready = "RDY_dequeue_data_fall",
									 enable = "EN_dequeue_data_fall" #-};
    ¶ddr-sram-vhdl-import¶.¡RDY_dequeue_data_fall¡ :: ¶Prelude®¶.¶Bit®¶ 1
};
 
instance ¶ddr-sram-vhdl-import¶ ¶Prelude®¶.¶PrimMakeUndefined®¶
				(¶ddr-sram-vhdl-import©¶.¶_ddr-sram-vhdl-import.PRIMITIVE_DDR_SRAM_DEVICE128©¶ _n0);
														   
instance ¶ddr-sram-vhdl-import¶ ¶Prelude®¶.¶PrimMakeUninitialized®¶
				(¶ddr-sram-vhdl-import©¶.¶_ddr-sram-vhdl-import.PRIMITIVE_DDR_SRAM_DEVICE128©¶ _n0);
														   
instance ¶ddr-sram-vhdl-import¶ ¶Prelude®¶.¶PrimDeepSeqCond®¶
				(¶ddr-sram-vhdl-import©¶.¶_ddr-sram-vhdl-import.PRIMITIVE_DDR_SRAM_DEVICE128©¶ _n0)
}
