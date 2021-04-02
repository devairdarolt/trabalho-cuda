
#include "lib.h"

#include <cuda.h>
#include <stdio.h>
#include <math.h>
#include <sys/time.h>



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// --- VARIÁVEIS GLOBAIS DA PLACA DE VIDEO                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


extern __device__ Data * global_part=NULL; //Array global para guardar os índices de partições préordenadas
extern __device__ long global_nr_part=0;   //Tamanho do array de particoes;
extern __device__  long * global_vet_device=NULL; //Array global para guardar o vetor a ser ordenado
extern __device__  long global_size_vet=0;
extern __device__  long global_nr_nucleos=0;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// --- FUNÇÕES PRIVADAS (Não acessível para o programa main)                                                                          //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

__device__ int is_sort(long * arr,long n);


__device__ double ceild(double num);

__device__ void sort_subarray(long arr[], long n, long exp) ;

__device__ long get_max_val(long arr[], long n);

__device__ long radix_sort_array(long x);


__device__ void swap(long* a, long* b);

__device__ void heapify(long *arr, long n, long i);

__device__ void heapSort(long *arr, long n);

__device__ long heap_sort_array(long x);


__device__ void intercala (long p, long q, long r, long *v);

__device__ void print_erro(const char *func,const char *msg);

__device__ void print_sucess(const char *func,const char *msg);


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// --- HEAP SORT                                                                                                                      //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// A utility function to swap two elements
__device__ void swap(long* a, long* b)
{
    long t = *a;
    *a = *b;
    *b = t;
}

// To heapify a subtree rooted with node i which is
// an index in arr[]. n is size of heap
__device__ void heapify(long *arr, long n, long i)
{
    long largest = i; // Initialize largest as root
    long l = 2 * i + 1; // left = 2*i + 1
    long r = 2 * i + 2; // right = 2*i + 2
 
    // If left child is larger than root
    if (l < n && arr[l] > arr[largest])
        largest = l;
 
    // If right child is larger than largest so far
    if (r < n && arr[r] > arr[largest])
        largest = r;
 
    // If largest is not root
    if (largest != i) {
        swap(&arr[i], &arr[largest]);
 
        // Recursively heapify the affected sub-tree
        heapify(arr, n, largest);
    }
}
 
// main function to do heap sort
__device__ void heapSort(long *arr, long n)
{
    // Build heap (rearrange array)
    for (long i = n / 2 - 1; i >= 0; i--)
        heapify(arr, n, i);
 
    // One by one extract an element from heap
    for (long i = n - 1; i > 0; i--) {
        // Move current root to end
        swap(&arr[0], &arr[i]);
 
        // call max heapify on the reduced heap
        heapify(arr, i, 0);
    }
}
 
__device__ long heap_sort_array(long x){
	
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
	

	long *sub_arr =NULL;
	
	sub_arr = &global_vet_device[a];
	heapSort(&sub_arr[0], n);		
	__syncthreads();
	
	//if(x!=1) return 0; //para facilitar a programação 
	is_sort(&sub_arr[0], n);	
	return 1;
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// --- RADIX SORT                                                                                                                     //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
__device__ void sort_subarray(long *arr, long n, long exp) 
{ 
	//long output[n]; // output array 
	long *output = (long*)malloc(n * sizeof(long));
	if(output==NULL){
		
		print_erro("sort_subarray","Erro ao alocar memória na placa de vídeo para 'output'");				
	}
	long i, count[10] = { 0 }; 
	
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
	free(output); 
		
}

__device__ long get_max_val(long *arr, long n) 
{ 
	long mx = arr[0]; 
	for (long i = 1; i < n; i++) 
		if (arr[i] > mx) 
			mx = arr[i]; 
	return mx; 
} 

__device__ long radix_sort_array(long x){
	
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
	long *sub_arr =NULL;
	/*long *sub_arr = (long *)malloc(n * sizeof(long));// Cria na memória um espaço para um sub_array
	if(!sub_arr){
		printf("\033[0;31m Erro ao alocar sub array\n \e[m");
	}
	*/
	//printf("Part[%d]:n[%d] [%d <= x <= %d]\n",x,n,a,b);
	//sub_array recebe a referencia da posição inicial do vetor global
	sub_arr = &global_vet_device[a];
	
	/*
		long j=0;
		long aux;
		//printf("\n");
		for(long i=a;i<=b;i++,j++){
			aux = global_vet_device[i];
			sub_arr[j]=aux;			
		}
	*/
	long m = get_max_val(&sub_arr[0], n); 
	//iteração para cada dígito, no caso de um long muito grande esse for vai ocorrer 2^32 -> (10 casas) 
	for (long exp = 1; m / exp > 0; exp *= 10) {
		sort_subarray(&sub_arr[0], n, exp); // primeiro faz o sort pelo bit 0, bit 1 ... até bit exp 
	}	

	/*
		j=0;
		for(long i=a;i<=b;i++,j++){
			global_vet_device[i]=sub_arr[j];
		}
	*/

	return 0;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// --- FUNÇÕES DE KERNEL                                                                                                              //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
__global__ void GPU_set_globals(long *vet_d, long vet_size,long nthreads){
	//seta as variáveis globais
	global_vet_device = vet_d;
	global_size_vet = vet_size;
	global_nr_nucleos = nthreads;
	global_nr_part = nthreads;
	global_part = (Data *)malloc(nthreads * sizeof(Data));
	if(global_part==NULL){
		print_erro("GPU_set_globals","Erro ao alocar memória para 'global_part' na placa de video");
	}

}

__global__ void GPU_call_sort (long nthreads) {
	long x = threadIdx.x;
	
	
	//Inicia particionamento e ordenação
	if((global_size_vet<2000000)){
		if(x==0){
			printf("\nutilizando [radix sort]\n");
		}
		radix_sort_array(x);	//TODO anteriormente
	}else{
		if(x==0){
			printf("\nUtilizando[heap sort]\n");
		}
		heap_sort_array(x);	

	}
	

}
__global__ void GPU_reset(){
	free(global_vet_device);
	free(global_part);
}

__global__ void GPU_print(){
	printf("GPU_print\n");
	if(global_vet_device==NULL||global_size_vet==0||global_vet_device[global_size_vet-1]==0){		
		print_erro("GPU_print","os dados não foram copiados para a memória da placa de video...");
	}
	
	int max_index = global_size_vet;
	if(max_index>20){
		max_index = 20;
	}
	printf("\n%d primeiros:",max_index);
	for(int i=0;i<max_index;i++){
		printf(" %ld ",global_vet_device[i]);
	}
	printf("\n%d ultimos:",max_index);
	long sum=0;
	for(int i=global_size_vet-max_index;i<global_size_vet;i++){
		printf(" %ld ",global_vet_device[i]);
		sum+=global_vet_device[i];
	}	
	
	if(global_vet_device[global_size_vet-1]==NULL||sum==0){		
		print_erro("GPU_print","os dados não foram copiados para a memória da placa...");
	}
	printf("\n");
	
	if(is_sort(&global_vet_device[0],global_size_vet)){		
		print_sucess("GPU_print","VETOR ORDENADO!");
	}else{
		print_erro("GPU_print","VETOR DESORDENADO!");		
	}	
	printf("\n");
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// --- FUNÇÕES DE AUXILIARES                                                                                                          //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

__host__ long *criar_vetor_desordenado(long vet_size){	
	if(vet_size < 0){
		printf("O tamanho do vetor tem que ser maior que 0\n");
	}
	printf("Alocando na memória do host\n");
	long *vet;
	cudaMallocHost((void **) &vet, vet_size*sizeof(long));	
	if(vet==NULL){
		h_print_erro("criar_vetor_desordenado","Erro ao alocar memória 'cudaMallocHost'");
	}
	printf("memória alocada\n");
	//inicia valores do vetor desordenado
	srand(time(0));
	for(long i=0;i<vet_size;i++){
		vet[i]= rand() % 100000;// (0 <= rand <= vet_size)
	}
	printf("Vetor aleatório gerado alocado\n");
	return vet;
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
	long max_index = vet_size;
	if(max_index>50){
		max_index = 50;
	}
	
	printf("\n%ld primeiros\t",max_index);
	for(long i=0;i<max_index;i++){
		printf(" %ld, ",v[i]);
	}
	if(vet_size>50){
		printf("\n%ld Ultimas\t",max_index);
		for(long i=vet_size-50;i<vet_size;i++){
			printf(" %ld, ",v[i]);
		}		
	}		
	printf("\n");

	int ordenado = h_is_sort(v,vet_size);	
	if(ordenado){
		h_print_sucess("vet_imprimir","ORDENADO!");
		
	}else{
		h_print_erro("vet_imprimir","DESORDENADO!");		
	}	


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
//Tem um custo maior de espaço pois cada thread cria um vetor de tamanho n
__device__ void intercala (long p, long q, long r, long *v) 
{
   long *w;                                 //  1
   w =(long *)malloc((r-p) * sizeof(long));  //  2
   if(w==NULL){
		print_erro("intercala","Não foi possivel alocar memoria para w");
   }
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
	long n1 = global_part[x*2].n;
	long a2,b2,n2;
	long single_part =0;
	
	Data *xData = (Data*)malloc(sizeof(Data));
	if(xData==NULL){
		print_erro("GPU_merge","Erro ao alocar memória na placa de vídeo");		
	}
	if(b1==global_size_vet-1){
		single_part = 1;		
	}
	if(!single_part){
		a2 = global_part[(x*2)+1].a;
		b2 = global_part[(x*2)+1].b;
		n2 = global_part[(x*2)+1].n;

		xData->a=a1;
		xData->b=b2;
		xData->n=n1+n2;				
		//printf("\033[0;34m x[%ld]-{(a1:%ld,b1:%ld),(a2:%ld,b2:%ld)- merge----{a1:%ld,b2:%ld} - n:%ld}\e[m\n",x,a1,b1,a2,b2,xData->a,xData->b,xData->n);		
		intercala(a1,a2,a2+n2,global_vet_device);
		if(!is_sort(&global_vet_device[a1],xData->n)){
			print_erro("GPU_merge","A sub particao não esta ordenada");
		}
		//global_part[x].a=a1;
		//global_part[x].b=b2;
	}else{
		//global_part[x].a=a1;
		//global_part[x].b=b1;
		xData->a=a1;
		xData->b=b1;
		xData->n=(b1+1)-a1;
		//printf("Part[%ld]-{(%ld,%ld) n:%ld- copiado}\n",x,a1,b1,xData->n);		
		if(!is_sort(&global_vet_device[a1],xData->n)){
			print_erro("GPU_merge","A sub particao não esta ordenada");
		}		
	}
	
	__syncthreads();// Quando todas as threads chegarem aqui escolhe uma thread para alocar o vetor de particoes		

	//parte do código executada apenas pela ultima thread	
	if(x==nr_thread-1){
		//printf("Thread:%d reorganizando vetor de particoes...\n",x);
		free(global_part);
		global_part = (Data *)malloc((x+1)*sizeof(Data));
		if(global_part==NULL){
			print_erro("GPU_merge","Erro ao alocar memoria para 'global_part'");
		}
		global_nr_part = x+1;
	}
	__syncthreads();	
	global_part[x]=*xData;
		
}
__device__ void print_erro(const char *func,const char *msg){
	printf("\033[0;31m [%s]--%s\e[m\n",func,msg);
}
__device__ void print_sucess(const char *func,const char *msg){
	printf("\033[0;32m [%s]--%s\e[m\n",func,msg);
}


__device__ int is_sort(long * arr,long n){	
	long ordenado = 0;	
	for(long i=1;i<n;i++){
		if(arr[i-1]>arr[i]){
			//printf("arr[%ld]>arr[%ld]--[%ld,%ld]\n",i-1,i,arr[i-1],arr[i]);
			ordenado ++;			
		}		
	}
	if(ordenado==0){
		//printf("\nSub particao ordenada!\n");
		return 1;
	}else{
		//printf("\nSub particao desordenada, %ld posicoes fora de ordem!\n",ordenado);
		return 0;
	}	
}
//#####################################################################################################
__global__ void GPU_get_d_part(Data *d_part){
	memcpy(d_part,global_part,global_nr_part*sizeof(Data));
	
}
__global__ void GPU_get_nr_part(long *d_nr_part){
	//int erro_memcpy;	
	*d_nr_part = global_nr_part;
	//printf("d_nr_part %ld\n",*d_nr_part);

}

__global__ void GPU_get_global_vet(long *d_vet){
	//d_vet = global_vet_device;
	/* for(int i=0;i<global_size_vet;i++){
		d_vet[i] =global_vet_device[i];
	} */
	//d_vet = global_vet_device;
	memcpy(d_vet,global_vet_device,global_size_vet*sizeof(long));
	printf("d_vet[0] %d\n",d_vet[0]);	
	//memcpy(d_vet,global_vet_device,global_size_vet * sizeof(long));
}

__host__ void h_print_erro(const char *func,const char *msg){
	printf("\033[0;31m [%s]--%s\e[m\n",func,msg);
}

__host__ void h_print_sucess(const char *func,const char *msg){
	printf("\033[0;32m [%s]--%s\e[m\n",func,msg);
}


__host__ int h_is_sort(long * arr,long n){	
	long ordenado = 0;	
	for(long i=1;i<n;i++){
		if(arr[i-1]>arr[i]){
			//printf("arr[%ld]>arr[%ld]--[%ld,%ld]\n",i-1,i,arr[i-1],arr[i]);
			ordenado ++;			
		}		
	}
	if(ordenado==0){
		//printf("\nSub particao ordenada!\n");
		return 1;
	}else{
		//printf("\nSub particao desordenada, %ld posicoes fora de ordem!\n",ordenado);
		return 0;
	}	
}