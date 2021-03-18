#include <cuda.h>
#include <stdio.h>
#include <math.h>


// função executada na GPU
__global__ void sem_nome (int *vet_d, int size) {
   int i = threadIdx.x;

   vet_d[i] = i*100;
   //printf("Sou nucleo %d\n", i);
}


// função executada no HOST

__host__ int *criar_vetor_desordenado(int *v,int size);

__host__ void vet_imprimir(int *v,int size);

int main (int argc, char ** argv) {
	int nthreads = 4;
	int nblocos = 1;

	int size = 40;
	//vetores do host	
	int *vet_desordenado=NULL, *vet_ordenado=NULL;
	vet_desordenado = criar_vetor_desordenado(vet_desordenado,size);//aloca vetor em host
	cudaMallocHost((void **) &vet_ordenado, size*sizeof(int));
	vet_imprimir(vet_desordenado,size); 

	int *dev_vet =NULL;
	cudaMalloc((void**)&dev_vet,size * sizeof(int));// aloca vetor na memória global da placa
	cudaMemcpy (dev_vet, vet_desordenado, size*sizeof(int), cudaMemcpyHostToDevice);
	sem_nome<<<1,10>>>(dev_vet, size);
	cudaMemcpy (vet_ordenado, dev_vet, size, cudaMemcpyDeviceToHost);
	vet_imprimir(vet_ordenado,size); 


	return 0;
}

__host__ int *criar_vetor_desordenado(int *v,int size){

	if(v!=NULL){
		printf("O vetor informado ja existe!\n");
		return v;
	}
	if(size < 0){
		printf("O tamanho do vetor tem que ser maior que 0\n");
	}
	

	cudaMallocHost((void **) &v, size*sizeof(int));
	
	//inicia valores do vetor desordenado
	for(int i=0;i<size;i++){
		v[i]= rand() % size;// (0 <= rand <= size)
	}
	return v;
}
__host__ void vet_imprimir(int *v,int size){
	if(v==NULL){
		printf("O vetor informado é NULL!\n");
		return;
	}
	if(size < 0){
		printf("O tamanho do vetor tem que ser maior que 0\n");
		return;		
	}

	for(int i=1;i<size-1;i++){
		if(!i%10){
			printf("\n");
		}
		printf("%d\t",v[i]);		
		
	}
	printf("\n");


}
