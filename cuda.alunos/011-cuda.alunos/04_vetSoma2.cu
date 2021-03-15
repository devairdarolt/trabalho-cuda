#include <cuda.h>
#include <stdio.h>
#include <math.h>

#define N 2048
#define T 1024 // numero max de threads por bloco

// função executada na GPU
__global__ void vecAdd (int *da, int *db, int *dc) {
   int i = blockIdx.x * blockDim.x + threadIdx.x;
   if (i < N) {
     dc[i] = da[i] + db[i];
   }
}

// função executada na CPU
__host__ void initvet(int *host_a, int *host_b) {
  // Inicialização dos vetores a e b
  for (int i=0; i < N; i++) {
    host_a[i] = N-i;
    host_b[i] = i;
  }
}

// função executada na CPU
__host__ void printvetores (int *a, int *b, int *c) {
  printf("\t [i] \t A\t B\t C\t \n");
  for (int i=0; i < N; i++) {
    if ((i % 100) == 0)
      printf("\t [%d] \t %d\t %d\t %d\n", i, a[i], b[i], c[i]);
  }
}

// função principal executada iniciada em CPU
int main(int argc, char const *argv[]) {
  int *a, *b, *c;
  int *dev_a, *dev_b, *dev_c;
  int size;

  size = N * sizeof(int);

  // Inicialização dos vetores
  cudaMallocHost((void **) &a, size);
  cudaMallocHost((void **) &b, size);
  initvet(a,b);

  // alocação de memória na GPU para os vetores (a,b e c)
  cudaMalloc ((void **) &dev_a, size);
  cudaMalloc ((void **) &dev_b, size);
  cudaMalloc ((void **) &dev_c, size);

  // cópia dos vetores gerados em CPU p/ memória da GPU
  cudaMemcpy (dev_a, a, size, cudaMemcpyHostToDevice);
  cudaMemcpy (dev_b, b, size, cudaMemcpyHostToDevice);

  // execução do kernel vecAdd em GPU.
  vecAdd<<<(int)ceil(N/T),T>>>(dev_a, dev_b, dev_c);

  cudaMallocHost((void **) &c, size);
  cudaMemcpy (c, dev_c, size, cudaMemcpyDeviceToHost);
  printvetores (a, b, c);
  printf ("\n **** \n Nro Threads = %d\n Nro Max por Bloco = %d\n Nro de Blocos = %d\n", N, T, (int) ceil(N/T));

  cudaFree(dev_a);
  cudaFree(dev_b);
  cudaFree(dev_c);

  cudaFreeHost(a);
  cudaFreeHost(b);
  cudaFreeHost(c);

  return 0;
}
