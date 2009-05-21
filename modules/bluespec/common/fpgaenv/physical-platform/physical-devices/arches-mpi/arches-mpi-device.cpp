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
#include "mpi.h"

#include "asim/provides/arches_mpi_device.h"

using namespace std;

// ============================================
//              Arches MPI Device
// ============================================

//
// There's a lot of channel functionality in this
// module that should be moved to the arches channel
// module. This module should be analogous to its
// Bluespec counterpart and only provide a low-level
// wrapper around the core driver functionalities.
//

#define C_DATA_TAG       0xCAFECAFE
#define C_ACK_TAG        0xDEADBEEF
#define ACP_M2C_MPI_RANK 2

unsigned int fortytwo = 42;

ARCHES_MPI_DEVICE_CLASS::ARCHES_MPI_DEVICE_CLASS(
    PLATFORMS_MODULE p) :
        PLATFORMS_MODULE_CLASS(p)
{
    // setup MPI
    int   argc   = 1;
    char* argv[] = { "arches-mpi-wrapper" };

    MPI_Init(&argc, (char ***)&argv);

    MPI_Comm_size(MPI_COMM_WORLD, &mpiSize);
    MPI_Comm_rank(MPI_COMM_WORLD, &mpiRank);

    outstandingRequest = false;
    outstandingSend = false;

    MPI_Irecv(&outstandingReqBuffer, 1, MPI_INT, 2,
              MPI_ANY_TAG, MPI_COMM_WORLD, &outstandingReqHandle);
    outstandingRequest = true;

    // reset hardware
    ResetFPGA();
}

ARCHES_MPI_DEVICE_CLASS::~ARCHES_MPI_DEVICE_CLASS()
{
    Cleanup();
}

// override default chain-uninit method because
// we need to do something special
void
ARCHES_MPI_DEVICE_CLASS::Uninit()
{
    Cleanup();

    // call default uninit so that we can continue
    // chain if necessary
    PLATFORMS_MODULE_CLASS::Uninit();
}

// cleanup
void
ARCHES_MPI_DEVICE_CLASS::Cleanup()
{
    // close driver etc.
    MPI_Finalize();
}

// non-blocking read, for now it follows all-or-nothing semantics
// and involves an unnecessary copy of the data
bool
ARCHES_MPI_DEVICE_CLASS::TryRead(
    unsigned char* buf,
    int bytes_requested)
{
    // we currently only support 32-bit transfers
    if (bytes_requested != 4)
    {
        cerr << "arches_mpi_device: unsupported read size " << bytes_requested << endl;
        CallbackExit(1);
    }
/*
    // check if there's an outstanding Irecv request
    if (!outstandingRequest)
    {
        // no outstanding request, start a new one
        //MPI_Irecv(&outstandingReqBuffer, 1, MPI_INT, ACP_M2C_MPI_RANK,
        //          C_DATA_TAG, MPI_COMM_WORLD, &outstandingReqHandle);

        MPI_Irecv(&outstandingReqBuffer, 1, MPI_INT, 2,
                  MPI_ANY_TAG, MPI_COMM_WORLD, &outstandingReqHandle);

        outstandingRequest = true;
    }
*/      
    // test for completion
    MPI_Status status;
    int flag = 0;

    MPI_Test(&outstandingReqHandle, &flag, &status);

    if (flag)
    {
        // send an ACK back to the FPGA
        MPI_Send((unsigned char*) &fortytwo, 1, MPI_INT, ACP_M2C_MPI_RANK, C_ACK_TAG, MPI_COMM_WORLD);
/*
        // request completed, return value.
        outstandingRequest = false;
*/
        // memcpy 1 UMF_CHUNK... ouch, baby
        memcpy(buf, &outstandingReqBuffer, 4);

        MPI_Irecv(&outstandingReqBuffer, 1, MPI_INT, 2,
                  MPI_ANY_TAG, MPI_COMM_WORLD, &outstandingReqHandle);

        // got data
        return true;
    }

    return false;
}

// blocking read
void
ARCHES_MPI_DEVICE_CLASS::Read(
    unsigned char* buf,
    int bytes_requested)
{
    // we currently only support 32-bit transfers
    if (bytes_requested != 4)
    {
        cerr << "arches_mpi_device: unsupported read size " << bytes_requested << endl;
        CallbackExit(1);
    }

    // check if there's an outstanding Irecv request
    if (!outstandingRequest)
    {
        // no outstanding request, so go ahead and do a blocking Recv
        MPI_Status status;
        MPI_Recv(buf, 1, MPI_INT, ACP_M2C_MPI_RANK, C_DATA_TAG, MPI_COMM_WORLD, &status);

        // send an ACK back to the FPGA
        MPI_Send((unsigned char*) &fortytwo, 1, MPI_INT, ACP_M2C_MPI_RANK, C_ACK_TAG, MPI_COMM_WORLD);
    }
    else
    {
        // there's already an outstanding request, so loop on Test until the data arrives
        MPI_Status status;
        int flag = 0;

        do
        {
            MPI_Test(&outstandingReqHandle, &flag, &status);
        }
        while (flag == 0);

        // send an ACK back to the FPGA
        MPI_Send((unsigned char*) &fortytwo, 1, MPI_INT, ACP_M2C_MPI_RANK, C_ACK_TAG, MPI_COMM_WORLD);
/*
        // request completed, return value.
        outstandingRequest = false;
*/

        // memcpy 1 UMF_CHUNK... ouch, baby
        memcpy(buf, &outstandingReqBuffer, 4);

        MPI_Irecv(&outstandingReqBuffer, 1, MPI_INT, 2,
                  MPI_ANY_TAG, MPI_COMM_WORLD, &outstandingReqHandle);
    }
}

// write
void
ARCHES_MPI_DEVICE_CLASS::Write(
    unsigned char* buf,
    int bytes_requested)
{
    // we currently only support 32-bit transfers
    if (bytes_requested != 4)
    {
        cerr << "arches_mpi_device: unsupported write size " << bytes_requested << endl;
        CallbackExit(1);
    }

    // write bytes_requested bytes from buf into channel
    MPI_Send(buf, 1, MPI_INT, ACP_M2C_MPI_RANK, C_DATA_TAG, MPI_COMM_WORLD);
}

// reset FPGA
void
ARCHES_MPI_DEVICE_CLASS::ResetFPGA()
{
    // not implemented
}
