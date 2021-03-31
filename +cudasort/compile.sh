#!/usr/bin/env bash

clear

export PATH=/usr/bin/:$PATH
#set dir para nvcc cuda 7
#CC = nvcc
#TARGET = compile rename clean



nvcc  --device-c *.cu
nvcc  *.o	

mv 'a.out' main
rm -f *.o  *.map *.result *.log

