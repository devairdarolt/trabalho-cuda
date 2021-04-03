
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
long *h_global_vet_device; //Array global para guardar o vetor a ser ordenado
long h_global_size_vet;
long h_global_nr_nucleos;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// --- FUNÇÕES DO HOST                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

__host__ void h_intercala (long p, long q, long r, long *v);

__host__ void h_print_erro(const char *func,const char *msg);

__host__ void h_print_sucess(const char *func,const char *msg);

__host__ void host_get_global_vet();

__host__ void get_global_nr_part();

__host__ void get_global_part();

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// --- FUNÇÕES DE ARQUIVO                                                                                                             //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

__host__ int criar_arquivo(char *nome);

__host__ int read_file(char *nome);





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
	char nome[] = "teste.map";
	

	
	if (argc == 3 ||argc == 4) {
		nthreads = atoi(argv[1]);
		strcpy(nome,argv[2]);
		if(argc == 4){
			h_global_size_vet = atoi(argv[3]);	
			criar_arquivo(nome);
		}
		//nome = argv[2];
		//h_global_size_vet = atoi(argv[2]);
	}else{
		printf ("./main <nthreads> <fileName> --- faz a leitura do arquivo de entrada\n");
		printf ("./main <nthreads> <fileName> <size>--- cria um arquivo de leitura com tamanho size.\n");
		return 0;
	} 
	
	read_file(nome);


	printf("Ordenando vetor de %ld elementos long - %f Kbytes\n",h_global_size_vet,((double)h_global_size_vet*sizeof(long))/(double)1024);	
	//h_global_vet_device =criar_vetor_desordenado(h_global_size_vet);//aloca vetor em host	
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
	
	GPU_call_sort<<<1,nthreads>>>(nthreads);	
	cudaDeviceSynchronize();	
	double g_time = wtime();	
	h_print_sucess("GPU_call_sort","GPU sort finalizado");
	printf("Tempo levado para ordenar as sub particoes na GPU[%f]\n",g_time-s_time);
	
	
	//Copia as variaveis globais da placa para a memoria do host	
	get_global_nr_part();
	get_global_part();
	host_get_global_vet();

	
	
	
	while(h_global_nr_part>1 ){		
		int count=0;
		omp_set_num_threads(1);//Cria uma thread para cada par de particao, o escalonador que se lasque!
		//printf("\n\n");
		#pragma omp parallel for shared(count,h_global_part,h_global_vet_device)		
		for(int part =0;part<h_global_nr_part;part+=2){			
			int idT = omp_get_thread_num();
			//printf("Thread[%d] mesclando %d e %d\n",idT, part,part+1);
			Data aux_1;
			Data aux_2;
			
			aux_1 = h_global_part[part];
			if(h_global_nr_part%2!=0 && part==h_global_nr_part-1){
				h_global_part[count] =aux_1;
				//printf("%d [%ld -- %ld][%ld] -- cpiado\n",idT,aux_1.a,aux_1.b,aux_1.n);
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
	//cudaFree(dev_vet);
	if(h_global_part!=NULL){
		printf("free h_global_part\n");
		//cudaFreeHost(h_global_part);
		//free(h_global_part);
	}
	if(h_global_vet_device!=NULL){
		printf("free h_global_vet_device\n");
		//cudaFreeHost(h_global_vet_device);
		//free(h_global_vet_device);
	}

	return 0;
}
__host__ void h_intercala (long p, long q, long r, long *v) 
{
   long *w;     
   //printf("p:%ld,r:%ld\nalocando r-p:%ld\n",p,r,r-p);                            //  1
   w =(long *)calloc(r-p,sizeof(long));  //  2
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

__host__ void host_get_global_vet(){
	/* if(h_global_vet_device!=NULL){
		cudaMallocHost((void **)&h_global_vet_device,h_global_size_vet*sizeof(long));	
	} */
	if(h_global_vet_device==NULL){		
		h_print_erro("host_get_global_vet","Erro ao alocar d_vet");
	}	
	GPU_get_global_vet<<<1,1>>>(h_global_vet_device);	
	cudaDeviceSynchronize();	
	printf("h_global_vet_device[0] %ld\n ",h_global_vet_device[0]);
	
}

__host__ void get_global_nr_part(){
	long *d_nr_part;
	cudaMalloc((void**)&d_nr_part,sizeof(long));	
	GPU_get_nr_part<<<1,1>>>(d_nr_part);
	cudaDeviceSynchronize();
	cudaMemcpy(&h_global_nr_part,d_nr_part,sizeof(long),cudaMemcpyDeviceToHost);
	//printf("h_global_nr_part %ld\n",h_global_nr_part);
}

__host__ void get_global_part(){
	if(h_global_part!=NULL){
		cudaFreeHost(h_global_part);
	}
	cudaMallocHost((void**)&h_global_part,h_global_nr_part* sizeof(Data));
	if(h_global_part==NULL){
		printf("Erro ao alocar h_global_part\n");
	}
	GPU_get_d_part<<<1,1>>>(h_global_part);
	cudaDeviceSynchronize();
	//copia o vetor de particoes da placa de video para o host
	//cudaMemcpy(&h_global_part[0],&d_part[0],h_global_nr_part * sizeof(Data),cudaMemcpyDeviceToHost);	
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// --- FUNÇÕES DE ARQUIVOS                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

__host__ int criar_arquivo(char *nome){

	FILE *fp;

	printf("Abrindo arquivo.\n");
	if((fp = fopen(nome,"w")) == NULL){		
		h_print_erro("criar_arquivo","Erro na abertura do arquivo");
		return 0;
	}
	long val;
	char buffer[10] = "#size";
	fprintf(fp, "%s\n", buffer);
	fprintf(fp, "%ld\n", h_global_size_vet);

	for(int i=0; i<h_global_size_vet;i++){
		val  = rand() % 1000;// (0 <= rand <= n)
		fprintf(fp, "%ld\n",val);// escreve o numero separado por ','
	}
	printf("Arquivo gerado!\n");
	fclose(fp);
	return 1;
}

__host__ int read_file(char *nome){
	FILE *fp;

	printf("Abrindo arquivo.\n");
	if((fp = fopen(nome,"r")) == NULL){		
		h_print_erro("read_file","Erro na leitura do arquivo");
		return 0;
	}
	
	//header
	char buffer[10];
	fscanf(fp, "%s",buffer);
	printf("-- [%s]\n",buffer);

	//size
	long size;
	fscanf(fp, "%ld",&size);
	printf("size [%s]:%ld\n",buffer,size);

	long value;
	long i = 0;
	//long *aux = (long*)malloc(size * sizeof(long));
	h_global_size_vet = size;
	cudaMallocHost((void **) &h_global_vet_device, h_global_size_vet*sizeof(long));	
	//h_global_vet_device = (long*)malloc(size * sizeof(long));
	while ( fscanf(fp, "%ld",&value) != EOF ){		
		h_global_vet_device[i] =(long) value;		
		i++;
	}
	fclose(fp);	
	return 1;
}

