#include <stdio.h>
#include <time.h>
#include <sys/time.h>

// GPU: Impressão dos índices 
__global__ void fIndice() {

   printf ("%d\t%d\t%d\n", threadIdx.x, blockIdx.x, blockDim.x);
}

// CPU: Função principal
int main (int argc, char ** argv) { 
       int nblocos = 0;
       int nthreads = 0;

       // Tratamento dos paramêtros
	if (argc == 3) {
		nblocos = atoi(argv[1]);
		nthreads = atoi(argv[2]);
	} else {
                printf ("\n ############# \n");
		printf ("./07_kernel <nblocos> <nthreads>\n");
		printf ("./07_kernel 32 128  | sort -n | tail -32\n");
		exit(1);
	}

        // Limite bloco 1024, limite de thread 1024
        // Limite MAX (bloco * thread) = 4096 
	fIndice<<<nblocos,nthreads>>>();
	cudaDeviceSynchronize();
        printf ("threadIdx.x blockIdx.x blockDim.x\n");

	return 0;
}
