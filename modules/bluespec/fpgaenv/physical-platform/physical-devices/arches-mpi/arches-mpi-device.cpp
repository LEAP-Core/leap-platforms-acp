#include <iostream>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <sys/ioctl.h>

#include "asim/provides/arches_mpi_device.h"

using namespace std;

// ============================================
//              Arches MPI Device
// ============================================

ARCHES_MPI_DEVICE_CLASS::ARCHES_MPI_DEVICE_CLASS(
    PLATFORMS_MODULE p) :
        PLATFORMS_MODULE_CLASS(p)
{
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
}

// probe pipe to look for fresh data
bool
ARCHES_MPI_DEVICE_CLASS::Probe()
{
    // no fresh data
    return false;
}

// blocking read
void
ARCHES_MPI_DEVICE_CLASS::Read(
    unsigned char* buf,
    int bytes_requested)
{
    // read bytes_requested bytes into buf
}

// write
void
ARCHES_MPI_DEVICE_CLASS::Write(
    unsigned char* buf,
    int bytes_requested)
{
    // write bytes_requested bytes from buf into channel
}

// reset FPGA
void
ARCHES_MPI_DEVICE_CLASS::ResetFPGA()
{
    // not implemented
}
