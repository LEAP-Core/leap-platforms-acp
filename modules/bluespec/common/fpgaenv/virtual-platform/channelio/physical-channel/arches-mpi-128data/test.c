#include "stdio.h"
#include "math.h"
#include "stdlib.h"
#include "mpi.h"

#define TEST_VECT_SIZE 64
#define TEST_LOOP_SIZE 2

int main (int argc, char **argv) 
{
    //int x[4096];
    //int y[4096];
		int temp[TEST_VECT_SIZE];
    int *x;
    int *y;
    int i,j;
    int myrank;
    int size;
    int fpga;
		int bufsize;
		int mem_window_sz;
    MPI_Status status; 
    int use_rma;
		int found_error;
		 
		MPI_Win win_x, win_y;

		use_rma = 1;
		fpga = 1;
	  printf("STARTING TEST..............................\n");
		printf("Initializing MPI...\n");
    MPI_Init(&argc, &argv);
    MPI_Comm_size(MPI_COMM_WORLD, &size);
    MPI_Comm_rank(MPI_COMM_WORLD, &myrank);
		
		printf("Allocating Buffers...\n");
		bufsize = TEST_VECT_SIZE*sizeof(int);
    mem_window_sz = 1024*1024;
    MPI_Alloc_mem(mem_window_sz, MPI_INFO_USE_IOMEM, &x);
    y = x + TEST_VECT_SIZE;
		printf("%x, %x %x %x\n", x, y, bufsize, sizeof(int));

	  printf("sending MODE....\n");
    if(use_rma){
		   MPI_Send(NULL, 0, MPI_INT, fpga, 0xA0000000, MPI_COMM_WORLD);
		} else {
		   MPI_Send(NULL, 0, MPI_INT, fpga, 0x80000000, MPI_COMM_WORLD);
		}
		if(use_rma){
		   printf("Running RMA Test...\n");
		   printf("Creating Memory Windows...\n");
       //MPI_Win_create(x, bufsize, 4, MPI_INFO_NULL, MPI_COMM_WORLD, &win_x);
       MPI_Win_create(x, mem_window_sz, 4, MPI_INFO_USE_IOMEM, MPI_COMM_WORLD, &win_x);
       
			 MPI_Recv(temp, 4, MPI_INT, fpga, MPI_ANY_TAG, MPI_COMM_WORLD, &status);
			
	  } else {
		   printf("receiving MODE ack\n");
       MPI_Recv(NULL, 0, MPI_INT, MPI_ANY_SOURCE, 0xA0000000, MPI_COMM_WORLD, &status);
		}
		
		printf("starting test loop(endless)...\n");
		i = 0;
    found_error = 0;
		while(!found_error){
        for(j=0; j<TEST_VECT_SIZE; j++){
            x[j] = rand();
						y[j] = 0;
        }

				if(use_rma){
            MPI_Send(NULL, 0, MPI_INT, fpga, 0x80000000, MPI_COMM_WORLD);
            
            MPI_Recv(NULL, 0, MPI_INT, MPI_ANY_SOURCE, MPI_ANY_TAG, MPI_COMM_WORLD, &status);
				} else {
		        printf("sending data...\n");
            MPI_Send(x, TEST_VECT_SIZE, MPI_INT, fpga, 0x80000000, MPI_COMM_WORLD);
            
				    printf("receiving data...\n");
            MPI_Recv(y, TEST_VECT_SIZE, MPI_INT, fpga, MPI_ANY_TAG, MPI_COMM_WORLD, &status);
				    printf("done...\n");
        }
        for(j=0; j<TEST_VECT_SIZE; j++){
            if(x[j] != y[j]){
                printf("error mismatch in test loop %d, in element %d, x[j] = %x, y[j] = %x temp[j] = %x!!!!!!!!!!!!\n", i, j, x[j], y[j], temp[j]);
                found_error = 1;
	          }
        }
				i++;
				if(i % 1000000 == 0){
				  printf("iteration %d done\n", i);
				}
				//printf("done comparing data\n");

	      	
    }
		if ( use_rma )
    {
        MPI_Win_free(&win_y);
        MPI_Win_free(&win_x);
    }
    //MPI_Free_mem(y);
    MPI_Free_mem(x);

    printf("End of Test\n");
}

