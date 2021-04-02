
#include "lib.h"

#include <cuda.h>
#include <stdio.h>
#include <math.h>

#include <omp.h>

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// --- VARIÁVEIS GLOBAIS DO HOST                                                                                                      //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


long h_global_nr_part;   //Tamanho do array de particoes;
Data * h_global_part; //Array global para guardar os índices de partições préordenadas
long * h_global_vet_device; //Array global para guardar o vetor a ser ordenado
long h_global_size_vet;
long h_global_nr_nucleos;

void h_intercala (long p, long q, long r, long *v);

void h_print_erro(const char *func,const char *msg);

void h_print_sucess(const char *func,const char *msg);


void get_global_vet(){
	
	cudaMallocHost((void **)&h_global_vet_device,h_global_size_vet*sizeof(long));
	
	if(h_global_vet_device==NULL){		
		h_print_erro("get_global_vet","Erro ao alocar d_vet");
	}
	
	GPU_get_global_vet<<<1,1>>>(h_global_vet_device);	
	cudaDeviceSynchronize();
	

	printf("h_global_vet_device[0] %ld\n ",h_global_vet_device[0]);
	
}

void get_global_nr_part(){
	long *d_nr_part;
	cudaMalloc((void**)&d_nr_part,sizeof(long));	
	GPU_get_nr_part<<<1,1>>>(d_nr_part);
	cudaDeviceSynchronize();
	cudaMemcpy(&h_global_nr_part,d_nr_part,sizeof(long),cudaMemcpyDeviceToHost);
	//printf("h_global_nr_part %ld\n",h_global_nr_part);
}
void get_global_part(){
	Data *d_part;
	cudaMalloc((void**)&d_part,h_global_nr_part* sizeof(Data));

	if(d_part==NULL){
		printf("Erro ao alocar d_part\n");
	}
	cudaMallocHost((void**)&h_global_part,h_global_nr_part* sizeof(Data));
	if(h_global_part==NULL){
		printf("Erro ao alocar h_global_part\n");
	}

	GPU_get_d_part<<<1,1>>>(d_part);
	cudaDeviceSynchronize();
	//copia o vetor de particoes da placa de video para o host
	cudaMemcpy(&h_global_part[0],&d_part[0],h_global_nr_part * sizeof(Data),cudaMemcpyDeviceToHost);	
}

int main (int argc, char ** argv) {
	//INICIALIZA VARIAVEIS GLOBIAS
	h_global_nr_part=0;   //Tamanho do array de particoes;
	h_global_part=NULL; //Array global para guardar os índices de partições préordenadas
	h_global_vet_device=NULL; //Array global para guardar o vetor a ser ordenado
	
	h_global_size_vet=100000;	
	h_global_nr_nucleos=0;
	


	long nthreads = 96;
	h_global_nr_nucleos = nthreads;
	//long nblocos = 1;
	

	
	if (argc == 3) {
		nthreads = atoi(argv[1]);
		h_global_size_vet = atoi(argv[2]);
	}else{
		printf ("./main <nthreads> <h_global_size_vet>\n");
		printf ("Caso não haja passagem de parâmetros, nthreads=%ld e h_global_size_vet=%ld\n",nthreads,h_global_size_vet);
	} 

	 
	printf("Ordenando vetor de %ld elementos long - %3ld Kbytes\n",h_global_size_vet,(h_global_size_vet*8)/1024);
	//vetores do host	
	
	criar_vetor_desordenado(h_global_vet_device,h_global_size_vet);//aloca vetor em host
	
	//printf("Vetor desordenado\n");
	printf("Teste imprimir..\n");
	vet_imprimir(h_global_vet_device,h_global_size_vet); 

	

	long *dev_vet =NULL;
	int erro = cudaMalloc((void**)&dev_vet,h_global_size_vet * sizeof(long));// aloca vetor na memória global da placa
	if(erro){
		printf("\033[0;31m Erro ao alocar memória da placa de video...\n \e[m");
	}
	printf("Dados copiados para a placa de video %3f MB\n",(double)(h_global_size_vet*sizeof(long))/1024/1024);
	cudaMemcpy (dev_vet, h_global_vet_device, h_global_size_vet*sizeof(long), cudaMemcpyHostToDevice);
	
	//Cada CUDA core ordena uma partição de DEV_VET
	//resulta em um único vetor de partições ordenadas
	double s_time = wtime();	
		
	
	GPU_set_globals<<<1,1>>>(dev_vet, h_global_size_vet,nthreads);		
	cudaDeviceSynchronize();
	
	//printf("Teste de copia vetor grande..n:%ld\n",h_global_size_vet);
	//GPU_print<<<1,1>>>();
	//cudaDeviceSynchronize();	
	
	GPU_call_sort<<<1,nthreads>>>(nthreads);	
	cudaDeviceSynchronize();	
	double g_time = wtime();	
	h_print_sucess("GPU_call_sort","GPU sort finalizado");
	printf("Tempo levado para ordenar as sub particoes na GPU[%f]\n",g_time-s_time);
	

	

	// MODO 2 - realiza o merge utilizando openMP
	
	
	//Copia as variaveis globais da placa para a memoria do host
	
	get_global_nr_part();
	get_global_part();
	get_global_vet();

	GPU_reset<<<1,1>>>();		
	
	//for(int test=0;test<2;test++){
	while(h_global_nr_part>1 ){
		//printf("h_global_nr_part:%ld\n",h_global_nr_part);
		//h_global_nr_part = ceil((double)h_global_nr_part/(double)2);				
		//Cada duas particao gera uma nova
		int count=0;
		for(int part =0;part<h_global_nr_part;part+=2){
			Data aux_1;
			Data aux_2;
			
			aux_1 = h_global_part[part];
			if(h_global_nr_part%2!=0 && part==h_global_nr_part-1){
				h_global_part[count] =aux_1;
				//printf("%d [%ld -- %ld][%ld] -- cpiado\n",count,aux_1.a,aux_1.b,aux_1.n);
			}else{
				//aux_1 = h_global_part[part];
				aux_2 = h_global_part[part+1];	
							
				//printf("%d [%ld -- %ld][%ld - %ld][%ld] -- intercalado [%ld -- %ld]\n",count,aux_1.a,aux_1.b,aux_2.a,aux_2.b,aux_1.n+aux_2.n,aux_1.a,aux_2.b);
				h_intercala(aux_1.a,aux_2.a,aux_2.b+1,&h_global_vet_device[0]);
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
	
	printf("\n");
	h_is_sort(h_global_vet_device,h_global_size_vet);
	vet_imprimir(h_global_vet_device,h_global_size_vet);
	printf("\n");
	double e_time = wtime();	
	printf("Tempo total de ordenação:[%f]\n",e_time - s_time);
	
	free(h_global_part);
	free(h_global_vet_device);

	return 0;
}
void h_intercala (long p, long q, long r, long *v) 
{
   long *w;     
   //printf("p:%ld,r:%ld\nalocando r-p:%ld\n",p,r,r-p);                            //  1
   w =(long *)malloc((r-p) * sizeof(long));  //  2
   if(w==NULL){
		h_print_erro("h_intercala","Não foi possivel alocar memoria para w");
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


