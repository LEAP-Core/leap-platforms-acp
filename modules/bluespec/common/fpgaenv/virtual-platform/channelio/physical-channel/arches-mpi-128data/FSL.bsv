// (c) 2009 UTFAST, University of Texas at Austin
// Released under GPLv2

import FIFO::*;
import FIFOF::*;
import GetPut::*;
import Connectable::*;

//import CommonLib::*;

// The FSL MasterI interface represents the *exact* inside-out version
// of an enq-interface -- e.g, the full signal is going into the module,
// instead of coming out. This means that the master interface of a fsl_v20 can
// be connected port-to-port with a FSLMasterI interface.
//
// Note that this is different from a deq-interface. Instead think of how a
// FIFO sees an enq happening into it.
//
// Similarly, the FSL SlaveI interface...

interface FSLMasterI#(type a);
    (*always_ready*)
    method a data();
    (*always_ready*)
    method Bool ctrl();
    (*always_ready*)
    method Bool write();
    (*always_enabled,prefix=""*)
    method Action full((*port="full"*) Bool x);
endinterface

interface FSLSlaveI#(type a);
    (*always_enabled,prefix=""*)
    method Action data((*port="data"*) a x);
    (*always_enabled,prefix=""*)
    method Action ctrl((*port="ctrl"*) Bool x);
    (*always_enabled,prefix=""*)
    method Action exists((*port="exists"*) Bool x);
    (*always_ready*)
    method Bool read();
		(*always_ready*)
		method Bool does_exist();
endinterface

// This is a simple module that "converts" a Put interface to an
// FSLMasterI. Note how the module only has wires in it.

interface FSLMasterChannel#(type a);
    interface FSLMasterI#(a)        master;
    interface Put#(Tuple2#(Bool,a)) put;
endinterface

module mkFSLMasterChannel
        (FSLMasterChannel#(a))
            provisos (Bits#(a,sa));

    PulseWire               w_full <- mkPulseWire;
    RWire#(Tuple2#(Bool,a)) w_data <- mkRWire;

    interface FSLMasterI master;
        method a data();
            return unJust(w_data.wget).snd;
        endmethod
        method Bool ctrl();
            return unJust(w_data.wget).fst;
        endmethod
        method Bool write();
            return isValid(w_data.wget);
        endmethod
        method Action full(Bool x);
            if (x)
                w_full.send();
        endmethod
    endinterface

    interface Put put;
        method Action put(Tuple2#(Bool,a) x) if (!w_full);
            w_data.wset(x);
        endmethod
    endinterface
endmodule

// This is a simple module that "converts" a Get interface to an
// FSLSlaveI. Note how the module only has wires in it.
//
interface FSLSlaveChannel#(type a);
    interface FSLSlaveI#(a)         slave;
    interface Get#(Tuple2#(Bool,a)) get;
endinterface

module mkFSLSlaveChannel
        (FSLSlaveChannel#(a))
            provisos (Bits#(a,sa));

    Wire#(a)    w_data   <- mkBypassWire;
    Wire#(Bool) w_ctrl   <- mkBypassWire;
    Wire#(Bool) w_exists <- mkBypassWire;
    PulseWire   w_read   <- mkPulseWire;

    interface FSLSlaveI slave;
        method Action data(a x);
            w_data <= x;
        endmethod
        method Action ctrl(Bool x);
            w_ctrl <= x;
        endmethod
        method Action exists(Bool x);
            w_exists <= x;
        endmethod
        method Bool read();
            return w_read;
        endmethod
				method Bool does_exist();
            return w_exists;
        endmethod
    endinterface

    interface Get get;
        method ActionValue#(Tuple2#(Bool,a)) get() if (w_exists);
            w_read.send();
            return tuple2(w_ctrl,w_data);
        endmethod
    endinterface
endmodule

// Convenience interfaces/modules for situations where both Get and
// Put are required. This should only be the case where there are two
// FSLs, one into and one out of the module.

interface FSLDuplexLink#(type a);
    interface FSLSlaveI#(a)  from_fsl;
    interface FSLMasterI#(a) to_fsl;
endinterface

interface FSLDuplexChannel#(type a);
    interface FSLDuplexLink#(a) fsl;
    method ActionValue#(Tuple2#(Bool,a)) get();
    method Action put(Tuple2#(Bool,a) x);
endinterface

module mkFSLDuplexChannel
        (FSLDuplexChannel#(a))
            provisos (Bits#(a,sa));
    let ch_get <- mkFSLSlaveChannel;
    let ch_put <- mkFSLMasterChannel;

    interface FSLDuplexLink fsl;
        interface from_fsl = ch_get.slave;
        interface to_fsl   = ch_put.master;
    endinterface
    method get = ch_get.get.get;
    method put = ch_put.put.put;
endmodule

instance Connectable#(FIFOF#(Tuple2#(Bool,a)), FSLMasterI#(a));
    // AUTO-IMPORT HINT: undefine mkConnection
    module mkConnection#(FIFOF#(Tuple2#(Bool,a)) fifo, FSLMasterI#(a) m_fsl)
            (Empty);

        rule full;
            m_fsl.full(!fifo.notFull);
        endrule

        rule doit (m_fsl.write);
            let x = tuple2(m_fsl.ctrl, m_fsl.data);
            fifo.enq(x);
        endrule
    endmodule
endinstance

instance Connectable#(FIFOF#(Tuple2#(Bool,a)), FSLSlaveI#(a));
    // AUTO-IMPORT HINT: undefine mkConnection
    module mkConnection#(FIFOF#(Tuple2#(Bool,a)) fifo, FSLSlaveI#(a) s_fsl)
            (Empty);

        rule exists;
            s_fsl.exists(fifo.notEmpty);
        endrule

        rule read;
            match { .b, .x } = fifo.first();
            s_fsl.ctrl(b);
            s_fsl.data(x);
        endrule

        rule deq (s_fsl.read);
            fifo.deq();
        endrule

    endmodule
endinstance

// move 2N-bit data from/into N-bit FSL

module mkFSLMarshallPutCtrl#(Put#(Tuple2#(Bool,a)) p, Get#(v) g, Bool ctrl0, Bool ctrl1)
        (Empty)
            provisos (Bits#(a, sa),
                      Bits#(v, sv),
                      Add#(sa, sa, sv));

    Reg#(Bool) state <- mkReg(False);

    rule one (!state);
        let val = peekGet(g);
        Tuple2#(a,a) tup = unpack(pack(val));
        p.put(tuple2(ctrl0, tup.snd));
        state <= True;
    endrule
    rule two (state);
        let val <- g.get();
        Tuple2#(a,a) tup = unpack(pack(val));
        p.put(tuple2(ctrl1, tup.fst));
        state <= False;
    endrule
endmodule

module mkFSLMarshallPut#(Put#(Tuple2#(Bool,a)) p, Get#(v) g)
        (Empty)
            provisos (Bits#(a, sa),
                      Bits#(v, sv),
                      Add#(sa, sa, sv));

    let _x <- mkFSLMarshallPutCtrl(p, g, False, False);
    return _x;
endmodule

module mkFSLMarshallPut1#(Put#(Tuple2#(Bool,a)) p, Get#(v) g)
        (Empty)
            provisos (Bits#(a, sa),
                      Bits#(v, sv),
                      Add#(sa, sa, sv));

    let _x <- mkFSLMarshallPutCtrl(p, g, True, False);
    return _x;
endmodule

module mkFSLMarshallGet#(Get#(Tuple2#(Bool,a)) g, Put#(v) p)
        (Empty)
            provisos (Bits#(a, sa),
                      Bits#(v, sv),
                      Add#(sa, sa, sv));

    FIFO#(a) val <- mkFIFO1;
    (*mutually_exclusive="one,two"*)
    rule one;
        match { .b, .x } <- g.get();
        val.enq(x);
    endrule
    rule two;
        val.deq();
        match { .b, .x } <- g.get();
        let tup = tuple2(x, val.first());
        p.put(unpack(pack(tup)));
    endrule
endmodule

// // Simple test
// 
// (*synthesize*)
// module mkTest
//         (FSLDuplexLink#(int));
// 
//     let ch_fsl <- mkFSLDuplexChannel;
// 
//     mkConnection(ch_fsl.put,ch_fsl.get);
// 
//     return ch_fsl.fsl;
// endmodule
