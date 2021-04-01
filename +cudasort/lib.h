typedef struct Data{
	long a;
	long b;
	long n;
}Data;





////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// --- FUNÇÕES PÚBLICAS                                                                                                               //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

extern __global__ void GPU_set_globals(long *vet_d, long vet_size,long nthreads);

extern __global__ void GPU_reset();

extern __global__ void GPU_print();

extern __global__ void GPU_call_sort (long nthreads); 



extern __host__ double wtime();

extern __host__ long *criar_vetor_desordenado(long *v,long vet_size);

extern __host__ void vet_imprimir(long *v,long vet_size);

extern __global__ void GPU_merge (long nr_thread); 

extern __host__ void GPU_get_nr_part();

extern __host__ void HOST_merge (long nr_thread); 

extern __host__ void HOST_merge_work (long nr_thread,long x);

extern __host__ void h_print_erro(const char *func,const char *msg);

extern __host__ void h_print_sucess(const char *func,const char *msg);

extern __host__ int h_is_sort(long * arr,long n);


extern __global__ void GPU_get_nr_part(long *d_nr_part);

extern __global__ void GPU_get_d_part(Data *d_part);

extern __global__ void GPU_get_global_vet(long * d_vet);
