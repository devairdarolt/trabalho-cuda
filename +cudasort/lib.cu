#include "lib.h"
#include "lista.h"

#include <cuda.h>
#include <stdio.h>
#include <math.h>
#include <sys/time.h>


__device__ void device_log(char *msg){
	printf("%s\n", msg);
}


//##########################################################################
__device__ Data * global_part=NULL;
__device__ Data global_last_part;
__device__ int global_nr_part=0;
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
	int b = (a +n)-1;
	global_part[x].a =a;
	global_part[x].b=b;
	global_part[x].n=n;
	//set do vetor de particoes;	
	//int a = x * n; // if x=0 -> a=0 ... if x=1 --> a=5...  if x=10 --> a = 50
	int *sub_arr = (int *)malloc(n * sizeof(int));// Cria na memória um espaço para um sub_array

	printf("Part[%d]:n[%d] [%d <= x <= %d]\n",x,n,a,b);
	//sub_array recebe a referencia da posição inicial do vetor global
	//sub_arr = &global_vet_device[a];
	int j=0;
	int aux;
	//printf("\n");
	for(int i=a;i<=b;i++,j++){
		aux = global_vet_device[i];
		sub_arr[j]=aux;			
	}

	int m = get_max_val(sub_arr, n); 
	//iteração para cada dígito, no caso de um int muito grande esse for vai ocorrer 2^32 -> (10 casas) 
	for (int exp = 1; m / exp > 0; exp *= 10) {
		sort_subarray(&sub_arr[0], n, exp); 
	}	

	j=0;
	for(int i=a;i<=b;i++,j++){
		global_vet_device[i]=sub_arr[j];
	}

	return 0;
}

__global__ void GPU_set_globals(int *vet_d, int vet_size,int nthreads){
	//seta as variáveis globais
	global_vet_device = vet_d;
	global_size_vet = vet_size;
	global_nr_nucleos = nthreads;
	global_part = (Data *)malloc(nthreads * sizeof(Data));

}

__global__ void GPU_sort (int nthreads) {
	int x = threadIdx.x;
	
	
	//Inicia particionamento e ordenação
	sort_array(x);	

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
	srand(time(0));
	for(int i=0;i<vet_size;i++){
		v[i]= rand() % 10000;// (0 <= rand <= vet_size)
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
	//printf("primeiro elemento:%d\n",v[0]);
	//printf("ultimo elemento:%d\n",v[vet_size-1]);	
	printf("vet_d: ");
	if(1==1){
		if(vet_size<=500){

			for(int i=0;i<vet_size;i++){
				printf("%10d,",v[i]);
			}
		}
	}
	int value = v[0];
	int ordenado = 1;
	
	for(int i=1;i<vet_size;i++){
		if(v[i]<value){
			ordenado =0;
			break;
		}
		value = v[i];
	}
	if(ordenado){
		printf("\nVETOR ORDENADO!\n");
	}else{
		printf("\nVETOR DESORDENADO!\n");
	}	
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
__global__ void GPU_get_nr_partitions(int *d_nr_part){
	int count;
	for(int i=0; i< global_nr_part;i++){
		//if(global_part[i]!=NULL){
		//}
		count++;
	}
	*d_nr_part = count+1;
	

}

__global__ void GPU_merge (int nr_thread){
	int x = threadIdx.x;
	//printf("[GPU_merge]\n");
	//if(x!=0)return;
	// |0..3|4..7|||8..9|
	//    0    1     2       3         4
	//    ______     __________      _____ 
	//x:     0           1             2
	int a1 = global_part[x*2].a;
	int b1 = global_part[x*2].b;
	int a2,b2;
	int single_part =0;
	
	Data *xData = (Data*)malloc(sizeof(Data));
	if(b1==global_size_vet-1){
		single_part = 1;
		
	}
	if(!single_part){
		a2 = global_part[(x*2)+1].a;
		b2 = global_part[(x*2)+1].b;
		xData->a=a1;
		xData->b=b2;
		xData->n=(xData->b+1)-xData->a;
		
		printf("Part[%d]-{(%d,%d),(%d,%d)- merge----{%3d,%3d}}\n",x,a1,b1,a2,b2,xData->a,xData->b);		
		intercala(a1,a2,b2+1,global_vet_device);

		//global_part[x].a=a1;
		//global_part[x].b=b2;
	}else{
		//global_part[x].a=a1;
		//global_part[x].b=b1;
		xData->a=a1;
		xData->b=b1;
		printf("Part[%d]-{(%d,%d)- copiado}\n",x,a1,b1);		
		//free(global_part[x+1]);
	}
	__syncthreads();		
	//parte do código executada apenas pela ultima thread
	
	if(x==nr_thread-1){
		//printf("Thread:%d reorganizando vetor de particoes...\n",x);
		free(global_part);
		global_part = (Data *)malloc((x+1)*sizeof(Data));
		global_nr_part = x+1;
	}
	__syncthreads();	
	global_part[x]=*xData;
	/*if(x==0){
		printf("\n Particoes restante:%d\t",global_nr_part);
		for(int i=0;i<global_nr_part;i++){
			printf("(%3d,%3d)",global_part[i].a,global_part[i].b);
		}
		printf("\n");
	}*/

	//printf("[GPU_merge] x:%d[%d--%d)[%d--%d]\n",x,global_part[x*2].a,global_part[x*2].b,global_part[x*2+1].a,global_part[x*2+1].b);
	//printf("[GPU_merge] x:%d[%d--%d)[%d--%d]\n",x,a1,b1,a2,b2);
	//intercala(a1,a2,b2,global_vet_device);
	//change_global_partition(x,global_part[x*2].a,global_part[x*2+1].b);

	
}