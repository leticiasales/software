#include <stdio.h>
extern void allocate_init(void);
extern long int allocate(long int);
extern void deallocate(void* ptr);
extern void print(void);

long int heap_begin;
long int current_break;
long int inicio;
long int fim;
long int a;
long int b;
long int c;
long int d;
long int e;
long int f;
long int g;
long int h;
long int tes;
long int tes2;

int main(){
  
 allocate_init();
 //printf("%ld - %ld\n",print1,print2);
 long int a = heap_begin;
 long int *p = (long int*)allocate(100);
 printf("\n/-/-/ Primeiro valor /-/-/\n\n");
 printf("- rax: %ld\n",a);
 printf("- rbx: %ld\n",b);
 printf("- param (rcx): %ld\n",c);
 printf("/\n");
 printf("-- inicial: %ld -> diff:%lu+16\n",e,e-a-16);
 printf("-- quant: %ld -> diff:%li+16\n",f,f-b-16);
 printf("-- param: %ld",g);
 long int *k = (long int*)allocate(115);
 printf("\n\n/-/-/ Novo valor /-/-/\n\n");
 printf("- inicial: %ld\n",a);
 printf("- quant: %ld\n",b);
 printf("- param: %ld\n",c);
printf("/\n");
 printf("-- inicial: %ld -> diff:%lu+16\n",e,e-a-16);
 printf("-- quant: %ld -> diff:%lu+16\n",f,f-b - 16);
 printf("-- param: %ld \n",g);

 
 long int *m = (long int*)allocate(100);
 printf("\n\n/-/-/ Novo valor /-/-/\n\n");
 printf("- inicial: %ld\n",a);
 printf("- quant: %ld\n",b);
 printf("- param: %ld\n",c);
 printf("/\n");
 printf("-- inicial: %ld -> diff:%lu+16\n",e,e-a-16);
 printf("-- quant: %ld -> diff:%lu+16\n",f,f-b - 16);
 printf("-- param: %ld \n",g);
 print();
 printf("1\n");
 deallocate(k);
 deallocate(p);
 deallocate(m);

long int *n = (long int*)allocate(100);
 printf("\n\n/-/-/ Novo valor /-/-/\n\n");
 printf("- inicial: %ld\n",a);
 printf("- quant: %ld\n",b);
 printf("- param: %ld\n",c);
printf("/\n");
 printf("-- inicial: %ld -> diff:%lu-16\n",e,e-a - 0);
 printf("-- quant: %ld -> diff:%lu-16\n",f,f-b - 0);
 printf("-- param: %ld \n",g);
 printf("2\n");
 long int *n = (long int*)allocate(50);

 print();
 printf("\n%ld\n",tes);
 printf("\n%ld\n",tes2);

 //printf("%d\n",p);
 //deallocate(p);
 //int *r=(int)MyMalloc(1000*sizeof(int));
 //MyFree(p);
 //char *w=(char)MyMalloc(700);
 //MyFree(r);
 //int *k=(int)MyMalloc(500*sizeof(int));
 //printf("Allocation and deallocation is done successfully!");
}