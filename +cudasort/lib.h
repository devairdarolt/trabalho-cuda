
typedef struct Data{
	int a;
	int b;
	int n;
}Data;

extern __global__ void GPU_set_globals(int *vet_d, int vet_size,int nthreads);

extern __global__ void GPU_sort (int nthreads); 

extern __global__ void GPU_get_nr_partitions(int *d_nr_part);

extern __global__ void GPU_merge (int nr_thread); 

extern __host__ double wtime();

extern __host__ int *criar_vetor_desordenado(int *v,int vet_size);

extern __host__ void vet_imprimir(int *v,int vet_size);

