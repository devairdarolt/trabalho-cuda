#include "lib.h"

#include <cuda.h>
#include <stdio.h>
#include <math.h>




int main (int argc, char ** argv) {
	long nthreads = 3;
	//long nblocos = 1;
	long vet_size = 12;

	
	if (argc == 3) {
		nthreads = atoi(argv[1]);
		vet_size = atoi(argv[2]);
	}else{
		printf ("./main <nthreads> <vet_size>\n");
		printf ("Caso não haja passagem de parâmetros, nthreads=%ld e vet_size=%ld\n",nthreads,vet_size);
	} 
	printf("Ordenando %3ld Kbytes\n",(vet_size*4)/1024);
	//vetores do host	
	long *host_vet=NULL, *device_vet=NULL;
	host_vet = criar_vetor_desordenado(host_vet,vet_size);//aloca vetor em host
	cudaMallocHost((void **) &device_vet, vet_size*sizeof(long));
	//printf("Vetor desordenado\n");
	printf("Vetor criado..\n");
	vet_imprimir(host_vet,vet_size); 

	

	long *dev_vet =NULL;
	cudaMalloc((void**)&dev_vet,vet_size * sizeof(long));// aloca vetor na memória global da placa
	cudaMemcpy (dev_vet, host_vet, vet_size*sizeof(long), cudaMemcpyHostToDevice);
	/*for(long i=0;i<vet_size;i++){
		cudaMemcpy (&dev_vet[i], &host_vet[i], sizeof(long), cudaMemcpyHostToDevice);
	}
	*/
	printf("Dados copiados para a placa de video %3f MB\n",(double)(vet_size*sizeof(long))/1024/1024);
	//Cada CUDA core ordena uma partição de DEV_VET
	//resulta em um único vetor de partições ordenadas
	double s_time = wtime();	
	
	//cudaMemcpy (device_vet, dev_vet, vet_size*sizeof(long), cudaMemcpyDeviceToHost);		
	
	GPU_set_globals<<<1,1>>>(dev_vet, vet_size,nthreads);		
	cudaDeviceSynchronize();
	
	printf("Teste de copia vetor grande..n:%ld\n",vet_size);
	GPU_print<<<1,1>>>();
	cudaDeviceSynchronize();

	printf("\n\n\nGPU_sort\n");
	GPU_sort<<<1,nthreads>>>(nthreads);	
	cudaDeviceSynchronize();	
	GPU_print<<<1,1>>>();
	cudaDeviceSynchronize();

	/*
	while(nthreads>1){
		
		nthreads = ceil((double)nthreads/(double)2);
		cudaDeviceSynchronize();
		GPU_merge<<<1,nthreads>>>(nthreads);	
		cudaDeviceSynchronize();
		//printf("\n\n\nPos GPU_merge\n");
		//GPU_print<<<1,1>>>();
		//cudaDeviceSynchronize();
	}	
	cudaDeviceSynchronize();
	*/
	double e_time = wtime();
	printf("Time:%f (s)\n", e_time-s_time);
	
	printf("\noperacao finalizada\n");
	GPU_print<<<1,1>>>();
	cudaDeviceSynchronize();
	
	//free(host_vet);
	cudaFree(device_vet);
	GPU_reset<<<1,1>>>();
	return 0;
}

