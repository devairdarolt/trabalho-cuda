#include <cuda.h>
#include <stdio.h>
#include <math.h>

// valores compatíveis devem ter sqrt(N) inteiro (ex.: sqrt(4), sqrt(9), srqt(16), srqt (25)
#define N 4 // Número de linhas de uma matriz quadrada!
            // Número de colunas = número de linhas (matriz quadrada)

// Uma thread por posição da matriz
// Alocação da matriz em bloco contíguo de memória (um vetor N*N)
// Acesso com índices de matrizes (i,j), sendo i=linha e j=coluna
// sqrt(N) é o número de blocos
// sqrt(N) é o número de threads por bloco
// Ex.: Para N=4, tem-se 4 linhas e 4 colunas, totalizando 16 elementos
//      2 blocos c/ 2 threads cada para x (0,1,2,3)
__global__ void matAdd (int *da, int *db, int *dc) {
   int i = blockIdx.x * blockDim.x + threadIdx.x;
   int j = blockIdx.y * blockDim.y + threadIdx.y;

   printf ("[%d][%d]=%d\t(x)\t%d\t%d\t%d\t(y)\t%d\t%d\t%d\n", \\
           i,j,(i*N+j), threadIdx.x, blockIdx.x, blockDim.x, \\
           threadIdx.y, blockIdx.y, blockDim.y);

   dc[i*N+j] = da[i*N+j] + db[i*N+j];
}

// função executada na GPU
__global__ void vecAdd (int *da, int *db, int *dc) {
   int i = blockIdx.x * blockDim.x + threadIdx.x;

   //printf ("x=(%d)\t%d\t%d\t%d\n", i, threadIdx.x, blockIdx.x, blockDim.x);

   if (i < (N*N)) {
     dc[i] = da[i] + db[i];
   }
}

// função executada na CPU
__host__ void initvet(int *host_a, int *host_b) {
  // Inicialização dos vetores a e b
  for (int i=0; i < N; i++) {
    for (int j=0; j < N; j++) {
       host_b[i*N+j] = (i+j)+((N-1)*i);
       host_a[i*N+j] = (N*N)-host_b[i*N+j];
    }
  }
}

// função executada na CPU
__host__ void printvetores (int *a, int *b, int *c) {
  printf("\t [l,c] \t A\t B\t C\t \n");
  for (int i=0; i < N; i++) {
    for (int j=0; j < N; j++) { 
      // if (((i % 10) == 0) && ((j%10) == 0)) 
      printf("\t [%d,%d] \t %d\t %d\t %d\n", i, j, a[i*N+j], b[i*N+j], c[i*N+j]);
    }
  }
}

// função principal executada iniciada em CPU
int main(int argc, char const *argv[]) {
  int *a, *b, *c;
  int *dev_a, *dev_b, *dev_c;
  int size;

  // Alocação de matriz quadrada
  size = N * N * sizeof(int);

  // Alocação de memória na CPU
  cudaMallocHost((void **) &a, size);
  cudaMallocHost((void **) &b, size);
  cudaMallocHost((void **) &c, size);
  
  // Inicialização dos vetores
  initvet(a,b);

  // Alocação de memória na GPU para os vetores (a,b e c)
  cudaMalloc ((void **) &dev_a, size);
  cudaMalloc ((void **) &dev_b, size);
  cudaMalloc ((void **) &dev_c, size);

  // Cópia dos vetores gerados em CPU p/ memória da GPU
  cudaMemcpy (dev_a, a, size, cudaMemcpyHostToDevice);
  cudaMemcpy (dev_b, b, size, cudaMemcpyHostToDevice);

  // Número de linhas/colunas por bloco
  dim3 dimGrid ((int) sqrt(N), (int) sqrt(N)); 
  dim3 dimBlock((int) sqrt(N), (int) sqrt(N)); 

  // GPU: Processamento do kernel matAdd
  //      Uso dos índices como matriz
  printf ("[i][j]=(i*N+j) (x)threadIdx.x blockIdx.x blockDim.x (y)threadIdx.y blockIdx.y blockDim.y\n");
  matAdd<<< dimGrid, dimBlock>>>(dev_a, dev_b, dev_c);
  cudaDeviceSynchronize();

  // Cópia do vetor (c) da GPU p/ CPU
  cudaMemcpy (c, dev_c, size, cudaMemcpyDeviceToHost);

  // Impressão dos vetores
  printf ("\t ##### #####       ##### ##### \n");
  printvetores (a, b, c);
  printf ("\t ##### #####       ##### ##### \n");


  // GPU: Processamento do kernel vecAdd 
  //      Soma c/ índices formato de vetor
  vecAdd<<<N, N>>>(dev_a, dev_b, dev_c);

  // Cópia do vetor (c) da GPU p/ CPU
  cudaMemcpy (c, dev_c, size, cudaMemcpyDeviceToHost);

  // Impressão dos vetores
  printvetores (a, b, c);
  printf ("\t ##### #####       ##### ##### \n");

  // Liberação de memória GPU
  cudaFree(dev_a);
  cudaFree(dev_b);
  cudaFree(dev_c);

  // Liberação de memória CPU
  cudaFreeHost(a);
  cudaFreeHost(b);
  cudaFreeHost(c);

  return 0;
}
