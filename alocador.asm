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
	movq $0, listaVazia(%rip)	# listaVazia <- 0
	movq $0, listaOcupada(%rip)	# listaOcupada <- 0

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
	
	movq %rdi, %r8
	subq $24, %r8					# r8 <- endereço do nodo desalocado
	lea listaOcupada(%rip), %r9		# r9 <- endereço da listaOcupada
	movq listaOcupada(%rip), %r10	# r10 <- endereço do nodo atual
	movq %r10, %r11
	addq $16, %r11					# r11 <- endereço do ponteiro atual
	movq %r8, %r12					 
	addq $16, %r12					# r12 <- endereço do ponteiro desalocado
	
	cmpq $0, %r10				# se listaOcupada != 0
	jne fimCheckListaOcupada	# executa normalmente
	
	movq $0, %rax				# se listaOcupada está vazia
	jmp fimLiberaMem			# retorna 0
	
fimCheckListaOcupada:
	movq $0, (%r8)				# verificação <- 0 (vazio)
	
	cmpq (%r9), %r8				# se nodo desalocado != listaOcupada
	jne loopBuscaDesalocado		# procura nodo anterior ao desalocado
	
	movq (%r12), %rax			# rax <- ponteiro desalocado
	movq %rax, (%r9)			# listaOcupada <- rax
	jmp fimBuscaDesalocado		

loopBuscaDesalocado:
	cmpq %r8, (%r11)			# se nodo removido == ponteiro atual
	je fimLoopBuscaDesalocado	# achou o nodo anterior
	
	movq (%r11), %r10			# r10 <- proximo nodo
	movq %r10, %r11
	addq $16, %r11				# r11 <- ponteiro do próximo nodo
	
	jmp loopBuscaDesalocado
	
fimLoopBuscaDesalocado:
	movq (%r12), %rax			# rax <- ponteiro desalocado
	movq %rax, (%r11)			# ponteiro atual <- rax

fimBuscaDesalocado:
	pushq %r8						# empilha nodo desalocado
	lea listaVazia(%rip), %rbx
	pushq %rbx						# empilha endereço da listaVazia
	pushq $0						# empilha 0, indicando listaVazia
	call insereLista				# chama função de inserção
	addq $24, %rsp

	movq $1, %rax				# retorna 1
	
fimLiberaMem:
	popq %rbp
	ret


# FUNÇÃO DE ALOCAÇÃO	
alocaMem:
	pushq %rbp
	movq %rsp, %rbp
	subq $8, %rsp
	
	movq %rdi, %r8				# r8 <- num_bytes
	movq listaVazia(%rip), %r9	# r9 <- endereço do nodo atual (listaVazia)
	movq %r9, %r10				# r10 <- endereço do nodo anterior
	lea listaVazia(%rip), %rcx	# rcx <- endereço da listaVazia
	
loopPercorreVazia:
	cmpq $0, %r9				# se endereço do nodo atual == 0
	je aumentaHeap				# topoHeap aumenta
teste:
	movq %r9, %r11
	addq $8, %r11				# r11 <- endereço do tamanho
	
	movq %r9, %r12
	addq $16, %r12				# r12 <- endereço do ponteiro
	
	cmpq (%r11), %r8			# se num_bytes > tamanho
	jg elseNodoVazioEncontrado	# não encontrou o nodo
	
ifNodoVazioEncontrado:
	movq $1, (%r9)				# verificação <- 1 (ocupado)
	
	cmpq (%rcx), %r9			# se listaVazia != nodo atual
	jne elseNodoListaVazia		# substituição de ponteiro normal
	
	movq (%r12), %rax			# rax <- conteudo do ponteiro
	movq %rax, (%rcx)			# listaVazia <- segundo nodo da lista
	jmp fimNodoListaVazia
	
elseNodoListaVazia:
	addq $16, %r10				# r10 <- endereço do ponteiro anterior
	movq (%r12), %rax			# rax <- conteudo do ponteiro atual
	movq %rax, (%r10)			# ponteiro anterior <- rax

fimNodoListaVazia:	
	movq %r9, %rax					# rax <- endereço do nodo atual
	addq $24, %rax					# rax <- valor de retorno
	movq %rax, -8(%rbp)				# salva rax na variavel antes da função
	
	pushq %r9						# empilha nodo atual
	lea listaOcupada(%rip), %rbx
	pushq %rbx						# empilha endereço da listaOcupada
	pushq $1						# empilha 1, indicando listaOcupada
	call insereLista				# chama função de inserção
	addq $24, %rsp					
	
	movq -8(%rbp), %rax				# rax <- retorno
	jmp fimAlocaMem				
	
elseNodoVazioEncontrado:	
	movq %r9, %r10				# r10 <- endereço do nodo atual
	movq (%r12), %r9			# r9 <- próximo nodo
	
	jmp loopPercorreVazia		# volta para o início do loop
	
aumentaHeap:
	movq topoHeap(%rip), %r9	# r9 <- endereço do topoHeap
	movq %r9, %r10				# r10 <- endereço do topoHeap
	addq $24, %r10				# r10 <- r10 + 24
	addq %r8, %r10				# r10 <- r10 + num_bytes (novoTopoHeap)
	
	movq $12, %rax			
	movq %r10, %rdi				# rdi <- novoTopoHeap
	syscall						# brk <- novoTopoHeap
	
	movq %rdi, topoHeap(%rip)	# topoHeap <- novoTopoHeap
	
	movq $1, (%r9)				# verificação <- 1 (ocupado)
	movq %r8, 8(%r9)			# tamanho <- num_bytes
	movq $0, 16(%r9)			# ponteiro <- 0
	
	lea listaOcupada(%rip), %r11	# r11 <- endereço de listaOcupada
	movq listaOcupada(%rip), %r12	# r12 <- endereço do nodo atual
	movq %r12, %r13					
	addq $16, %r13					# r13 <- endereço do ponteiro
	
	cmpq $0, (%r11)				# se o valor em listaOcupada != 0
	jne loopFimDaOcupada		# vai para o loop
	
	movq %r9, (%r11)			# listaOcupada <- endereço do nodo atual
	jmp fimListaOcupadaVazia	# finaliza código
	
loopFimDaOcupada:
	cmpq $0, (%r13)				# se o valor em r13 == 0
	je fimloopFimDaOcupada		# chegou no fim da fila
	
	movq (%r13), %r12			# r12 <- endereço do próximo nodo
	movq %r12, %r13					
	addq $16, %r13				# r13 <- endereço do ponteiro
	
	jmp loopFimDaOcupada

fimloopFimDaOcupada:
	movq %r9, (%r13)			# ponteiro do penultimo <- ultimo nodo
	
fimListaOcupadaVazia:
	movq %r9, %rax
	addq $24, %rax				# rax <- valor de retorno
	
fimAlocaMem:
	addq $8, %rsp
	popq %rbp
	ret


# FUNÇÃO DE ORDENAÇÃO DE LISTA
insereLista:
	pushq %rbp
	movq %rsp, %rbp
	
	movq 16(%rbp), %rdx			# rdx <- indice (lista vazia ou ocupada)
	movq 24(%rbp), %r8			# r8 <- endereço da variável lista
	
	movq (%r8), %r9				# r9 <- endereço do nodo atual
	movq %r9, %r10				
	addq $16, %r10				# r10 <- endereço do ponteiro atual
	
	movq 32(%rbp), %r11			# r11 <- endereço do nodo inserido
	movq %r11, %r12				
	addq $16, %r12				# r12 <- endereço do ponteiro inserido
	
	movq %r9, %r13				# r13 <- endereço do nodo anterior
	
	cmpq $0, %r9				# se inicio da lista == 0
	jne listaDiferenteZero		# adiciona no inicio da lista
	
	movq %r11, (%r8)			# lista aponta para no inserido
	movq $0, (%r12)				# ponteiro inserido <- 0
	
	jmp fimInsereLista			# finaliza programa

listaDiferenteZero:
	cmpq %r11, %r9				# se nodo atual > nodo inserido
	jle loopPrimeiroNodo		# insere na primeira posição
	
	movq %r9, (%r12)			# ponteiro inserido <- primeiro nodo
	movq %r11, (%r8)			# lista <- endereço do nodo inserido
	
	jmp fimPrimeiroNodo
	
loopPrimeiroNodo:
	cmpq %r11, %r9				# se nodo atual < nodo inserido
	jge fimLoopPrimeiroNodo		# encontrou lugar para inserir
	
	movq %r9, %r13				# r13 <- endereço do nodo atual
	movq %r13, %r14				
	addq $16, %r14				# r14 <- endereço do ponteiro atual	
	movq (%r10), %r9			# r9 <- endereço do proximo nodo
	movq %r9, %r10
	addq $16, %r10				# r10 <- endereço do proximo ponteiro
	
	cmpq $0, (%r14)				# se ponteiro anterior == 0
	je fimLoopPrimeiroNodo		# r13 é o ultimo nodo							 
	
	jmp loopPrimeiroNodo

fimLoopPrimeiroNodo:
	movq (%r14), %rax			# rax <- ponteiro anterior
	movq %rax, (%r12)			# ponteiro inserido <- rax
	movq %r11, (%r14)			# ponteiro anterior <- endereço do nodo inserido
	
fimPrimeiroNodo:
	cmpq $0, %rdx				# se rdx == 0
	jne fimInsereLista			# possível merge dos nodos
	
	cmpq $0, (%r12)				# se proximo nodo == 0
	je endereçosDiferentes		# impossível merge para frente

endereçosIguais:
	movq %r11, %rax
	addq $8, %rax				# rax <- endereço do tamanho inserido
	movq %r11, %rbx
	addq $24, %rbx				# rbx <- endereço do espaço de escrita inserido
	movq %rbx, %rcx
	addq (%rax), %rcx			# rcx <- endereço do pŕoximo nodo na heap
	
	cmpq %rcx, %r9			# se proximo nodo == rcx
	jne endereçosDiferentes		# efetua merge do nodo inserido com próximo
	
	addq $24, (%rax)			# tamanho inserido += 24
	movq %r9, %rbx
	addq $8, %rbx				# rbx <- endereço do próximo tamanho
	movq (%rbx), %rcx			# rcx <- próximo tamanho
	addq %rcx, (%rax)			# tamanho inserido += rcx
	
	addq $8, %rax				# rax <- endereço do ponteiro inserido
	addq $8, %rbx				# rbx <- endereço do próximo ponteiro
	movq (%rbx), %rcx			# rcx <- próximo ponteiro
	movq %rcx, (%rax)			# ponteiro atual <- rcx
	
endereçosDiferentes:
	movq %r13, %rax
	addq $8, %rax				# rax <- endereço do tamanho anterior
	movq %r13, %rbx
	addq $24, %rbx				# rbx <- endereço do espaço de escrita anteior
	movq %rbx, %rcx
	addq (%rax), %rcx			# rcx <- endereço do pŕoximo nodo na heap
	
	cmpq %rcx, %r11				# se rcx == nodo inserido
	jne fimInsereLista			# efetua merge do nodo anterior com inserido
	
	addq $24, (%rax)			# tamanho anteiror += 24
	movq %r11, %rbx
	addq $8, %rbx				# rbx <- endereço do tamanho inserido
	movq (%rbx), %rcx			# rcx <- tamanho inserido
	addq %rcx, (%rax)			# tamanho anterior += rcx
	
	addq $8, %rax				# rax <- endereço do ponteiro anteior
	addq $8, %rbx				# rbx <- endereço do ponteiro inserido
	movq (%rbx), %rcx			# rcx <- ponteiro inserido
	movq %rcx, (%rax)			# ponteiro anteiror <- rcx

fimInsereLista:
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
	movq 16(%rbp), %r13		# r13 <- condição de parada
	
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
