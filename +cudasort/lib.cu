#include "lib.h"
__device__  int * global_vet_device=NULL;
__device__  int global_size_vet=0;
__device__  int global_nr_nucleos=0;



__device__ void sort_subarray(int arr[], int n, int exp) 
{ 

	//int output[n]; // output array 
	int *output = (int*)malloc(n * sizeof(int));
	int i, count[10] = { 0 }; 
	//printf("sort_subarray[arr[0]]:%d\n", arr[0]);
	// Store count of occurrences in count[] 
	for (i = 0; i < n; i++) 
		count[(arr[i] / exp) % 10]++; 

	// Change count[i] so that count[i] now contains actual 
	// position of this digit in output[] 
	for (i = 1; i < 10; i++) 
		count[i] += count[i - 1]; 

	// Build the output array 
	for (i = n - 1; i >= 0; i--) { 
		output[count[(arr[i] / exp) % 10] - 1] = arr[i]; 
		count[(arr[i] / exp) % 10]--; 
	} 

	// Copy the output array to arr[], so that arr[] now 
	// contains sorted numbers according to current digit 
	for (i = 0; i < n; i++){
		arr[i] = output[i]; 
	} 
		
}

__device__ int get_max_val(int arr[], int n) 
{ 
	int mx = arr[0]; 
	for (int i = 1; i < n; i++) 
		if (arr[i] > mx) 
			mx = arr[i]; 
	return mx; 
} 

__device__ int sort_array(int x){
	
	//if(x!=0) return 0; //para facilitar a programação 

		
	//printf("CUDA core [%d]\n",x);

	// 0 <= x=0 < 5 ... 5 <= x=1 <= 10
	int n = global_size_vet/global_nr_nucleos; // n = sub_arr_size	
	int *sub_arr = (int *)malloc(n * sizeof(int));// Cria na memória um espaço para um sub_array
	int a = x * n; // if x=0 -> a=0 ... if x=1 --> a=5...  if x=10 --> a = 50
	
	//sub_array recebe a referencia da posição inicial do vetor global
	sub_arr = &global_vet_device[a];
	//memcpy(&sub_arr[0],&global_vet_device[a],sizeof(int)*n);
	
	int m = get_max_val(&sub_arr[0], n); 
	//iteração para cada dígito, no caso de um int muito grande esse for vai ocorrer 2^32 -> (10 casas) 
	for (int exp = 1; m / exp > 0; exp *= 10) {
		sort_subarray(&sub_arr[0], n, exp); 
	}	
	
	return 0;

}


__global__ void GPU_sort (int *vet_d, int vet_size,int nthreads) {
	int x = threadIdx.x;
	
	//seta as variáveis globais
	global_vet_device = vet_d;
	global_size_vet = vet_size;
	global_nr_nucleos = nthreads;

	
	//Inicia particionamento e ordenação
	sort_array(x);	

}

//############################################################################################
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
		v[i]= rand() % 1000;// (0 <= rand <= vet_size)
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

	printf("primeiro elemento:%d\n",v[0]);
	printf("ultimo elemento:%d\n",v[vet_size-1]);
	printf("Impressão truncada em 100\n");
	/*for(int i=0;i<10;i++){
		if(vet_size%(vet_size/8)==0){
			printf("v[%d]:%d\n",i,v[i]);			
		}		
	}*/	
		
	
	printf("\n");


}

__host__ double wtime() {
  struct timeval t;
  gettimeofday(&t, NULL);
  return t.tv_sec + (double) t.tv_usec / 1000000;
}






































/*__global__ void GPU_sort (int *vet_d, int vet_size,int nthreads) {
   

   int k = threadIdx.x;   
   printf("Nucleo %d\n",k );
   int part = vet_size / nthreads; //== cada trede ordenara quatro posições do vetor[40]
   
   /**
		0 < i=0 < 4 .... 4 < i=1 < 8 .... 8 < i=2 < 12 ... 12 < i=3 < 18
   /
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

   
   
}*/