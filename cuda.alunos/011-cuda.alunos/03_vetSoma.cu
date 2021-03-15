#include <cuda.h>
#include <stdio.h>

#define N 32

// função executada na GPU
__global__ void vecAdd (int *Da, int *Db, int *Dc) {
   int i = threadIdx.x;
   Dc[i] = Da[i] + Db[i];
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
  for (int i=0; i < N; i++)
    printf("\t [%d] \t %d\t %d\t %d\n", i, a[i], b[i], c[i]);
}

// função principal executada iniciada em CPU
int main(int argc, char const *argv[]) {
  int *a, *b, *c;
  int *dev_a, *dev_b, *dev_c;
  int size;

  size = sizeof(int)*N;
  
  // alocação de memória no HOST para os vetores (a,b e c)
  // a = (int *) malloc (size);
  b = (int *) malloc (size);
  // c = (int *) malloc (size);
  cudaMallocHost((void **) &a, size);
  // cudaMallocHost((void **) &b, size);
  cudaMallocHost((void **) &c, size);

  // Inicialização dos vetores
  initvet(a,b);

  // alocação de memória na GPU para os vetores (a,b e c)
  cudaMalloc ((void **) &dev_a, size);
  cudaMalloc ((void **) &dev_b, size);
  cudaMalloc ((void **) &dev_c, size);

  // cópia dos vetores gerados em CPU p/ memória da GPU
  cudaMemcpy (dev_a, a, size, cudaMemcpyHostToDevice);
  cudaMemcpy (dev_b, b, size, cudaMemcpyHostToDevice);

  // execução do kernel vecAdd em GPU.
  vecAdd<<<1,N>>>(dev_a, dev_b, dev_c);

  // cópia do vetor de resultado calculado em GPU p/ memória do HOST
  cudaMemcpy (c, dev_c, size, cudaMemcpyDeviceToHost);

  // impressão dos vetores
  printvetores (a, b, c);
  printf ("\n **** \n Nro Threads = %d\n Nro de Blocos = 1\n", N);

  // Libera memória da GPU
  cudaFree(dev_a);
  cudaFree(dev_b);
  cudaFree(dev_c);

  // Libera memória no HOST
  cudaFreeHost(a);
  cudaFreeHost(b);
  cudaFreeHost(c);

  return 0;
}
