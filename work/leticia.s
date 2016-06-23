.section .data
	heap_begin: .long 0
	tam_anterior: .long 0
	current_break: .long 0
	tes: .long 0
	tes2: .long 0

	velha: .ascii  "#\n"
	velha_length: .quad   . - velha

	mais: .ascii  "+\n"
	mais_length: .quad   . - mais

	risco: .ascii  "-\n"
	risco_length: .quad   . - risco

	.equ sz_header, 12
	.equ break, 45
	.equ true, 1
	.equ false, 0
	.equ bit_available, 0 # Posicao de true ou false no cabe�alho
	.equ bit_size, 4 # Posicao do tamanho no cabe�alho
	.equ sz_prev, 8

.section .text

.global meuAlocaMem
.type meuAlocaMem,@function
meuAlocaMem:
	pushl %ebp
	movl %esp, %ebp

	cmpl $0,heap_begin
	jne end_if
	movl $break, %eax
	movl $0, %ebx
	int $0x80

	incl %eax #incrementa em 1 o valor da break, para pegar o primeiro endere�o v�lido
	movl %eax, current_break
	movl %eax, heap_begin

end_if:
	movl heap_begin, %eax #Carrega as vari�veis globais
	movl current_break, %ebx #tamanho a ser meuAlocaMemdo em registradores
	movl 8(%ebp), %ecx #tamanho do malloc

procura_espaco:
	cmpl %ebx, %eax # Se o endere�o de mem�ria analisado for igual a break
	je aumenta_brk #igual a break, aumentamos a break

	movl bit_size(%eax), %edx #edx recebe o tamanho do segmento atual
	cmpl $false, bit_available(%eax) # Se o segmento estiver ocupado
	je prox_segmento # desvia para o proximo segmento

	cmpl %edx, %ecx # Se o segmento � do mesmo tamanho que precisamos meuAlocaMemr
	je meuAlocaMem_igual

	cmpl %edx, %ecx # Se o segmento � maior que o que queremos meuAlocaMemr
	jl meuAlocaMem_menor

prox_segmento:
	movl bit_size(%eax), %edx
	movl %edx, tam_anterior

	addl bit_size(%eax), %eax #Somamos o tamanho do segmento mais o cabe�alho
	addl $sz_header, %eax # Para chegar ao pr�ximo segmento
	jmp procura_espaco

aumenta_brk:
	addl %ecx, %ebx # Soma em ebx o tamanho a ser meuAlocaMemdo
	addl $sz_header, %ebx # e o tamanho do cabecalho

	pushl %eax
	pushl %ebx
	pushl %ecx

	movl $break, %eax
	int $0x80

	cmpl $0, %eax # Vericia se foi possivel aumentar a break
	je erro

	popl %ecx # tamanho do malloc
	popl %ebx # tamanho malloc + cabe�alho
	popl %eax # inicio heap

	movl $false, bit_available(%eax) # Define o status como indisponivel
	movl %ecx, bit_size(%eax) # e informa o tamanho do segmento

	movl tam_anterior, %ecx
	movl %ecx, sz_prev(%eax)

	addl $sz_header, %eax  # *esconder tam do cabe�alho para imprimir somente o meuAlocaMemdo
	movl %ebx, current_break # Novo valor break
	popl %ebp
	ret

meuAlocaMem_igual:

	movl $false, bit_available(%eax) # Se o segmento tem o mesmo tamanho do que
	addl $sz_header, %eax # queremos meuAlocaMemr, definimos o status como
	popl %ebp # indisponivel
	ret

meuAlocaMem_menor:

	subl $sz_header, %edx # Verifica se o segmento tem pelo menos o
	cmpl %ecx, %edx # tamanho que queremos meuAlocaMemr somado em *
	jle prox_segmento # (8 do cabecalho e 1 do espaco novo), que � o minimo necessario para outro segmento
	movl $false, bit_available(%eax)
	movl %ecx, bit_size(%eax)

	addl %ecx, %eax # Segue para o peda�o livre que sobrou do segmento
	addl $sz_header, %eax

	subl %ecx, %edx
	movl %edx, bit_size(%eax) # Define o tamanho que restou do segmento
	movl $true, bit_available(%eax) # e o status como disponivel

	subl %ecx, %eax # Volta para o segmento anterior
	popl %ebp # na primeira posicao apos o cabecalho
	ret

erro:
	movl $0, %eax # Retorna zero para informar o erro
	popl %ebp
	ret


# imprime o mapa
.globl imprMapa2
.type imprMapa2, @function

	msg1: .string "\nInicio bss: %p\n"
	msg2: .string "Segmento %d: %d bytes ocupados\n"
	msg3: .string "Segmento %d: %d bytes livres\n"
	msg4: .string "Segmentos Ocupados: %d / %d bytes\n"
	msg5: .string "Segmentos Livres: %d / %d bytes\n\n"

	.equ HEAP_ATUAL, -4
	.equ TOTAL_OCUPADOS, -8 # guarda quantos segmentos s�o ocupados
	.equ TOTAL_LIVRES, -12 # Guarda quantos segmentos s�o livres
	.equ TOTAL_SEG_OCUPADOS, -16
	.equ TOTAL_SEG_LIVRES, -20
	.equ INC, -24 # N�mero segmento atual

imprMapa2:
	pushl %ebp
	movl %esp, %ebp

	subl $24, %esp # Aumenta a pilha para meuAlocaMemr as variaveis locais

	movl $0, TOTAL_OCUPADOS(%ebp)
	movl $0, TOTAL_LIVRES(%ebp)
	movl $0, TOTAL_SEG_OCUPADOS(%ebp)
	movl $0, TOTAL_SEG_LIVRES(%ebp)
	movl $1, INC(%ebp)

	pushl heap_begin # Parametros para impressao do endere�o do inicio da heap
	pushl $msg1 # e a mensagem
	call printf
	addl $8, %esp # Restaura a pilha

	movl heap_begin, %eax

loop_seg:

	cmpl current_break, %eax
	je fim_loop

if_ocupado:

	cmpl $false, bit_available(%eax) # Verifica se o segmento esta ocupado
	jne else_livre # Se estiver livre vai para o else_livre
	addl $1, TOTAL_OCUPADOS(%ebp) # Incrementa TOTAL_OCUPADOS
	movl bit_size(%eax), %ebx
	addl %ebx, TOTAL_SEG_OCUPADOS(%ebp) # Soma o tamanho do segmento atual em TOTAL_SEG_OCUPADOS

	pushl %eax

	pushl bit_size(%eax) # empilha para o printf
	pushl INC(%ebp)
	pushl $msg2
	call printf
	addl $12, %esp # Restaura a pilha

	popl %eax # Contem o endere�o do segmento

	jmp proximo_seg

else_livre:

	addl $1, TOTAL_LIVRES(%ebp) # Incrementa TOTAL_LIVRES
	movl bit_size(%eax), %ebx
	addl %ebx, TOTAL_SEG_LIVRES(%ebp) # Soma o tamanho do segmento atual

	pushl %eax

	pushl bit_size(%eax) # Empilha para o printf
	pushl INC(%ebp)
	pushl $msg3
	call printf
	addl $12, %esp # Restaura a pilha

	popl %eax

proximo_seg:
	addl $1, INC(%ebp) # Incrementa INC
	addl bit_size(%eax), %eax # Soma o tamanho do segmento e cabecalho
	addl $sz_header, %eax # para ir para o proximo segmento

	jmp loop_seg

fim_loop:
	pushl TOTAL_SEG_OCUPADOS(%ebp) # Empilha para o printf
	pushl TOTAL_OCUPADOS(%ebp)
	pushl $msg4
	call printf
	addl $12, %esp # Restaura pilha

	pushl TOTAL_SEG_LIVRES(%ebp)
	pushl TOTAL_LIVRES(%ebp)
	pushl $msg5
	call printf
	addl $12, %esp

	addl $24, %esp
	popl %ebp
	ret

.globl meuLiberaMem
.type meuLiberaMem, @function

.equ LIBERA, 4
meuLiberaMem:
	movl LIBERA(%esp), %eax # Acessa parametro
	subl $sz_header, %eax # posiciona eax no inicio do segmento
	movl $true, bit_available(%eax) # e coloca esse segmento como disponivel
	movl bit_size(%eax), %ecx

	movl %eax, %ebx
	addl %ecx, %ebx
	addl $sz_header, %ebx

	cmpl current_break, %ebx
	jge parte_1

	cmpl $true, bit_available(%ebx)
	jne parte_1

	movl bit_size(%eax), %ecx # ecx tera o tam do segmento atual
	movl bit_size(%ebx), %edx # edx tera o tam do segmento de ebx
	addl $sz_header, %edx
	addl %ecx, %edx
	movl %edx, bit_size(%eax)

parte_1:

	movl %eax, %ebx
	cmpl $0, sz_prev(%eax)
	je parte_2

	subl sz_prev(%eax), %ebx
	subl $sz_header, %ebx

	cmpl $true, bit_available(%ebx)
	jne parte_2

	movl bit_size(%eax), %ecx
	movl sz_prev(%eax), %edx
	addl $sz_header, %edx
	addl %ecx, %edx
	movl %edx, bit_size(%ebx)
	movl %ebx, %eax

parte_2:

	movl %eax, %ebx
	addl $sz_header, %ebx
	addl bit_size(%eax), %ebx

	cmpl current_break, %ebx
	jl fim

diminui_brk:

	movl %eax, %ebx
	movl $break, %eax
	int $0x80
	movl %eax, current_break

fim:
	ret

	.global imprMapa
	.type imprMapa, @function              #<-Important

	imprMapa:
	  	movl heap_begin, %eax

	print2:
		cmpl $false, bit_available(%eax)
		je next_location2
		jmp next_location3
		ret

	next_location2:
			addl $8, %eax #The total size of the memory
				movl %eax,tes

				movl	%eax, %edx
			    movl     $1,%eax               # Move 1(write) into eax
			    movl     $1,%edi               # Move 1(fd stdOut) into edi.
		    	movl     $risco,%esi            # Move the _location_ of the string into esi
			    movl     risco_length,%edx             # Move the _length_ of the string into edx
			    call printf                         # Call the kernel
		   		movl %edx,%eax

		    addl (%eax),%eax
			addl $8,%eax


	#		addl $8,%eax
			movl bit_available(%eax),%ecx
			movl %ecx,tes2

			cmpl %eax, current_break
			jne print2
	  	ret

	  next_location3:
				addl $8, %eax #The total size of the memory
				movl %eax,tes

				movl	%eax, %edx
			    movl     $1,%eax               # Move 1(write) into eax
			    movl     $1,%edi               # Move 1(fd stdOut) into edi.
		    	movl     $mais,%esi            # Move the _location_ of the string into esi
			    movl     mais_length,%edx             # Move the _length_ of the string into edx
			    syscall                         # Call the kernel
		   		movl %edx,%eax

		    addl (%eax),%eax
			addl $8,%eax


	#		addl $8,%eax
			movl bit_available(%eax),%ecx
			movl %ecx,tes2

			cmpl %eax, current_break
			jne print2
	ret
