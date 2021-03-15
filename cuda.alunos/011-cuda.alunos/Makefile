# GNU Makefile

CC = nvcc
#CC = gcc
CCFLAGS = #-Wall
LDFLAGS =
TARGET = 01_device 02_hello 03_vetSoma 04_vetSoma2 05_proc 06_mem 07_kernel 08_matSoma 09_matMult
EXE =

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
