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

#include "stdlib.h"
#include "ctype.h"
#include "math.h"

#include "asim/provides/nallatech_edge_device.h"

#define NALLATECH_WORKSPACE_SIZE 512 // "Size of the Nallatech workspace in NALLATECH_WORD units"
#define NALLATECH_WINDOW_SPLIT   256 // "Index where the workspace input and output windows are split"

#define INPUT_WINDOW_SIZE   NALLATECH_WINDOW_SPLIT
#define OUTPUT_WINDOW_SIZE (NALLATECH_WORKSPACE_SIZE - NALLATECH_WINDOW_SPLIT)

#define TRANSFER_SIZE 256

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

NALLATECH_WORD*
NALLATECH_EDGE_DEVICE_CLASS::GetInputWindow()
{
    return workspace;
}

NALLATECH_WORD*
NALLATECH_EDGE_DEVICE_CLASS::GetOutputWindow()
{
    return (workspace + NALLATECH_WINDOW_SPLIT);
}

// initialize hardware
void
NALLATECH_EDGE_DEVICE_CLASS::Init()
{
	int ret;
	int i;

	// Open card
	printf("Opening card...                           ");
	hsocket = ACP_OpenSocket(ACP_FSB_SOCKET);
    if (hsocket == NULL)
    {
        printf("failed to open socket %d\n", ACP_FSB_SOCKET);
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

	ret = ACP_ConfigureFPGA(hsocket, bitfile, DEVICE_ID(1,0,0));

	if (ret != 0)
	{
		ACP_ERROR error = ACP_GetLastError();
		printf("Last error ID = %lx\n",(long)error);
		switch (error)
		{
			case ACP_INVALID_BITFILE :
				printf("Invalid bitfile %s\n", bitfile);
				break;
			default : printf("Unknown error\n");
				break;
		}
		printf("Configuration Failed\n");
        CallbackExit(1);
	}
	printf("\tOK\n");

	printf("Initializing Base to FPGA 0 LVDS link...  ");

	ret = ACP_Initialize_LVDS_Link(hsocket, DEVICE_ID(0,0,0), DEVICE_ID(1,0,0));

	if (ret != 0)
	{
		ACP_ERROR error = ACP_GetLastError();
		printf("Last error ID = %lx\n",(long)error);

		printf("LVDS Intialization Failed Press <Enter> To Exit\n");
        getchar();
        CallbackExit(1);
	}
	printf("\tOK\n");

	printf("Setting up AFU and Workspace...           ");

	// Open AFU handle
	hafu = ACP_OpenAFU(hsocket, 0);

	// Allocate workspace
	workspace = (NALLATECH_WORD*) ACP_Allocate(hafu,
                                               NALLATECH_WORKSPACE_SIZE * sizeof(NALLATECH_WORD),
                                               &workspacePA);
    if (workspace == NULL)
    {
        printf("Failed!\n");
        CallbackExit(1);
    }

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
        ACP_Deallocate(hafu, workspace, NALLATECH_WORKSPACE_SIZE * sizeof(NALLATECH_WORD));
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
    int m,
    int n)
{
    int m_bytes = m * sizeof (NALLATECH_WORD);
    int n_bytes = n * sizeof (NALLATECH_WORD);

    // size checks
    if (m > INPUT_WINDOW_SIZE || n > OUTPUT_WINDOW_SIZE)
    {
        cout << "AAL transaction size exceeds size of workspace\n";
        CallbackExit(1);
    }

	// Send m words of data to SPL interface from workspace
	// Read n words from SPL interface to workspace offset by m bytes

    //
    // BUG: the Nallatech stack cannot handle transactions less than 64 bytes
    //      in length, so transfer at leaset 64 bytes both ways
    //

    int window = NALLATECH_WINDOW_SPLIT * sizeof(NALLATECH_WORD);

    if (m > TRANSFER_SIZE || n > TRANSFER_SIZE)
    {
        cout << "AAL transaction size exceeds transfer size";
        CallbackExit(1);
    }

    m_bytes = TRANSFER_SIZE * sizeof(NALLATECH_WORD);
    n_bytes = TRANSFER_SIZE * sizeof(NALLATECH_WORD);

	ACP_MemCopy(hafu, workspacePA, m_bytes, workspacePA + window, n_bytes);
}
