#include "lib.h"

#include <cuda.h>
#include <stdio.h>
#include <math.h>




int main (int argc, char ** argv) {
	long nthreads = 96;
	//long nblocos = 1;
	long vet_size = 100000000; //762.939453

	
	if (argc == 3) {
		nthreads = atoi(argv[1]);
		vet_size = atoi(argv[2]);
	}else{
		printf ("./main <nthreads> <vet_size>\n");
		printf ("Caso não haja passagem de parâmetros, nthreads=%ld e vet_size=%ld\n",nthreads,vet_size);
	} 
	printf("Ordenando %3ld Kbytes\n",(vet_size*4)/1024);
	//vetores do host	
	long *host_vet=NULL;
	host_vet = criar_vetor_desordenado(host_vet,vet_size);//aloca vetor em host
	
	//printf("Vetor desordenado\n");
	printf("Vetor criado..\n");
	vet_imprimir(host_vet,vet_size); 

	

	long *dev_vet =NULL;
	int erro = cudaMalloc((void**)&dev_vet,vet_size * sizeof(long));// aloca vetor na memória global da placa
	if(erro){
		printf("\033[0;31m Erro ao alocar memória da placa de video...\n \e[m");
	}
	printf("Dados copiados para a placa de video %3f MB\n",(double)(vet_size*sizeof(long))/1024/1024);
	cudaMemcpy (dev_vet, host_vet, vet_size*sizeof(long), cudaMemcpyHostToDevice);
	
	//Cada CUDA core ordena uma partição de DEV_VET
	//resulta em um único vetor de partições ordenadas
	double s_time = wtime();	
		
	
	GPU_set_globals<<<1,1>>>(dev_vet, vet_size,nthreads);		
	cudaDeviceSynchronize();
	
	//printf("Teste de copia vetor grande..n:%ld\n",vet_size);
	//GPU_print<<<1,1>>>();
	//cudaDeviceSynchronize();

	
	GPU_call_sort<<<1,nthreads>>>(nthreads);	
	cudaDeviceSynchronize();	
	GPU_print<<<1,1>>>();
	cudaDeviceSynchronize();

	
	while(nthreads>1){
		
		nthreads = ceil((double)nthreads/(double)2);		
		GPU_merge<<<1,nthreads>>>(nthreads);	
		cudaDeviceSynchronize();
		//printf("\n\n\nPos GPU_merge\n");
		//GPU_print<<<1,1>>>();
		//cudaDeviceSynchronize();
	}		
	/**/
	double e_time = wtime();
	printf("Time:%f (s)\n", e_time-s_time);
	
	printf("\nOpercacao finalizada\n");
	GPU_print<<<1,1>>>();
	cudaDeviceSynchronize();
	
	//free(host_vet);
	GPU_reset<<<1,1>>>();
	return 0;
}

