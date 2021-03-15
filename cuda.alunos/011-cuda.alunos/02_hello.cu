#include <stdio.h>

// declaração de uma constante (compartilhada c/ somente leitura c/ todas as threads)
__device__ const char *STR = "HELLO WORLD!";
const char STR_LENGTH = 12;

// GPU: Função imprime um letra por fluxo de execução.
__global__ void hello()
{
	printf("%c", STR[threadIdx.x % STR_LENGTH]);
}

// CPU: Função principal
int main (int argc, char ** argv) { 
	int nthreads = 12;
	int nblocos = 1;

	if (argc == 3) {
		nblocos = atoi(argv[1]);
		nthreads = atoi(argv[2]);
	} else {
                printf ("\n ############# \n");
		printf ("./02_hello <nblocos> <nthreads>\n");
		printf ("Caso não haja passagem de parâmetros, atribuiu-se:\n(1) nblocos c/ 1 e nthreads definido c/ 12\n");
	}

        // Função que será executada em GPU
        // Parâmetros do kernel (número de blocos e número de threads)
        // A função não recebe parâmetros
	hello<<<nblocos,nthreads>>>();

	// Sincronização das threads
	cudaDeviceSynchronize();
	printf("\n");

	return 0;
}
