#include <cuda.h>
#include <stdio.h>

#define mega 1048576

__global__ void fdcalc(int n)
{
   long n1 = 0;

    for (int j=0; j < 100000; j++) {
      for(int i=2; i < n; ++i) {
         n1=pow(n1,i);
         //n1=n1*i; (GF 730)
       }
     }
}

// função principal executada iniciada em CPU
int main(int argc, char const *argv[]) {
  unsigned long *dev_a;
  unsigned long *dev_b;
  unsigned long *dev_c;
  unsigned long *dev_d;
  unsigned long *dev_e;
  unsigned long *dev_f;
  int error=0;
  int i=0, mem=0, mem2=0;


  if (argc == 3) {
     mem = atoi(argv[1]);
     mem2 = atoi(argv[2]);
  } else {
     printf ("./06_mem <mem_contigua> <mem_N_contigua>`\n");
     printf ("Titan = ./06_mem 2040 12000\n");
     printf ("730   = ./06_mem 1930 1970\n");
     exit(1);
  }

  printf ("\n #####  ##### \n Alocação de Memória Global\n");
  i = mem;
  while (!error) {
     // alocação de memória na GPU 
     error = cudaMalloc ((void **) &dev_a, mega*i);
     printf ("\t cudaMalloc (%d MB)\tError Status %d\n", i, error);
     fdcalc <<<1,1>>>(20);
     cudaDeviceSynchronize();
     cudaFree(dev_a);
     i+=10;
  }

  printf ("\n #####  ##### \n Alocação de Memória Global\n");
  error=0;
  i = (int)mem2/6;
  while (!error) {
     // alocação de memória na GPU 
     error = cudaMalloc ((void **) &dev_a, mega*i);
     error = cudaMalloc ((void **) &dev_b, mega*i);
     error = cudaMalloc ((void **) &dev_c, mega*i);
     error = cudaMalloc ((void **) &dev_d, mega*i);
     error = cudaMalloc ((void **) &dev_e, mega*i);
     error = cudaMalloc ((void **) &dev_f, mega*i);
     printf ("\t cudaMalloc (%d MB)\tError Status %d\n", i*6, error);
     fdcalc <<<1,1>>>(20);
     cudaDeviceSynchronize();
     cudaFree(dev_a);
     cudaFree(dev_b);
     cudaFree(dev_c);
     cudaFree(dev_d);
     cudaFree(dev_e);
     cudaFree(dev_f);
     i+=10;
  }
  printf("\n");

  return 0;
}
