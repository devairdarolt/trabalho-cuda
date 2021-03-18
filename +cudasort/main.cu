#include <cuda.h>
#include <stdio.h>
#include <math.h>





///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// função executada na GPU
__global__ void sort (int *vet_d, int size) {
   int k = threadIdx.x;   
   int part = size / 10; //== cada trede ordenara quatro posições do vetor[40]
   /**
		0 < i=0 < 4 .... 4 < i=1 < 8 .... 8 < i=2 < 12 ... 12 < i=3 < 18
   */
   /*int min_idx=999999;
   for(k=i*part;k< ((i*part) + part);k++){
		
   		
   } */  

   int a = k*part;
   int b = k*part+part;
   int i=0,j=0;
   int min_idx=0,temp;
   for(i=a;i<b;i++){
   		min_idx = i;
   		for(j=i+1;j<b;j++){
   			if(vet_d[j]<vet_d[min_idx]){
   				min_idx = j;
   			}
   		}
   		temp = 0;
   		temp = vet_d[min_idx];
   		vet_d[min_idx] = vet_d[i];
   		vet_d[i] = temp;	
   }
   
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

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
	sort<<<1,10>>>(dev_vet, size);
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

	printf("\n");
	printf("\n");
	for(int i=0;i<size;i++){
		if(i%10==0){
			printf("\n");
		}
		printf("%d\t",v[i]);		
		
	}
	printf("\n");


}
