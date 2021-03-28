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

	
	int *dev_vet =NULL;
	cudaMalloc((void**)&dev_vet,vet_size * sizeof(int));// aloca vetor na memória global da placa
	cudaMemcpy (dev_vet, vet_desordenado, vet_size*sizeof(int), cudaMemcpyHostToDevice);
	//Cada CUDA core ordena uma partição de DEV_VET
	//resulta em um único vetor de partições ordenadas
	
	//Set global propriedades
	GPU_set_global_prop<<<1,1>>>(dev_vet, vet_size,nthreads);
	
	//Ordena sub arrays
	double s_time = wtime();
	GPU_sort<<<1,nthreads>>>(dev_vet, vet_size,nthreads);			
	cudaDeviceSynchronize();
	double e_time = wtime();

	
	//Mescla sub arrays
	GPU_merge<<<1,1>>>(dev_vet, vet_size,nthreads);	
	// Agora precisa fazer o merge entre as partições	
	// Para cada par de partição faça o merge até que reste apenas uma partição
	/*for(int i=nthreads/2;i>=1;i=i/2){
		GPU_merge<<<1,i>>>(dev_vet, vet_size,i);	

	}*/
	printf("Time:%f (s)\n", e_time-s_time);
	cudaMemcpy (vet_ordenado, dev_vet, vet_size*sizeof(int), cudaMemcpyDeviceToHost);
	
	printf("Vetor parcialmente ordenado\n");
	vet_imprimir(vet_ordenado,vet_size); 


	return 0;
}

