#include <cuda.h>
#include <stdio.h>
#include <math.h>

int *criar_vetor_desordenado(int *v,int size);

void vet_imprimir(int *v,int size);

int main (int argc, char ** argv) {
	int nthreads = 4;
	int nblocos = 1;

	//vetores
	
	int *vet_desordenado, *vet_ordenado;

	vet_desordenado = criar_vetor_desordenado(vet_desordenado,40);
	vet_imprimir(vet_desordenado,40); 


	return 0;
}

int *criar_vetor_desordenado(int *v,int size){

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
void vet_imprimir(int *v,int size){
	if(v==NULL){
		printf("O vetor informado é NULL!\n");
		return;
	}
	if(size < 0){
		printf("O tamanho do vetor tem que ser maior que 0\n");
		return		
	}

	for(int i=0;i<size;i++, j++){
		printf("%d\t",v[i]);
		
		if(j==10){
			printf("\n");
		}
	}


}
