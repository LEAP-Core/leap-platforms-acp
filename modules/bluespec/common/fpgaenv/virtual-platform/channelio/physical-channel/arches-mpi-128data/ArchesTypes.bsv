
//new command format
///////////////////////////////////////////////////////
//Opcode(5b)|Rank(8b)|Msg Size(22b)|Tag(32b)|Unused|5b|
///////////////////////////////////////////////////////

typedef enum {
    MPE_Send = 1,
    MPE_Recv = 2,
    MPE_Rsend = 3,
    MPE_GetOp = 4,
    MPE_PutOp = 5,
    MPE_WinOp = 6,
    Unused = 31
} MPE_Opcode deriving (Bits,Eq);

typedef enum {
    AnyTag       = 32'hFFFF_FFF0,
    InitRankTag  = 32'hFFFF_FFF1,
    BarrierTag   = 32'hFFFF_FFFC,
    CmdQValueTag = 32'hA000_0000,
    ReadCmdQTag  = 32'h9000_0000,
    TraceTag     = 32'h8000_0000
} Tag deriving (Bits,Eq);

typedef enum {
    RankX86   = 0,
    RankFPGA0 = 1,
    RankFPGA1 = 2,
    RankAny   = 255
} Rank deriving (Bits,Eq);

typedef Bit#(22) MsgSize;

typedef struct {
    MPE_Opcode op;
    Rank       rank;
    MsgSize    size;
    Tag        tag;
    Bit#(5)    unused;
} MPE_Command deriving (Bits,Eq);
///////////////////////////////////////////////////////////////
//RMA commands are formatted a bit differently from Send/Revice
//see Arches mpe user doc for details
///////////////////////////////////////////////////////////////
typedef Bit#(8) DispUnit;
typedef Bit#(20) WinSize;
typedef Bit#(26) WinBase;
typedef struct {
    MPE_Opcode op;
    //Bit#(8)    unused;
    //MsgSize    size;
    //Bit#(37)   unused2;
    DispUnit disp_unit;
    WinSize  win_size;
    WinBase  win_base;
    Bit#(13) unused;
} MPE_WinC deriving (Bits,Eq);

typedef struct {
    Bit#(67) unused;
    Bit#(5)  win_handle;
} MPE_WinStat deriving (Bits,Eq);

typedef Bit#(32) WinDisp;
typedef Bit#(5)  WinHand;

typedef struct {
    MPE_Opcode op;
    Rank       rank;
    MsgSize    size;
    WinHand    win_handle;
    WinDisp    displace;
} MPE_Get deriving (Bits,Eq);

typedef struct {
    MPE_Opcode op;
    Rank       rank;
    MsgSize    size;
    WinHand    win_handle;
    WinDisp    displace;
} MPE_Put deriving (Bits,Eq);

typedef Bit#(72) MPE_Word;

typedef MPE_Command MPE_Status;
//typedef MPE_Word MPE_Command;

// static assertions for sizes
typeclass SizeAssert#(type a, type sa)
            provisos (Bits#(a,sa))
                      dependencies (a determines sa);
endtypeclass

instance SizeAssert#(MPE_Command, 72); endinstance
instance SizeAssert#(MPE_WinC, 72); endinstance
instance SizeAssert#(MPE_WinStat, 72); endinstance
instance SizeAssert#(MPE_Get, 72); endinstance
instance SizeAssert#(MPE_Put, 72); endinstance
instance SizeAssert#(Tag,      32); endinstance
instance SizeAssert#(Rank,      8); endinstance
