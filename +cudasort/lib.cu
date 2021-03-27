#include "lib.h"
#include "lista.h"

#include <cuda.h>
#include <stdio.h>
#include <math.h>
#include <sys/time.h>


__device__ void device_log(char *msg){
	printf("%s\n", msg);
}

typedef struct Data{
	int a;
	int b;
}Data;
//##########################################################################
__device__  int * global_vet_device=NULL;
__device__  int global_size_vet=0;
__device__  int global_nr_nucleos=0;

__device__ Lista particoes;// = list_init(sizeof(Data)); // Inicia uma lista para o tipo Data



// FUNÇÕES PRIVADAS (Não acessível para o programa main)
__device__ double ceild(double num);

__device__ void sort_subarray(int arr[], int n, int exp) ;

__device__ int get_max_val(int arr[], int n);

__device__ int sort_array(int x);

__device__ void intercala (int p, int q, int r, int *v);

// CODE
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
	
	// 0 <= x=0 < 5 ... 5 <= x=1 <= 10
	int n =(int) ceild((double)global_size_vet/(double)global_nr_nucleos); // arredonda pra cima
	int a = x * n; // if x=0 -> a=0 ... if x=1 --> a=5...  if x=10 --> a = 50
	if((global_size_vet%global_nr_nucleos!=0)&&(x==global_nr_nucleos-1)){	
		n=global_size_vet-a;		
	}
	int b = a +n;

	//int a = x * n; // if x=0 -> a=0 ... if x=1 --> a=5...  if x=10 --> a = 50
	int *sub_arr = (int *)malloc(n * sizeof(int));// Cria na memória um espaço para um sub_array

	printf("Part[%d]:n[%d] [%d <= x < %d]\n",x,n,a,b);
	//sub_array recebe a referencia da posição inicial do vetor global
	//sub_arr = &global_vet_device[a];
	int j=0;
	int aux;
	printf("\n");
	for(int i=a;i<b;i++,j++){
		aux = global_vet_device[i];
		sub_arr[j]=aux;			
	}

	int m = get_max_val(sub_arr, b-a); 
	//iteração para cada dígito, no caso de um int muito grande esse for vai ocorrer 2^32 -> (10 casas) 
	for (int exp = 1; m / exp > 0; exp *= 10) {
		sort_subarray(&sub_arr[0], b-a, exp); 
	}	

	j=0;
	for(int i=a;i<b;i++,j++){
		global_vet_device[i]=sub_arr[j];
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
	/*
	for(int i=0;i<vet_size;i++){
		if(vet_size%(vet_size/10)==0){
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



__device__ double ceild(double num){	
	int inum = (int)num;
    if (num == (float)inum) {
        return inum;
    }
    return inum + 1;
}

// A função recebe vetores crescentes v[p..q-1] 
// e v[q..r-1] e rearranja v[p..r-1] em ordem 
// crescente.
__device__ void intercala (int p, int q, int r, int *v) 
{
   int *w;                                 //  1
   w =(int *)malloc((r-p) * sizeof(int));  //  2
   int i = p, j = q;                       //  3
   int k = 0;                              //  4

   while (i < q && j < r) {                //  5
      if (v[i] <= v[j])  w[k++] = v[i++];  //  6
      else  w[k++] = v[j++];               //  7
   }                                       //  8
   while (i < q)  w[k++] = v[i++];         //  9
   while (j < r)  w[k++] = v[j++];         // 10
   for (i = p; i < r; ++i)  v[i] = w[i-p]; // 11
   free (w);                               // 12
}

__global__ void GPU_merge (int *vet_d, int vet_size,int nthreads){
	int x = threadIdx.x;
	if(x!=0)return;
	printf("[GPU_merge] global_size_vet:%3d\n",global_size_vet);
	printf("[GPU_merge] nthreads:%3d\n",nthreads);
	int m = ceild((double)vet_size/(double)2);//Divide o vetor em duas partes [0][1][2] [3][4]
	int n = vet_size - m;
	int *vet1 = &vet_d[0];
	int *vet2 = &vet_d[m];
	printf("1[%d--%d]\n",0,m-1);
	printf("2[%d--%d]\n",m,vet_size-1);

	intercala(0,m,vet_size,vet_d);

	printf("vet1:\n");
	for(int k=0;k<m;k++){
		printf("%4d",vet_d[k]);
	}
	printf("\n");

	printf("vet2:\n");
	for(int k=m;k<vet_size;k++){
		printf("%4d",vet_d[k]);
	}
	printf("\n");

	printf("vet ordenado:\n");
	for(int k=0;k<vet_size;k++){
		printf("%4d",vet_d[k]);
	}
	printf("\n");
	//merge(vet1,m,vet2,n);
	
}