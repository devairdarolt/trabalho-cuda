
typedef struct Data{
	long a;
	long b;
	long n;
}Data;

extern __global__ void GPU_set_globals(long *vet_d, long vet_size,long nthreads);

extern __global__ void GPU_reset();

extern __global__ void GPU_print();

extern __global__ void GPU_sort (long nthreads); 

extern __global__ void GPU_get_nr_partitions(long *d_nr_part);

extern __global__ void GPU_merge (long nr_thread); 

extern __host__ double wtime();

extern __host__ long *criar_vetor_desordenado(long *v,long vet_size);

extern __host__ void vet_imprimir(long *v,long vet_size);

