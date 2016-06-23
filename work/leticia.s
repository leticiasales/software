.section .data
	heap_begin: .quad 0
	prev_size: .quad 0
	curr_break: .quad 0

	.equ sz_header, 12
	.equ bit_disp, 0
	.equ bit_ant, 8
	.equ true, 1
	.equ false, 0
	.equ bit_size, 4
	.equ break, 45

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

	incl %eax #incrementa em 1 o valor da break, para pegar o primeiro endere�o v�lido
	movl %eax, curr_break
	movl %eax, heap_begin

end_if:
	movl heap_begin, %eax #Carrega as vari�veis globais
	movl curr_break, %ebx #tamanho a ser alocado em registradores
	movl 8(%ebp), %ecx #tamanho do malloc

procura_espaco:
	cmpl %ebx, %eax # Se o endere�o de mem�ria analisado for igual a break
	je aumenta_break #igual a break, aumentamos a break

	movl bit_size(%eax), %edx #edx recebe o tamanho do segmento atual
	cmpl $false, bit_disp(%eax) # Se o segmento estiver ocupado
	je prox_segmento # desvia para o proximo segmento

	cmpl %edx, %ecx # Se o segmento � do mesmo tamanho que precisamos alocar
	je meuAlocaMem_igual

	cmpl %edx, %ecx # Se o segmento � maior que o que queremos alocar
	jl meuAlocaMem_menor

prox_segmento:
	movl bit_size(%eax), %edx
	movl %edx, prev_size

	addl bit_size(%eax), %eax #Somamos o tamanho do segmento mais o cabe�alho
	addl $sz_header, %eax # Para chegar ao pr�ximo segmento
	jmp procura_espaco

aumenta_break:
	addl %ecx, %ebx # Soma em ebx o tamanho a ser alocado
	addl $sz_header, %ebx # e o tamanho do cabecalho

	pushl %eax
	pushl %ebx
	pushl %ecx

	movl $break, %eax

	cmpl $0, %eax # Vericia se foi possivel aumentar a break
	je erro

	popl %ecx # tamanho do malloc
	popl %ebx # tamanho malloc + cabe�alho
	popl %eax # inicio heap

	movl $false, bit_disp(%eax) # Define o status como indisponivel
	movl %ecx, bit_size(%eax) # e informa o tamanho do segmento

	movl prev_size, %ecx
	movl %ecx, bit_ant(%eax)

	addl $sz_header, %eax  # *esconder tam do cabe�alho para imprimir somente o alocado
	movl %ebx, curr_break # Novo valor break
	popl %ebp
	ret

meuAlocaMem_igual:

	movl $false, bit_disp(%eax) # Se o segmento tem o mesmo tamanho do que
	addl $sz_header, %eax # queremos alocar, definimos o status como
	popl %ebp # indisponivel
	ret

meuAlocaMem_menor:

	subl $sz_header, %edx # Verifica se o segmento tem pelo menos o
	cmpl %ecx, %edx # tamanho que queremos alocar somado em *
	jle prox_segmento # (8 do cabecalho e 1 do espaco novo), que � o minimo necessario para outro segmento
	movl $false, bit_disp(%eax)
	movl %ecx, bit_size(%eax)

	addl %ecx, %eax # Segue para o peda�o livre que sobrou do segmento
	addl $sz_header, %eax

	subl %ecx, %edx
	movl %edx, bit_size(%eax) # Define o tamanho que restou do segmento
	movl $true, bit_disp(%eax) # e o status como disponivel

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

  .equ am_busy, -8
  .equ am_free, -12
  .equ am_p_busy, -16
  .equ am_p_free, -20
	.equ inc, -24

imprMapa2:
	pushl %ebp
	movl %esp, %ebp

	subl $24, %esp # Aumenta a pilha para alocar as variaveis locais

	movl $0, am_busy(%ebp)
	movl $0, am_free(%ebp)
	movl $0, am_p_busy(%ebp)
	movl $0, am_p_free(%ebp)
	movl $1, inc(%ebp)

	pushl heap_begin # Parametros para impressao do endere�o do inicio da heap
	pushl $msg1 # e a mensagem
	call printf
	addl $8, %esp # Restaura a pilha

	movl heap_begin, %eax

loop_seg:

	cmpl curr_break, %eax
	je fim_loop

if_ocupado:

	cmpl $false, bit_disp(%eax) # Verifica se o segmento esta ocupado
	jne else_livre # Se estiver livre vai para o else_livre
	addl $1, am_busy(%ebp) # incrementa am_busy
	movl bit_size(%eax), %ebx
	addl %ebx, am_p_busy(%ebp) # Soma o tamanho do segmento atual em am_p_busy

	pushl %eax

	pushl bit_size(%eax) # empilha para o printf
	pushl inc(%ebp)
	pushl $msg2
	call printf
	addl $12, %esp # Restaura a pilha

	popl %eax # Contem o endere�o do segmento

	jmp proximo_seg

else_livre:

	addl $1, am_free(%ebp)
	movl bit_size(%eax), %ebx
	addl %ebx, am_p_free(%ebp)

	pushl %eax

	pushl bit_size(%eax) # Empilha para o printf
	pushl inc(%ebp)
	pushl $msg3
	call printf
	addl $12, %esp # Restaura a pilha

	popl %eax

proximo_seg:
	addl $1, inc(%ebp) # incrementa inc
	addl bit_size(%eax), %eax # Soma o tamanho do segmento e cabecalho
	addl $sz_header, %eax # para ir para o proximo segmento

	jmp loop_seg

fim_loop:
	pushl am_p_busy(%ebp) # Empilha para o printf
	pushl am_busy(%ebp)
	pushl $msg4
	call printf
	addl $12, %esp

	pushl am_p_free(%ebp)
	pushl am_free(%ebp)
	pushl $msg5
	call printf
	addl $12, %esp

	addl $24, %esp
	popl %ebp
	ret

#meuLiberaMem
.globl meuLiberaMem
.type meuLiberaMem, @function

meuLiberaMem:
	movl 4(%esp), %eax
	subl $sz_header, %eax # posiciona eax no inicio do segmento
	movl $true, bit_disp(%eax) # e coloca esse segmento como disponivel
	movl bit_size(%eax), %ecx

	movl %eax, %ebx
	addl %ecx, %ebx
	addl $sz_header, %ebx

	cmpl curr_break, %ebx
	jge parte_1

	cmpl $true, bit_disp(%ebx)
	jne parte_1

	movl bit_size(%eax), %ecx # ecx tera o tam do segmento atual
	movl bit_size(%ebx), %edx # edx tera o tam do segmento de ebx
	addl $sz_header, %edx
	addl %ecx, %edx
	movl %edx, bit_size(%eax)

parte_1:

	movl %eax, %ebx
	cmpl $0, bit_ant(%eax)
	je parte_2

	subl bit_ant(%eax), %ebx
	subl $sz_header, %ebx

	cmpl $true, bit_disp(%ebx)
	jne parte_2

	movl bit_size(%eax), %ecx
	movl bit_ant(%eax), %edx
	addl $sz_header, %edx
	addl %ecx, %edx
	movl %edx, bit_size(%ebx)
	movl %ebx, %eax

parte_2:

	movl %eax, %ebx
	addl $sz_header, %ebx
	addl bit_size(%eax), %ebx

	cmpl curr_break, %ebx
	jl fim

diminui_break:

	movl %eax, %ebx
	movl $break, %eax
	int $60
	movl %eax, curr_break

fim:
	ret

.globl imprMapa
.type imprMapa, @function

  msg_1: .string "Segmento %d\n"
  msg_2: .string "#"
  msg_3: .string "\n"
  msg_4: .string "*"
  msg_5: .string "-"

imprMapa:
    pushl %ebp
    movl %esp, %ebp
    subl $8, %esp
    movl heap_begin, %eax
    movl $0, -8(%ebp)

verifica_se_imprime:
    cmpl curr_break, %eax # se for igual, cai fora do imprime
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
    cmpl $true, bit_disp(%eax)
    jne indisponivel
    movl bit_size(%eax), %edx
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
    movl bit_size(%eax), %edx
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
    addl bit_size(%eax), %eax # Soma o tamanho do segmento e cabecalho
    addl $sz_header, %eax # para ir para o proximo segmento
    jmp verifica_se_imprime

fim_mapa:
    addl $8, %esp
    popl %ebp
    ret
