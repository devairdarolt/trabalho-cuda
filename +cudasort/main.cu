#include "lib.h"

#include <cuda.h>
#include <stdio.h>
#include <math.h>

#include <omp.h>



extern long h_global_nr_part;   //Tamanho do array de particoes;
//Data * h_global_part=NULL; //Array global para guardar os índices de partições préordenadas
//long h_global_nr_part=0;   //Tamanho do array de particoes;
//long * h_global_vet_device=NULL; //Array global para guardar o vetor a ser ordenado
//long h_global_size_vet=0;
//long h_global_nr_nucleos=0;



int main (int argc, char ** argv) {
	long nthreads = 96;
	//long nblocos = 1;
	long vet_size = 100000000; //762.939453

	
	if (argc == 3) {
		nthreads = atoi(argv[1]);
		vet_size = atoi(argv[2]);
	}else{
		printf ("./main <nthreads> <vet_size>\n");
		printf ("Caso não haja passagem de parâmetros, nthreads=%ld e vet_size=%ld\n",nthreads,vet_size);
	} 
	printf("Ordenando %3ld Kbytes\n",(vet_size*4)/1024);
	//vetores do host	
	long *host_vet=NULL;
	host_vet = criar_vetor_desordenado(host_vet,vet_size);//aloca vetor em host
	
	//printf("Vetor desordenado\n");
	printf("Teste imprimir..\n");
	vet_imprimir(host_vet,vet_size); 

	

	long *dev_vet =NULL;
	int erro = cudaMalloc((void**)&dev_vet,vet_size * sizeof(long));// aloca vetor na memória global da placa
	if(erro){
		printf("\033[0;31m Erro ao alocar memória da placa de video...\n \e[m");
	}
	printf("Dados copiados para a placa de video %3f MB\n",(double)(vet_size*sizeof(long))/1024/1024);
	cudaMemcpy (dev_vet, host_vet, vet_size*sizeof(long), cudaMemcpyHostToDevice);
	
	//Cada CUDA core ordena uma partição de DEV_VET
	//resulta em um único vetor de partições ordenadas
	double s_time = wtime();	
		
	
	GPU_set_globals<<<1,1>>>(dev_vet, vet_size,nthreads);		
	cudaDeviceSynchronize();
	
	//printf("Teste de copia vetor grande..n:%ld\n",vet_size);
	//GPU_print<<<1,1>>>();
	//cudaDeviceSynchronize();	
	
	GPU_call_sort<<<1,nthreads>>>(nthreads);	
	cudaDeviceSynchronize();	
	GPU_print<<<1,1>>>();
	cudaDeviceSynchronize();

	//MODO 1 - realiza o merge usando os cuda cores
	/*************  UTILIZA MUITA MEMÓRIA DA PLACA DE VÍDEO
	while(nthreads>1){
		
		nthreads = ceil((double)nthreads/(double)2);		
		GPU_merge<<<1,nthreads>>>(nthreads);	
		cudaDeviceSynchronize();
		//printf("\n\n\nPos GPU_merge\n");
		//GPU_print<<<1,1>>>();
		//cudaDeviceSynchronize();
	}		
	/**/

	// MODO 2 - realiza o merge utilizando openMP
	///////////// 
	
	cpyGlobalsFromGpu();

	//printf("h_global_nr_part:%ld\n",h_global_nr_part);
	nthreads =100;
	while(nthreads>1){		
		nthreads = ceil((double)nthreads/(double)2);		
		HOST_merge(nthreads);
		

	}
	/////////////


	double e_time = wtime();
	printf("Time:%f (s)\n", e_time-s_time);
	
	printf("\nOpercacao finalizada\n");
	GPU_print<<<1,1>>>();
	cudaDeviceSynchronize();
	
	//free(host_vet);
	GPU_reset<<<1,1>>>();


	//TESTE DO OpenMP
	/****************
	printf("____________________________________________________________________________________\n");
	omp_set_num_threads(100);
	int omp_id;
	int omp_n = omp_get_num_threads();
	printf("omp_n:%d\n",omp_id);
	#pragma omp parallel for
	for(int i=0;i<100;i++){
		omp_id = omp_get_thread_num();
		printf("sou omp:%d\n",omp_id);

	}
	printf("____________________________________________________________________________________\n");
	*/
	return 0;
}
__host__ void HOST_merge (long nr_thread){
	int omp_id; 
	omp_set_num_threads(nr_thread); 	// basicamente simula como o merge da placa de video, para usar a mesma logica
	#pragma omp parallel for
	for(int x=0;x<nr_thread;x++){  	// 
		omp_id = omp_get_thread_num();
		printf("x:%d th:%d\n",x,omp_id);
	}
	printf("\n");
}


__host__ void HOST_merge (long nr_thread,long x){
	
	//printf("[GPU_merge]\n");
	//if(x!=0)return;
	// |0..3|4..7|||8..9|
	//    0    1     2       3         4
	//    ______     __________      _____ 
	//x:     0           1             2
	
	/*long a1 = global_part[x*2].a;
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
		printf("\033[0;34m x[%ld]-{(a1:%ld,b1:%ld),(a2:%ld,b2:%ld)- merge----{a1:%ld,b2:%ld} - n:%ld}\e[m\n",x,a1,b1,a2,b2,xData->a,xData->b,xData->n);		
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
		printf("Part[%ld]-{(%ld,%ld) n:%ld- copiado}\n",x,a1,b1,xData->n);		
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
	*/		
}