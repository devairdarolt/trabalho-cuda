#include "lib.h"

#include <cuda.h>
#include <stdio.h>
#include <math.h>




int main (int argc, char ** argv) {
	int nthreads = 3;
	int nblocos = 1;
	int vet_size = 12;

	
	if (argc == 3) {
		nthreads = atoi(argv[1]);
		vet_size = atoi(argv[2]);
	}else{
		printf ("./main <nthreads> <vet_size>\n");
		printf ("Caso não haja passagem de parâmetros, nthreads=%d e vet_size=%d\n",nthreads,vet_size);
	} 

	//vetores do host	
	int *vet_desordenado=NULL, *vet_ordenado=NULL;
	vet_desordenado = criar_vetor_desordenado(vet_desordenado,vet_size);//aloca vetor em host
	cudaMallocHost((void **) &vet_ordenado, vet_size*sizeof(int));
	//printf("Vetor desordenado\n");
	vet_imprimir(vet_desordenado,vet_size); 

	int *d_nr_part,  h_nr_part;
	cudaMalloc((void**)&d_nr_part, sizeof(int));// aloca vetor na memória global da placa
	//Data *d_last_part, h_last_part;
	//cudaMalloc((void**)&d_last_part, sizeof(Data));// aloca vetor na memória global da placa

	int *dev_vet =NULL;
	cudaMalloc((void**)&dev_vet,vet_size * sizeof(int));// aloca vetor na memória global da placa
	cudaMemcpy (dev_vet, vet_desordenado, vet_size*sizeof(int), cudaMemcpyHostToDevice);
	//Cada CUDA core ordena uma partição de DEV_VET
	//resulta em um único vetor de partições ordenadas
	double s_time = wtime();	
	
	GPU_set_globals<<<1,1>>>(dev_vet, vet_size,nthreads);		
	cudaDeviceSynchronize();

	GPU_sort<<<1,nthreads>>>(nthreads);	
	cudaDeviceSynchronize();	
		cudaMemcpy (vet_ordenado, dev_vet, vet_size*sizeof(int), cudaMemcpyDeviceToHost);			
		vet_imprimir(vet_ordenado,vet_size); 
	//GPU_get_nr_partitions<<<1,1>>>(d_nr_part);// Busca o nr de partições resultantes na operação de sort	
	cudaDeviceSynchronize();	
	//cudaMemcpy (&h_nr_part, d_nr_part, sizeof(int), cudaMemcpyDeviceToHost);
	//printf("particoes para mesclar %d\n",h_nr_part);
	
	while(nthreads>1){
		nthreads = ceil((double)nthreads/(double)2);
		GPU_merge<<<1,nthreads>>>(nthreads);	
		cudaDeviceSynchronize();
		cudaMemcpy (vet_ordenado, dev_vet, vet_size*sizeof(int), cudaMemcpyDeviceToHost);	
		vet_imprimir(vet_ordenado,vet_size); 

	}
	
	
	//GPU_get_nr_partitions<<<1,1>>>(d_nr_part);// Busca o nr de partições resultantes na operação de sort
	//cudaDeviceSynchronize();
	//cudaMemcpy (&h_nr_part, d_nr_part, sizeof(int), cudaMemcpyDeviceToHost);




	cudaDeviceSynchronize();
	double e_time = wtime();
	printf("Time:%f (s)\n", e_time-s_time);
	cudaMemcpy (vet_ordenado, dev_vet, vet_size*sizeof(int), cudaMemcpyDeviceToHost);	
	printf("Vetor parcialmente ordenado\n");
	vet_imprimir(vet_ordenado,vet_size); 
	return 0;
}

