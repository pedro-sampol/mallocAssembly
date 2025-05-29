.section .data
	vazio: 		.asciz "<vazio>"  
	charGerencial: 	.byte '#'
	charLivre: 		.byte '-'
	charOcupado: 	.byte '+'
	linha: 			.byte 0x0A

.section .bss
	.lcomm topoHeap, 8		# Topo da heap
    .lcomm baseHeap, 8		# Base da heap
    .lcomm listaVazia, 8	# Inicio da lista vazia
    .lcomm listaOcupada, 8	# Inicio da lista ocupada
    
.extern brk

.section .text                                                                                                                                                                     
.global iniciaAlocador                                                          
.global finalizaAlocador                                                        
.global liberaMem                                                               
.global alocaMem                                                                
.global imprimeMapa

# FUNÇÃO DE INICIALIZAÇÃO
iniciaAlocador:
	pushq %rbp
	movq %rsp, %rbp
	
	movq $12, %rax			
	movq $0, %rdi			
	syscall						# rax <- brk atual

	movq %rax, topoHeap(%rip)	# topoHeap <- endereço de brk
	movq %rax, baseHeap(%rip)	# baseHeap <- endereço de brk

	popq %rbp
	ret


# FUNÇÃO DE FINALIZAÇÃO
finalizaAlocador:
	pushq %rbp
	movq %rsp, %rbp
	
	movq $12, %rax			
	movq baseHeap(%rip), %rdi
	movq %rdi, topoHeap(%rip)	# topoHeap <- baseHeap
	syscall						# brk <- baseHeap
	
	popq %rbp
	ret


# FUNÇÃO DE DESALOCAÇÃO
liberaMem:
	pushq %rbp
	movq %rsp, %rbp
	
	popq %rbp
	ret


# FUNÇÃO DE ALOCAÇÃO	
alocaMem:
	pushq %rbp
	movq %rsp, %rbp
	
	movq %rdi, %r8				# r8 <- tamanho
	
aumentaHeap:
	movq topoHeap(%rip), %r9	# r9 <- antigoTopoHeap
	movq %r9, %r10				# r10 <- antigoTopoHeap
	addq $24, %r10				# r10 <- r10 + 24
	addq %r8, %r10				# r10 <- r10 + tamanho (novoTopoHeap)
	
	movq $12, %rax			
	movq %r10, %rdi				# rdi <- novoTopoHeap
	syscall						# brk <- novoTopoHeap
	
	movq %rdi, topoHeap(%rip)	# topoHeap <- novoTopoHeap
	
	movq $1, (%r9)				# campo 1 = ocupado
	movq %r8, 8(%r9)			# campo 2 = tamanho
	movq $0, 16(%r9)			# campo 3 = ponteiro (0)

fimAlocaMem:
	popq %rbp
	ret


# FUNÇÃO DE IMPRESSÃO
imprimeMapa:
	pushq %rbp
	movq %rsp, %rbp
	
	movq baseHeap(%rip), %r8	# r8 <- baseHeap
	movq topoHeap(%rip), %r9	# r9 <- topoHeap
	
	cmpq %r9, %r8			# se baseHeap == topoHeap, heap vazia
	jne loopImpressão		# impressão da heap

imprimeVazio:
	lea vazio(%rip), %rsi	# rip <- endereço de vazio
    movq $8, %rdx			# rdx <- tamanho da string               
    movq $1, %rax			# rax <- syscall: write
    movq $1, %rdi			# rdi <- stdout
    syscall   
	
	jmp fimImprimeMapa		# finaliza a função de impressão
	
loopImpressão:
	cmpq %r9, %r8			# verifica se r8 >= topoHeap
	jge fimImprimeMapa		# true = finaliza, false = loop
	
	call funcGerencial		# imprimir 24 hashtags
	
	movq (%r8), %r10		# r10 <- livre ou ocupado
	movq 8(%r8), %r14		# r14 <- tamanho
	
	cmpq $0, %r10			# se r10 == 0, livre
	jne ifOcupado			# se r10 != 0, ocupado
	
	pushq %r14				# empilha parametro da função (tamanho)
	call funcLivre			# impressão dos espaços livres
	addq $8, %rsp			# desempilha parametro da função
	
	jmp fimIf				# sai do if
	
ifOcupado:
	pushq %r14				# empilha parametro da função (tamanho)
	call funcOcupado		# impressão dos espaços livres
	addq $8, %rsp			# desempilha parametro da função

fimIf:
	addq $24, %r8
	addq %r14, %r8			# passa para o próximo nodo
	
	jmp loopImpressão		# reinicia o loop de impressão
	
fimImprimeMapa:
	lea linha(%rip), %rsi	# rip <- endereço de linha
    movq $1, %rdx			# rdx <- tamanho da string               
    movq $1, %rax			# rax <- syscall = write                           
    movq $1, %rdi			# rdi <- stdout
    syscall
    
	popq %rbp
	ret


# FUNÇÃO DE IMPRESSÃO GERENCIAL	
funcGerencial:
	pushq %rbp
	movq %rsp, %rbp
	
	movq $0, %r12			# r12 <- iterador
	movq $24, %r13			# r13 <- condição de parada
	
loopGerencial:
	cmpq %r13, %r12
	jge fimFuncGerencial	# enquanto r12 for menor que 24 continua
	
	lea charGerencial(%rip), %rsi	# rip <- endereço de vazio
    movq $1, %rdx					# rdx <- tamanho da string
    movq $1, %rax					# rax <- syscall: write
    movq $1, %rdi					# rdi <- stdout
    syscall
    
    addq $1, %r12			# r12++
    jmp loopGerencial
    
fimFuncGerencial:
	popq %rbp
	ret


# FUNÇÃO DE IMPRESSÃO LIVRE	
funcLivre:
	pushq %rbp
	movq %rsp, %rbp
	
	movq $0, %r12			# r12 <- iterador
	movq 16(%rbp), %r13	# r13 <- condição de parada
	
loopLivre:
	cmpq %r13, %r12
	jge fimFuncLivre		# enquanto r12 for menor que num_bytes
	
	lea charLivre(%rip), %rsi	# rip <- endereço de vazio
    movq $1, %rdx				# rdx <- tamanho da string
    movq $1, %rax				# rax <- syscall: write
    movq $1, %rdi				# rdi <- stdout
    syscall
    
    addq $1, %r12			# r12++
    jmp loopLivre
    
fimFuncLivre:
	popq %rbp
	ret


# FUNÇÃO DE IMPRESSÃO OCUPADO	
funcOcupado:
	pushq %rbp
	movq %rsp, %rbp
	
	movq $0, %r12			# r12 <- iterador
	movq 16(%rbp), %r13	# r13 <- condição de parada
	
loopOcupado:
	cmpq %r13, %r12
	jge fimFuncOcupado		# enquanto r12 for menor que num_bytes
	
	lea charOcupado(%rip), %rsi	# rip <- endereço de vazio
    movq $1, %rdx				# rdx <- tamanho da string
    movq $1, %rax				# rax <- syscall: write
    movq $1, %rdi				# rdi <- stdout
    syscall
    
    addq $1, %r12				# r12++
    jmp loopOcupado
    
fimFuncOcupado:
	popq %rbp
	ret
