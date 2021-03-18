#include <cuda.h>
#include <stdio.h>
#include <math.h>

__host__ int *criar_vetor_desordenado(int *v,int size);

__host__ void vet_imprimir(int *v,int size);

int main (int argc, char ** argv) {
	int nthreads = 4;
	int nblocos = 1;

	//vetores
	
	int *vet_desordenado=NULL, *vet_ordenado=NULL;


	vet_desordenado = criar_vetor_desordenado(vet_desordenado,40);//aloca vetor em host
	vet_imprimir(vet_desordenado,40); 


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

	for(int i=1, j=0;i<size-1;i++, j++){
		printf("%d\t",v[i]);		
		if(!j%10){
			printf("\n");
		}
	}
	printf("\n");


}
