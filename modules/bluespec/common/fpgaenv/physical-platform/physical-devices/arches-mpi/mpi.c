#include "mpi.h"

void
_mpi_get_runtime_env(void)
{
    int i;

    _mpi_size               = MPI_SIZE;
    _mpi_rank               = MPI_RANK;

    for(i=0; i != MPI_SIZE; i++)
    {
        _mpi_ce_types[i] = anMPITypes[i];
        _mpi_os_types[i] = anMPIOS[i];
        _mpi_bootld[i]   = anMPIBOOTLD[i];
    }


/*
#if defined(TMD_MPI_USE_FLI_MODULE)
    _mpi_use_fli_module     = 1;
#else
    _mpi_use_fli_module     = 0;
#endif
*/

#ifdef TMD_MPI_FLI_MODULE
    //_mpi_fli_module         = 1;
    _mpi_node               = MPI_NODE;
#else
    //_mpi_fli_module         = 0;
#endif



#if defined(X86)
    sprintf(_mpi_rank_map_filename, "%s", MPI_MAP_FILE);
    _mpi_num_fpga_stacks    = MPI_NUM_FPGA_STACKS;
    _mpi_num_extra_gprs     = MPI_NUM_EXTRA_GPRS;
    _mpi_num_gprs           = MPI_NUM_GPRS;
    _mpi_num_local_nodes    = MPI_NUM_LOCAL_NODES;
    _mpi_shm_local_leader   = MPI_SHM_LOCAL_LEADER;
#endif

#if defined(MB)

#define MPI_SYSTEM_TIMER_DEVICE_ID \
    arg_cat(arg_cat(XPAR_MPI_TIMER_, PROCESSOR_ID), _DEVICE_ID)

#define MPI_SYSTEM_TIMER_BASEADDR \
    arg_cat(arg_cat(XPAR_MPI_TIMER_, PROCESSOR_ID), _BASEADDR)

#define MPI_SYSTEM_INTC_SYSTEM_TIMER_INTERRUP_INTR \
    arg_cat(arg_cat(arg_cat(arg_cat(XPAR_INTC_, PROCESSOR_ID), _MPI_TIMER_), PROCESSOR_ID), _INTERRUPT_INTR)



    _mpi_system_timer_device_id                     = MPI_SYSTEM_TIMER_DEVICE_ID;
    _mpi_system_timer_baseaddr                      = MPI_SYSTEM_TIMER_BASEADDR;
    _mpi_system_intc_system_timer_interrupt_intr    = MPI_SYSTEM_INTC_SYSTEM_TIMER_INTERRUP_INTR;
    _mpi_proc_clock_hz                              = XPAR_CPU_CORE_CLOCK_FREQ_HZ;
#endif // #if defined(MB)
}
