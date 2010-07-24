//
// INTEL CONFIDENTIAL
// Copyright (c) 2008 Intel Corp.  Recipient is granted a non-sublicensable 
// copyright license under Intel copyrights to copy and distribute this code 
// internally only. This code is provided "AS IS" with no support and with no 
// warranties of any kind, including warranties of MERCHANTABILITY,
// FITNESS FOR ANY PARTICULAR PURPOSE or INTELLECTUAL PROPERTY INFRINGEMENT. 
// By making any use of this code, Recipient agrees that no other licenses 
// to any Intel patents, trade secrets, copyrights or other intellectual 
// property rights are granted herein, and no other licenses shall arise by 
// estoppel, implication or by operation of law. Recipient accepts all risks 
// of use.
//

//
// @file platform-debugger.cpp
// @brief Platform Debugger Application
//
// @author Angshuman Parashar
//

#include <cstdio>
#include <cstdlib>
#include <iostream>
#include <iomanip>
#include <cmath>

#include "asim/syntax.h"
#include "asim/ioformat.h"
#include "asim/provides/hybrid_application.h"
#include "asim/provides/clocks_device.h"

using namespace std;

// constructor
HYBRID_APPLICATION_CLASS::HYBRID_APPLICATION_CLASS(
    VIRTUAL_PLATFORM vp)
{
    clientStub = new PLATFORM_DEBUGGER_CLIENT_STUB_CLASS(NULL);
}

// destructor
HYBRID_APPLICATION_CLASS::~HYBRID_APPLICATION_CLASS()
{
    delete clientStub;
}

void
HYBRID_APPLICATION_CLASS::Init()
{
}

// main
void
HYBRID_APPLICATION_CLASS::Main()
{
    UINT64 sts, oldsts;
    UINT64 data;

    // print banner
    cout << "\n";
    cout << "Welcome to the Intra FPGA Platform Debugger\n";
    cout << "--------------------------------\n";

    cout << endl << "Initializing hardware\n";

    // transfer control to hardware
    sts = clientStub->StartDebug(0);
    cout << "debugging started, sts = " << sts << endl << flush;

    // and the inverse of data is written to bank 1.
    for (int i = 0; i <= 1000; i += 1)
    {
        int addr = i;
        sts = clientStub->TransferReq(addr * 4);
        cout << "transfer request, sts = " << sts << endl << flush;
        OUT_TYPE_TransferRsp result = clientStub->TransferRsp(0);
        cout << "transfer complete:" << endl << flush;
        if(~0 ^ result.payloadFPGA0 ^ result.payloadFPGA1) {
  	   cout << "Data corruption!" << endl;
           cout << "fpga0 data: " << std::hex << result.payloadFPGA0 << endl << flush;
           cout << "fpga1 data: " << std::hex << result.payloadFPGA1 << endl << flush;
        }

        cout << "fpga0 cycles: " << (result.curCycle - result.fpga0Timestamp) << endl << flush;
        cout << "fpga1 timestep: " << result.fpga1Timestamp << endl << flush;
    }

    cout << "Test completed" << endl;

}
