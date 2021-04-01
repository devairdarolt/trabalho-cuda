#ifndef  EXTERN
#define  EXTERN  extern
#endif

extern long h_global_nr_part;   //Tamanho do array de particoes;
//extern Data * h_global_part=NULL; //Array global para guardar os índices de partições préordenadas

//extern long * h_global_vet_device=NULL; //Array global para guardar o vetor a ser ordenado
//extern long h_global_size_vet=0;
//extern long h_global_nr_nucleos=0;

typedef struct Data{
	long a;
	long b;
	long n;
}Data;


//Data * h_global_part=NULL; //Array global para guardar os índices de partições préordenadas
//long h_global_nr_part=0;   //Tamanho do array de particoes;
//long * h_global_vet_device=NULL; //Array global para guardar o vetor a ser ordenado
//long h_global_size_vet=0;
//long h_global_nr_nucleos=0;



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// --- FUNÇÕES PÚBLICAS                                                                                                               //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

extern __global__ void GPU_set_globals(long *vet_d, long vet_size,long nthreads);

extern __global__ void GPU_reset();

extern __global__ void GPU_print();

extern __global__ void GPU_call_sort (long nthreads); 

extern __global__ void GPU_get_nr_partitions(long *d_nr_part);

extern __host__ double wtime();

extern __host__ long *criar_vetor_desordenado(long *v,long vet_size);

extern __host__ void vet_imprimir(long *v,long vet_size);

extern __global__ void GPU_merge (long nr_thread); 

extern __host__ void cpyGlobalsFromGpu();

extern __host__ void HOST_merge (long nr_thread); 

