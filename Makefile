all: 
	gcc -c trab.s -o trab.o -m32
	gcc -c testeMalloc.c -o testeMalloc.o -m32
	gcc -o teste trab.o  -m32

clean:
	rm *.o
	rm teste


