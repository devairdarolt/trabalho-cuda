# GNU Makefile


# GNU Makefile

export PATH=/usr/bin/:$PATH
#set dir para nvcc cuda 7
CC = nvcc
#CC = gcc
CCFLAGS = #-Wall
LDFLAGS =
TARGET = main #02_hello 03_vetSoma 04_vetSoma2 05_proc 06_mem 07_kernel 08_matSoma 09_matMult
EXE = main

all: $(TARGET)

%.o: %.cu
	$(CC) $(CCFLAGS) -c $< -lm

%: %.o
	$(CC) $(LDFLAGS) $^ -o $@



help:
	@echo
	@echo
	@echo "####### Exemplo de Execução GPU #######"
	@echo "./01_device"

clean:
	rm -f *.o *~ $(TARGET) *.map *.result

