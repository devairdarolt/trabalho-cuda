
#include "lib.h"

#include <cuda.h>
#include <stdio.h>
#include <math.h>
#include <sys/time.h>



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// --- VARIÁVEIS GLOBAIS DA PLACA DE VIDEO                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


extern __device__ Data * _device_global_partitions=NULL; //Array global para guardar os índices de partições préordenadas
extern __device__ long _device_global_nr_partitions=0;   //Tamanho do array de particoes;
extern __device__  long * _device_global_array=NULL; //Array global para guardar o vetor a ser ordenado
extern __device__  long _device_global_array_size=0;
extern __device__  long _device_global_nr_thread=0;


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// --- FUNÇÕES PRIVADAS (Não acessível para o programa main)                                                                          //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

__device__ int device_check_sorted(long * arr,long n);


__device__ double device_ceild(double num);

__device__ void device_radix_sort_subarray(long arr[], long n, long exp) ;

__device__ long device_radix_get_max_val(long arr[], long n);

__device__ long device_radix_sort_array(long x);


__device__ void device_swap(long* a, long* b);

__device__ void device_heapify(long *arr, long n, long i);

__device__ void device_heap_sort(long *arr, long n);

__device__ long device_heap_sort_array(long x);


__device__ void device_intercala (long p, long q, long r, long *v);

__device__ void device_print_erro(const char *func,const char *msg);

__device__ void device_print_sucess(const char *func,const char *msg);

__device__ int device_is_sort();

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// --- BUBLLE SORT                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


__device__ void device_bubble_sort_array(long index) 
{ 			
	if(index<_device_global_array_size){

		long index_a = index;
		long index_b = index_a+1;
		// testa index out of bound array				
		if(index_a < _device_global_array_size && index_b < _device_global_array_size){	
			long *a = &_device_global_array[index_a];			// posicao i
			long *b = &_device_global_array[index_b];			// posicao i+1
			if(*b < *a){				
				device_swap(a,b);		
			}								
		}
	}
	
    
} 

__device__ void device_bubble_sort(long tId) {

	for(int k=0; k<device_ceild(((double)(_device_global_array_size)/((double)2)));k++){
		
		long x=tId,y=0;
		int shift = 0;
		long posicao=0;
		
		for(int i=0;i<device_ceild(((double)_device_global_array_size)/(double)(2*_device_global_nr_thread)); i++,y+=_device_global_nr_thread){
			posicao = (2 * x) + (2 * y) + shift; // y = deslocamento em relação ao y anterior, deslocamento de n threads			
			device_bubble_sort_array(posicao);					
			
		}
		__syncthreads();
		shift = 1; // desloca uma unidade para pegar os ímpares
		y=0;
		
		for(int i=0;i<device_ceild(((double)_device_global_array_size)/(double)(2*_device_global_nr_thread)); i++,y+=_device_global_nr_thread){
			posicao = (2 * x) + (2 * y) + shift; // y = deslocamento em relação ao y anterior, deslocamento de n threads			
			device_bubble_sort_array(posicao);					
			
		}		
		__syncthreads();
	}
	
	
	

}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// --- HEAP SORT                                                                                                                      //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// A utility function to device_swap two elements
__device__ void device_swap(long* a, long* b)
{
    long t = *a;
    *a = *b;
    *b = t;
}

// To device_heapify a subtree rooted with node i which is
// an index in arr[]. n is size of heap
__device__ void device_heapify(long *arr, long n, long i)
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
        device_swap(&arr[i], &arr[largest]);
 
        // Recursively device_heapify the affected sub-tree
        device_heapify(arr, n, largest);
    }
}
 
// main function to do heap sort
__device__ void device_heap_sort(long *arr, long n)
{
    // Build heap (rearrange array)
    for (long i = n / 2 - 1; i >= 0; i--)
        device_heapify(arr, n, i);
 
    // One by one extract an element from heap
    for (long i = n - 1; i > 0; i--) {
        // Move current root to end
        device_swap(&arr[0], &arr[i]);
 
        // call max device_heapify on the reduced heap
        device_heapify(arr, i, 0);
    }
}
 
__device__ long device_heap_sort_array(long x){
	
	//if(x!=0) return 0; //para facilitar a programação 	
	// 0 <= x=0 < 5 ... 5 <= x=1 <= 10
	long n =(long) device_ceild((double)_device_global_array_size/(double)_device_global_nr_thread); // arredonda pra cima
	long a = x * n; // if x=0 -> a=0 ... if x=1 --> a=5...  if x=10 --> a = 50
	if((_device_global_array_size%_device_global_nr_thread!=0)&&(x==_device_global_nr_thread-1)){	
		n=_device_global_array_size-a;		
	}
	long b = (a +n)-1;
	_device_global_partitions[x].a =a;
	_device_global_partitions[x].b=b;
	_device_global_partitions[x].n=n;
	

	long *sub_arr =NULL;
	
	sub_arr = &_device_global_array[a];
	device_heap_sort(&sub_arr[0], n);		
	__syncthreads();
	
	//if(x!=1) return 0; //para facilitar a programação 
	device_check_sorted(&sub_arr[0], n);	
	return 1;
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// --- RADIX SORT                                                                                                                     //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
__device__ void device_radix_sort_subarray(long *arr, long n, long exp) 
{ 
	//long output[n]; // output array 
	long *output = (long*)malloc(n * sizeof(long));
	if(output==NULL){
		
		device_print_erro("device_radix_sort_subarray","Erro ao alocar memória na placa de vídeo para 'output'");				
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

__device__ long device_radix_get_max_val(long *arr, long n) 
{ 
	long mx = arr[0]; 
	for (long i = 1; i < n; i++) 
		if (arr[i] > mx) 
			mx = arr[i]; 
	return mx; 
} 

__device__ long device_radix_sort_array(long x){
	
	//if(x!=0) return 0; //para facilitar a programação 
	
	// 0 <= x=0 < 5 ... 5 <= x=1 <= 10
	long n =(long) device_ceild((double)_device_global_array_size/(double)_device_global_nr_thread); // arredonda pra cima
	long a = x * n; // if x=0 -> a=0 ... if x=1 --> a=5...  if x=10 --> a = 50
	if((_device_global_array_size%_device_global_nr_thread!=0)&&(x==_device_global_nr_thread-1)){	
		n=_device_global_array_size-a;		
	}
	long b = (a +n)-1;
	_device_global_partitions[x].a =a;
	_device_global_partitions[x].b=b;
	_device_global_partitions[x].n=n;
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
	sub_arr = &_device_global_array[a];
	
	/*
		long j=0;
		long aux;
		//printf("\n");
		for(long i=a;i<=b;i++,j++){
			aux = _device_global_array[i];
			sub_arr[j]=aux;			
		}
	*/
	long m = device_radix_get_max_val(&sub_arr[0], n); 
	//iteração para cada dígito, no caso de um long muito grande esse for vai ocorrer 2^32 -> (10 casas) 
	for (long exp = 1; m / exp > 0; exp *= 10) {
		device_radix_sort_subarray(&sub_arr[0], n, exp); // primeiro faz o sort pelo bit 0, bit 1 ... até bit exp 
	}	

	/*
		j=0;
		for(long i=a;i<=b;i++,j++){
			_device_global_array[i]=sub_arr[j];
		}
	*/

	return 0;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// --- FUNÇÕES DE KERNEL                                                                                                              //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
__global__ void KERNEL_set_globals(long *vet_d, long vet_size,long nthreads){
	//seta as variáveis globais
	_device_global_array = vet_d;
	_device_global_array_size = vet_size;
	_device_global_nr_thread = nthreads;
	_device_global_nr_partitions = nthreads;
	_device_global_partitions = (Data *)malloc(nthreads * sizeof(Data));
	if(_device_global_partitions==NULL){
		device_print_erro("KERNEL_set_globals","Erro ao alocar memória para '_device_global_partitions' na placa de video");
	}

}

__global__ void KERNEL_call_sort (long nthreads,int opc) {
	long tId = threadIdx.x;
	
	switch(opc){

		case CUDA_BUBBLE:
			if(tId==0){
				printf("\nUtilizando[bubble sort]\n");
			}
			device_bubble_sort(tId);
			break;

		case CUDA_HEAP:
			if(tId==0){
				printf("\nUtilizando[heap sort]\n");
			}
			device_heap_sort_array(tId);
			break;


	}
	

	
	
	
	
	/* for(long k=0;k< nthreads*_device_global_array_size ;k++){
		for(long shift=0;shift<2;shift++){
			//enquanto não estiver 
			int iteracoes_per_array = device_ceild((double)_device_global_array_size/2*nthreads); ///  10 / (2*2) = 10/4 = 3.
			//printf("iteracoes_per_array [%d]\n",iteracoes_per_array);									     
			for(int i=0;i<iteracoes_per_array;i++){			//												 x0       x1      x0        x1      x0       x1 === iterações para fazer o array todo(vezes)
				device_bubble_sort_array(x,shift);			//executa sobre todo o array fazendo swap entre [0][1] - [2][3] - [4][5] - [6][7] - [8][9]   NULL
				if(device_is_sort())return;
				x+=nthreads;				
			}
			x = threadIdx.x;
		}
	} */
	
	//Inicia particionamento e ordenação
	/* if((_device_global_array_size<1000000)){
		if(x==0){
			printf("\nutilizando [radix sort]\n");
		}
		device_radix_sort_array(x);	//TODO anteriormente
	}else{
		if(x==0){
			printf("\nUtilizando[heap sort]\n");
		}
		device_heap_sort_array(x);	

	} */
	

}
__global__ void KERNEL_reset(){
	free(_device_global_array);
	free(_device_global_partitions);
}

__global__ void KERNEL_print_array(){
	printf("KERNEL_print_array\n");
	if(_device_global_array==NULL||_device_global_array_size==0||_device_global_array[_device_global_array_size-1]==0){		
		device_print_erro("KERNEL_print_array","os dados não foram copiados para a memória da placa de video...");
	}
	
	int max_index = _device_global_array_size;
	if(max_index>10){
		max_index = 10;
	}
	printf("\n%d primeiros:",max_index);
	for(int i=0;i<max_index;i++){
		printf(" %ld ",_device_global_array[i]);
	}
	printf("\n%d ultimos:",max_index);
	long sum=0;
	for(int i=_device_global_array_size-max_index;i<_device_global_array_size;i++){
		printf(" %ld ",_device_global_array[i]);
		sum+=_device_global_array[i];
	}	
	
	if(_device_global_array[_device_global_array_size-1]==NULL||sum==0){		
		device_print_erro("KERNEL_print_array","os dados não foram copiados para a memória da placa...");
	}
	printf("\n");
	/* 
	if(device_check_sorted(&_device_global_array[0],_device_global_array_size)){		
		device_print_sucess("KERNEL_print_array","VETOR ORDENADO!");
	}else{
		device_print_erro("KERNEL_print_array","VETOR DESORDENADO!");		
	}	
	printf("\n"); */
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// --- FUNÇÕES DE AUXILIARES                                                                                                          //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

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
	
	long max_index = vet_size;
	if(max_index>10){
		max_index = 10;
	}
	
	printf("\n%ld primeiros:   ",max_index);
	for(long i=0;i<max_index;i++){
		printf(" %ld, ",v[i]);
	}
	if(vet_size>50){
		printf("\n%ld Ultimos:  ",max_index);
		for(long i=vet_size-max_index;i<vet_size;i++){
			printf(" %ld, ",v[i]);
		}		
	}		
	printf("\n");
	/* 
	int ordenado = h_is_sort(v,vet_size);	
	if(ordenado){
		host_print_sucess("vet_imprimir","ORDENADO!");
		
	}else{
		host_print_erro("vet_imprimir","DESORDENADO!");		
	} */	


}

__host__ double wtime() {
  struct timeval t;
  gettimeofday(&t, NULL);
  return t.tv_sec + (double) t.tv_usec / 1000000;
}



__device__ double device_ceild(double num){	
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
__device__ void device_intercala (long p, long q, long r, long *v) 
{
   long *w;                                 //  1
   w =(long *)malloc((r-p) * sizeof(long));  //  2
   if(w==NULL){
		device_print_erro("device_intercala","Não foi possivel alocar memoria para w");
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

__global__ void KERNEL_merge (long nr_thread){
	long x = threadIdx.x;
	//printf("[KERNEL_merge]\n");
	//if(x!=0)return;
	// |0..3|4..7|||8..9|
	//    0    1     2       3         4
	//    ______     __________      _____ 
	//x:     0           1             2
	long a1 = _device_global_partitions[x*2].a;
	long b1 = _device_global_partitions[x*2].b;
	long n1 = _device_global_partitions[x*2].n;
	long a2,b2,n2;
	long single_part =0;
	
	Data *xData = (Data*)malloc(sizeof(Data));
	if(xData==NULL){
		device_print_erro("KERNEL_merge","Erro ao alocar memória na placa de vídeo");		
	}
	if(b1==_device_global_array_size-1){
		single_part = 1;		
	}
	if(!single_part){
		a2 = _device_global_partitions[(x*2)+1].a;
		b2 = _device_global_partitions[(x*2)+1].b;
		n2 = _device_global_partitions[(x*2)+1].n;

		xData->a=a1;
		xData->b=b2;
		xData->n=n1+n2;				
		//printf("\033[0;34m x[%ld]-{(a1:%ld,b1:%ld),(a2:%ld,b2:%ld)- merge----{a1:%ld,b2:%ld} - n:%ld}\e[m\n",x,a1,b1,a2,b2,xData->a,xData->b,xData->n);		
		device_intercala(a1,a2,a2+n2,_device_global_array);
		if(!device_check_sorted(&_device_global_array[a1],xData->n)){
			device_print_erro("KERNEL_merge","A sub particao não esta ordenada");
		}
		//_device_global_partitions[x].a=a1;
		//_device_global_partitions[x].b=b2;
	}else{
		//_device_global_partitions[x].a=a1;
		//_device_global_partitions[x].b=b1;
		xData->a=a1;
		xData->b=b1;
		xData->n=(b1+1)-a1;
		//printf("Part[%ld]-{(%ld,%ld) n:%ld- copiado}\n",x,a1,b1,xData->n);		
		if(!device_check_sorted(&_device_global_array[a1],xData->n)){
			device_print_erro("KERNEL_merge","A sub particao não esta ordenada");
		}		
	}
	
	__syncthreads();// Quando todas as threads chegarem aqui escolhe uma thread para alocar o vetor de particoes		

	//parte do código executada apenas pela ultima thread	
	if(x==nr_thread-1){
		//printf("Thread:%d reorganizando vetor de particoes...\n",x);
		free(_device_global_partitions);
		_device_global_partitions = (Data *)malloc((x+1)*sizeof(Data));
		if(_device_global_partitions==NULL){
			device_print_erro("KERNEL_merge","Erro ao alocar memoria para '_device_global_partitions'");
		}
		_device_global_nr_partitions = x+1;
	}
	__syncthreads();	
	_device_global_partitions[x]=*xData;
		
}
__device__ void device_print_erro(const char *func,const char *msg){
	printf("\033[0;31m [%s]--%s\e[m\n",func,msg);
}
__device__ void device_print_sucess(const char *func,const char *msg){
	printf("\033[0;32m [%s]--%s\e[m\n",func,msg);
}


__device__ int device_check_sorted(long * arr,long n){	
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
__global__ void KERNEL_get_array_partitions(Data *d_part){
	memcpy(d_part,_device_global_partitions,_device_global_nr_partitions*sizeof(Data));
	
}
__global__ void KERNEL_get_nr_partitions(long *d_nr_part){
	//int erro_memcpy;	
	*d_nr_part = _device_global_nr_partitions;
	//printf("d_nr_part %ld\n",*d_nr_part);

}

__global__ void KERNEL_get_global_array(long *d_vet){
	
	memcpy(d_vet,_device_global_array,_device_global_array_size*sizeof(long));
	
}

__host__ void host_print_erro(const char *func,const char *msg){
	printf("\033[0;31m [%s]--%s\e[m\n",func,msg);
}

__host__ void host_print_sucess(const char *func,const char *msg){
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

__device__ int device_is_sort(){	
	long * arr = _device_global_array;
	long n = _device_global_array_size;
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