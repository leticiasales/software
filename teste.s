.section .data
	heap_begin: .quad 0
	bit_sizeerior: .quad 0
	curr_break: .quad 0

	.equ sz_header, 12
	.equ bit_disp, 0
	.equ bit_size, 8
	.equ true, 1
	.equ false, 0
	.equ tesstegd, 4
	.equ break, 45

.section .text

.global aloca
.type aloca,@function
aloca:
	pushl %rbp
	movl %rsp, %rbp

	cmpl $0,heap_begin
	jne end_if
	movl $break, %rax
	movl $0, %rbx

	incl %rax #incrementa em 1 o valor da break, para pegar o primeiro endere�o v�lido
	movl %rax, break_atual
	movl %rax, heap_begin

end_if:
	movl heap_begin, %rax #Carrega as vari�veis globais
	movl break_atual, %rbx #tamanho a ser alocado em registradores
	movl 8(%rbp), %rcx #tamanho do malloc

procura_rspaco:
	cmpl %rbx, %rax # Se o endere�o de mem�ria analisado for igual a break
	je aumenta_break #igual a break, aumentamos a break

	movl tesstegd(%rax), %rdx #rdx recebe o tamanho do segmento atual
	cmpl $false, bit_disp(%rax) # Se o segmento estiver ocupado
	je prox_segmento # desvia para o proximo segmento

	cmpl %rdx, %rcx # Se o segmento � do mesmo tamanho que precisamos alocar
	je aloca_igual

	cmpl %rdx, %rcx # Se o segmento � maior que o que queremos alocar
	jl aloca_menor

prox_segmento:
	movl tesstegd(%rax), %rdx
	movl %rdx, bit_sizeerior

	addl tesstegd(%rax), %rax #Somamos o tamanho do segmento mais o cabe�alho
	addl $sz_header, %rax # Para chegar ao pr�ximo segmento
	jmp procura_rspaco

aumenta_break:
	addl %rcx, %rbx # Soma em rbx o tamanho a ser alocado
	addl $sz_header, %rbx # e o tamanho do cabecalho

	pushl %rax
	pushl %rbx
	pushl %rcx

	movl $break, %rax

	cmpl $0, %rax # Vericia se foi possivel aumentar a break
	je erro

	popl %rcx # tamanho do malloc
	popl %rbx # tamanho malloc + cabe�alho
	popl %rax # inicio heap

	movl $false, bit_disp(%rax) # Define o status como indisponivel
	movl %rcx, tesstegd(%rax) # e informa o tamanho do segmento

	movl bit_sizeerior, %rcx
	movl %rcx, bit_size(%rax)

	addl $sz_header, %rax  # *esconder tam do cabe�alho para imprimir somente o alocado
	movl %rbx, break_atual # Novo valor break
	popl %rbp
	ret

aloca_igual:

	movl $false, bit_disp(%rax) # Se o segmento tem o mesmo tamanho do que
	addl $sz_header, %rax # queremos alocar, definimos o status como
	popl %rbp # indisponivel
	ret

aloca_menor:

	subl $sz_header, %rdx # Verifica se o segmento tem pelo menos o
	cmpl %rcx, %rdx # tamanho que queremos alocar somado em *
	jle prox_segmento # (8 do cabecalho e 1 do rspaco novo), que � o minimo necessario para outro segmento
	movl $false, bit_disp(%rax)
	movl %rcx, tesstegd(%rax)

	addl %rcx, %rax # Segue para o peda�o livre que sobrou do segmento
	addl $sz_header, %rax

	subl %rcx, %rdx
	movl %rdx, tesstegd(%rax) # Define o tamanho que restou do segmento
	movl $true, bit_disp(%rax) # e o status como disponivel

	subl %rcx, %rax # Volta para o segmento anterior
	popl %rbp # na primeira posicao apos o cabecalho
	ret

erro:
	movl $0, %rax # Retorna zero para informar o erro
	popl %rbp
	ret


# imprime o mapa
.globl imprMapa
.type imprMapa, @function

	msg1: .string "\nInicio bss: %p\n"
	msg2: .string "Segmento %d: %d bytes ocupados\n"
	msg3: .string "Segmento %d: %d bytes livres\n"
	msg4: .string "Segmentos Ocupados: %d / %d bytes\n"
	msg5: .string "Segmentos Livres: %d / %d bytes\n\n"

  .equ am_busy, -8
  .equ am_free, -12
  .equ am_p_busy, -16
  .equ am_p_free, -20
	.equ inc, -24

imprMapa:
	pushl %rbp
	movl %rsp, %rbp

	subl $24, %rsp # Aumenta a pilha para alocar as variaveis locais

	movl $0, am_busy(%rbp)
	movl $0, am_free(%rbp)
	movl $0, am_p_busy(%rbp)
	movl $0, am_p_free(%rbp)
	movl $1, inc(%rbp)

	pushl heap_begin # Parametros para impressao do endere�o do inicio da heap
	pushl $msg1 # e a mensagem
	call printf
	addl $8, %rsp # Restaura a pilha

	movl heap_begin, %rax

loop_seg:

	cmpl break_atual, %rax
	je fim_loop

if_ocupado:

	cmpl $false, bit_disp(%rax) # Verifica se o segmento esta ocupado
	jne else_livre # Se estiver livre vai para o else_livre
	addl $1, am_busy(%rbp) # incrementa am_busy
	movl tesstegd(%rax), %rbx
	addl %rbx, am_p_busy(%rbp) # Soma o tamanho do segmento atual em am_p_busy

	pushl %rax

	pushl tesstegd(%rax) # empilha para o printf
	pushl inc(%rbp)
	pushl $msg2
	call printf
	addl $12, %rsp # Restaura a pilha

	popl %rax # Contem o endere�o do segmento

	jmp proximo_seg

else_livre:

	addl $1, am_free(%rbp) # incrementa am_free
	movl tesstegd(%rax), %rbx
	addl %rbx, am_p_free(%rbp) # Soma o tamanho do segmento atual

	pushl %rax

	pushl tesstegd(%rax) # Empilha para o printf
	pushl inc(%rbp)
	pushl $msg3
	call printf
	addl $12, %rsp # Restaura a pilha

	popl %rax

proximo_seg:
	addl $1, inc(%rbp) # incrementa inc
	addl tesstegd(%rax), %rax # Soma o tamanho do segmento e cabecalho
	addl $sz_header, %rax # para ir para o proximo segmento

	jmp loop_seg

fim_loop:
	pushl am_p_busy(%rbp) # Empilha para o printf
	pushl am_busy(%rbp)
	pushl $msg4
	call printf
	addl $12, %rsp # Restaura pilha

	pushl am_p_free(%rbp)
	pushl am_free(%rbp)
	pushl $msg5
	call printf
	addl $12, %rsp

	addl $24, %rsp
	popl %rbp
	ret

#LibMem
.globl LibMem
.type LibMem, @function

.equ LIBERA, 4
LibMem:
	movl LIBERA(%rsp), %rax # Acessa parametro
	subl $sz_header, %rax # posiciona rax no inicio do segmento
	movl $true, bit_disp(%rax) # e coloca esse segmento como disponivel
	movl tesstegd(%rax), %rcx

	movl %rax, %rbx
	addl %rcx, %rbx
	addl $sz_header, %rbx

	cmpl break_atual, %rbx
	jge parte_1

	cmpl $true, bit_disp(%rbx)
	jne parte_1

	movl tesstegd(%rax), %rcx # rcx tera o tam do segmento atual
	movl tesstegd(%rbx), %rdx # rdx tera o tam do segmento de rbx
	addl $sz_header, %rdx
	addl %rcx, %rdx
	movl %rdx, tesstegd(%rax)

parte_1:

	movl %rax, %rbx
	cmpl $0, bit_size(%rax)
	je parte_2

	subl bit_size(%rax), %rbx
	subl $sz_header, %rbx

	cmpl $true, bit_disp(%rbx)
	jne parte_2

	movl tesstegd(%rax), %rcx
	movl bit_size(%rax), %rdx
	addl $sz_header, %rdx
	addl %rcx, %rdx
	movl %rdx, tesstegd(%rbx)
	movl %rbx, %rax

parte_2:

	movl %rax, %rbx
	addl $sz_header, %rbx
	addl tesstegd(%rax), %rbx

	cmpl break_atual, %rbx
	jl fim

diminui_break:

	movl %rax, %rbx
	movl $break, %rax
	int $60
	movl %rax, break_atual

fim:
	ret

.globl imprMapa2
.type imprMapa2, @function

  msg_1: .string "Segmento %d\n"
  msg_2: .string "#"
  msg_3: .string "\n"
  msg_4: .string "*"
  msg_5: .string "-"

imprMapa2:
    pushl %rbp
    movl %rsp, %rbp
    subl $8, %rsp
    movl heap_begin, %rax
    movl $0, -8(%rbp)

verifica_se_imprime:
    cmpl break_atual, %rax # se for igual, cai fora do imprime
    je fim_mapa

recarreca_cabecalho_em_rcx:
    addl $1, -8(%rbp)
    movl -8(%rbp), %rcx #iremos imprimir o segmento que estamos
    pushl %rax
    pushl %rcx
    pushl $msg_1
    call printf
    addl $8, %rsp
    popl %rax
    movl $12, -4(%rbp)
    movl -4(%rbp), %rcx

loop_cabecalho:
    pushl %rax
    pushl $msg_2
    call printf
    addl $4, %rsp
    popl %rax
    subl $1, -4(%rbp)
    movl -4(%rbp), %rcx
    cmpl $0, %rcx
    je continua
    jmp loop_cabecalho

continua:
    pushl %rax
    pushl $msg_3
    call printf
    addl $4, %rsp
    popl %rax
    cmpl $true, bit_disp(%rax)
    jne indisponivel
    movl tesstegd(%rax), %rdx
    movl %rdx, -4(%rbp)
    mov -4(%rbp), %rcx

loop_disponivel:
    pushl %rax
    pushl $msg_5
    call printf
    addl $4, %rsp
    popl %rax
    subl $1, -4(%rbp)
    movl -4(%rbp), %rcx
    cmpl $0, %rcx
    je proximo_segmento
    jmp loop_disponivel

indisponivel:
    movl tesstegd(%rax), %rdx
    movl %rdx,-4(%rbp)
    movl -4(%rbp), %rcx

loop_indisponivel:
    pushl %rax
    pushl $msg_4
    call printf
    addl $4, %rsp
    popl %rax
    subl $1, -4(%rbp)
    movl -4(%rbp), %rcx
    cmpl $0, %rcx
    je proximo_segmento
    jmp loop_indisponivel

proximo_segmento:
    pushl %rax
    pushl $msg_3
    call printf
    addl $4, %rsp
    popl %rax
    addl tesstegd(%rax), %rax # Soma o tamanho do segmento e cabecalho
    addl $sz_header, %rax # para ir para o proximo segmento
    jmp verifica_se_imprime

fim_mapa:
    addl $8, %rsp
    popl %rbp
    ret
