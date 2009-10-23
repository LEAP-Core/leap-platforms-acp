#define IOCTL_GETPHYSICAL 	1
#define IOCTL_GPRWRITE 		2
#define IOCTL_SENDIPI		3
#define IOCTL_MEMALLOC 		4
#define IOCTL_MEMFREE		5
#define IOCTL_GET_BUFADDR       6
#define IOCTL_GET_BUFID         7
#define IOCTL_MEMFREE_BY_ID     8
#define IOCTL_SETIODELAYS	9
#define IOCTL_GETIODELAYS	10
#define IOCTL_SETGPRBASE	11
#define IOCTL_DISABLEGPRS	12
#define IOCTL_ENABLEGPRS	13
#define IOCTL_ASSOCIATEUSER	14
#define IOCTL_LOOKUPUSER	15
#define IOCTL_RESETIODELAYS	17

#define MAX_NUM_BUFFERS 400

#define MAXCOREID	4
#define MAXPACKAGEID	4

//Library to driver parameters

struct associateuser_params {
	void *user_base;
	uint64_t physical_base;
};

struct memalloc_params {
	uint64_t size;
	struct page *pg_base;
	uint64_t physical_base;
	uint64_t order;
        uint64_t buf_id;
};

struct ipi_params{
	uint8_t apicid;
	uint8_t vector;
};

struct acp_iodelays{
	uint8_t dphydata[64];
	uint8_t dphydbi[4];
	uint8_t dphystroben[4];
	uint8_t dphystrobep[4];
	uint8_t dphywc;
	uint8_t aphydata;
	uint8_t aphystroben;
	uint8_t aphystrobep;
};

struct setiodelays_params{
	int acp_id;
	struct acp_iodelays acp_iodelays;
};

struct getiodelays_params{
	int acp_id;
	struct acp_iodelays *acp_iodelays;
};

struct setgprbase_params{
	int acp_id;
	uint64_t gpraddress;
};

struct disablegprbase_params{
	int acp_id;
};

//Driver state
uint8_t sockettoapicid[4]={0x0,0x4,0xC,0x8};

struct acp_state{
	/*bool*/char socketoccupied;
	struct acp_iodelays iodelays;
	uint8_t isc_apicid0,isc_apicid1;
	uint64_t gprbase;
	uint8_t gprenabled;
};

struct memalloc_state{
	struct page *pg_base;
	uint64_t size;
	uint64_t physical_base;
	uint64_t user_base;
	uint64_t order;
        uint64_t buf_id;
};


