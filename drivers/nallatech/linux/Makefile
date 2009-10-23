#Copyright Xilinx, Inc 2007
#Author : Henry Styles

#If KERNELRELEASE is defined, involked from the kernel build system

ifneq ($(KERNELRELEASE),)
	obj-m := acpdriver.o

#Otherwise called from command
else
	KERNELDIR ?= /lib/modules/$(shell uname -r)/build
	PWD := $(shell pwd)

default:
	$(MAKE) -C $(KERNELDIR) M=$(PWD) modules

endif

clean : 
	rm -f *.ko acpdriver.mod.c *.o Module.symvers
