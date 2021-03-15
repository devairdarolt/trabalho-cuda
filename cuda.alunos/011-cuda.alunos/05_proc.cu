#include <stdio.h>
#include <time.h>
#include <sys/time.h>

// CPU: marca o tempo
__host__ double wtime() {
  struct timeval t;
  gettimeofday(&t, NULL);
  return t.tv_sec + (double) t.tv_usec / 1000000;
}

// CPU: Núcleo de execução (processamento)
__host__ void fhcalc(int n)
{
   double v1=0;

    for (int j=0; j < 10000; j++) {
      for(int i=2; i < n; ++i) {
          v1=pow(v1,i);          
       }
     }
}

// GPU: Núcleo de execução (processamento)
__global__ void fdcalc(int n)
{
   double v1=0;

    for (int j=0; j < 10000; j++) {
      for(int i=2; i < n; ++i) {
          v1=pow(v1,i);          
       }
     }
}

// CPU: Função principal
int main (int argc, char ** argv) { 
	int nthreads = 400;
	int nblocos = 1;
	int ncalc = 400;
        double start_time = 0, end_time = 0;

        // Tratamento dos paramêtros
	if (argc == 4) {
		nblocos = atoi(argv[1]);
		nthreads = atoi(argv[2]);
		ncalc = atoi(argv[3]);
	} else {
                printf ("\n ############# \n");
		printf ("./05_proc <nblocos> <nthreads> <nloop>\n");
		printf ("Caso não haja passagem de parâmetros, atribuiu-se:\n(1) nblocos c/ %d, nthreads definido c/ %d e ncalc = %d \n", nblocos, nthreads, ncalc);
	}

        // Mensura o tempo de processamento do kernel em 1 bloco c/ 1 thread
        printf ("\n##### DEVICE (1,1) #####\n");
        start_time = wtime();

        // GPU: Execução do kernel em 1,1
	fdcalc<<<1,1>>>(ncalc);
        
        // CPU: Aguarda a sincronização das threads
	cudaDeviceSynchronize();
        end_time = wtime();
        printf("\n");
        printf("\tRuntime: %f\n", end_time - start_time);

       
        // Mensura o tempo de processamento do kernel c/ n blocos e m threads
        printf ("\n##### DEVICE (%d,%d) #####\n", nblocos, nthreads);
        start_time = wtime();

        // GPU: Execução do kernel em n,m
	fdcalc<<<nblocos,nthreads>>>(ncalc/nthreads);

        // CPU: Aguarda a sincronização das threads
	cudaDeviceSynchronize();
        end_time = wtime();
        printf("\n");
        printf("\tRuntime: %f\n", end_time - start_time);


        // Mensura o tempo de processamento em CPU
        printf ("\n##### HOST #####\n");
        start_time = wtime();
	fhcalc(ncalc);
	cudaDeviceSynchronize();
        end_time = wtime();
        printf("\n");
        printf("\tRuntime: %f\n", end_time - start_time);
	return 0;
}
