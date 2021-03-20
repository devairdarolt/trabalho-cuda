# GNU Makefile

export PATH=/usr/bin/:$PATH
#set dir para nvcc cuda 7
CC = nvcc
TARGET = compile rename clean


all: $(TARGET)

compile:
	$(CC)  --device-c *.cu
	$(CC)  *.o	
	echo "Renomeando arquivos...\n"

rename:
	mv 'a.out' main
help:
	@echo
	@echo
	@echo "####### Exemplo de Execução GPU #######"
	@echo "./matMult"

clean:
	rm -f *.o  *.map *.result
