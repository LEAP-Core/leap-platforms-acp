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

    char bitfile[255];
    sprintf(bitfile, ".xilinx/%s_par.bit", APM_NAME);

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
    workspaceSize = 2048 / sizeof(NALLATECH_WORD);
	workspace = (NALLATECH_WORD*) ACP_Allocate(hafu,
                                               workspaceSize * sizeof(NALLATECH_WORD),
                                               &workspacePA);
    if (workspace == NULL)
    {
        printf("Failed!\n");
        CallbackExit(1);
    }

	printf("\tOK\n");

    /*
    // DEBUG: perform loopback test and exit
    int len = 8;
    int len_bytes = len * sizeof(NALLATECH_WORD);
    int disp = 1024;

	for (i = 0; i < len; i++)
		workspace[i] = i;

    for (i = len; i < 2*len; i++)
        workspace[i] = 0;

	for (i = 0; i < len; i++)
		printf("Before %d = %d\n", i, workspace[i+len]);

    // printf("To perform loopback test, press <enter>.\n");
    // getchar();

	// ACP_MemCopy(hafu, workspacePA, len_bytes, workspacePA + disp, len_bytes);

    cout << "len_bytes = " << len_bytes << endl;

    ACP_MemCopy(hafu, workspacePA, 32, workspacePA + 1024, 32);

    // print results.
	for (i = 0; i < len; i++)
		printf("Result %d = %d\n", i, workspace[i+(disp/4)]);

    cout << "ACP shutting down\n";

    // shutdown ACP stack
    if (workspace != NULL)
    {
        ACP_Deallocate(hafu, workspace, workspaceSize * sizeof(NALLATECH_WORD));
    }

    cout << "Deallocate done.\n";
	ACP_CloseAFU(hafu);
    cout << "AFU closed.\n";
	ACP_CloseSocket(hsocket);
    cout << "All finished, exiting.\n";

    CallbackExit(0); // should eventually trigger Uninit()
    */
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
        ACP_Deallocate(hafu, workspace, workspaceSize * sizeof(NALLATECH_WORD));
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

    // m AND n should be less than half the workspace size
    if (m > workspaceSize/2 || n > workspaceSize/2)
    {
        cout << "AAL transaction size exceeds size of workspace\n";
        CallbackExit(1);
    }

    // firmware bug: cannot handle transactions less than 64 bytes in length
    if (m_bytes < 64)
    {
        cout << "AAL transaction size (write) smaller than 64: "
             << m_bytes << "\n";
        CallbackExit(1);
    }

    if (n_bytes < 64)
    {
        cout << "AAL transaction size (read) smaller than 64: "
             << n_bytes << "\n";
        CallbackExit(1);
    }

	// Send m words of data to SPL interface from workspace
	// Read n words from SPL interface to workspace offset by m bytes
    //     BUG? Send the entire half-workspace
    int window = (workspaceSize/2) * sizeof(NALLATECH_WORD);
	ACP_MemCopy(hafu, workspacePA, m_bytes, workspacePA + window, n_bytes);
}
