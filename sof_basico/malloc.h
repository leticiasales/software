#include<stdio.h>
#include<stddef.h>
#define TAM 20000
char memory[TAM];

struct block{
 size_t size;
 int free;
 struct block *next; 
};

struct block *freeList=(void*)memory;

void initialize();
void split(struct block *curr_size,size_t nbytes);
void *MyMalloc(size_t nbytes);
void merge();
void MyFree(void* ptr);
