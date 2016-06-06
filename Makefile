all: 
	gcc -c trab.s -o trab.o -m32
	gcc -c teste2.c -o teste2.o -m32
	gcc -o teste trab.o teste2.o -m32

clean:
	rm *.o
	rm teste


