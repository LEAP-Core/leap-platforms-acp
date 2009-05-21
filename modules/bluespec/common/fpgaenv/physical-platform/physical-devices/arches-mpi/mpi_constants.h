/*******************************************************************************
 *
 * Copyright (c) 2007, 2008 ArchesComputing
 *
 * This design is confidential and proprietary of ArchesComputing. All Rights Reserved
 *
 *  Arches-MPI library Version 1.0
 *
 *  December 2007
 *
 *  Author: Manuel Saldaña
 *
 *  Purpose:
 *      Concentrates most of the constants
 *
 *  Notes:
 *      
 *******************************************************************************/


#ifndef _MPI_CONSTANTS_H_
#define _MPI_CONSTANTS_H_

#ifdef __cplusplus
extern "C"
{
#endif

#define MPI_COMM_WORLD 0
#define MPI_COMM_MD 1

#define MPI_COMM_NULL 99
//#define MAX_PENDING_SENDS 2*MPI_SIZE
//#define MAX_PENDING_RECVS 2*MPI_SIZE

// src and dest fields in the Network Packet header are 8 bits
#define MAX_MPI_SIZE 255  

// A "posted send" is a request, from another node, to send data.
// Since we use the Rendezvous protocol, there will be a maximum of 
// MPI_SIZE posted sends in the worst case scenario.
#define MAX_POSTED_SENDS MAX_MPI_SIZE

// 255 = Maximum number of addressable processes with 8 bits
// (0xFF = -1 with 2's complement)
#define MPI_ANY_SOURCE 0x000000FF 
#define MPI_ANY_NODE   MPI_ANY_SOURCE

//#define MPI_ANY_TAG -1
//#define __MPI_REDUCE_TAG__ 0x000000FA
//#define __MPI_BARRIER_TAG__ 0x000000FB   
//#define __MPI_BCAST_TAG__ 0x000000FC

//#define MPI_ANY_TAG -1
// 0xFFFFFFFF is reserved for clr2snd
#define __MPI_GATHER_TAG__      0xFFFFFFFE
#define __MPI_BCAST_TAG__       0xFFFFFFFD
#define __MPI_BARRIER_TAG__     0xFFFFFFFC  
#define __MPI_REDUCE_TAG__      0xFFFFFFFB
#define __MPE_INIT_RANK_TAG__   0xFFFFFFF1
#define MPI_ANY_TAG             0xFFFFFFF0

#define MPI_UNINITIALIZED_REQUEST 0xFFFFFFFF

//#if defined(THREAD_MPE)
//#define MPI_REQUEST_NULL 0
//#else
#define MPI_REQUEST_NULL NULL
//#endif

#define MPI_INFO_NULL 0

#define MPI_STATUS_IGNORE NULL

// MPI Error codes
#define MPI_SUCCESS         0 // No error   
#define MPI_ERR_BUFFER      1 // Invalid buffer pointer
#define MPI_ERR_COUNT       2 // Invalid count argument
#define MPI_ERR_TYPE        3 // Invalid datatype argument
#define MPI_ERR_TAG         4 // Invalid tag argument
#define MPI_ERR_COMM        5 // Invalid communicator
#define MPI_ERR_RANK        6 // Invalid rank 
#define MPI_ERR_REQUEST     7 // Invalid request 
#define MPI_ERR_ROOT        8 // Invalid root 
#define MPI_ERR_GROUP       9 // Invalid group 
#define MPI_ERR_OP          10 // Invalid operation 
#define MPI_ERR_TOPOLOGY    11 // Invalid topology 
#define MPI_ERR_DIMS        12 // Invalid dimensions argument 
#define MPI_ERR_ARG         13 // Invalid argument of some other kind 
#define MPI_ERR_UNKNOWN     14 // Unknown error 
#define MPI_ERR_TRUNCATE    15 // Message truncated on receive
#define MPI_ERR_OTHER       16 // Known error not in this list   
#define MPI_ERR_INTERN      17 // Internal MPI error   
#define MPI_ERR_IN_STATUS   18 // Error code is in status	 
#define MPI_ERR_PENDING     19 // Pending request	
#define MPI_ERR_LASTCODE    20 // Last error code

// max. number of words per packet without counting header and tag. 
// This limit is historical due to the fsl_aurora core
// There are 16 words per cacheline; reserve two words for header and tag
//
// Note. To use Chris Comis' FSL_Aurora use MPI_PAYLOAD_SIZE = 450 or less
//
// MPI_PAYLOAD_SIZE in 32bit WORDS (2^16 words MAX per packet)
//
//#define MPI_PAYLOAD_SIZE (16-2)     // 1 cacheline (MIN)
//#define MPI_PAYLOAD_SIZE (32-2)     // 2 cachelines
//#define MPI_PAYLOAD_SIZE (64-2)     // 4 cachelines
//#define MPI_PAYLOAD_SIZE (128-2)    // 8 cachelines 
//#define MPI_PAYLOAD_SIZE (256-2)    // 16 cachelines
//#define MPI_PAYLOAD_SIZE (512-2)    // 32 cachelines
#define MPI_PAYLOAD_SIZE   (1024-2)   // 64 cachelines = 1 page (4KB per Page)
//#define MPI_PAYLOAD_SIZE   (2048-2)   // 128 cachelines = 2 pages (4KB per Page)
//#define MPI_PAYLOAD_SIZE   (4096-2)   // 256 cachelines = 4 pages (4KB per Page)
// ...
//#define MPI_PAYLOAD_SIZE (65536-2)  // 4096 cachelines = 64 pages (4KB each) (MAX)

// TODO. Implement the double packet size to improve Zero-copy transfers
// 32bit WORDS { 2^16 words (MIN) to 2^22 words (MAX) }
//#define MPI_ZC_PAYLOAD_SIZE (65536-2)     // 4096 cachelines = 64 pages (4KB each) = 262 KB (MIN)
//#define MPI_ZC_PAYLOAD_SIZE (4194304-2)   // 262144 cachelines = 4096 pages (4KB each) = 16 MB (MAX)

// Type of packets    
// MPI_NORMAL_PACKET = { MPI_ENVELOPE_PACKET | MPI_DATA_PACKET }
// MPI_ANY_PACKET = { MPI_CLR2SND_PACKET | MPI_ENVELOPE_PACKET | MPI_DATA_PACKET }
enum PACKET_TYPE { MPI_CLR2SND_PACKET, MPI_ENVELOPE_PACKET, MPI_DATA_PACKET, MPI_NORMAL_PACKET, MPI_ANY_PACKET };

#define MPI_CLR2SND_TAG 0xFFFFFFFF

// Maxuimum number of buffers allocated by MPI_Alloc_mem
#define MPI_MAX_ALLOC_BUF 10

// Maximum number of local nodes in the sared memory matrix.
// The shared memory matrix is MPI_MAX_NUM_LOCAL_NODES^2
#define MPI_MAX_NUM_LOCAL_NODES 16

// Total number of GPRs (both directions: CPU2FPGA and FPGA2CPU)
#define MPI_MAX_NUM_GPRS 128


// ----- MicroBlaze Timers -----
#define TIMER_COUNTER_0     0
#define RESET_VALUE         0x00000000
//#define SEC_PER_INT         42.94967296 // (2^32)/CLOCK_HZ (@100MHz)
#define SEC_PER_INT         32.212262 // (2^32)/CLOCK_HZ (@133.33MHz)
//#define CLOCK_HZ          XPAR_CPU_CORE_CLOCK_FREQ_HZ
#define CLOCK_HZ            133333333

#ifdef __cplusplus
}
#endif
#endif

