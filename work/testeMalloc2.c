#include <stdio.h>

main()
	{
	void *a, *b, *c, *d;
	a = meuAlocaMem(60);
	b = meuAlocaMem(20);
	imprMapa2();
	
	meuLiberaMem(b);
	imprMapa();
	c = meuAlocaMem(500);
	b = meuAlocaMem(1500);
	d = meuAlocaMem(35);
	imprMapa();
	meuLiberaMem(b);
	b = meuAlocaMem(900);
	imprMapa();
    
}
