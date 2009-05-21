/*******************************************************************************
 *
 * Copyright (c) 2007, 2008 ArchesComputing
 *
 * This design is confidential and proprietary of ArchesComputing. All Rights Reserved
 *
 *  Arches-MPI library Version 1.0
 *
 *  April, 2005 - April 2008
 *
 *  Author: Manuel Saldaña
 *
 *  Purpose:
 *      mpi.h - Main header (user's header)
 *
 *  Notes:
 *      
 *******************************************************************************/


#ifndef _MPI_H_
#define _MPI_H_

#ifdef __cplusplus
extern "C"
{
#endif
#include "mpi_headers.h"

#ifndef ARCHES_MPI_LIB
#include "GeneratedConstants.h"
#endif

#include "mpi_constants.h"

#ifndef arg_cat2
#define arg_cat2(x, y) x ## y
#endif

#ifndef arg_cat
#define arg_cat(x, y) arg_cat2(x, y)
#endif        

// ---------------------------------------
// Datatypes
// ---------------------------------------
struct pending_request_struct;
typedef struct pending_request_struct *MPI_Request;

//#define MPI_Request addr_t

typedef int MPI_Comm;
typedef int MPI_Info;
typedef int MPI_Group;

// address width
#if defined(MPI_32BIT)
typedef uint32_t addr_t;
#define PTR_FMT "0x%08x"
#define ADDR_CAST (unsigned int)
#else
typedef uint64_t addr_t;
#define PTR_FMT "0x%016llx"
#define ADDR_CAST (unsigned long long)
#endif

// MPI_Aint is defined to be an integer of the size needed to hold any valid address on the target architecture
#define MPI_Aint addr_t

enum MPI_OP  {MPI_SUM, MPI_MAX, MPI_MIN, MPI_LOR};
enum MPI_DATATYPE {MPI_INT, MPI_FLOAT};

#define MPI_Datatype enum MPI_DATATYPE
#define MPI_Op enum MPI_OP

typedef struct
{
    unsigned int MPI_TAG;
    unsigned int MPI_SOURCE;
    unsigned int MPI_ERROR;
} MPI_Status;

// ---------------------------------------
// Constants
// ---------------------------------------


// ---------------------------------------
// Function Prototypes 
// ---------------------------------------
#define MPI_Ssend(args...) MPI_Send(args)

int MPI_Init(int *argc, char ***argv);
int MPI_Finalize();

int MPI_Comm_size(MPI_Comm comm, int *size);
int MPI_Comm_rank(MPI_Comm comm, int *rank);

int MPI_Issend(void *buf, int count, MPI_Datatype datatype, int dest, int tag, MPI_Comm comm, MPI_Request *request);
int MPI_Isend(void *buf, int count, MPI_Datatype datatype, int dest, int tag, MPI_Comm comm, MPI_Request *request );
int MPI_Ssend(void *buf, int count, MPI_Datatype datatype, int dest, int tag, MPI_Comm comm );
//int MPI_Rsend(void *buf, int count, MPI_Datatype datatype, int dest, int tag, MPI_Comm comm );
int MPI_Send(void *buf, int count, MPI_Datatype datatype, int dest, int tag, MPI_Comm comm);

int MPI_Irecv(void *buf, int count, MPI_Datatype datatype, int source, int tag, MPI_Comm comm, MPI_Request *request);
int MPI_Recv(void *buf, int count, MPI_Datatype datatype, int source, int tag, MPI_Comm comm, MPI_Status *status);

int MPI_Barrier(MPI_Comm comm);
int MPI_Bcast( void *buffer, int count, MPI_Datatype datatype, int root, MPI_Comm comm );
int MPI_Reduce(void *sendbuf, void *recvbuf, int count, MPI_Datatype datatype, MPI_Op op, int root, MPI_Comm comm);
int MPI_Allreduce(void *sendbuf, void *recvbuf, int count, MPI_Datatype datatype, MPI_Op op, MPI_Comm comm );
int MPI_Gather(void *send_buf, int send_len, MPI_Datatype send_datatype, void *recv_buf, 
                int recv_len, MPI_Datatype recv_datatype, int root, MPI_Comm comm);


int MPI_Waitall( int count, MPI_Request array_of_requests[], MPI_Status array_of_statuses[] );
int MPI_Wait ( MPI_Request  *request, MPI_Status   *status);
int MPI_Test ( MPI_Request  *request, int *flag, MPI_Status  *status);
int MPI_Request_free(MPI_Request *request);

int MPI_Alloc_mem(MPI_Aint size, MPI_Info info, void *baseptr);
int MPI_Free_mem(void *base);

double MPI_Wtime(); 



// ---------------------------------------
// MPI runtime and system-dependant variables
// ---------------------------------------
#ifndef ARCHES_MPI_LIB
extern int _mpi_node;
extern int _mpi_rank;
extern int _mpi_size;

extern unsigned char _mpi_ce_types[MAX_MPI_SIZE];
extern unsigned char _mpi_os_types[MAX_MPI_SIZE];
extern unsigned char _mpi_bootld[MAX_MPI_SIZE];

#if defined(X86)
//#include "stdio.h"
extern char _mpi_rank_map_filename[300];
extern int _mpi_num_fpga_stacks;
extern int _mpi_num_local_nodes;
extern int _mpi_num_local_ranks;
extern int _mpi_shm_local_leader;
extern int _mpi_num_fpga_stacks;
extern int _mpi_num_gprs;
extern int _mpi_num_extra_gprs;
#endif // #if defined(X86)

#if defined(MB) || defined(PPC)
//#include "xparameters.h"
extern float _mpi_proc_clock_hz;
extern float _mpi_sec_per_int;
extern int _mpi_system_timer_device_id;
extern int _mpi_system_intc_system_timer_interrupt_intr;
extern unsigned long int _mpi_system_timer_baseaddr;
#endif

void _mpi_get_runtime_env(void);

#endif // ARCHES_MPI_LIB

#ifdef __cplusplus
}
#endif
#endif // _MPI_H_
