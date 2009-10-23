//Copyright Xilinx, Inc 2007
//Author : Henry Styles
//Simple driver for testing GPR functionality

//Define I/O memory for GPR BAR
//GPR BAR points to pinned region on GPRs

//Revision :
//2008-07-18 Henry Styles
//Interrupt Side Channel (ISC)
//2008-10-09 Henry Styles
//Multiple phyical board support
//2008-10-23 Henry Styles
//Memory allocation and deallocation fix

//To do : guard access to memory allocation stacks with synchronization
//	  locks

//#include<stdbool.h>

#include <linux/fs.h>
#include <linux/init.h>
#include <linux/module.h>
#include <linux/mm.h>
#include <asm/uaccess.h>
#include <linux/kdev_t.h>
#include <asm/io.h>
#include <linux/cdev.h>

//#include <asm/fixmap.h>
//#include <asm/hw_irq.h>
#include <asm/apicdef.h>
#include <asm/genapic.h>
#include "acp.h"

#define DEBUG

//APIC programming
//modified from send_IPI_mask_sequence in include/asm-x86_64/ipi.h
static void send_ipi(unsigned int apicid,int vector)
{
	/*
	//take a look at the APICID table
	unsigned int i;
	for(i=0;i<256;i++){
	printk("%i %i\n",i,x86_cpu_to_apicid[i]);
	}
	 */
	unsigned long cfg,flags;
	local_irq_save(flags);
	//wait for idle
	apic_wait_icr_idle();
	//prepare target chip field
	//cfg = SET_APIC_DEST_FIELD(x86_cpu_to_apicid[destcpu]);
	cfg = SET_APIC_DEST_FIELD(apicid);
	apic_write(APIC_ICR2,cfg);
	//program ICR
	cfg = APIC_DM_FIXED | vector | APIC_DEST_PHYSICAL;
	//send the IPI
	apic_write(APIC_ICR,cfg);
	local_irq_restore(flags);
}

//Interrupt Side Channel (ISC)
#define ISC_COMMANDWIDTH		8
#define ISC_PARAMETERWIDTH		76
#define ISC_COMMANDAPHY			0x1
#define ISC_COMMANDDPHYDIRECTION	0x2
#define ISC_COMMANDDPHYSTEP		0x4
#define ISC_COMMANDDPHYWC		0x8
#define ISC_COMMANDGPRBASE		0x10

//iscaphy
// uint8_t aphyreset         	 : 1 bit reset (applies to complete phy)
// uint8_t aphydatastep          : 1 bit data step
// uint8_t aphydatadirection     : 1 bit data direction
// uint8_t aphystrobenstep       : 1 bit stroben step
// uint8_t aphystrobendirecetion : 1 bit stroben direction
// uint8_t aphystrobepstep       : 1 bit strobep step
// uint8_t aphystrobepdirecetion : 1 bit strobep direction
static void iscaphy(uint8_t apicid0,uint8_t apicid1,uint8_t aphyreset,uint8_t aphydatastep,uint8_t aphydatadirection,uint8_t aphystrobenstep, uint8_t aphystrobendirection, uint8_t aphystrobepstep,uint8_t aphystrobepdirection){
	uint8_t command=ISC_COMMANDAPHY;
	//command
	unsigned int i;
	uint8_t dontcare=5;
	for(i=0;i<8;i++){
		if(command&0x01) send_ipi(apicid1,dontcare);
		else send_ipi(apicid0,dontcare);
		command = command >> 1;
	}
	//parameter
	//1 bit aphy IODELAY reset
	if(aphyreset&0x01) send_ipi(apicid1,dontcare);
	else send_ipi(apicid0,dontcare);
	//1 bit aphy IODELAY step
	if(aphydatastep&0x01) send_ipi(apicid1,dontcare);
	else send_ipi(apicid0,dontcare);
	//1 bit aphy IODELAY direction
	if(aphydatadirection&0x01) send_ipi(apicid1,dontcare);
	else send_ipi(apicid0,dontcare);
	//1 bit aphy stroben IODELAY step
	if(aphystrobenstep&0x01) send_ipi(apicid1,dontcare);
	else send_ipi(apicid0,dontcare);
	//1 bit aphy stroben IODELAY direction
	if(aphystrobendirection&0x01) send_ipi(apicid1,dontcare);
	else send_ipi(apicid0,dontcare);
	//1 bit aphy strobep IODELAY step
	if(aphystrobepstep&0x01) send_ipi(apicid1,dontcare);
	else send_ipi(apicid0,dontcare);
	//1 bit aphy strobep IODELAY direction
	if(aphystrobendirection&0x01) send_ipi(apicid1,dontcare);
	else send_ipi(apicid0,dontcare);
	//pad to end of parameter
	//reset interrupt counter by wrapping round
	for(i=0;i<(76-7);i++){
		send_ipi(apicid0,dontcare);
	}
}


//iscdphystep
// uint64_t datastep   : 1 bit per bit lane lsb is group 0 bit lane 0
// uint8_t dbistep     : 1 bit per group lsb is group 0
// uint8_t strobenstep : 1 bit per group, lsb is group 0
// uint8_t strobepstep : 1 bit per group, lsb is group 0
static void iscdphystep(uint8_t apicid0, uint8_t apicid1, uint64_t datastep, uint8_t dbistep, uint8_t strobenstep, uint8_t strobepstep){
		uint8_t command=ISC_COMMANDDPHYSTEP;
	//command
	unsigned int i;
	uint8_t dontcare=5;
	uint64_t idatastep;
	uint8_t idbistep;
	uint8_t istrobepstep;
	uint8_t istrobenstep;
	for(i=0;i<8;i++){
		if(command&0x01) send_ipi(apicid1,dontcare);
		else send_ipi(apicid0,dontcare);
		command = command >> 1;
	}
	//parameter
	//64 bits data lane step
	idatastep=datastep;
	for(i=0;i<64;i++){
		if(idatastep&0x01) send_ipi(apicid1,dontcare);
		else send_ipi(apicid0,dontcare);
		idatastep = idatastep >> 1;
	}
	//4 bits group dbis
	idbistep=dbistep;
	for(i=0;i<4;i++){
		if(idbistep&0x01) send_ipi(apicid1,dontcare);
		else send_ipi(apicid0,dontcare);
		idbistep = idbistep >> 1;
	}
	//4 bits group strobe p
	istrobepstep=strobepstep;
	for(i=0;i<4;i++){
		if(istrobepstep&0x01) send_ipi(apicid1,dontcare);
		else send_ipi(apicid0,dontcare);
		istrobepstep = istrobepstep >> 1;
	}
	//4 bits group strobe n
	istrobenstep=strobenstep;
	for(i=0;i<4;i++){
		if(istrobenstep&0x01) send_ipi(apicid1,dontcare);
		else send_ipi(apicid0,dontcare);
		istrobenstep = istrobenstep >> 1;
	}
}

//acp_iscdphydirection
// uint64_t datadirection   : 1 bit per bit lane lsb is group 0 bit lane 0
// uint8_t dbidirection     : 1 bit per group lsb is group 0
// uint8_t strobendirection : 1 bit per group, lsb is group 0
// uint8_t strobepdirection : 1 bit per group, lsb is group 0
static void iscdphydirection(uint8_t apicid0, uint8_t apicid1, uint64_t datadirection, uint8_t dbidirection, uint8_t strobendirection, uint8_t strobepdirection){

	uint8_t command=ISC_COMMANDDPHYDIRECTION;
	//command
	unsigned int i;
	uint8_t dontcare=5;
	uint64_t idatadirection;
	uint8_t idbidirection;
	uint8_t istrobepdirection;
	uint8_t istrobendirection;
	for(i=0;i<8;i++){
		if(command&0x01) send_ipi(apicid1,dontcare);
		else send_ipi(apicid0,dontcare);
		command = command >> 1;
	}
	//parameter
	//64 bits data lane direction
	idatadirection=datadirection;
	for(i=0;i<64;i++){
		if(idatadirection&0x01) send_ipi(apicid1,dontcare);
		else send_ipi(apicid0,dontcare);
		idatadirection = idatadirection >> 1;
	}
	//4 bits group dbis
	idbidirection=dbidirection;
	for(i=0;i<4;i++){
		if(idbidirection&0x01) send_ipi(apicid1,dontcare);
		else send_ipi(apicid0,dontcare);
		idbidirection = idbidirection >> 1;
	}
	//4 bits group strobe p
	istrobepdirection=strobepdirection;
	for(i=0;i<4;i++){
		if(istrobepdirection&0x01) send_ipi(apicid1,dontcare);
		else send_ipi(apicid0,dontcare);
		istrobepdirection = istrobepdirection >> 1;
	}
	//4 bits group strobe n
	istrobendirection=strobendirection;
	for(i=0;i<4;i++){
		if(istrobendirection&0x01) send_ipi(apicid1,dontcare);
		else send_ipi(apicid0,dontcare);
		istrobendirection = istrobendirection >> 1;
	}
}

//acp_iscdphywc
// uint8_t direction	: 1 bit write clock direction
// uint8_t step		: 1 bit write clock step
static void iscdphywc(uint8_t apicid0,uint8_t apicid1,uint8_t direction,uint8_t step){
	uint8_t command=ISC_COMMANDDPHYWC;
	//command
	unsigned int i;
	uint8_t dontcare=5;
	for(i=0;i<8;i++){
		if(command&0x01) send_ipi(apicid1,dontcare);
		else send_ipi(apicid0,dontcare);
		command = command >> 1;
	}
	//parameter
	//1 bit wc step
	if(step==1) send_ipi(apicid1,dontcare);
	else send_ipi(apicid0,dontcare);
	//1 bit wc direction
	if(direction==1) send_ipi(apicid1,dontcare);
	else send_ipi(apicid0,dontcare);
	//76-2 bits parameter padding
	//74 bits parameter padding
	for(i=0;i<74;i++) send_ipi(apicid0,dontcare);
}

//acp_gprcontrol
// uint64_t gprbaseaddress : 37 bits gprbaseaddress
// uint8_t gprenable 	   : 1 bit gprenable
static void iscgprcontrol(uint8_t apicid0,uint8_t apicid1,uint64_t gprbaseaddress,uint8_t gprenable){
	uint8_t command=ISC_COMMANDGPRBASE;
	uint64_t igprbaseaddress=gprbaseaddress;
	//command
	unsigned int i;
	uint8_t dontcare=5;
	for(i=0;i<8;i++){
		if(command&0x01) send_ipi(apicid1,dontcare);
		else send_ipi(apicid0,dontcare);
		command = command >> 1;
	}
	//parameter
	//37 bits gpr base address
	for(i=0;i<37;i++){
		if(igprbaseaddress&0x01) send_ipi(apicid1,dontcare);
		else send_ipi(apicid0,dontcare);
		igprbaseaddress = igprbaseaddress >> 1;
	}
	//1 bit gpr enable
	if(gprenable&0x01) send_ipi(apicid1,dontcare);
	else send_ipi(apicid0,dontcare);
	//76-37-1 bits parameter padding
	//38 bits parameter padding
	for(i=0;i<38;i++) send_ipi(apicid0,dontcare);
}

static struct acp_state global_acp_state[4];

static void resetiodelays(struct acp_state *acp_state){
	unsigned int i;
	if(acp_state->socketoccupied){
		//reset the complete PHY
		iscaphy(acp_state->isc_apicid0,
				acp_state->isc_apicid1,
				1,
				0,0,
				0,0,
				0,0);
		for(i=0;i<64;i++){
			acp_state->iodelays.dphydata[i]=0;
		}
		for(i=0;i<4;i++){
			acp_state->iodelays.dphydbi[i]=0;
			acp_state->iodelays.dphystroben[i]=0;
			acp_state->iodelays.dphystrobep[i]=0;
		}
		acp_state->iodelays.aphydata=0;
		acp_state->iodelays.aphystroben=0;
		acp_state->iodelays.aphystrobep=0;
	}
}

static void setiodelays(struct acp_iodelays *newacp_iodelays,
						struct acp_state *acp_state){
	struct acp_iodelays *oldacp_iodelays=&(acp_state->iodelays);
	//dphy
	//directions
	unsigned int i,j;
	uint64_t datadirection;
	uint64_t dbidirection;
	uint64_t strobendirection;
	uint64_t strobepdirection;
	datadirection=0;
	for(i=0;i<64;i++){
		if(newacp_iodelays->dphydata[63-i] >
			oldacp_iodelays->dphydata[63-i]) datadirection=(datadirection<<1)|0x1;
		else datadirection = datadirection << 1;
	}
	dbidirection=0;
	strobendirection=0;
	strobepdirection=0;
	for(i=0;i<4;i++){
		//dbi
		if(newacp_iodelays->dphydbi[3-i] > oldacp_iodelays->dphydbi[3-i])
			dbidirection=(dbidirection<<1)|0x1;
		else dbidirection = dbidirection << 1;
		//stroben
		if(newacp_iodelays->dphystroben[3-i] > oldacp_iodelays->dphystroben[3-i]) strobendirection=(strobendirection<<1)|0x1;
			else strobendirection = strobendirection << 1;
			//strobep
			if(newacp_iodelays->dphystrobep[3-i] >
							oldacp_iodelays->dphystrobep[3-i]) strobepdirection=(strobepdirection<<1)|0x1;
			else strobepdirection = strobepdirection << 1;
	}
	iscdphydirection(acp_state->isc_apicid0,
					acp_state->isc_apicid1,
					datadirection,
					dbidirection,
					strobendirection,
					strobepdirection);
	//step
	for(i=0;i<64;i++){
			//step lane
			uint8_t steps;
			uint64_t stepbit;
			int16_t a = newacp_iodelays->dphydata[i];
			int16_t b = oldacp_iodelays->dphydata[i];
			steps=abs(a-b);
#ifdef DEBUG
			printk("bit %ld steps %ld\n",(long int)i,
							(long int)(newacp_iodelays->dphydata[i]));
#endif
			stepbit = 0x1;
			stepbit = stepbit << i;
				for(j=0;j<steps;j++){
						iscdphystep(acp_state->isc_apicid0,
										acp_state->isc_apicid1,
										stepbit,0,0,0);
				}

				oldacp_iodelays->dphydata[i] = newacp_iodelays->dphydata[i];
		}
		//4 bits dbi
		for(i=0;i<4;i++){
				uint8_t steps;
				uint64_t stepbit = 0x1;
				steps=abs(newacp_iodelays->dphydbi[i]-
								oldacp_iodelays->dphydbi[i]);
				stepbit = 0x1;
				stepbit = stepbit << i;
				for(j=0;j<steps;j++){
						iscdphystep(acp_state->isc_apicid0,
										acp_state->isc_apicid1,
										0,stepbit,0,0);

				}
				oldacp_iodelays->dphydbi[i] = newacp_iodelays->dphydbi[i];
		}
		//4 bits stroben
		for(i=0;i<4;i++){
				uint8_t steps;
				uint64_t stepbit;
				steps=abs(newacp_iodelays->dphystroben[i]-
								oldacp_iodelays->dphystroben[i]);
				stepbit = 0x1;
				stepbit = stepbit << i;
				for(j=0;j<steps;j++){
						iscdphystep(acp_state->isc_apicid0,
										acp_state->isc_apicid1,
										0,0,stepbit,0);

				}
				oldacp_iodelays->dphystroben[i] = newacp_iodelays->dphystroben[i];
		}
		//4 bits strobep
		for(i=0;i<4;i++){
				uint8_t steps;
				uint64_t stepbit;
				steps=abs(newacp_iodelays->dphystrobep[i]-
								oldacp_iodelays->dphystrobep[i]);
				stepbit = 0x1;
				stepbit = stepbit << i;
				for(j=0;j<steps;j++){
						iscdphystep(acp_state->isc_apicid0,
										acp_state->isc_apicid1,
										0,0,0,stepbit);

				}
				oldacp_iodelays->dphystrobep[i] = newacp_iodelays->dphystrobep[i];
		}
		//write clock
		{
				uint64_t direction;
				uint8_t steps;
				if(newacp_iodelays->dphywc >
								oldacp_iodelays->dphywc) direction=1;
				else direction=0;
				steps=abs(newacp_iodelays->dphywc-
								oldacp_iodelays->dphywc);
				for(j=0;j<steps;j++) iscdphywc(acp_state->isc_apicid0,
								acp_state->isc_apicid1,
								direction,
								1);
				oldacp_iodelays->dphywc=newacp_iodelays->dphywc;
		}
		//aphy
		//address
		{
				uint8_t aphydirection=0;
				uint8_t aphysteps=0;
				if(newacp_iodelays->aphydata >
								oldacp_iodelays->aphydata) aphydirection=1;
				else aphydirection=0;
				aphysteps=abs(newacp_iodelays->aphydata -
								oldacp_iodelays->aphydata);
				for(j=0;j<aphysteps;j++){
						iscaphy(acp_state->isc_apicid0,
										acp_state->isc_apicid1,
										0,
										1,aphydirection,
										0,0,
										0,0);
				}
				oldacp_iodelays->aphydata = newacp_iodelays->aphydata;
		}
		//address strobe n
		{
				uint8_t aphystrobendirection=0;
				uint8_t aphystrobensteps=0;
				if(newacp_iodelays->aphystroben >
								oldacp_iodelays->aphystroben) aphystrobendirection=1;
				else aphystrobendirection=0;
				aphystrobensteps=abs(newacp_iodelays->aphystroben -
								oldacp_iodelays->aphystroben);
				for(j=0;j<aphystrobensteps;j++){
						iscaphy(acp_state->isc_apicid0,
										acp_state->isc_apicid1,
										0,
										0,0,
										1,aphystrobendirection,
										0,0);
				}
				oldacp_iodelays->aphystroben=newacp_iodelays->aphystroben;
		}
		//address strobe p
		{
				uint8_t aphystrobepdirection=0;
				uint8_t aphystrobepsteps=0;
				if(newacp_iodelays->aphystrobep >
								oldacp_iodelays->aphystrobep) aphystrobepdirection=1;
				else aphystrobepdirection=0;
				aphystrobepsteps=abs(newacp_iodelays->aphystrobep -
								oldacp_iodelays->aphystrobep);
				for(j=0;j<aphystrobepsteps;j++){
						iscaphy(acp_state->isc_apicid0,
										acp_state->isc_apicid1,
										0,
										0,0,
										0,0,
										1,aphystrobepdirection);
				}
				oldacp_iodelays->aphystrobep=newacp_iodelays->aphystrobep;
		}
}




//Constants
//GPRbar base address in bytes : 512MB + 16 MB
//#define GPRBARADDRESS 0x20000000+0x1000000
//#define GPRBARADDRESS 42000000  // For Xilinx Foxcove

#define GPRBARADDRESS 0x1E0000000 // 7.5GB for Linux (512 MB for ioremap); Total: 8GB

//GPRbar region size in bytes : 1MB
#define GPRBARSIZE 0x400
static void *v_gprbar;

// It cointains the array index of the latest allocated buffer
static int _buf_id = -1;
static struct memalloc_state memalloc_array[MAX_NUM_BUFFERS];
//lists of free and used buffer indices
//need to guard access to these stacks !!
static unsigned int free_memallocindex[MAX_NUM_BUFFERS];
static unsigned int used_memallocindex[MAX_NUM_BUFFERS];
static unsigned int usedmemallocs;


static void dump_memallocs(){
#ifdef DEBUG
		printk("Used memalloc count %i\n",usedmemallocs);
		int i;
		printk("Free memallocs :");
		if(usedmemallocs<MAX_NUM_BUFFERS)
				for(i=0;i<MAX_NUM_BUFFERS-usedmemallocs;i++){
						printk("%i ",free_memallocindex[i]);
				}
		printk("\n");
		printk("Used memallocs :");
		if(usedmemallocs>0)
				for(i=0;i<usedmemallocs;i++){
						printk("%i ",used_memallocindex[i]);
				}
		printk("\n");
#endif
}

MODULE_LICENSE("Dual BSD/GPL");

static dev_t acpdriver_dev;
struct cdev *acpdriver_cdev;

static struct vm_area_struct *vmalast;

static int acpdriver_open(struct inode *inode,struct file *flip){
#ifdef DEBUG
		printk("acpdriver fopen\n");
#endif
		return 0;
}

static int acpdriver_release(struct inode *inode,struct file *flip){
		void *vbase;
		unsigned long offset;
		struct page *page;
		unsigned int i,iindex;
#ifdef DEBUG
		printk("acpdriver release\n");
#endif
		// deallocate memalloc buffers
		for(i=0;i<usedmemallocs;i++){
				iindex=used_memallocindex[i];
				vbase = page_address(memalloc_array[iindex].pg_base);
#ifdef DEBUG
				printk("memfree base %d size %d\n",vbase,
								memalloc_array[iindex].size
					  );
#endif
				for(offset=0;offset<memalloc_array[iindex].size;
								offset+=PAGE_SIZE){
						page=virt_to_page(vbase+offset);
						ClearPageReserved(page);
				}
				__free_pages( memalloc_array[iindex].pg_base, memalloc_array[iindex].order );
		}
		//setup memory allocat	//initialize allocated buffers
		for(i=0;i<MAX_NUM_BUFFERS;i++)
				free_memallocindex[i]=MAX_NUM_BUFFERS-1-i;
		usedmemallocs = 0;
		return 0;
}

static int acpdriver_ioctl(struct inode *inode,struct file* flip,unsigned int command,unsigned long arg){
	unsigned int i;
	struct page *vmalastpage;
	volatile void *vmalastpagekaddr;
	void *vmalastphys;

	unsigned int gpr_writeparams[2];
	//set gprbase
	struct setgprbase_params ksetgprbase_params;
	//set setiodelays
	struct setiodelays_params ksetiodelays_params;
	//get iodelays
	struct getiodelays_params kgetiodelays_params;
	//memory block allocation
	struct memalloc_params kmemalloc_params;
	struct acp_state *selectedboardstate;
	unsigned int order;
	struct page *pg_base;
	void *kv_pg_base;
	struct page *page;
	unsigned long offset;
	void *vbase;
	unsigned int freeindex;
	//bind user address to bufid
	struct associateuser_params kassociateuser_params;
	//memory deallocate
	uint64_t kmemfree_params;
	int imatch,imatch2;

	//ipi
	struct ipi_params kipi_params;

	//minor
	unsigned int minor=iminor(inode);
	selectedboardstate = &(global_acp_state[minor]);
#ifdef DEBUG
	printk("acpdriver ioctl\n");
#endif
	switch(command){
		case IOCTL_SETGPRBASE :
#ifdef DEBUG
			printk("acpdriver ioctl SETGPRBASE\n");
#endif
			//select board based on setgprbase_params->acp_id
			if(copy_from_user(&ksetgprbase_params,(void *)arg,
					         (sizeof (struct setgprbase_params))))
				return -EFAULT;
			iscgprcontrol(selectedboardstate->isc_apicid0,
			 			  selectedboardstate->isc_apicid1,
						  ksetgprbase_params.gpraddress,
						  0);
			selectedboardstate->gprbase=ksetgprbase_params.gpraddress;
			selectedboardstate->gprenabled=0;
			break;
		case IOCTL_ENABLEGPRS :

#ifdef DEBUG
			printk("acpdriver ioctl IOCTL_ENABLEGPRS\n");
#endif
			iscgprcontrol(selectedboardstate->isc_apicid0,
						  selectedboardstate->isc_apicid1,
						  selectedboardstate->gprbase,
						  1);
			selectedboardstate->gprenabled=1;
			break;

		case IOCTL_DISABLEGPRS :
#ifdef DEBUG
			printk("acpdriver ioctl IOCTL_DISABLEGPRS\n");
#endif
			//select board base on disablegpr_params->acp_id
			iscgprcontrol(selectedboardstate->isc_apicid0,
		 				  selectedboardstate->isc_apicid1,
						  selectedboardstate->gprbase,
						  0);
			selectedboardstate->gprenabled=0;
			break;
		case IOCTL_RESETIODELAYS :
#ifdef DEBUG
			printk("acpdriver ioctl RESETIODELAYS\n");
#endif
			resetiodelays(selectedboardstate);
			break;
		case IOCTL_SETIODELAYS :
#ifdef DEBUG
			printk("acpdriver ioctl SETIODELAYS\n");
#endif
			if(copy_from_user (&ksetiodelays_params,
							  (void *)arg,
							  (sizeof(struct setiodelays_params))))
				return -EFAULT;
			//temporary, select from a list of boards
			//based on acp_id identifier in setiodelays_params
			setiodelays(&(ksetiodelays_params.acp_iodelays),
						selectedboardstate);
			break;
		case IOCTL_GETIODELAYS :
#ifdef DEBUG
			printk("acpdriver ioctl GETIODELAYS\n");
#endif
			if(copy_from_user(&kgetiodelays_params,
									(void *)arg,
									(sizeof(struct getiodelays_params))))
				return -EFAULT;
			//temporary, select from a list of boards as above
			if(copy_to_user(kgetiodelays_params.acp_iodelays,
									&(selectedboardstate->iodelays),
									sizeof(struct acp_iodelays)))
				return -EFAULT;
			break;
		case IOCTL_GETPHYSICAL :
			//get last physical address mmaped
#ifdef DEBUG
			printk("acpdriver ioctl GETPHYSICAL\n");
#endif
			vmalastpage = pfn_to_page(vmalast->vm_pgoff);
			vmalastpagekaddr = page_address(vmalastpage);
			vmalastphys = virt_to_phys(vmalastpagekaddr);
#ifdef DEBUG
			printk("phy GPR base %x %x %x %x\n",
							(unsigned int) vmalast->vm_pgoff,
							(unsigned int) vmalastpage,
							(unsigned int) vmalastpagekaddr,
							(unsigned int)vmalastphys);
#endif
			if(copy_to_user ((void *) arg,&vmalastphys,sizeof(void *)))
				return -EFAULT;
			break;
		case IOCTL_ASSOCIATEUSER :
#ifdef DEBUG
			printk("acpdriver ioclt ASSOCIATEUSER\n");
#endif
			//associate a user base address to a memalloc ID
			if (copy_from_user (&kassociateuser_params, (void *) arg, (sizeof(struct associateuser_params))));
			for(i=0;i<=usedmemallocs;i++){
				if(memalloc_array[used_memallocindex[i]].physical_base==kassociateuser_params.physical_base){
					memalloc_array[used_memallocindex[i]].user_base=(uint64_t)kassociateuser_params.user_base;
				}
			}
			break;
		case IOCTL_GPRWRITE :
#ifdef DEBUG
			printk("acpdriver ioclt GPRWRITE\n");
#endif
			if (copy_from_user (&gpr_writeparams, (void *) arg, 2*sizeof(unsigned int)))
					return -EFAULT;
#ifdef DEBUG
			printk("gpr write\n");
			printk("gpr offset %ld\n",(long int)gpr_writeparams[0]);
			printk("gpr value %ld\n",(long int)gpr_writeparams[1]);
#endif
			iowrite32(gpr_writeparams[1],GPRBARADDRESS+gpr_writeparams[0]);

			break;
		case IOCTL_SENDIPI :
			//printk("acpdriver ioclt SENDIPI\n");
			if(copy_from_user((void *)& kipi_params,(void *) arg, sizeof(struct ipi_params))) return -EFAULT;
			send_ipi(kipi_params.apicid,kipi_params.vector);

			break;
		case IOCTL_MEMALLOC :
#ifdef DEBUG
			printk("acpdriver ioclt MEMALLOC\n");
#endif
			dump_memallocs();
			//allocate a contigious
			if(copy_from_user((void *)& kmemalloc_params,(void *) arg, sizeof(struct memalloc_params))) return -EFAULT;

			if (usedmemallocs < MAX_NUM_BUFFERS)
			{
				order = get_order(kmemalloc_params.size);
				pg_base = alloc_pages(GFP_KERNEL, order);
				if(pg_base==NULL) return -ENOMEM;
				kv_pg_base = page_address(pg_base);
				//memset(kv_pg_base, 0, PAGE_SIZE << order); // ????
				//set the pages to be reserved ?
				vbase = page_address(pg_base);
				for(offset=0;offset<kmemalloc_params.size;
								offset += PAGE_SIZE){
					page = virt_to_page(vbase+offset);
					SetPageReserved(page);
				}
				freeindex=free_memallocindex[MAX_NUM_BUFFERS-1-
											 usedmemallocs];
				//_buf_id++; // increase the allocated buffers counter
				//printk("memalloc buf_id:%d\n", _buf_id);
				// store the buffer info for future reference
				memalloc_array[freeindex].pg_base = pg_base;
				memalloc_array[freeindex].user_base = NULL;
				memalloc_array[freeindex].physical_base =
					virt_to_phys(kv_pg_base);
				memalloc_array[freeindex].order = order;
				memalloc_array[freeindex].size = kmemalloc_params.size;
				memalloc_array[freeindex].buf_id = freeindex;

				//return allocation results
				kmemalloc_params.pg_base =
						memalloc_array[freeindex].pg_base;
				kmemalloc_params.physical_base =
						memalloc_array[freeindex].physical_base;
				kmemalloc_params.order =
						memalloc_array[freeindex].order;
				kmemalloc_params.buf_id =
						memalloc_array[freeindex].buf_id;

				//update memory allocation stacks
				//add to used stack
				used_memallocindex[usedmemallocs-1+1]=
						free_memallocindex[MAX_NUM_BUFFERS-1-
						usedmemallocs];
				usedmemallocs++;
				dump_memallocs();
				if(copy_to_user((void *) arg,(void *)&kmemalloc_params,sizeof(struct memalloc_params))) return -EFAULT;
			}
			else
				return -ENOMEM;
			break;

		case IOCTL_MEMFREE :
#ifdef DEBUG
			//free a pinned region by page address
			printk("acpdriver ioclt MEMFREE\n");
#endif
			dump_memallocs();
			imatch=-1;
			if(copy_from_user((void *)& kmemfree_params,(void *) arg,sizeof(uint64_t))) return -EFAULT;
#ifdef DEBUG
			printk("parameter %u\n",kmemfree_params);
#endif
			for(i=0;i<usedmemallocs;i++){
#ifdef DEBUG
				printk("match ? addr:%u %u\n",
						memalloc_array[i].user_base,kmemfree_params);
#endif
				if(memalloc_array[used_memallocindex[i]].user_base==
								kmemfree_params){
					imatch=used_memallocindex[i];
					imatch2=i;
				}
			}
			if(imatch>=0){
				vbase = page_address(memalloc_array[imatch].pg_base);
#ifdef DEBUG
				printk("memfree base %d size %d\n",vbase,
						memalloc_array[imatch].size
			  	);
#endif
				for(offset=0;offset<memalloc_array[imatch].size;
								offset+=PAGE_SIZE){
					page=virt_to_page(vbase+offset);
					ClearPageReserved(page);
				}
				__free_pages(memalloc_array[imatch].
								pg_base,memalloc_array[imatch].order);
#ifdef DEBUG
				printk("memfree buf_id:%d\n", _buf_id);
#endif
				//add to free stack
				free_memallocindex[MAX_NUM_BUFFERS-1-(usedmemallocs-1)]=
					imatch;
				//remove element from used stack
				//pop stack and replacing element to remove with
				//popped element
				used_memallocindex[imatch2]=
					used_memallocindex[usedmemallocs-1];
				usedmemallocs--;
				dump_memallocs();
				//_buf_id--;
			}
			break;

		case IOCTL_MEMFREE_BY_ID :
			//free a pinned region by id
#ifdef DEBUG
			printk("acpdriver ioclt MEMFREE_BY_ID\n");
#endif
			if(copy_from_user((void *)& kmemalloc_params,(void *) arg,sizeof (struct memalloc_params))) return -EFAULT;

						if ( (kmemalloc_params.buf_id > -1) && (kmemalloc_params.buf_id <= _buf_id ) )
						{
								vbase = page_address(kmemalloc_params.pg_base);
								for(offset=0;offset<kmemalloc_params.size;offset+=PAGE_SIZE){
										page=virt_to_page(vbase+offset);
										ClearPageReserved(page);
								}
								__free_pages(memalloc_array[kmemalloc_params.buf_id].pg_base, memalloc_array[kmemalloc_params.buf_id].order);
#ifdef DEBUG
								printk("memfree buf_id:%d\n", _buf_id);
#endif
								_buf_id--;
						}
						else
						{
#ifdef DEBUG
								printk("Invalid buf_id");
#endif
								return -EINVAL; // invalid argument
						}


						break;


				case IOCTL_GET_BUFID :
#ifdef DEBUG
						printk("acpdriver ioclt GET_BUFID\n");
#endif

						// returns the current buf_id (the user should know that current buf_id + 1 = number of allocated buffers)
						if ( (_buf_id > -1) && (_buf_id < MAX_NUM_BUFFERS) )
						{
								// if the requested buffer has been already allocated then return buffer info
								kmemalloc_params.pg_base        = memalloc_array[_buf_id].pg_base;
								kmemalloc_params.physical_base  = memalloc_array[_buf_id].physical_base;
								kmemalloc_params.order          = memalloc_array[_buf_id].order;
								kmemalloc_params.buf_id         = _buf_id;
						}
						else
						{
								// if the the requested buffer has NOT been allocated then return NULL.
								kmemalloc_params.pg_base        = NULL;
								kmemalloc_params.physical_base  = 0;
								kmemalloc_params.order          = 0;
								kmemalloc_params.buf_id         = -1;
						}

						if (arg)
						{
								if(copy_to_user((void *) arg, (void *)&kmemalloc_params, sizeof(struct memalloc_params))) return -EFAULT;
						}
						else
						{
								printk(KERN_ERR "ioctl argument is NULL\n");
								return -EINVAL;
						}

						break;


				case IOCTL_GET_BUFADDR :
						// returns the physical memory of a previously allocated buffer based on the buffer ID
#ifdef DEBUG
						printk("acpdriver ioclt GET_BUFADDR\n");
#endif
						if(copy_from_user((void *)& kmemalloc_params,(void *) arg, sizeof (struct memalloc_params))) return -EFAULT;


						if ( (kmemalloc_params.buf_id <= _buf_id) && ( _buf_id > -1 ) )
						{
								// if the requested buffer has been already allocated then return buffer info
								kmemalloc_params.pg_base        = memalloc_array[kmemalloc_params.buf_id].pg_base;
								kmemalloc_params.physical_base  = memalloc_array[kmemalloc_params.buf_id].physical_base;
								kmemalloc_params.order          = memalloc_array[kmemalloc_params.buf_id].order;
						}
						else
						{
								// if the the requested buffer has NOT been allocated then return NULL.
								kmemalloc_params.pg_base        = NULL;
								kmemalloc_params.physical_base  = 0;
								kmemalloc_params.order          = 0;
						}


						if (arg)
						{
								if(copy_to_user((void *) arg,(void *)&kmemalloc_params,sizeof(struct memalloc_params))) return -EFAULT;
						}
						else
						{
								printk(KERN_ERR "ioctl argument is NULL\n");
								return -EINVAL;
						}

						break;
				default :
#ifdef DEBUG
						printk("acpdriver ioctl unknown code\n");
#endif
						return -EINVAL;
						break;
		}
		return 0;
}

void acp_vma_open(struct vm_area_struct *vma){
}

void acp_vma_close(struct vm_area_struct *vma){
}

static struct vm_operations_struct acp_remap_vm_ops = {
		.open = acp_vma_open,
		.close = acp_vma_close
};

//mmap to remap_pfn_range
static int acpdriver_mmap(struct file *flip, struct vm_area_struct *vma){
		int remapresult;
#ifdef DEBUG
		printk("acpdriver mmap pgoff %x vm_start %x vm_end %x\n",(unsigned int)vma->vm_pgoff,(unsigned int) vma->vm_start,(unsigned int) vma->vm_end);
#endif
		vmalast = vma;
		vma->vm_flags |= VM_RESERVED;
		remapresult = remap_pfn_range( vma, vma->vm_start, vma->vm_pgoff, vma->vm_end-vma->vm_start, vma->vm_page_prot );
		if(remapresult){
				return -EAGAIN;
		}
		else{
				vma->vm_ops = &acp_remap_vm_ops;
				acp_vma_open(vma);
				return 0;
		}
}


struct file_operations acpdriver_fops = {
		.open  = 	acpdriver_open,
		.release = 	acpdriver_release,
		.ioctl =	acpdriver_ioctl,
		.mmap = 	acpdriver_mmap,
		.owner = 	THIS_MODULE,
};



static int d_init(void){
		int result,i;
#ifdef DEBUG
		printk("cl d_init\n");
#endif
		//dev_t
		result=alloc_chrdev_region(&acpdriver_dev,0,4,"acpdriver");
		if(result){
				printk("acpdriver: alloc_chrdev_region fail\n");
				goto fail_allocchrdev;
		}else{
				printk("acpdriver: registered with major %d minor %d count 4\n",MAJOR(acpdriver_dev),MINOR(acpdriver_dev));
		}

		//cdev
		acpdriver_cdev = cdev_alloc();
		cdev_init(acpdriver_cdev,&acpdriver_fops);
		cdev_add(acpdriver_cdev,acpdriver_dev,4);

		//initialize state
		//initalize constants in acp_state
		for(i=0;i<MAXPACKAGEID;i++){
				global_acp_state[i].isc_apicid0=sockettoapicid[i];
				global_acp_state[i].isc_apicid1=sockettoapicid[i]+1;

		}

		//reset PHY and IO delays
		for(i=0;i<MAXPACKAGEID;i++) resetiodelays(&global_acp_state);

		//ioremap GPRBAR
		v_gprbar = ioremap(GPRBARADDRESS,GPRBARSIZE);
		if(v_gprbar!=NULL){
#ifdef DEBUG
				printk("acpdriver: d_init ioremap success %lx\n",(long unsigned int)v_gprbar);
#endif
		}
		else{
#ifdef DEBUG
				printk("acpdriver: d_init ioremap fail \n");
#endif
				goto fail_gprbaralloc;
		}

		_buf_id = -1; // no buffers at the beginning
#ifdef DEBUG
		printk("_buf_id:%d\n", _buf_id);
#endif

		//initialize allocated buffers
		for(i=0;i<MAX_NUM_BUFFERS;i++)
				free_memallocindex[i]=MAX_NUM_BUFFERS-1-i;
		usedmemallocs = 0;

		return 0;
fail_allocchrdev : return 1;
fail_gprbaralloc : return 1;
}


static void d_exit(void)
{
		void *vbase;
		unsigned long offset;
		struct page *page;
		printk("cl d_exit\n");

		// deallocate all the buffers
		while( _buf_id >= 0 )
		{
				vbase = page_address(memalloc_array[_buf_id].pg_base);
#ifdef DEBUG
				printk("memfree base %d size %d\n",vbase,
								memalloc_array[_buf_id].size
					  );
#endif
				for(offset=0;offset<memalloc_array[_buf_id].size;
								offset+=PAGE_SIZE){
						page=virt_to_page(vbase+offset);
						ClearPageReserved(page);
				}

				__free_pages( memalloc_array[_buf_id].pg_base, memalloc_array[_buf_id].order );
#ifdef DEBUG
				printk("free buf_id:%d\n", _buf_id);
#endif
				_buf_id--;
		}

		if(v_gprbar!=NULL) iounmap(v_gprbar);
		cdev_del(acpdriver_cdev);
		unregister_chrdev_region(acpdriver_dev,4);
}


module_init(d_init);
module_exit(d_exit);
