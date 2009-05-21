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
 *      mpi_headers.h - Inlcudes some environment header files (OS, BSP, etc.)
 *
 *  Notes:
 *      
 *******************************************************************************/


#ifndef _MPI_HEADERS_H_
#define _MPI_HEADERS_H_

#ifdef __cplusplus
extern "C"
{
#endif

#include <stdio.h> // printf, xil_printf
#include <stdint.h>


#if XPAR_XUARTNS550_NUM_INSTANCES > 0
#   include "xuartns550_l.h"
#endif

#if defined(LINUX)
#   include <sys/types.h>  
#   include <sys/time.h>
#else
#   if defined(PPC)
#       include "xtime_l.h"
#   endif
#endif // if defined(LINUX)

#if defined(MB) || defined(PPC)
//#   include "mpi_fpga_datatypes.h"
#   include "mb_interface.h"
#   include "xtmrctr.h" 
//#   include "mpi_fsl.h"
#endif

// Determine whether interrupts are required or not
#if defined(PLB_MPE) || defined(MB)
#define __INTERRUPTS_REQUIRED
#   include "xintc.h"
#endif

#if defined(__INTERRUPTS_REQUIRED) && defined(PPC)
#   include "xexception_l.h"
#endif   

// MPE constants
//#if defined(PLB_MPE) || defined(FSL_MPE)
//#   include "mpi_mpe.h"
//#endif

#if defined(X86)
#   include <stdlib.h>
#   include <errno.h>
#   include <string.h>  
#   include <fcntl.h>
#   include <sys/stat.h>
#   include <sys/ipc.h>
#   include <sys/shm.h>
#   include <unistd.h>
#   include <sched.h>
#   include <sys/file.h>
#   include <signal.h>
#   include <sys/fcntl.h>
    //#include <sys/sem.h>	
#   include <sys/resource.h>
#   include <sys/mman.h>
 
#endif // if defined(X86)

#ifdef __cplusplus
}
#endif

#endif // _MPI_HEADERS_H_

