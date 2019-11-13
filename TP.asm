.8086
.model small
.stack 2048h    

GOTO_XY	MACRO	X,Y
	MOV	AH,02H
	MOV	BH,0
	MOV	DL,X
	MOV	DH,Y
	INT	10H
ENDM          

PRINTF MACRO STR 
	MOV AH,09H
	LEA DX,STR 
	INT 21H
ENDM   

PAUSE MACRO
	PUSH AX
	PRINTF anyKey
	mov ah, 0         ; esperar uma tecla
	int 16h
	POP AX
ENDM   

SCANF MACRO
	mov ah, 01h
    int 21h
ENDM 
          
                                           
                                    
dseg    segment para public 'data'      
    STR12	 		            DB 	"            "; String para 12 digitos 
    Segundos		            dw	0	; Vai guardar os minutos actuais 
    CronometroS                 dw  0   ;contador de segundos
    CronometroM                 dw  0   ;contador de segundos
    Old_seg		                dw	0	; Guarda os últimos segundos que foram lidos 
	
    POSy	                    db	10	; a linha pode ir de [1 .. 25]
    Iniy	                    db	10	; a linha pode ir de [1 .. 25]
    
	POSx	                    db	10	; POSx pode ir [1..80]	
	Inix	                    db	10	; POSx pode ir [1..80]	
    
    Erro_Open		            db	'Erro ao tentar abrir o ficheiro$'
    Erro_Ler_Msg	            db	'Erro ao tentar ler do ficheiro$'
    Erro_Close		            db	'Erro ao tentar fechar o ficheiro$'
	anyKey						db	0Dh,0Ah, 'Prima qualquer tecla para continuar',0Dh,0Ah, '$'
    debugSTR		            db	'ENTREI$'
	debugINT					db ?
	
	fbuffer		                db	40 dup (?)	
	;fbuffer		                db	?	
    fileName		            db	'lbt.txt',0 
    ; top_file		            db	'top10.txt',0
	; fileName					db	?
    HandleFich		            dw	0
    car_fich		            db	?
	contador		          	dw	5
	monitor 					db 4000 dup (?)
	
	msgErrorCreate	          	db  "Ocorreu um erro na criacao do ficheiro!$"
	msgErrorWrite	          	db	"Ocorreu um erro na escrita para ficheiro!$"
	msgErrorClose	          	db	"Ocorreu um erro no fecho do ficheiro!$"	
	
	menu_principal            	db  "Escolha uma opcao:",0Dh,0Ah, "$"; ,0Dh,0Ah, -> \n
	menu_principal_opcao1     	db  "1 - Novo jogo",0Dh,0Ah, "$"
	menu_principal_opcao2     	db  "2 - Novo jogo Hexadecimal",0Dh,0Ah, "$"  
	menu_principal_opcao3     	db  "3 - Editar Labirinto",0Dh,0Ah, "$"
	menu_principal_opcao4     	db  "4 - Sair",0Dh,0Ah, "$"
	
	Car							db	32	; Guarda um caracter do Ecran 
	Cor							db	7	; Guarda os atributos de cor do caracter
	POSya						db	5	; Posição anterior de y
	POSxa						db	10	; Posição anterior de x
	case_vitoria				db 	0Dh,0Ah, 'Parabens venceu o labirinto!',0Dh,0Ah, '$'
	vector_hexa 				db  '1','2','3','4','5','6','7','8','9','a','b','c','d','e','f'
	vector_Passos				db	'1','2','3','1','2','3','4','1','2','3','4','1','2','3','4' 
	         
	        
	
dseg	ends

cseg	segment para public 'code'
	assume  cs:cseg, ds:dseg
	
LER_FICHEIRO PROC 
    ;abre ficheiro
    call 	CLEAR
    mov     ah,3dh			; vamos abrir ficheiro para leitura 
    mov     al,0			; tipo de ficheiro	
    lea     dx,fileName			; nome do ficheiro
    int     21h			; abre para leitura 
    jc      erro_abrir		; pode aconter erro a abrir o ficheiro 
    mov     HandleFich,ax		; ax devolve o Handle para o ficheiro
	goto_xy 0,0	
    jmp     ler_ciclo		; depois de abero vamos ler o ficheiro 

  erro_abrir:
    mov     ah,09h
    lea     dx,Erro_Open
    int     21h
    

 ler_ciclo:
    mov     ah,3fh			; indica que vai ser lido um ficheiro 
    mov     bx,HandleFich		; bx deve conter o Handle do ficheiro previamente aberto 
    mov     cx,1			; numero de bytes a ler 
    lea     dx,car_fich		; vai ler para o local de memoria apontado por dx (car_fich) 
    
	
    int     21h				; faz efectivamente a leitura
    jc	    erro_ler		; se carry é porque aconteceu um erro
    cmp	    ax,0			;   EOF?	verifica se já estamos no fim do ficheiro 
    je	    fecha_ficheiro	; se EOF fecha o ficheiro 
    mov     ah,02h			; coloca o caracter no ecran
    mov	    dl,car_fich		; este é o caracter a enviar para o ecran
	cmp     dl, '*'
	je 		changechar
    int	    21h				; imprime no ecran
    jmp	    ler_ciclo		; continua a ler o ficheiro
	
 changechar:
	mov dl, 0DBh
	int	    21h				; imprime no ecra
	jmp ler_ciclo

 erro_ler:
    mov     ah,09h
    lea     dx,Erro_Ler_Msg
    int     21h
	
	
 fecha_ficheiro:					; vamos fechar o ficheiro 
    mov     ah,3eh
    mov     bx,HandleFich
    int     21h	
    jmp     sai

    mov     ah,09h			; o ficheiro pode não fechar correctamente
    lea     dx,Erro_Close
    int     21h 	
	

 sai:		
	goto_xy 0,0
	
	ret
   
LER_FICHEIRO ENDP            


ESCREVE_FICHEIRO Proc
	mov		ax,0B800h
	mov		es,ax
	xor 	si,si
	xor 	bx,bx
	xor 	di,di
	mov 	cx, 25*80
	xor 	dx,dx
	
	
toArray:
	xor ah, ah
	
	mov al, es:[bx]
	add bx,2
	mov monitor[si],al
	cmp si,4000; fim do array monitor  
	je cont	
	cmp monitor[si], 190;avatar
	je isAvatar
	cmp monitor[si], 0DBh
	je isWall	
	
	mov al, 40; valor da coluna
	mov dx, di; valor da linha
	mul dx
	cmp si,ax; compara valor do contador do array com o valor em q tem de dar enter
	
	je mudalinha; se o valores coincidirem salta pq e final da linha
	; cmp di, 20
	; je cont
	
	
	inc si
	
loop toArray
isAvatar:
	mov monitor[si], ' '
	inc si
	jmp toArray
isWall:
	mov monitor[si], '*'
	inc si
	jmp toArray
	
mudalinha:

	cmp di,20
	jmp cont
	
	mov monitor[si], 0Dh
	inc si
	inc di
	jmp toArray
	
	
cont:	
	mov	ah, 3ch			; abrir ficheiro para escrita 
	mov	cx, 00H			; tipo de ficheiro
	lea	dx, fileName	; dx contem endereco do nome do ficheiro 
	int	21h				; abre efectivamente e AX vai ficar com o Handle do ficheiro 
	jnc	escreve			; se não acontecer erro vai vamos escrever
	
	mov	ah, 09h			; Aconteceu erro na leitura
	lea	dx, msgErrorCreate
	int	21h
	
	jmp	fim

escreve:
	
	xor dx,dx
	mov	bx, ax			; para escrever BX deve conter o Handle 
	mov	ah, 40h			; indica que vamos escrever    	
	lea	dx, monitor			; Vamos escrever o que estiver no endereço DX
	mov	cx, 1560			; vamos escrever multiplos bytes duma vez só
	int	21h				; faz a escrita 
	jnc	close				; se não acontecer erro fecha o ficheiro 
	
	mov	ah, 09h
	lea	dx, msgErrorWrite
	int	21h
close:
	mov	ah,3eh			; indica que vamos fechar
	int	21h				; fecha mesmo
	jnc	fim				; se não acontecer erro termina
	
	mov	ah, 09h
	lea	dx, msgErrorClose
	int	21h
fim:
	ret
ESCREVE_FICHEIRO ENDP


    ;########################################################################
; LE UMA TECLA	

LE_TECLA	PROC
		mov		ah,08h
		int		21h
		mov		ah,0
		cmp		al,0
		jne		SAI_TECLA
		mov		ah, 08h
		int		21h
		mov		ah,1
SAI_TECLA:	
		RET
LE_TECLA	endp

;########################################################################

MOVIMENTO  PROC 
				
		mov		ax,0B800h
		mov		es,ax
		mov 	cx, 25*80
		
		mov 	bh, Inix
		mov 	POSx, bh
		mov 	POSxa, bh
		mov 	bh,Iniy
		mov 	POSy, bh
		mov 	POSya, bh
	
		;mov		Car, al	; Guarda o Caracter que está na posição do Cursor
		goto_xy	POSx,POSy	; Vai para nova possição
		mov 	ah, 08h	; Guarda o Caracter que está na posição do Cursor
		mov		bh,0		; numero da página
		int		10h			
		mov		Car, al	; Guarda o Caracter que está na posição do Cursor
		mov		Cor, ah	; Guarda a cor que está na posição do Cursor

CICLO:	
		goto_xy	POSxa,POSya	; Vai para a posição anterior do cursor
		mov		ah, 02h
		mov		dl, Car	; Repoe Caracter guardado 
		int		21H		

		goto_xy	POSx,POSy	; Vai para nova possição
		

		mov 	ah, 08h
		mov		bh,0		; numero da página
		int		10h		
		mov		Car, al	; Guarda o Caracter que está na posição do Cursor
		mov		Cor, ah	; Guarda a cor que está na posição do Cursor
		cmp 	Car, 0DBh
		je 		PAREDE
		cmp 	Car,'X'
		je 		VITORIA	
	
		goto_xy	POSx,POSy	; Vai para posição do cursor
		jmp imprime
PAREDE:
		mov ah, POSxa
		mov POSx,	ah
		mov ah, POSya
		mov POSy, ah
		mov Car, 0
		
		mov		ah, POSx	; Guarda a posição do cursor
		mov		POSxa, ah
		mov		ah, POSy	; Guarda a posição do cursor
		mov 	POSya, ah
		goto_xy	POSx,POSy

		jmp CICLO	
		
VITORIA:		
		goto_xy	0,25
		PRINTF case_vitoria
		PAUSE
		ret	
		
IMPRIME:	
		mov		ah, 02h
		mov		dl, 190	; Coloca AVATAR
		int		21H	
		goto_xy	POSx,POSy	; Vai para posição do cursor
		
		mov		al, POSx	; Guarda a posição do cursor
		mov		POSxa, al
		mov		al, POSy	; Guarda a posição do cursor
		mov 	POSya, al
		
LER_SETA:	
		
		call LE_TECLA		
		
		cmp	ah, 1
		je		ESTEND		
		
		CMP 	AL, 27	; ESCAPE
		JE		EXIT
		jmp		LER_SETA
		
ESTEND:	cmp 		al,48h
		jne		BAIXO
		dec		POSy		;cima
		jmp		CICLO

BAIXO:	cmp		al,50h
		jne		ESQUERDA
		inc 	POSy		;Baixo
		jmp		CICLO

ESQUERDA:
		cmp		al,4Bh
		jne		DIREITA
		dec		POSx		;Esquerda
		jmp		CICLO

DIREITA:
		cmp		al,4Dh
		jne		LER_SETA 
		inc		POSx		;Direita
		jmp		CICLO
	
		
EXIT: 
	; call MENUPRINCIPAL
	ret

MOVIMENTO ENDP 


;########################################################################

MOVIMENTO_EDIT  PROC 
		
		mov		ax,0B800h
		mov		es,ax
		mov 	cx, 25*80
		
		mov 	bh, Inix
		mov 	POSx, bh
		mov 	POSxa, bh
		mov 	bh,Iniy
		mov 	POSy, bh
		mov 	POSya, bh
	
		goto_xy	POSx,POSy	; Vai para nova possição
		mov 	ah, 08h	; Guarda o Caracter que está na posição do Cursor
		mov		bh,0		; numero da página
		int		10h			
		mov		Car, al	; Guarda o Caracter que está na posição do Cursor
		mov		Cor, ah	; Guarda a cor que está na posição do Cursor
		

CICLO:	
		goto_xy	POSxa,POSya	; Vai para a posição anterior do cursor
		mov		ah, 02h
		mov		dl, Car	; Repoe Caracter guardado 
		int		21H		

		goto_xy	POSx,POSy	; Vai para nova possição
		

		mov 	ah, 08h
		mov		bh,0		; numero da página
		int		10h		
		mov		Car, al	; Guarda o Caracter que está na posição do Cursor
		mov		Cor, ah	; Guarda a cor que está na posição do Cursor
		cmp 	POSx, 39
		je 		PAREDE
		cmp		POSx, 0
		je 		PAREDE
		cmp		POSy, 0
		je 		PAREDE
		cmp 	POSy, 19
		je 		PAREDE
		
		goto_xy	POSx,POSy	; Vai para posição do cursor
		jmp imprime
PAREDE:
		mov ah, POSxa
		mov POSx,	ah
		mov ah, POSya
		mov POSy, ah
		mov Car, 0
		
		mov		ah, POSx	; Guarda a posição do cursor
		mov		POSxa, ah
		mov		ah, POSy	; Guarda a posição do cursor
		mov 	POSya, ah
		goto_xy	POSx,POSy

		jmp CICLO	
		
TROCA:	
	cmp		Car, 'X'
	je		CICLO 
	cmp		Car, 20h
	je		TROCAESPACO 	
	cmp 	Car, 0DBh
	mov 	Car, 20h
	mov		ah, 02h
	mov		dl, Car	; Repoe Caracter guardado 
	int		21H	
	jmp 	CICLO

TROCAESPACO:		
	mov 	Car, 0DBh
	mov		ah, 02h
	mov		dl, Car	; Repoe Caracter guardado 
	int		21H	
	jmp 	CICLO	
IMPRIME:	
		mov		ah, 02h
		mov		dl, 190	; Coloca AVATAR
		int		21H	
		goto_xy	POSx,POSy	; Vai para posição do cursor
		
		mov		al, POSx	; Guarda a posição do cursor
		mov		POSxa, al
		mov		al, POSy	; Guarda a posição do cursor
		mov 	POSya, al
		
LER_SETA:	
		call 		LE_TECLA
		cmp		ah, 1
		je		ESTEND
		CMP 	AL, 20h	; ESPACO
		JE		ESPACO
		CMP 	AL, 27	; ESCAPE
		JE		EXIT
		jmp		LER_SETA
ESPACO:
		jmp TROCA
ESTEND:	cmp 		al,48h
		jne		BAIXO
		dec		POSy		;cima
		jmp		CICLO

BAIXO:	cmp		al,50h
		jne		ESQUERDA
		inc 	POSy		;Baixo
		jmp		CICLO

ESQUERDA:
		cmp		al,4Bh
		jne		DIREITA
		dec		POSx		;Esquerda
		jmp		CICLO

DIREITA:
		cmp		al,4Dh
		jne		LER_SETA 
		inc		POSx		;Direita
		jmp		CICLO
		
EXIT: 
	call ESCREVE_FICHEIRO
	ret

MOVIMENTO_EDIT ENDP 

MOVIMENTO_HEXA Proc
	
		mov		ax,0B800h
		mov		es,ax
		mov 	cx, 25*80
		
		mov 	bh, Inix
		mov 	POSx, bh
		mov 	POSxa, bh
		mov 	bh,Iniy
		mov 	POSy, bh
		mov 	POSya, bh
		
		goto_xy	POSx,POSy	; Vai para nova possição
		mov 	ah, 08h	; Guarda o Caracter que está na posição do Cursor
		mov		bh,0		; numero da página
		int		10h			
		mov		Car, al	; Guarda o Caracter que está na posição do Cursor
		mov		Cor, ah	; Guarda a cor que está na posição do Cursor
		
		
		

CICLO:	
		
		xor si,si
		goto_xy	POSxa,POSya	; Vai para a posição anterior do cursor
		mov		ah, 02h
		mov		dl, Car	; Repoe Caracter guardado 
		int		21H		

		goto_xy	POSx,POSy	; Vai para nova possição
		

		mov 	ah, 08h
		mov		bh,0		; numero da página
		int		10h		
		mov		Car, al	; Guarda o Caracter que está na posição do Cursor
		mov		Cor, ah	; Guarda a cor que está na posição do Cursor
		
		cmp 	POSx, 39
		jge 	PAREDE
		cmp		POSx, 0
		jle 	PAREDE
		cmp		POSy, 0
		jle 	PAREDE
		cmp 	POSy, 19
		jge 	PAREDE


		
		cmp 	Car, 0DBh
		je 		PAREDE
		cmp 	Car,'X'
		je 		VITORIA				
	
		goto_xy	POSx,POSy	; Vai para posição do cursor
		jmp imprime
	
PAREDE:
		mov ah, POSxa
		mov POSx,	ah
		mov ah, POSya
		mov POSy, ah
		mov Car, 0
		
		mov		ah, POSx	; Guarda a posição do cursor
		mov		POSxa, ah
		mov		ah, POSy	; Guarda a posição do cursor
		mov 	POSya, ah
		goto_xy	POSx,POSy

		jmp CICLO	
		
VITORIA:		
		goto_xy	0,25
		PRINTF case_vitoria
		PAUSE
		ret	
		
IMPRIME:	
		mov		ah, 02h
		mov		dl, 190	; Coloca AVATAR
		int		21H	
		goto_xy	POSx,POSy	; Vai para posição do cursor
		
		mov		al, POSx	; Guarda a posição do cursor
		mov		POSxa, al
		mov		al, POSy	; Guarda a posição do cursor
		mov 	POSya, al
		
LER_INPUT:
		
		call LE_TECLA
		
		CMP 	AL, 27	; ESCAPE
		JE		EXIT
		

		cmp al, '1'
		jae Direcao
		cmp al, '9'
		jle Direcao
		
		cmp al,'f'
		jbe Direcao
		cmp al,'a'
		jae Direcao
		
		

Direcao:
		
		cmp al, vector_hexa[si]
		jne incHexa	
		cmp si, 3
		jl MoverNor
		cmp si, 7
		jl MoverSul
		cmp si, 11
		jl MoverDir
		cmp si, 15
		jle MoverEsq
		
		jmp CICLO
		
MoverNor:
		mov al,vector_Passos[si]
		sub al, 30h
		sub POSy,al
		cmp POSy, 0
		jmp CICLO
		
MoverSul:
		mov al,vector_Passos[si]
		sub al, 30h
		add POSy,al	
		jmp CICLO
		
MoverDir:
		mov al,vector_Passos[si]
		sub al, 30h
		sub POSx,al	
		jmp CICLO

MoverEsq:
		mov al,vector_Passos[si]
		sub al, 30h
		add POSx,al		
		jmp CICLO
incHexa:
		inc si
		cmp si,15
		je CICLO
		jmp Direcao
		
EXIT: 
	; call MENUPRINCIPAL
	ret

MOVIMENTO_HEXA ENDP





MENUPRINCIPAL Proc
	mov		ax,0B800h
	mov		es,ax
	mov 	cx, 25*80
	goto_xy 0,0
	call CLEAR
	
    PRINTF menu_principal 
    PRINTF menu_principal_opcao1
    PRINTF menu_principal_opcao2 
    PRINTF menu_principal_opcao3 
    PRINTF menu_principal_opcao4 
    ;PAUSE
    
    ret
MENUPRINCIPAL endp 
    
CLEAR	proc 
		mov		ax,0B800h
		mov		es,ax 
		xor		bx,bx
		mov		cx,25*80
		
apaga:			
		mov	byte ptr es:[bx],' '
		mov		byte ptr es:[bx+1],7
		inc		bx
		inc 		bx
		loop		apaga
		ret
CLEAR endp

  
Main	Proc
	mov     ax,dseg
	mov     ds,ax 
	mov		ax,0B800h
	mov		es,ax	
	
menu:
		
	call MENUPRINCIPAL   	   
	SCANF
	
	cmp al, '1'
    jl  menu
	
	cmp al, '4'
    jg  menu
    
    cmp al, '1'
    je  op1
    
    cmp al, '2'
    je op2
    
    cmp al, '3'
    je op3 
		
	cmp al, '4'
	je op4
	

op1:
	
	call LER_FICHEIRO
	call MOVIMENTO
	jmp	menu

op2:
	call LER_FICHEIRO
	call MOVIMENTO_HEXA
	jmp	menu
	pause
   
op3:
	call LER_FICHEIRO
	call MOVIMENTO_EDIT
	jmp	menu
	PAUSE
  	jnc exit
op4:
	PAUSE
  	jnc exit
exit:
	mov     ah,4ch
	int     21h
Main	endp     

cseg	ends
end	Main           
