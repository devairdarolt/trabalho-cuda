
#include "lib.h"

#include <string.h>
#include <cuda.h>
#include <stdio.h>
#include <math.h>

#include <omp.h>





////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// --- VARIÁVEIS GLOBAIS DO HOST                                                                                                      //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


long h_global_nr_part;   //Tamanho do array de particoes;
Data *h_global_part; //Array global para guardar os índices de partições préordenadas
long *h_global_array; //Array global para guardar o vetor a ser ordenado
long  h_global_array_size;
long h_global_nr_threads;

long *d_global_array; //Array para ser alocado em device
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// --- FUNÇÕES DO HOST                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

__host__ void host_intercala (long p, long q, long r, long *v);

__host__ void host_print_erro(const char *func,const char *msg);

__host__ void host_print_sucess(const char *func,const char *msg);

__host__ void host_get_global_array();

__host__ void host_get_global_nr_partitions();

__host__ void host_get_global_partitions();

__host__ void cpu_merge();

__host__ void swap(long *xp, long *yp);

__host__ void sequencial_bubble_sort(long *arr, int long);

__host__ double omp_bubble_sort(long *arr,  long n);

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// --- FUNÇÕES DE ARQUIVO                                                                                                             //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

__host__ int host_make_input_file(char *nome);

__host__ int host_load_input_file(char *nome);





int main (int argc, char ** argv) {
	//INICIALIZA VARIAVEIS GLOBIAS
	h_global_nr_part=0;   //Tamanho do array de particoes;
	h_global_part=NULL; //Array global para guardar os índices de partições préordenadas
	h_global_array=NULL; //Array global para guardar o vetor a ser ordenado
	
	d_global_array=NULL;
	
	h_global_array_size=100000;		
	h_global_nr_threads = 100;
	//long nblocos = 1;
	char nome[] = "caos.map";
	

	
	if (argc == 3 ||argc == 4) {
		h_global_nr_threads = atoi(argv[1]);
		strcpy(nome,argv[2]);
		if(argc == 4){
			h_global_array_size = atoi(argv[3]);	
			host_make_input_file(nome);
		}
		//nome = argv[2];
		//h_global_array_size = atoi(argv[2]);
	}else{
		printf ("./main <h_global_nr_threads> <fileName> --- faz a leitura do arquivo de entrada\n");
		printf ("./main <h_global_nr_threads> <fileName> <size>--- cria um arquivo de leitura com tamanho size.\n");
		return 0;
	} 
	
	if(!((double)h_global_array_size/h_global_nr_threads >= 2)){
		host_print_erro("A quantidade de números precisa ser duas vezes maior que a quantidade de threads","");
		return 0;
	}

	
	host_load_input_file(nome);
	printf("Ordenando vetor de %ld elementos long - %f Kbytes\n",h_global_array_size,((double)h_global_array_size*sizeof(long))/(double)1024);	
	vet_imprimir(h_global_array,h_global_array_size); 	
	printf("\n\n\n");
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	////////////////////////////                     SEQUENCIAL BUBBLE SORT                             ////////////////////////////
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	if(h_global_array_size<=1000000){
		double s_time_seq = wtime();
		sequencial_bubble_sort(h_global_array,h_global_array_size);
		double e_time_seq = wtime();
	
		if(h_is_sort(h_global_array,h_global_array_size)){
			vet_imprimir(h_global_array,h_global_array_size);			
			printf("Tempo SEQUENCIAL[%f]\n",e_time_seq-s_time_seq);
			host_print_sucess("SEQUENCIAL","ORDENADO\n\n");
		}else{
			host_print_erro("SEQUENCIAL","FORA DE ORDEM\n\n");
		}
		cudaFreeHost(h_global_array);
		

	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	////////////////////////////                        OPEN_MP BUBBLE SORT                             ////////////////////////////

	if(h_global_array_size<=100000 ){
		host_load_input_file(nome);
		double omp_time;	

		omp_time = omp_bubble_sort(h_global_array,h_global_array_size);		
		if(h_is_sort(h_global_array,h_global_array_size)){
			printf("Tempo omp[%3f]\n",omp_time);
			host_print_sucess("OMP_BUBBLE","ORDENADO\n\n");

		}else{
			host_print_erro("OMP_BUBBLE","ORDENADO\n\n");
		}
		cudaFreeHost(h_global_array);
	}
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	////////////////////////////                             CUDA HEAP SORT                             ////////////////////////////
	
	if(h_global_nr_threads<=200 && h_global_array_size <=100000){
		host_load_input_file(nome);
		if(d_global_array!= NULL){
			cudaFree(d_global_array);
		}
		if(cudaMalloc((void**)&d_global_array,h_global_array_size * sizeof(long))){
			host_print_erro("main","Erro ao alocar memória da placa de video");
		}
		printf("Dados copiados para a placa de video %3f MB\n",(double)(h_global_array_size*sizeof(long))/1024/1024);
		cudaMemcpy (d_global_array, h_global_array, h_global_array_size*sizeof(long), cudaMemcpyHostToDevice);

		double s_time_cuda_heap = wtime();			
			
		KERNEL_set_globals<<<1,1>>>(d_global_array, h_global_array_size,h_global_nr_threads);		
		cudaDeviceSynchronize();	
			
		KERNEL_call_sort<<<1,h_global_nr_threads>>>(h_global_nr_threads,CUDA_HEAP);	
		cudaDeviceSynchronize();	
		
		host_get_global_array();	
		cudaDeviceSynchronize();	
		 
		//Copia as variaveis globais da placa para a memoria do host	
		host_get_global_nr_partitions();
		cudaDeviceSynchronize();	

		host_get_global_partitions();
		cudaDeviceSynchronize();	 

		
		cpu_merge();
		double e_time_cuda_heap = wtime();	
		if(h_is_sort(h_global_array,h_global_array_size)){
			vet_imprimir(h_global_array,h_global_array_size);		
			printf("Tempo CUDA HEAP[%f]\n",e_time_cuda_heap -s_time_cuda_heap);
			host_print_sucess("CUDA HEAP","ORDENADO\n\n");			
		}
	
		if(d_global_array !=NULL){
			cudaFree(d_global_array);
		}
		if(h_global_part!=NULL){		
			cudaFreeHost(h_global_part);		
		}
		if(h_global_array!=NULL){		
			cudaFreeHost(h_global_array);		
		}
	
	
	}
	



	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	////////////////////////////                           CUDA BUBBLE SORT                             ////////////////////////////
	
	if(h_global_array_size<=100000){

		host_load_input_file(nome);
		if(d_global_array!= NULL){
			cudaFree(d_global_array);
		}
		if(cudaMalloc((void**)&d_global_array,h_global_array_size * sizeof(long))){
			host_print_erro("main","Erro ao alocar memória da placa de video");
		}
		printf("Dados copiados para a placa de video %3f MB\n",(double)(h_global_array_size*sizeof(long))/1024/1024);
		cudaMemcpy (d_global_array, h_global_array, h_global_array_size*sizeof(long), cudaMemcpyHostToDevice);
		
		//Cada CUDA core ordena uma partição de d_global_array
		//resulta em um único vetor de partições ordenadas
		double s_time_cuda = wtime();			
		
		KERNEL_set_globals<<<1,1>>>(d_global_array, h_global_array_size,h_global_nr_threads);		
		cudaDeviceSynchronize();	
			
		KERNEL_call_sort<<<1,h_global_nr_threads>>>(h_global_nr_threads,CUDA_BUBBLE);	
		cudaDeviceSynchronize();		
		double e_time_cuda = wtime();	
		
		
		host_get_global_array();	
		cudaDeviceSynchronize();	
		if(h_is_sort(h_global_array,h_global_array_size)){
			vet_imprimir(h_global_array,h_global_array_size);		
			printf("Tempo CUDA BUBBLE[%f]\n",e_time_cuda-s_time_cuda);
			host_print_sucess("CUDA BUBBLE","ORDENADO\n\n");			
		}
		
		double e_time = wtime();			
		if(d_global_array !=NULL){
			cudaFree(d_global_array);
		}
		if(h_global_part!=NULL){		
			cudaFreeHost(h_global_part);		
		}
		if(h_global_array!=NULL){		
			cudaFreeHost(h_global_array);		
		}
	}

	
	
	return 0;
}



























__host__ void host_intercala (long p, long q, long r, long *v) 
{
   long *w;     
   //printf("p:%ld,r:%ld\nalocando r-p:%ld\n",p,r,r-p);                            //  1
   w =(long *)calloc(r-p,sizeof(long));  //  2
   if(w==NULL){
		host_print_erro("host_intercala","Não foi possivel alocar memoria para w");
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
   
   //vet_imprimir(v,r-p);
   free (w);                               // 12
}

__host__ void host_get_global_array(){
	
	cudaFreeHost(h_global_array);
	cudaMallocHost((void **)&h_global_array,h_global_array_size*sizeof(long));	
	if(h_global_array==NULL){		
		host_print_erro("host_get_global_array","h_global_array é NULL");
	}	
	KERNEL_get_global_array<<<1,1>>>(h_global_array);	
	cudaDeviceSynchronize();	
	//printf("h_global_array[0] %ld\n ",h_global_array[0]);
	
}

__host__ void host_get_global_nr_partitions(){
	long *d_nr_part;
	cudaMalloc((void**)&d_nr_part,sizeof(long));	
	KERNEL_get_nr_partitions<<<1,1>>>(d_nr_part);
	cudaDeviceSynchronize();
	cudaMemcpy(&h_global_nr_part,d_nr_part,sizeof(long),cudaMemcpyDeviceToHost);
	//printf("h_global_nr_part %ld\n",h_global_nr_part);
}

__host__ void host_get_global_partitions(){
	
	if(h_global_part!=NULL){
		cudaFreeHost(h_global_part);
	}
	printf("h_global_nr_part:[%ld]",h_global_nr_threads);
	Data *temp;
	cudaMallocHost((void **)&temp,h_global_nr_threads * sizeof(Data));	
	//cudaMallocHost((void**)&h_global_part,h_global_nr_part* sizeof(Data));
	if(temp==NULL){
		host_print_erro("host_get_global_partitions","Erro ao alocar h_global_part");
	}
	KERNEL_get_array_partitions<<<1,1>>>(temp);
	h_global_part = temp;
	cudaDeviceSynchronize();
	//copia o vetor de particoes da placa de video para o host
	//cudaMemcpy(&h_global_part[0],&d_part[0],h_global_nr_part * sizeof(Data),cudaMemcpyDeviceToHost);	
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// --- FUNÇÕES DE ARQUIVOS                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

__host__ int host_make_input_file(char *nome){

	FILE *fp;

	printf("Gerando arquivo random arquivo.\n");
	if((fp = fopen(nome,"w")) == NULL){		
		host_print_erro("host_make_input_file","Erro na abertura do arquivo");
		return 0;
	}
	long val;
	char buffer[10] = "#size";
	fprintf(fp, "%s\n", buffer);
	fprintf(fp, "%ld\n", h_global_array_size);

	for(int i=0; i<h_global_array_size;i++){
		val  = rand() % 1000000;// (0 <= rand <= 1 Bilhao)
		fprintf(fp, "%ld\n",val);// escreve o numero separado por ','
	}
	printf("Arquivo gerado!\n");
	fclose(fp);
	return 1;
}

__host__ int host_load_input_file(char *nome){
	FILE *fp;

	printf("Abrindo arquivo.\n");
	if((fp = fopen(nome,"r")) == NULL){		
		host_print_erro("host_load_input_file","Erro na leitura do arquivo");
		return 0;
	}
	
	//header
	char buffer[10];
	fscanf(fp, "%s",buffer);
	//printf("-- [%s]\n",buffer);

	//size
	long size;
	fscanf(fp, "%ld",&size);
	//printf("size [%s]:%ld\n",buffer,size);

	long value;
	long i = 0;
	//long *aux = (long*)malloc(size * sizeof(long));
	h_global_array_size = size;
	if(h_global_array!=NULL){
		cudaFreeHost(h_global_array);
	}
	cudaMallocHost((void **) &h_global_array, h_global_array_size*sizeof(long));	
	//h_global_array = (long*)malloc(size * sizeof(long));
	while ( fscanf(fp, "%ld",&value) != EOF ){		
		h_global_array[i] =(long) value;		
		i++;
	}
	fclose(fp);	
	printf("Arquivo carregado para a memoria!\n");
	return 1;
}

__host__ void swap(long *xp, long *yp)
{
    int temp = *xp;
    *xp = *yp;
    *yp = temp;
}

__host__ void sequencial_bubble_sort(long *arr,  long n)
{
   long i, j;
   for (i = 0; i < n-1; i++){ 
  
       // Last i elements are already in place   
       for (j = 0; j < n-i-1; j++) {
           if (arr[j] > arr[j+1]){
				swap(&arr[j], &arr[j+1]);			
		   }
	   }
	}
              
}


__host__ double omp_bubble_sort(long *arr,  long n){
	long i=0, j=0; 
	long first;
	double start,end;
	start=omp_get_wtime();
	int thr;
	thr = h_global_array_size/2;
	if(h_global_array_size*2>16){
		thr = 16;
	}
	omp_set_num_threads(thr);
	for( i = 0; i < n-1; i++ )
	{
		first = i % 2; 
		#pragma omp parallel for default(none),shared(arr,first,n)
		for( j = first; j < n-1; j += 1 )
		{
			if( arr[ j ] > arr[ j+1 ] )
			{				
				swap( &arr[ j ], &arr[ j+1 ] );
			}
		}
	}
	end=omp_get_wtime();
	return end -start;
}


__host__ void cpu_merge(){

	while(h_global_nr_part>1 ){		
		int count=0;				
		for(int part =0;part<h_global_nr_part;part+=2){			
			int idT = omp_get_thread_num();
			//printf("Thread[%d] mesclando %d e %d\n",idT, part,part+1);
			Data aux_1;
			Data aux_2;
			
			aux_1 = h_global_part[part];
			if(h_global_nr_part%2!=0 && part==h_global_nr_part-1){
				//copia;
				h_global_part[count] =aux_1;
			}else{
				//aux_1 = h_global_part[part];
				aux_2 = h_global_part[part+1];												
				host_intercala(aux_1.a,aux_2.a,aux_2.b+1,&h_global_array[0]);
				Data result;
				result.a=aux_1.a;
				result.b=aux_2.b;
				result.n=aux_1.n+aux_2.n;				
				h_global_part[count] = result;
			}
			count++;
		}						
		h_global_nr_part = ceil((double)h_global_nr_part/(double)2);				
	}
	
}