#include "lista.h"

#include <cuda.h>
#include <stdio.h>
#include <math.h>
#include <sys/time.h>

__device__ Lista list_init(int t){
    Lista l;
    l.sizeof_data=t;
	l.root=NULL;
    return l;
}
__device__ int list_is_empty(Lista l){
	return l.root==NULL;
}
__device__ int list_push_first(Lista *l,void *data){	
    Node *p;
	p=(Node *)malloc(sizeof(Node));
	p->data=malloc(l->sizeof_data);
	memcpy(p->data,data,l->sizeof_data);
	p->next=l->root;
	l->root=p;
	p->privious=NULL;
	if(p->next!=NULL)
		p->next->privious=p;
	return 1;	
}
__device__ int list_pop_first(Lista *l, void *data){
	if(list_is_empty(*l)){
		return ERRO_LISTA_VAZIA;
	}else{
		Node *p=l->root;
		memcpy(data,p->data,l->sizeof_data);
		free(p->data);
		l->root=p->next;
		free(p);
		if(l->root!=NULL)
			l->root->privious=NULL;
		return 1;	
	}
	return 0;
}	
__device__ int list_push_last(Lista *l,void *data){	
    if(list_is_empty(*l)){        
		return list_push_first(l,data);
	}else{
		Node *p=l->root;
		Node *novo=(Node *)malloc(sizeof(Node));
		novo->data=malloc(l->sizeof_data);
		memcpy(novo->data,data,l->sizeof_data);
		while(p->next!=NULL){
			p=p->next;
		}
		p->next=novo;
		novo->privious=p;
		novo->next=NULL;
		
	}
	return 1;
}
	
__device__ int list_pop_last(Lista *l,void * data){
	if(list_is_empty(*l)){
		return ERRO_LISTA_VAZIA;
	}else{
		if(l->root->next==NULL){
			return list_pop_first(l,data);
		}else{
			Node *p=l->root;
			while(p->next!=NULL){
				p=p->next;
			}
			memcpy(data,p->data,l->sizeof_data);
			free(p->data);
			p->privious->next=NULL;
			free(p);
			return 1;
		}
	}
}
__device__ int list_push_position(Lista *l, void * data,int pos){
	if(pos<0){
		return ERRO_POSICAO_INVALIDA;
	}else{
		if(pos==0){
			return list_push_first(l,data);
		}else{
			Node *p=l->root;
			int cont=0;
			if(p!=NULL){
				while(p->next!=NULL && cont<pos){
					cont++;
					p=p->next;
				}
			}
			if(cont==pos){
				Node *novo=(Node *)malloc(sizeof(Node));
				novo->data=malloc(l->sizeof_data);
				memcpy(p->data,data,l->sizeof_data);
				novo->next=p;
				novo->privious=p->privious;
				p->privious=novo;
				novo->privious->next=novo;
				return 1;
			}else if(cont==pos-1)
				return list_push_last(l,data);
			 else{
				return ERRO_POSICAO_INVALIDA;
			}
			
		}
	}
}
__device__ int list_pop_position(Lista *l,void *data,int pos){
	if(pos<0){
		return ERRO_POSICAO_INVALIDA;
	}else{
		if(pos==0){
			return list_pop_first(l,data);
		}else{
			Node *p=l->root;
			int cont=0;
			if(p!=NULL){
				while(p->next!=NULL && cont<pos){
					cont++;
					p=p->next;
				}
			}
			if(cont==pos){
				memcpy(data,p->data,l->sizeof_data);
				p->next->privious=p->privious;
				p->privious=p->next;
				free(p->data);
				return 1;
			}
			 else{
				return ERRO_POSICAO_INVALIDA;
			}
			
		}
	}
}		

__device__ int list_get_position(Lista *l,void *data,int pos){
	if(pos<0){
		return ERRO_POSICAO_INVALIDA;
	}else{
		if(pos==0){
			Node *p=l->root;
		    memcpy(data,p->data,l->sizeof_data);
            return 1;
		}else{
			Node *p=l->root;
			int cont=0;
			if(p!=NULL){
				while(p->next!=NULL && cont<pos){
					cont++;
					p=p->next;
				}
			}
			if(cont==pos){
				memcpy(data,p->data,l->sizeof_data);				
				return 1;
			}
			 else{
				return ERRO_POSICAO_INVALIDA;
			}
			
		}
	}
}		