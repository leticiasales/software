.section .data
#######GLOBAL VARIABLES########

#heap_begin: .quad 0
#current_break: .quad 0
velha: .ascii  "#\n"
velha_length: .quad   . - velha

mais: .ascii  "+\n"
mais_length: .quad   . - mais

risco: .ascii  "-\n"
risco_length: .quad   . - risco


######STRUCTURE INFORMATION####

.equ HEADER_SIZE, 16 # size of space for memory region header
.equ HDR_AVAIL_OFFSET, 0 # Location of the "available" flag in the header
.equ HDR_SIZE_OFFSET, 8 # Location of the size field in the header

###########CONSTANTS###########

.equ UNAVAILABLE, 0 
.equ AVAILABLE, 1        

###############################
.section .text
.globl allocate_init
.type allocate_init,@function

# If the brk system call is called with 0 in %rbx, it returns the last valid 
# usable address

allocate_init:
		pushq %rbp
		movq %rsp,%rbp

		movq $12, %rax
		movq $0,%rbx
		syscall

		incq %rax

		movq %rax, current_break    # store the current break
		movq %rax, heap_begin       
		popq %rbp
ret

################################################################################
##allocate##
# PURPOSE:        
# This function is used to grab a section of memory. It checks to see if there 
# are any free blocks, and, if not, it asks Linux for a new one.
#
# PARAMETERS: 
# This function has one parameter - the size of the memory block we want to 
# allocate
#
# RETURN VALUE:
# This function returns the address of the allocated memory in %rax. If there 
# is no memory available, it will return 0 in %rax
#
######PROCESSING########
# Variables used:
#
#    %rcx - hold the size of the requested memory (first/only parameter)
#    %rax - current memory region being examined
#    %rbx - current break position
#    %rdx - size of current memory region
#
# e scan through each memory region starting with heap_begin. We look at the 
# size of each one, and if it has been allocated. If itÂs big enough for the
# requested size, and its available, it grabs that one.If it does not find a 
# region large enough, it asks Linux for more memory. In that case, it moves
# current_break up
################################################################################
.globl allocate
.type allocate,@function

allocate:
		pushq %rbp
		movq %rsp,%rbp
		
# %rcx will hold the size we are looking for (which is the first and only parameter)
		movq %rdi, %rcx
# %rax will hold the current search location  
		movq heap_begin, %rax   
# %rbx will hold the current break
		movq current_break, %rbx   
		
		movq %rax,a
		movq %rbx,b
		movq %rcx,c


alloc_loop_begin:       

# se for igual, eh comeco de alocacao, sem memoria, eh preciso pedir para alocar      
		cmpq %rbx, %rax
		je move_break

#grab the size of this memory
		movq HDR_SIZE_OFFSET(%rax), %rdx
		movq %rdx,c

#If the space is unavailable, go to the next one
		cmpq $UNAVAILABLE, HDR_AVAIL_OFFSET(%rax)
		je next_location          

# If the space is available, compare#the size to the needed size. If its big 
# enough, go to allocate_here
		cmpq %rdx, %rcx     
		jle allocate_here  

next_location:

		addq $HEADER_SIZE, %rax #The total size of the memory
		addq %rdx, %rax                
# region is the sum of the size requested (currently stored in %rdx), plus 
# another 16 bytes for the header (8 for the AVAILABLE/UNAVAILABLE flag, and 8 
# for the size of the region). So, adding %rdx and $8 to %rax will get the 
# address of the next memory region
		jmp alloc_loop_begin

# if weÂve made it here, that means that the region header of the region to 
# allocate is in %rax

allocate_here:
		movq $UNAVAILABLE, HDR_AVAIL_OFFSET(%rax)
# move %rax past the header to the usable memory (since thatÂs what we return)
		addq $HEADER_SIZE, %rax            
		movq %rbp,%rsp
		popq %rbp
		ret

# if weÂve made it here, that means that we have exhausted all addressable 
# memory, and we need to ask for more. %rbx holds the current endpoint of the 
# data, and %rcx holds its size we need to increase %rbx to where we _want_ 
# memory to end, so we

move_break:
# add space for the headers structure
		addq $HEADER_SIZE, %rbx 

# add space to the break for the data requested
		addq %rcx, %rbx         

# now its time to ask Linux for more memory
		pushq %rax               
		pushq %rcx
		pushq %rbx

		#pushq %rbp
		#movq %rsp,%rbp

		movq $12, %rax
		movq %rbx, %rdi
		#movq %rdx,%rbx
		syscall
# reset the break (%rbx has the requested break point)


# under normal conditions, this should return the new break in %rax, which will 
# be either 0 if it fails, or it will be equal to or larger than we asked for. 
# We donÂt care in this program where it actually sets the break, so as long 
# as %rax isnÂt 0, we donÂt care what it is check for error conditions
		cmpq $0, %rax           
		je error

		popq %rbx
		popq %rcx
		popq %rax


# set this memory as unavailable, since weÂre about to give it away
		movq $UNAVAILABLE, HDR_SIZE_OFFSET(%rax)


# set the size of the memory
		movq %rcx, HDR_SIZE_OFFSET(%rax)

# move %rax to the actual start of usable memory. %rax now holds the return 
# value
		addq $HEADER_SIZE, %rax

		movq %rax,e
		movq %rbx,f
		movq %rcx,g
		movq %rdx,h

# save the new break
		movq %rbx, current_break        
		movq %rbp,%rsp
		popq %rbp
		ret

error:
		movq $0, %rax
		movq %rbp,%rsp
		popq %rbp
		ret

################################################################################
# deallocate##
# PURPOSE:
# The purpose of this function is to give back a region of memory to the pool 
# after weÂre done using it.
#
# PARAMETERS:
# The only parameter is the address of the memory we want to return to the 
# memory pool.
#
# RETURN VALUE:
# There is no return value
#
# PROCESSING:
# If you remember, we actually hand the program the start of the memory that 
# they can use, which is 16 storage locations after the actual start of the
# memory region. All we have to do is go back 16 locations and mark that memory 
# as available, so that the allocate function knows it can use it.
################################################################################
.globl deallocate
.type deallocate,@function

deallocate:
	# since the function is so simple, we donÂt need any of the fancy function stuff
	# get the address of the memory to free (normally this is 16(%rbp), but since
	# we didnÂt push %rbp or move %rsp to %rbp, we can just do 8(%rsp)
	movq %rdi, %rax
	subq $HEADER_SIZE, %rax
	movq $AVAILABLE, HDR_AVAIL_OFFSET(%rax)
	ret

# A program to be called from a C program
# Declaring data that doesn't change
# The actual code
.global print
.type print, @function              #<-Important

print:
  	movq heap_begin, %rax

print2:
	cmpq $UNAVAILABLE, HDR_AVAIL_OFFSET(%rax)
	je next_location2
	jmp next_location3
	ret

next_location2:
		addq $8, %rax #The total size of the memory
			movq %rax,tes

			movq	%rax, %r10
		    movq     $1,%rax               # Move 1(write) into rax
		    movq     $1,%rdi               # Move 1(fd stdOut) into rdi.
	    	movq     $risco,%rsi            # Move the _location_ of the string into rsi
		    movq     risco_length,%rdx             # Move the _length_ of the string into rdx
		    syscall                         # Call the kernel
	   		movq %r10,%rax

	    addq (%rax),%rax
		addq $8,%rax


#		addq $8,%rax
		movq HDR_AVAIL_OFFSET(%rax),%r9
		movq %r9,tes2

		cmpq %rax, current_break
		jne print2
  	ret

  next_location3:
			addq $8, %rax #The total size of the memory
			movq %rax,tes

			movq	%rax, %r10
		    movq     $1,%rax               # Move 1(write) into rax
		    movq     $1,%rdi               # Move 1(fd stdOut) into rdi.
	    	movq     $mais,%rsi            # Move the _location_ of the string into rsi
		    movq     mais_length,%rdx             # Move the _length_ of the string into rdx
		    syscall                         # Call the kernel
	   		movq %r10,%rax

	    addq (%rax),%rax
		addq $8,%rax


#		addq $8,%rax
		movq HDR_AVAIL_OFFSET(%rax),%r9
		movq %r9,tes2

		cmpq %rax, current_break
		jne print2
ret



