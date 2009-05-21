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
 *      Describes the System-level structure
 *
 *  Notes:
 *      Generated automatically by compile.py script
 *******************************************************************************/


#ifndef _GENERATEDCONSTANTS_H_
#define _GENERATEDCONSTANTS_H_

#define MPI_NUM_EXTRA_GPRS  58
#define MPI_NUM_GPRS         6
#define STDOUT_ENABLED
#define MPI_SHM_LOCAL_LEADER 0
#define MPI_RANK             0
#define THREAD_MPE
#define MPI_SIZE             3
#define TMD_MPI
#define PROCESSOR_ID         X86A
#define X86
#define LINUX
#define FSL
#define MPI_NUM_LOCAL_NODES  2
#define MPI_NUM_FPGA_STACKS  1
#define MPI_MAP_FILE         "rank-node-map"


//----------------------
typedef enum
{
   NODE_PPC_405,
	NODE_MICROBLAZE,
	NODE_X86,
	NODE_CE,
	unused = 0x7FFFFFFF
} processor_t;
//----------------------
typedef enum
{
	NODE_STANDALONE,
	NODE_LINUX,
	NODE_UNDEFINED
} os_t;
//----------------------
static const processor_t anMPITypes[MPI_SIZE] =
{
	NODE_X86,
	NODE_MICROBLAZE,
	NODE_CE
};
//----------------------
static const os_t anMPIOS[MPI_SIZE] =
{
	NODE_LINUX,
	NODE_STANDALONE,
	NODE_STANDALONE
};
//----------------------
static const int anMPIBOOTLD[MPI_SIZE] =
{
	0,
	0,
	0
};
#endif // _GENERATEDCONSTANTS_H_
