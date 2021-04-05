chmod +x compile.sh

Para compilar execute 
	./compile.sh

Para rodar o programa execute
	./main <nrTreads> <entrada.map>

Caso não tenha um arquivo de entrada gere um utilizando o comando

	./main <nrTreads> <entrada.map> <size_arquivo>

Exemplo de um arquivo criado com 10 mil numeros aleatórios ordenados por 100 threads

	./main 100 teste.map 10000
	ou
	./main 100 chaos_1.map
	./main 200 chaos_2.map

O algoritimo sequencial desenvolvido é o bubble sort, portanto caso escolha uma entrada muito grande 
pode demorar para calcular.

(OBS) não consegui fazer o Makefile para compilar cuda e open mp juntos