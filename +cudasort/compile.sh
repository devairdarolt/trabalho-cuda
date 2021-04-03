#!/usr/bin/env bash

clear

export PATH=/usr/bin/:$PATH
#set dir para nvcc cuda 7
#CC = nvcc
#TARGET = compile rename clean



nvcc  --device-c *.cu -Xcompiler -fopenmp  #gera os arquivos .o
nvcc  *.o -lgomp	                    #gera o executavel

mv 'a.out' main
rm -f *.o  *.result *.log

