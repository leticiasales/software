#include <stdio.h>
#include <stddef.h>
#include "malloc.h"


void initialize(){
	freeList->size=TAM-(sizeof(struct block)); //aloca quantidade de memoria inicial
	freeList->free=1; // disponivel
	freeList->next=NULL;
}

/* Alocacao de mais memoria, ajuste da brk e tamanho inicial
void realoca(){
	struct block *new = (void*)((void*)
	freeList ->size=2*(TAM-(sizeof(struct block)));
}
*/
void split(struct block *curr_size,size_t nbytes){
	//cria apontador para area nova disponivel
	struct block *new=(void*)((void*)curr_size+nbytes+sizeof(struct block));
	new->size=(curr_size->size)-(nbytes+sizeof(struct block));
	new->free=1; // resto esta disponivel
	new->next=curr_size->next;
	curr_size->size=nbytes;
	curr_size->free=0; // area ocupada 
	curr_size->next=new;
}


void *MyMalloc(size_t nbytes){
	struct block *curr,*prev;
	void *result;
	if(!(freeList->size)){
		initialize();
		printf("Memory initialized\n");
	}
	curr=freeList;
	//passa areas de memorias ocupadas
	while((((curr->size)<nbytes)||((curr->free)==0))&&(curr->next!=NULL)){
		prev=curr;
		curr=curr->next;
	printf("One block checked\n");
	}//area de memoria de tamanho exato ao requisitado 
	if((curr->size)==nbytes){
		curr->free=0; //ocupado
		result=(void*)(++curr);
		printf("Exact fitting block allocated\n");
		return result;
	}//memoria maior daquela que deseja alocar,necessario quebrar 
 	else if((curr->size)>(nbytes+sizeof(struct block))){ 
		split(curr,nbytes);
		result=(void*)(++curr);
		printf("Fitting block allocated with a split\n");
		return result;
 	}
 	else{
  		result=NULL;
		printf("Sorry. No sufficient memory to allocate\n");
		return result;
 	}
}

void merge(){
	struct block *curr,*prev;
	curr=freeList;
	while((curr->next)!=NULL){
		//espacos vizinhos disponiveis, junta
		if((curr->free) && (curr->next->free)){
			curr->size+=(curr->next->size)+sizeof(struct block);
			curr->next=curr->next->next;
  		}
  		prev=curr;
  		curr=curr->next;
 	}
}

void MyFree(void* ptr){
	if(((void*)memory<=ptr)&&(ptr<=(void*)(memory+20000))){
		struct block* curr=ptr;
	--curr;
	curr->free=1;
	merge();
 	}
 	else printf("Please provide a valid pointer allocated by MyMalloc\n");
}
