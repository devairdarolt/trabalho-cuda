#include <cuda.h>
#include <stdio.h>
#include <math.h>
#include <sys/time.h>


extern __global__ void GPU_sort (int *vet_d, int vet_size,int nthreads); 

//extern __device__ int radix_sort(int x);

extern __host__ double wtime();


extern __host__ int *criar_vetor_desordenado(int *v,int vet_size);

extern __host__ void vet_imprimir(int *v,int vet_size);

