import FSL::*;
import ArchesTypes::*;
import FIFO::*;

// This module translates MPI functions (send/recv etc.) into commands
// to be enqd into the MPE Command FSL
interface MPI;
    method Rank   rank ();
    method Action send (Rank rank, Tag tag, MsgSize size);
    method Action irecv(Rank rank, Tag tag, MsgSize size);
    method Action rsend(Rank rank, Tag tag, MsgSize size);

    method ActionValue#(MPE_Status) test();

    method Action rma_get (Rank k, MsgSize size, WinHand handle, WinDisp disp);
    method Action rma_put (Rank k, MsgSize size, WinHand handle, WinDisp disp);
    method Action rma_win (DispUnit disp_unit, WinSize  win_size, WinBase  win_base);
    
    method ActionValue#(WinHand) getWin();

    // method Action finalize();

    interface FSLDuplexLink#(MPE_Word) mpe_cmd;
endinterface

module mkMPI
        (MPI);

    FSLDuplexChannel#(MPE_Word) ch_cmd <- mkFSLDuplexChannel;

    //FIFO#(MPE_Command)     cmd_fifo    <- mkFIFO;
    FIFO#(MPE_Word)     status_fifo <- mkFIFO;
    FIFO#(MPE_Word)     cmd_fifo    <- mkFIFO;

    Reg#(Rank) myRank <- mkReg(RankAny);
    Reg#(Bool) init_p <- mkReg(False);

    // MPI_Init
    rule init (!init_p);
        match { .b, .x } <- ch_cmd.get();
        MPE_Status w = unpack(x);
        myRank <= w.rank;
        init_p <= True;
    endrule

    rule put_cmd(init_p);
        let cmd = cmd_fifo.first();
        cmd_fifo.deq();
        ch_cmd.put(tuple2(True, cmd));	
    endrule

    rule get_cmd(init_p);
        match{.ctrl, .status} <- ch_cmd.get();
        status_fifo.enq(status);
    endrule

    function Action mpi_cmd(MPE_Opcode op, Rank rank, Tag tag, MsgSize size) =
      action
        let cmd = MPE_Command { tag: tag, op: op, rank: rank, size: size, unused: 0};
        cmd_fifo.enq(pack(cmd));
      endaction;

    // methods
    method Rank   rank () if (init_p) = myRank;
    method Action send (Rank k, Tag tag, MsgSize size) = mpi_cmd(MPE_Send,  k, tag, size);
    method Action irecv(Rank k, Tag tag, MsgSize size) = mpi_cmd(MPE_Recv,  k, tag, size);
    method Action rsend(Rank k, Tag tag, MsgSize size) = mpi_cmd(MPE_Rsend, k, tag, size);

    method ActionValue#(MPE_Status) test();
           MPE_Status stat= unpack(status_fifo.first());
           status_fifo.deq();
           return stat;
    endmethod

    method Action rma_get (Rank k, MsgSize size, WinHand handle, WinDisp disp);
           let rma = MPE_Get{op: MPE_GetOp, rank: k, size: size,
                             win_handle: handle, displace: disp};
          cmd_fifo.enq(pack(rma));
    endmethod
    method Action rma_put (Rank k, MsgSize size, WinHand handle, WinDisp disp);
          let rma = MPE_Put{op: MPE_PutOp, rank: k, size: size,
                            win_handle: handle, displace: disp};
          cmd_fifo.enq(pack(rma));
    endmethod
    method Action rma_win (DispUnit disp_unit, WinSize  win_size, WinBase  win_base);
           let rma = MPE_WinC{op: MPE_WinOp, disp_unit: disp_unit,
                              win_size: win_size, win_base: win_base};
           cmd_fifo.enq(pack(rma));
    endmethod
    
    method ActionValue#(WinHand) getWin();
        MPE_WinStat stat= unpack(status_fifo.first());
        status_fifo.deq();
        return stat.win_handle;
    endmethod


    interface mpe_cmd = ch_cmd.fsl;

endmodule

