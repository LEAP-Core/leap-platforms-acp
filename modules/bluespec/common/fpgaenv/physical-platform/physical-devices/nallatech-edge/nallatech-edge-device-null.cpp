//
// Copyright (C) 2008 Intel Corporation
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//

#include <iostream>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <sys/ioctl.h>
#include <stdio.h>

#include "stdlib.h"
#include "ctype.h"
#include "math.h"

#include "asim/syntax.h"
#include "asim/provides/physical_platform_utils.h"
#include "asim/provides/nallatech_edge_device.h"

using namespace std;

// ============================================
//              Nallatech EDGE Device
// ============================================

NALLATECH_EDGE_DEVICE_CLASS::NALLATECH_EDGE_DEVICE_CLASS(
    PLATFORMS_MODULE p) :
    PLATFORMS_MODULE_CLASS(p)
{
    workspace = NULL;
}


NALLATECH_EDGE_DEVICE_CLASS::~NALLATECH_EDGE_DEVICE_CLASS()
{
    Cleanup();
}


UINT64
NALLATECH_EDGE_DEVICE_CLASS::WorkspaceBytes() const
{
    return
        (NALLATECH_NUM_WRITE_WINDOWS + NALLATECH_NUM_READ_WINDOWS) *
        NALLATECH_MAX_MSG_WORDS *
        sizeof(NALLATECH_WORD);
}


NALLATECH_WORD*
NALLATECH_EDGE_DEVICE_CLASS::GetWriteWindow(int windowID) const
{
    return workspace + (windowID * NALLATECH_MAX_MSG_WORDS);
}


NALLATECH_WORD*
NALLATECH_EDGE_DEVICE_CLASS::GetReadWindow(int windowID) const
{
    return workspace + ((NALLATECH_NUM_WRITE_WINDOWS + windowID) *
                        NALLATECH_MAX_MSG_WORDS);
}


// initialize hardware
void
NALLATECH_EDGE_DEVICE_CLASS::Init()
{
	int ret;
	int i;

    // Which card is allocated?  The run script will pass the FPGA device
    // allocated in FPGA_DEV_PATH.  The socket number is the last digit of
    // the path.
    int acp_socket = ACP_FSB_SOCKET;  // In case no FPGA_DEV_PATH
    if (! FPGA_DEV_PATH.empty())
    {
        const char n = FPGA_DEV_PATH[FPGA_DEV_PATH.length() - 1];
        if ((n >= '0') && (n <= '9'))
        {
            acp_socket = n - '0';
        }
    }

	// Open card
	printf("Opening card...                           ");
	hsocket = ACP_OpenSocket(acp_socket);
    if (hsocket == NULL)
    {
        printf("failed to open socket %d\n", acp_socket);
        CallbackExit(1);
    }
	printf("\tOK\n");

	printf("Reseting module...                        ");
	ret = ACP_RESET(hsocket);
	if (ret != 0)
    {
		ACP_ERROR error = ACP_GetLastError();
        printf("\tfailed ACP_RESET (%lx)\n", (long)error);
    }
    else
    {
        printf("\tOK\n");
    }

	// Configure
	printf("Configuring compute FPGA...               ");

    char *bitfile = getenv("FPGA_BIT_FILE");
    if (bitfile == NULL)
    {
        printf("\nERROR:  FPGA_BIT_FILE environment variable must be defined!\n");
        CallbackExit(1);
    }

    char *bitfile0 = getenv("FPGA_BIT_FILE0");
    if (bitfile0 == NULL)
    {
        printf("\nERROR:  FPGA_BIT_FILE0 environment variable must be defined!\n");
        CallbackExit(1);
    }

	ret = ACP_ConfigureFPGA(hsocket, bitfile0, DEVICE_ID(1,ACP_FPGA0,0));

	if (ret != 0)
	{
		ACP_ERROR error = ACP_GetLastError();
		printf("Last error ID = %lx\n",(long)error);
		switch (error)
		{
			case ACP_INVALID_BITFILE :
				printf("Invalid bitfile ACP0 %s\n", bitfile);
				break;
			default : printf("Unknown error\n");
				break;
		}
		printf("Configuration Failed\n");
        CallbackExit(1);
	}

	ret = ACP_ConfigureFPGA(hsocket, bitfile, DEVICE_ID(1,ACP_FPGA1,0));

	if (ret != 0)
	{
		ACP_ERROR error = ACP_GetLastError();
		printf("Last error ID = %lx\n",(long)error);
		switch (error)
		{
			case ACP_INVALID_BITFILE :
				printf("Invalid bitfile ACP1 %s\n", bitfile);
				break;
			default : printf("Unknown error\n");
				break;
		}
		printf("Configuration Failed\n");
        CallbackExit(1);
	}




	printf("\tOK\n");

	printf("Initializing Base to FPGA 0 LVDS link...  ");

	ret = ACP_Initialize_LVDS_Link(hsocket,
                                   DEVICE_ID(0,0,0),
                                   DEVICE_ID(0,0,0),
                                   DEVICE_ID(1,0,0),
                                   DEVICE_ID(1,0,0));

	if (ret != 0)
	{
		ACP_ERROR error = ACP_GetLastError();
		printf("Last error ID = %lx\n",(long)error);

		printf("LVDS Initialization Failed Press <Enter> To Exit\n");
        getchar();
        CallbackExit(1);
	}
	printf("\tOK\n");


	printf("Initializing Base to FPGA 0 - FPGA 1 LVDS link...  ");

        ret = ACP_Initialize_LVDS_Link(hsocket,
                                       DEVICE_ID(1,0,0),
				       DEVICE_ID(1,0,0),
                                       DEVICE_ID(1,1,0),
                                       DEVICE_ID(1,1,0));
	
	if (ret != 0)
	{
		ACP_ERROR error = ACP_GetLastError();
		printf("Last error ID = %lx\n",(long)error);

		printf("LVDS Initialization Failed Press <Enter> To Exit\n");
        getchar();
        CallbackExit(1);
	}
	printf("\tOK\n");

	printf("Setting up AFU and Workspace...           ");

	// Open AFU handle
	hafu = ACP_OpenAFU(hsocket, 0);

	// Allocate workspace
	workspace = (NALLATECH_WORD*) ACP_Allocate(hafu, WorkspaceBytes(), &workspacePA);
    if (workspace == NULL)
    {
        printf("Failed!\n");
        CallbackExit(1);
    }

	printf("\tOK\n");

    printf("Setting up LEDS...           \n");
    ACP_REG reg;
    ACP_ReadAFURegister(hafu,
                        0x26000 + (0x5),
                        DEVICE_ID(1,0,0),
                        &reg);

    printf("FPGA 0 LEDS: 0x%x\n", reg);

    ACP_ReadAFURegister(hafu,
                        0x26000 + (0x5),
                        DEVICE_ID(1,1,0),
                        &reg);

    printf("FPGA 1 LEDS: 0x%x\n", reg);

    ACP_WriteAFURegister(hafu,
                         0x26000 + (0x5),
                         ~0,
                         DEVICE_ID(1,0,0));

    ACP_WriteAFURegister(hafu,
                         0x26000 + (0x5),
                         ~0,
                         DEVICE_ID(1,1,0));

    ACP_ReadAFURegister(hafu,
                        0x26000 + (0x5),
                        DEVICE_ID(1,0,0),
                        &reg);

    printf("FPGA 0 LEDS: 0x%x\n", reg);

    ACP_ReadAFURegister(hafu,
                        0x26000 + (0x5),
                        DEVICE_ID(1,1,0),
                        &reg);

    printf("FPGA 1 LEDS: 0x%x\n", reg);



	printf("\tOK\n");

}


// override default chain-uninit method because
// we need to do something special
void
NALLATECH_EDGE_DEVICE_CLASS::Uninit()
{
    Cleanup();

    // call default uninit so that we can continue
    // chain if necessary
    PLATFORMS_MODULE_CLASS::Uninit();
}

// cleanup
void
NALLATECH_EDGE_DEVICE_CLASS::Cleanup()
{
    cout << "ACP shutting down...\n";

    // shutdown ACP stack
    if (workspace != NULL)
    {
        ACP_Deallocate(hafu, workspace, WorkspaceBytes());
    }

    cout << "Deallocate done.\n";
	ACP_CloseAFU(hafu);
    cout << "AFU closed.\n";
	ACP_CloseSocket(hsocket);
    cout << "All finished, exiting.\n";
}


// An AAL Transaction is a Write of m words followed by a Read
// of n words. The entire process is a single blocking atomic
// transaction.
void
NALLATECH_EDGE_DEVICE_CLASS::DoAALTransaction(
    int writeWindowID,
    int writeWords,
    int readWindowID,
    int readWords)
{
    UINT64 write_pa = workspacePA + (writeWindowID *
                                     NALLATECH_MAX_MSG_WORDS * sizeof(NALLATECH_WORD));
    UINT64 read_pa = workspacePA + ((NALLATECH_NUM_WRITE_WINDOWS + readWindowID) *
                                    NALLATECH_MAX_MSG_WORDS * sizeof(NALLATECH_WORD));

    int write_bytes = writeWords * sizeof (NALLATECH_WORD);
    int read_bytes = readWords * sizeof (NALLATECH_WORD);

    // size checks
    if ((writeWords > NALLATECH_MAX_MSG_WORDS) ||
        (readWords > NALLATECH_MAX_MSG_WORDS))
    {
        cerr << "AAL transaction size exceeds size of workspace" << endl;
        CallbackExit(1);
    }

    if ((writeWindowID >= NALLATECH_NUM_WRITE_WINDOWS) ||
        (readWindowID >= NALLATECH_NUM_READ_WINDOWS))
    {
        cerr << "AAL transaction: illegal window ID" << endl;
        CallbackExit(1);
    }

    if ((write_bytes < NALLATECH_MIN_MSG_BYTES) ||
        (read_bytes < NALLATECH_MIN_MSG_BYTES))
    {
        cerr << "AAL transaction smaller than minimum transfer size" << endl;
        CallbackExit(1);
    }

	ACP_MemCopy(hafu, write_pa, write_bytes, read_pa, read_bytes);

    //
    // Bug in ACP I/O appears to require delay to avoid corruption.  4KB vs.
    // 8KB packets nearly eliminates the bug completely.  (4KB is now the
    // default.)
    //
    if (read_bytes > (NALLATECH_MAX_MSG_BYTES / 2))
    {
        volatile int delay = 5;
        while (--delay) ;
    }
}


//
// Register interface is used for debugging.  These requests are accessed
// as regWrite, etc. in the edge driver on the FPGA.
//
void
NALLATECH_EDGE_DEVICE_CLASS::DebugRegWrite(
    UINT16 addr,
    UINT16 data)
{
    ACP_WriteAFURegister(hafu,
                         FSB_EXP_USER_REG_IF2 + (addr & 0x1fff),
                         data,
                         DEVICE_ID(1,0,0));
}

UINT16
NALLATECH_EDGE_DEVICE_CLASS::DebugRegRead(
    UINT16 addr)
{
    ACP_REG reg;

    ACP_ReadAFURegister(hafu,
                        FSB_EXP_USER_REG_IF2 + (addr & 0x1fff),
                        DEVICE_ID(1,0,0),
                        &reg);

    return reg;
}
