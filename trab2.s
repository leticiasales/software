.section .data
	#Variáveis globais
	inicio_heap: .long 0
	tam_anterior: .long 0
	brk_atual: .long 0

	#Constantes
	.equ HDR_TAM, 12 # Tamanho do cabeçalho, para alocar uma posicao a mais  a do tam anterior, e somar com tam
	.equ BRK, 45
	.equ LINUX_SYSCALL, 0x80
	.equ DISP, 1
	.equ INDISP, 0
	.equ POS_AVAL, 0 # Posicao de DISP ou INDISP no cabeçalho
	.equ POS_TAM, 4 # Posicao do tamanho no cabeçalho
	.equ TAM_ANT, 8

.section .text

.global aloca
.type aloca,@function
aloca:
	pushl %ebp
	movl %esp, %ebp

	cmpl $0,inicio_heap
	jne end_if #Irá verificar o tamanho da heap
	movl $BRK, %eax
	movl $0, %ebx
	int $LINUX_SYSCALL

	incl %eax #incrementa em 1 o valor da brk, para pegar o primeiro endereço válido
	movl %eax, brk_atual
	movl %eax, inicio_heap

end_if:
	movl inicio_heap, %eax #Carrega as variáveis globais
	movl brk_atual, %ebx #tamanho a ser alocado em registradores
	movl 8(%ebp), %ecx #tamanho do malloc

procura_espaco:
	cmpl %ebx, %eax # Se o endereço de memória analisado for igual a brk
	je aumenta_brk #igual a brk, aumentamos a brk

	movl POS_TAM(%eax), %edx #edx recebe o tamanho do segmento atual
	cmpl $INDISP, POS_AVAL(%eax) # Se o segmento estiver ocupado
	je prox_segmento # desvia para o proximo segmento

	cmpl %edx, %ecx # Se o segmento é do mesmo tamanho que precisamos alocar
	je aloca_igual

	cmpl %edx, %ecx # Se o segmento é maior que o que queremos alocar
	jl aloca_menor

prox_segmento:
	movl POS_TAM(%eax), %edx
	movl %edx, tam_anterior

	addl POS_TAM(%eax), %eax #Somamos o tamanho do segmento mais o cabeçalho
	addl $HDR_TAM, %eax # Para chegar ao próximo segmento
	jmp procura_espaco

aumenta_brk:
	addl %ecx, %ebx # Soma em ebx o tamanho a ser alocado
	addl $HDR_TAM, %ebx # e o tamanho do cabecalho

	pushl %eax
	pushl %ebx
	pushl %ecx

	movl $BRK, %eax
	int $LINUX_SYSCALL

	cmpl $0, %eax # Vericia se foi possivel aumentar a brk
	je erro

	popl %ecx # tamanho do malloc
	popl %ebx # tamanho malloc + cabeçalho
	popl %eax # inicio heap

	movl $INDISP, POS_AVAL(%eax) # Define o status como indisponivel
	movl %ecx, POS_TAM(%eax) # e informa o tamanho do segmento

	movl tam_anterior, %ecx
	movl %ecx, TAM_ANT(%eax)

	addl $HDR_TAM, %eax  # *esconder tam do cabeçalho para imprimir somente o alocado
	movl %ebx, brk_atual # Novo valor BRK
	popl %ebp
	ret

aloca_igual:

	movl $INDISP, POS_AVAL(%eax) # Se o segmento tem o mesmo tamanho do que
	addl $HDR_TAM, %eax # queremos alocar, definimos o status como
	popl %ebp # indisponivel
	ret

aloca_menor:

	subl $HDR_TAM, %edx # Verifica se o segmento tem pelo menos o
	cmpl %ecx, %edx # tamanho que queremos alocar somado em *
	jle prox_segmento # (8 do cabecalho e 1 do espaco novo), que é o minimo necessario para outro segmento
	movl $INDISP, POS_AVAL(%eax)
	movl %ecx, POS_TAM(%eax)

	addl %ecx, %eax # Segue para o pedaço livre que sobrou do segmento
	addl $HDR_TAM, %eax

	subl %ecx, %edx
	movl %edx, POS_TAM(%eax) # Define o tamanho que restou do segmento
	movl $DISP, POS_AVAL(%eax) # e o status como disponivel

	subl %ecx, %eax # Volta para o segmento anterior
	popl %ebp # na primeira posicao apos o cabecalho
	ret

erro:
	movl $0, %eax # Retorna zero para informar o erro
	popl %ebp
	ret



#LibMem
.globl LibMem
.type LibMem, @function

.equ LIBERA, 4
LibMem:
	movl LIBERA(%esp), %eax # Acessa parametro
	subl $HDR_TAM, %eax # posiciona eax no inicio do segmento
	movl $DISP, POS_AVAL(%eax) # e coloca esse segmento como disponivel
	movl POS_TAM(%eax), %ecx

	movl %eax, %ebx
	addl %ecx, %ebx
	addl $HDR_TAM, %ebx

	cmpl brk_atual, %ebx
	jge parte_1

	cmpl $DISP, POS_AVAL(%ebx)
	jne parte_1

	movl POS_TAM(%eax), %ecx # ecx tera o tam do segmento atual
	movl POS_TAM(%ebx), %edx # edx tera o tam do segmento de ebx
	addl $HDR_TAM, %edx
	addl %ecx, %edx
	movl %edx, POS_TAM(%eax)

parte_1:

	movl %eax, %ebx
	cmpl $0, TAM_ANT(%eax)
	je parte_2

	subl TAM_ANT(%eax), %ebx
	subl $HDR_TAM, %ebx

	cmpl $DISP, POS_AVAL(%ebx)
	jne parte_2

	movl POS_TAM(%eax), %ecx
	movl TAM_ANT(%eax), %edx
	addl $HDR_TAM, %edx
	addl %ecx, %edx
	movl %edx, POS_TAM(%ebx)
	movl %ebx, %eax

parte_2:

	movl %eax, %ebx
	addl $HDR_TAM, %ebx
	addl POS_TAM(%eax), %ebx

	cmpl brk_atual, %ebx
	jl fim

diminui_brk:

	movl %eax, %ebx
	movl $BRK, %eax
	int $LINUX_SYSCALL
	movl %eax, brk_atual

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
    pushl %ebp
    movl %esp, %ebp
    subl $8, %esp
    movl inicio_heap, %eax
    movl $0, -8(%ebp)

verifica_se_imprime:
    cmpl brk_atual, %eax # se for igual, cai fora do imprime
    je fim_mapa

recarreca_cabecalho_em_ecx:
    addl $1, -8(%ebp)
    movl -8(%ebp), %ecx #iremos imprimir o segmento que estamos
    pushl %eax
    pushl %ecx
    pushl $msg_1
    call printf
    addl $8, %esp
    popl %eax
    movl $12, -4(%ebp)
    movl -4(%ebp), %ecx

loop_cabecalho:
    pushl %eax
    pushl $msg_2
    call printf
    addl $4, %esp
    popl %eax
    subl $1, -4(%ebp)
    movl -4(%ebp), %ecx
    cmpl $0, %ecx
    je continua
    jmp loop_cabecalho

continua:
    pushl %eax
    pushl $msg_3
    call printf
    addl $4, %esp
    popl %eax
    cmpl $DISP, POS_AVAL(%eax)
    jne indisponivel
    movl POS_TAM(%eax), %edx
    movl %edx, -4(%ebp)
    mov -4(%ebp), %ecx

loop_disponivel:
    pushl %eax
    pushl $msg_5
    call printf
    addl $4, %esp
    popl %eax
    subl $1, -4(%ebp)
    movl -4(%ebp), %ecx
    cmpl $0, %ecx
    je proximo_segmento
    jmp loop_disponivel

indisponivel:
    movl POS_TAM(%eax), %edx
    movl %edx,-4(%ebp)
    movl -4(%ebp), %ecx

loop_indisponivel:
    pushl %eax
    pushl $msg_4
    call printf
    addl $4, %esp
    popl %eax
    subl $1, -4(%ebp)
    movl -4(%ebp), %ecx
    cmpl $0, %ecx
    je proximo_segmento
    jmp loop_indisponivel

proximo_segmento:
    pushl %eax
    pushl $msg_3
    call printf
    addl $4, %esp
    popl %eax
    addl POS_TAM(%eax), %eax # Soma o tamanho do segmento e cabecalho
    addl $HDR_TAM, %eax # para ir para o proximo segmento
    jmp verifica_se_imprime

fim_mapa:
    addl $8, %esp
    popl %ebp
    ret
