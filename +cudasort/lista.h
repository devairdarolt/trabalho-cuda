#define ERRO_LISTA_VAZIA -0;
#define ERRO_POSICAO_INVALIDA -2;

typedef struct Node{
	void *data;
	struct Node *privious,*next;
}Node;

typedef struct {
	int sizeof_data;
	Node *root;
}Lista;

extern __device__ Lista list_init(int t);
//extern __device__ void list_init(Lista *l,int t);
extern __device__ int list_is_empty(Lista l);
extern __device__ int list_get_position(Lista *l,void *data,int pos);
extern __device__ int list_push_first(Lista *l,void *data);
extern __device__ int list_pop_first(Lista *l, void *data);
extern __device__ int list_push_last(Lista *l,void *data);
extern __device__ int list_pop_last(Lista *l,void * data);
