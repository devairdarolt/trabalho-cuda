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
__device__ long global_nr_part=0;
__device__  long * global_vet_device=NULL;
__device__  long global_size_vet=0;
__device__  long global_nr_nucleos=0;

__device__ Lista particoes;// = list_init(sizeof(Data)); // Inicia uma lista para o tipo Data



// FUNÇÕES PRIVADAS (Não acessível para o programa main)
__device__ double ceild(double num);

__device__ void sort_subarray(long arr[], long n, long exp) ;

__device__ long get_max_val(long arr[], long n);

__device__ long sort_array(long x);

__device__ void intercala (long p, long q, long r, long *v);

// CODE
__device__ void sort_subarray(long arr[], long n, long exp) 
{ 
	//long output[n]; // output array 
	long *output = (long*)malloc(n * sizeof(long));
	long i, count[10] = { 0 }; 
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

__device__ long get_max_val(long arr[], long n) 
{ 
	long mx = arr[0]; 
	for (long i = 1; i < n; i++) 
		if (arr[i] > mx) 
			mx = arr[i]; 
	return mx; 
} 

__device__ long sort_array(long x){
	
	//if(x!=0) return 0; //para facilitar a programação 
	
	// 0 <= x=0 < 5 ... 5 <= x=1 <= 10
	long n =(long) ceild((double)global_size_vet/(double)global_nr_nucleos); // arredonda pra cima
	long a = x * n; // if x=0 -> a=0 ... if x=1 --> a=5...  if x=10 --> a = 50
	if((global_size_vet%global_nr_nucleos!=0)&&(x==global_nr_nucleos-1)){	
		n=global_size_vet-a;		
	}
	long b = (a +n)-1;
	global_part[x].a =a;
	global_part[x].b=b;
	global_part[x].n=n;
	//set do vetor de particoes;	
	//long a = x * n; // if x=0 -> a=0 ... if x=1 --> a=5...  if x=10 --> a = 50
	long *sub_arr = (long *)malloc(n * sizeof(long));// Cria na memória um espaço para um sub_array
	if(!sub_arr){
		printf("\033[0;31m Erro ao alocar sub array\n \e[m");
	}
	//printf("Part[%d]:n[%d] [%d <= x <= %d]\n",x,n,a,b);
	//sub_array recebe a referencia da posição inicial do vetor global
	//sub_arr = &global_vet_device[a];
	long j=0;
	long aux;
	//printf("\n");
	for(long i=a;i<=b;i++,j++){
		aux = global_vet_device[i];
		sub_arr[j]=aux;			
	}

	long m = get_max_val(sub_arr, n); 
	//iteração para cada dígito, no caso de um long muito grande esse for vai ocorrer 2^32 -> (10 casas) 
	for (long exp = 1; m / exp > 0; exp *= 10) {
		sort_subarray(&sub_arr[0], n, exp); 
	}	

	j=0;
	for(long i=a;i<=b;i++,j++){
		global_vet_device[i]=sub_arr[j];
	}

	return 0;
}

__global__ void GPU_set_globals(long *vet_d, long vet_size,long nthreads){
	//seta as variáveis globais
	global_vet_device = vet_d;
	global_size_vet = vet_size;
	global_nr_nucleos = nthreads;
	global_part = (Data *)malloc(nthreads * sizeof(Data));

}

__global__ void GPU_sort (long nthreads) {
	long x = threadIdx.x;
	
	
	//Inicia particionamento e ordenação
	sort_array(x);	

}


__host__ long *criar_vetor_desordenado(long *v,long vet_size){

	if(v!=NULL){
		printf("O vetor informado ja existe!\n");
		return v;
	}
	if(vet_size < 0){
		printf("O tamanho do vetor tem que ser maior que 0\n");
	}

	cudaMallocHost((void **) &v, vet_size*sizeof(long));	
	//inicia valores do vetor desordenado
	srand(time(0));
	for(long i=0;i<vet_size;i++){
		v[i]= rand() % 10000;// (0 <= rand <= vet_size)
	}
	return v;
}

__host__ void vet_imprimir(long *v,long vet_size){
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
		printf("\n20 primeiros\n");
		for(long i=0;i<20;i++){
			printf("%10ld,",v[i]);
		}
		printf("\n20 ultimos\n");
		for(long i=vet_size-20;i<vet_size;i++){
			printf("%10ld,",v[i]);
		}
		
	}
	long value = v[0];
	long ordenado = 1;
	
	for(long i=1;i<vet_size;i++){
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
	long inum = (long)num;
    if (num == (float)inum) {
        return inum;
    }
    return inum + 1;
}

// A função recebe vetores crescentes v[p..q-1] 
// e v[q..r-1] e rearranja v[p..r-1] em ordem 
// crescente.
__device__ void intercala (long p, long q, long r, long *v) 
{
   long *w;                                 //  1
   w =(long *)malloc((r-p) * sizeof(long));  //  2
   long i = p, j = q;                       //  3
   long k = 0;                              //  4

   while (i < q && j < r) {                //  5
      if (v[i] <= v[j])  w[k++] = v[i++];  //  6
      else  w[k++] = v[j++];               //  7
   }                                       //  8
   while (i < q)  w[k++] = v[i++];         //  9
   while (j < r)  w[k++] = v[j++];         // 10
   for (i = p; i < r; ++i)  v[i] = w[i-p]; // 11
   free (w);                               // 12
}
__global__ void GPU_get_nr_partitions(long *d_nr_part){
	long count;
	for(long i=0; i< global_nr_part;i++){
		//if(global_part[i]!=NULL){
		//}
		count++;
	}
	*d_nr_part = count+1;
	

}

__global__ void GPU_merge (long nr_thread){
	long x = threadIdx.x;
	//printf("[GPU_merge]\n");
	//if(x!=0)return;
	// |0..3|4..7|||8..9|
	//    0    1     2       3         4
	//    ______     __________      _____ 
	//x:     0           1             2
	long a1 = global_part[x*2].a;
	long b1 = global_part[x*2].b;
	long a2,b2;
	long single_part =0;
	
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
		
		//printf("Part[%d]-{(%d,%d),(%d,%d)- merge----{%3d,%3d}}\n",x,a1,b1,a2,b2,xData->a,xData->b);		
		intercala(a1,a2,b2+1,global_vet_device);

		//global_part[x].a=a1;
		//global_part[x].b=b2;
	}else{
		//global_part[x].a=a1;
		//global_part[x].b=b1;
		xData->a=a1;
		xData->b=b1;
		//printf("Part[%d]-{(%d,%d)- copiado}\n",x,a1,b1);		
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
		
}

__global__ void GPU_reset(){
	free(global_vet_device);
	free(global_part);
}

__global__ void GPU_print(){
	printf("\n20 primeiros:");
	for(int i=0;i<20;i++){
		printf("%9ld",global_vet_device[i]);
	}
	printf("\n20 ultimos:");
	for(int i=global_size_vet-20;i<global_size_vet;i++){
		printf("%9ld",global_vet_device[i]);
	}
	printf("\n");
}