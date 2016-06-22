#include <stdio.h>

main()
	{
	printf("main");
	void *a, *b, *c, *d;
	printf("define");
	a = aloca(60);
	printf("a");
	b = aloca(20);
	imprMapa2();
	
	    LibMem(b);
	imprMapa();
	c = aloca(500);
	b = aloca(1500);
	d = aloca(35);
	imprMapa();
	LibMem(b);
	b = aloca(900);
	imprMapa();
    
}
