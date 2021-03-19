#include <cuda.h>
#include <stdio.h>
#include <math.h>





///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// função executada na GPU
__global__ void GPU_sort (int *vet_d, int vet_size,int nthreads) {
   

   int k = threadIdx.x;   
   printf("Nucleo %d\n",k );
   int part = vet_size / nthreads; //== cada trede ordenara quatro posições do vetor[40]
   
   /**
		0 < i=0 < 4 .... 4 < i=1 < 8 .... 8 < i=2 < 12 ... 12 < i=3 < 18
   */
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
   /*
   for(i=a;i<b;i++){

   		printf("v[%i]:%d\n",i,vet_d[i] );
   }
   printf("\n");
   */
   
   
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// função executada no HOST

__host__ int *criar_vetor_desordenado(int *v,int vet_size);

__host__ void vet_imprimir(int *v,int vet_size);

int main (int argc, char ** argv) {
	int nthreads = 4;
	int nblocos = 1;
	int vet_size = 20;


	if (argc == 2) {
		nthreads = atoi(argv[1]);
		vet_size = atoi(argv[2]);
	}else{
		printf ("./main <nthreads> <vet_size>\n");
		printf ("Caso não haja passagem de parâmetros, nthreads=4 e vet_size=20\n");
	} 

	//vetores do host	
	int *vet_desordenado=NULL, *vet_ordenado=NULL;
	vet_desordenado = criar_vetor_desordenado(vet_desordenado,vet_size);//aloca vetor em host
	cudaMallocHost((void **) &vet_ordenado, vet_size*sizeof(int));
	printf("Vetor desordenado\n");
	vet_imprimir(vet_desordenado,vet_size); 

	
	int *dev_vet =NULL;
	cudaMalloc((void**)&dev_vet,vet_size * sizeof(int));// aloca vetor na memória global da placa
	cudaMemcpy (dev_vet, vet_desordenado, vet_size*sizeof(int), cudaMemcpyHostToDevice);
	//Cada CUDA core ordena uma partição de DEV_VET
	GPU_sort<<<1,nthreads>>>(dev_vet, vet_size,nthreads);
	
	cudaDeviceSynchronize();
	cudaMemcpy (vet_ordenado, dev_vet, vet_size*sizeof(int), cudaMemcpyDeviceToHost);
	
	printf("Vetor parcialmente ordenado\n");
	vet_imprimir(vet_ordenado,vet_size); 


	return 0;
}

__host__ int *criar_vetor_desordenado(int *v,int vet_size){

	if(v!=NULL){
		printf("O vetor informado ja existe!\n");
		return v;
	}
	if(vet_size < 0){
		printf("O tamanho do vetor tem que ser maior que 0\n");
	}
	

	cudaMallocHost((void **) &v, vet_size*sizeof(int));
	
	//inicia valores do vetor desordenado
	for(int i=0;i<vet_size;i++){
		v[i]= rand() % vet_size;// (0 <= rand <= vet_size)
	}
	return v;
}
__host__ void vet_imprimir(int *v,int vet_size){
	if(v==NULL){
		printf("O vetor informado é NULL!\n");
		return;
	}
	if(vet_size < 0){
		printf("O tamanho do vetor tem que ser maior que 0\n");
		return;		
	}

	printf("\n");
	printf("\n");
	for(int i=0;i<vet_size;i++){		
		printf("%d\n",v[i]);		
		
	}
	printf("\n");


}
