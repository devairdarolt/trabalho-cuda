typedef struct Data{
	long a;
	long b;
	long n;
}Data;





////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// --- FUNÇÕES PÚBLICAS                                                                                                               //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

extern __global__ void KERNEL_set_globals(long *vet_d, long vet_size,long nthreads);

extern __global__ void KERNEL_reset();

extern __global__ void KERNEL_print_array();

extern __global__ void KERNEL_call_sort (long nthreads); 

extern __global__ void KERNEL_merge (long nr_thread); 

extern __global__ void KERNEL_get_nr_partitions(long *d_nr_part);


extern __global__ void KERNEL_get_array_partitions(Data *d_part);

extern __global__ void KERNEL_get_global_array(long *d_vet);

extern __host__ double wtime();

extern __host__ long *criar_vetor_desordenado(long vet_size);

extern __host__ void vet_imprimir(long *v,long vet_size);



extern __host__ void HOST_merge (long nr_thread); 

extern __host__ void HOST_merge_work (long nr_thread,long x);

extern __host__ void host_print_erro(const char *func,const char *msg);

extern __host__ void host_print_sucess(const char *func,const char *msg);

extern __host__ int h_is_sort(long * arr,long n);


