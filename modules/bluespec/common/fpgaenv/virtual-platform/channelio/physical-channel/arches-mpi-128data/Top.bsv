import TopArchesReal::*;
import FSL::*;
import ArchesTypes::*;
import FIFO::*;

// interfaces to the Arches MPE engine

interface TopArches;
    interface FSLDuplexLink#(MPE_Word) mpe_cmd;
    interface FSLDuplexLink#(Bit#(128)) mpe_data;
endinterface

typedef enum {INIT, 
              MODE, 
							GET_DATA, 
							TEST, 
							PROCESS_DATA,
						  RMA_SEND_DATA,	
							RMA_GET, 
							RMA_PUT, 
							RMA_DONE, 
							WRITE_WIN_SETUP,
							WRITE_WIN_CMD,
			        READ_WIN_SETUP} TestRigState deriving (Bits, Eq);

(*synthesize*)
module mkTopArches
        (TopArches);
    let ch_data <- mkFSLDuplexChannel;
    let mpi     <- mkMPI;
    //FIFO#(QEMUTrace) from_x86 <- mkSizedFIFO(1024);
    //FIFO#(QEMUTrace) to_x86 <- mkSizedFIFO(1024);
    FIFO#(Bit#(128)) data_fifo <- mkSizedFIFO(64);
    Reg#(MsgSize) size <- mkReg(0);
    Reg#(TestRigState) state  <- mkReg(INIT); 
    Reg#(Rank) hw_rank <- mkReg(?);
		Reg#(Bool) rma_mode <- mkReg(False);
    Reg#(WinHand) rd_handle <- mkReg(?);
    Reg#(WinHand) wr_handle <- mkReg(?);


    rule get_init(state == INIT);
        mpi.irecv(RankX86, AnyTag, 0);
				state <= MODE;
		endrule
		rule set_mode(state == MODE);
			  let st <- mpi.test();
		    if(st.tag == CmdQValueTag) begin
          rma_mode <= True;
          mpi.rma_win(0,0,0);

				  state <= READ_WIN_SETUP;
        end
        else begin
          rma_mode <= False;
          mpi.send(RankX86, CmdQValueTag, 0);
				  state <= GET_DATA;
        end
    endrule
    /////////set up windows/////////////////////
    rule read_window(state == READ_WIN_SETUP);
				let hand <- mpi.getWin();
				rd_handle <= hand;
        mpi.send(RankX86, CmdQValueTag, 4);
        ch_data.put(tuple2(False, {123'h0,hand}));
				//state <= WRITE_WIN_CMD;
				state <= GET_DATA;
    endrule

    /////////////rma mode////////////////////////
    //1 recieve a go signal
		//get data from remote mem
		//put data to remote mem
		//send a done
    rule start_sig (state == GET_DATA && rma_mode == True);
				//look for go signal
        mpi.irecv(RankX86, TraceTag, 0);
        //mpi.irecv(RankX86, TraceTag, 0);
        state <= RMA_GET;
    endrule

		rule get_rma (state == RMA_GET && rma_mode == True);
        let st <- mpi.test();
				//go signal recieved
				if(st.size == 0) begin
			      //start getting data
				    mpi.rma_get(RankX86, 64, rd_handle, 0);						
            state <= RMA_PUT;
				end
    endrule
		rule put_rma (state == RMA_PUT && rma_mode == True);
        size <= 64;				
	      state <= PROCESS_DATA;
    endrule
		rule rma_trasfer (state == PROCESS_DATA && rma_mode == True);
				//read out data and write it back
				match { .b, .x } <- ch_data.get();
				data_fifo.enq(x);
				
				if(size < 5) begin
	         state <= RMA_SEND_DATA;
				   mpi.rma_put(RankX86, 64, rd_handle, 64);
					 size <= 64;
	      end
        else
           size <= size - 4;
    endrule
		rule rma_send_data(state == RMA_SEND_DATA && rma_mode == True);
				 ch_data.put(tuple2(False, data_fifo.first()));
				 data_fifo.deq();
				 if(size < 5) begin
	         state <= RMA_DONE;
	      end
        else
           size <= size - 4;        
		endrule
		rule rma_done (state == RMA_DONE && rma_mode == True);
			  //send done msg
        mpi.send(RankX86, TraceTag, 0);
				state <= GET_DATA;				
    endrule

    /////////////default mode////////////////////
		rule get_data (state == GET_DATA && rma_mode == False);
        mpi.irecv(RankX86, TraceTag, 0);
        state <= TEST;
    endrule

  	rule test_data (state == TEST && rma_mode == False);
        let st <- mpi.test();
				if(st.size == 0) begin
            state <= GET_DATA;
            mpi.rsend(RankX86, CmdQValueTag, 0);
				end
				else begin
            size <= st.size;
	          state <= PROCESS_DATA;
            mpi.send(RankX86, CmdQValueTag, unpack(st.size));
				end
    endrule
		rule process (state == PROCESS_DATA && rma_mode == False);
				match { .b, .x } <- ch_data.get();
				ch_data.put(tuple2(False, x));
				
				if(size < 5) begin
	         state <= GET_DATA;
	      end
        else
           size <= size - 4;
    endrule

    interface mpe_cmd  = mpi.mpe_cmd;
    interface mpe_data = ch_data.fsl;	

endmodule


