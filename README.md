# trabalho-cuda
O presente trabalho busca resolver o problema de ordenação de números utilizando programação paralela com cuda.
O objetivo é escolher um algorítimo de ordenação e fazer as mudanças necessárias para que seu desempenho seja otmizado.

A implementação foi feita da seguinte forma:

    1. É passado um arquivo de tamanho indefinido ao programa contendo uma lista de números do tipo inteiro;
    2. O programa faz uma iteração nesse arquivo colocando na memória;
    3. O espaço e colocado da memória do computador na memória da placa de vídeo;
    4. Esse array é particionado de acordo com a capacidade de CUDA cores;
    5. Cada CUDA core recebe uma parte do array que será ordenado individualmente;
    6. É feito um merge de todas as partições ordenadas individualmente;
    7. O array ordenado é gravado em um arquivo auxiliar;
    8. O programa realiza a proxima iteração sobre o arquivo de entrada;
    9. É retornado ao passo 3 até que todo o arquivo de entrada seja iterado;
    10. É feito o merge entre todos os arquivos auxiliares em um arquivo ordenado.
    
