;------------------------------------------------------------------------
;	TRABALHO PRATICO - TECNOLOGIAS e ARQUITECTURAS de COMPUTADORES
;   
;	ANO LECTIVO 2014/2015
;   Luís Jordão - 21201026
;   André Oliveira - 21200800
;
;------------------------------------------------------------------------
; MACROS
;------------------------------------------------------------------------
GOTO_XY MACRO POSX,POSY
	MOV	AH,02H
	MOV	BH,0
	MOV	DL,POSX
	MOV	DH,POSY
	INT	10H
ENDM
;------------------------------------------------------------------------
PRINT MACRO STR 
    MOV AH,09H
    LEA DX,STR 
    INT 21H
ENDM
;---------------------------------------------------------------------------
PAUSE MACRO
	PUSH AX
	mov ah, 0         ; esperar uma tecla
	int 16h
	POP AX
ENDM
;---------------------------------------------------------------------------
PUTC MACRO char
    push    ax
    mov     al, char
    mov     ah, 0eh
    int     10h     
    pop     ax
endm
;---------------------------------------------------------------------------
NewLine MACRO
    mov     ah, 02h
	mov		dl, 13		; muda de linha (carr)
	int		21h
	
    mov     ah, 02h     ; nova linha
	mov		dl, 10
	int		21h
Endm
;------------------------------------------------------------------------
; FIM MACROS
;------------------------------------------------------------------------
.8086
.model small
.stack 2048h
dseg    segment para public 'data'
        menuItems       db      0Dh,0Ah, '1 . Iniciar Jogo',0Dh,0Ah         
                        db      '2 . Consultar ',0Dh,0Ah
                        db      '3 . Sair ',0Dh,0Ah, '$'      
        menuError       db      0Dh,0Ah,'Erro: Opcao Invalida, escolha de 1 a 3! ',0Dh,0Ah, '$'
        
		stringTeste     db      '1,2,3,4,5$',13,10 
		
		
		;len equ $-stringTeste 
		len             dw      0
		fhandler        dw      0
		fhistorico  	db	    'historico.txt',0
		fref          	db	    'referencias.txt',0
		
		
		historico		db		99 dup (?)
		refs    		db		99 dup (?)
		
		
        Erro_Open       db      'Erro ao tentar abrir o ficheiro$'
        Erro_Ler_Msg    db      'Erro ao tentar ler do ficheiro$'
        Erro_Close      db      'Erro ao tentar fechar o ficheiro$'
        
        Horas			dw		0				; Vai guardar a HORA actual
		Minutos			dw		0				; Vai guardar os minutos actuais
		Segundos		dw		0				; Vai guardar os segundos actuais
		Old_seg			dw		0				; Guarda os últimos segundos que foram lidos
		
		dado1			db		99 dup (32)
		oper1			db		99 dup (32)
		dado2			db		99 dup (32)
		oper2			db		99 dup (32)
		dado3			db		99 dup (32)
		
		curr_dado1		db		?
		curr_dado2		db		?
		curr_dado3		db		?
		curr_oper1      db      ?
		curr_oper2      db      ?
		curr_result     dw      ?
		input_result    dw      0			
		
        Fich         	db      'config.txt',0
        HandleFich      dw      0
        car_fich        db      ?
		id1				dw		0
		iop1			dw		0
		id2				dw		0
		contador		dw		5
		
		gameSecs        db      0
		gameSecsOld     db      0
		score           db      1
		totalScore      dw      0
		hardMode        db      0
		
		equals          db      '=$'
		str_correct     db      'Correcto!$'
		str_incorrect   db      'Incorrecto!$'
		str_endgame     db      'Acabou o tempo!$'
		str_Segundos    db      'Segundos:  $'
		str_Pontos      db      'Pontos:  $'
		
		POSy	db	10	; a linha pode ir de [1 .. 25]
		POSx	db	40	; POSx pode ir [1..80]	
		NUMDIG	db	0	; controla o numero de digitos do numero lido
		MAXDIG	db	7	; Constante que define o numero MAXIMO de digitos a ser aceite
		STR12	 		DB 		'            '	; String para 12 digitos	
		NUMERO			DB		'                    $'	; String destinada a guardar o número lido
		NUM_SP			db		'                    $' 	; PAra apagar zona de ecran

dseg    ends

cseg    segment para public 'code'
		assume  cs:cseg, ds:dseg	
		
Main    Proc
    MOV     AX,DSEG
    MOV     DS,AX
	MOV		AX,0B800H
	MOV		ES,AX		        ; ES É PONTEIRO PARA MEM VIDEO
	 
	CALL 	CONFIG              ; Copia dados do ficheiro e preenche os arrays
	
	MainMenu:
	    CALL CLRSCR
    	PRINT menuItems
          
        ;Ler opção escolhida
        mov ah, 01h
        int 21h
        
        cmp al, '1'
        je NEWGAME
        
        cmp al, '2'
        je NEWGAME
        
        cmp al, '3'
        je exit   
        
        PRINT menuError
        PAUSE   
    jmp MainMenu 
    	
exit:    
    MOV	AH,4Ch
	INT	21h
MAIN    endp
;------------------------------------------------------------------------
; PROCS
;------------------------------------------------------------------------
PrintInfo Proc
    
PrintInfo Endp
SecondCounter Proc
    Push Ax
    Push Dx
    MOV AH, 2CH             ; Buscar a hORAS
    INT 21H                 
    ;dh - segundos
    CMP DH,gameSecsOld
    je fim_sc
       cmp dh,90
       jb  non_hard_mode_continue 
            mov al,1
            mov hardMode,al
       non_hard_mode_continue:
       mov al,gameSecs
       INC AL
       MOV gameSecs, AL
       MOV gameSecsOld, DH
       
       goto_xy	20,3
	   PRINT	str_Segundos
	   xor      ah,ah
	   mov      al,gameSecs
	   CALL     PRINT_NUM			
	   goto_xy	20,10
    fim_sc:
    POP DX
    POP AX
    ret
SecondCounter endp
;------------------------------------------------------------------------
CLRSCR PROC       
    PUSH AX
    PUSH DX
    PUSH BX
    ;clearscreen
    mov ax, 03h
    int 10h

    ;posiciona o cursor

    mov dh, 2
    mov dl, 2
    mov bh, 0
    mov ah, 2
    int 10h 
    
    POP BX
    POP DX
    POP AX
    RET 
CLRSCR ENDP
;------------------------------------------------------------------------
CONFIG PROC
    ;abre ficheiro
        mov     ah,3dh
        mov     al,0
        lea     dx,Fich
        int     21h				; Chama a rotina de abertura de ficheiro (AX fica com Handle)
        jc      erro_abrir
        mov     HandleFich,ax
		xor		si,si			; indice da matriz dado1 inicia a zero
        jmp     ler_ciclo1

erro_abrir:
        mov     ah,09h
        lea     dx,Erro_Open
        int     21h
        jmp     sai_ficheiro

		
ler_ciclo1:							; faz a leitura da primeira linha do ficheiro
        mov     ah, 3fh
        mov     bx, HandleFich
        mov     cx, 1				; vai ler apenas um byte de cada vez
        lea     dx, car_fich		; DX fica a apontar para o caracter lido
        int     21h				; lê um caracter do ficheiro
		jc		erro_ler
		cmp		ax, 0			; verifica se já chegou o fim de ficheiro EOF? 
		je		fecha_ficheiro	; se chegou ao fim do ficheiro fecha e sai
		cmp		car_fich, 13	; verifica se já chegou ao fim da linha do ficheiro
		je		ler_oper1		; terminou de ler os dados1 e vai agora les os oper1
		
        mov     ah, 02h			; escreve o caracter no ecran
		mov		dl, car_fich
		mov 	dado1[si], dl	; e tambem guarda na matriz dado1
		inc		si		
		int		21h				; escreve no ecran
		jmp		ler_ciclo1		; vai ler o próximo caracter

ler_oper1:						; vai agora tratar a segunda linha do ficheiro
        NewLine

		mov 	dado1[si], '$'	; termina a matriz dado1
		xor		si, si			; inicia o si que agora serve de indice de oper1
		
ler_ciclo2:						; Trata a segunda linha do ficheiro e coloca em oper1
        mov     ah, 3fh
        mov     bx, HandleFich
        mov     cx, 1
        lea     dx, car_fich
        int     21h				; lê um caracter do ficheiro
		jc		erro_ler
		cmp		ax, 0			;EOF? 
		je		fecha_ficheiro	; se chegou ao fim do ficheiro fecha e sai
		cmp		car_fich, 13
		je		ler_dado2		; terminou de ler os oper1 e vai agora ler os dados2
		cmp		car_fich, 10
		je		ler_ciclo2		; se caracter LF (carecter 10) vai buscar outro
		
        mov     ah, 02h
		mov		dl, car_fich
		mov 	oper1[si], dl	; guarda o caracter em oper1 e tambem imprime no ecran
		inc		si		
		int		21h
		jmp		ler_ciclo2
		
ler_dado2:		
        NewLine
		
		mov 	oper1[si], '$';
		xor		si, si			
		
ler_ciclo3:							; mais um ciclo parecido com os anteriores para tratar a terceira linha
        mov     ah, 3fh
        mov     bx, HandleFich
        mov     cx, 1
        lea     dx, car_fich
        int     21h					; lê um caracter do ficheiro
		jc		erro_ler
		cmp		ax, 0				;EOF? 
		je		fecha_ficheiro		; se chegou ao fim do ficheiro fecha e sai
		cmp		car_fich, 13
		;je		fecha_ficheiro		; terminou de ler os dado2
		je      ler_oper2
		cmp		car_fich, 10
		je		ler_ciclo3			; se caracter LF (carecter 10) vai buscar outro		
		
        mov     ah, 02h
		mov		dl, car_fich
		mov 	dado2[si], dl	
		inc		si
		int		21h
		jmp		ler_ciclo3
;%
ler_oper2:						; vai agora tratar a quarta linha do ficheiro
        NewLine

		mov 	dado2[si], '$'	; termina a matriz dado1
		xor		si, si			; inicia o si que agora serve de indice de oper1
		
ler_ciclo4:						; Trata a segunda linha do ficheiro e coloca em oper1
        mov     ah, 3fh
        mov     bx, HandleFich
        mov     cx, 1
        lea     dx, car_fich
        int     21h				; lê um caracter do ficheiro
		jc		erro_ler
		cmp		ax, 0			;EOF? 
		je		fecha_ficheiro	; se chegou ao fim do ficheiro fecha e sai
		cmp		car_fich, 13
		je		ler_dado3		; terminou de ler os oper2 e vai agora ler os dados3
		cmp		car_fich, 10
		je		ler_ciclo4		; se caracter LF (carecter 10) vai buscar outro
		
        mov     ah, 02h
		mov		dl, car_fich
		mov 	oper2[si], dl	; guarda o caracter em oper2 e tambem imprime no ecran
		inc		si		
		int		21h
		jmp		ler_ciclo4
ler_dado3:		
        NewLine
		
		mov 	oper2[si], '$';
		xor		si, si			
		
ler_ciclo5:							; mais um ciclo parecido com os anteriores para tratar a terceira linha
        mov     ah, 3fh
        mov     bx, HandleFich
        mov     cx, 1
        lea     dx, car_fich
        int     21h					; lê um caracter do ficheiro
		jc		erro_ler
		cmp		ax, 0				;EOF? 
		je		fecha_ficheiro		; se chegou ao fim do ficheiro fecha e sai
		cmp		car_fich, 13
		je		fecha_ficheiro		; terminou de ler os dado3
		cmp		car_fich, 10
		je		ler_ciclo5			; se caracter LF (carecter 10) vai buscar outro		
		
        mov     ah, 02h
		mov		dl, car_fich
		mov 	dado3[si], dl	
		inc		si
		int		21h
		jmp		ler_ciclo5			
;%		
erro_ler:
        mov     ah,09h
        lea     dx,Erro_Ler_Msg
        int     21h

fecha_ficheiro:
        mov     ah,3eh
        mov     bx,HandleFich
        int     21h
        jnc     sai_ficheiro

        mov     ah,09h
        lea     dx,Erro_Close
        Int     21h
sai_ficheiro:
        ret
CONFIG ENDP
;------------------------------------------------------------------------
NEWGAME PROC
    call clrscr
    mostra_perguntas:
        NewLine

		mov 	dado2[si], '$';
		mov		cx, 5				; o numero de operações que se pretende mostrar
		
; Mostrar no ecran as primeiras  operações 	
		
ciclo_perguntas:                    ; cada operando tem no minimo 1 digito
        mov     al,1
        mov     score,al
        
		goto_xy	20,8
	    PRINT   NUM_SP
        goto_xy	20,8
        
		mov 	contador, cx
		mov		si, id1

ler_d1:	mov		dl, dado1[si]		; vai buscar um caracter a dado1
		cmp		dl, ' '				; se for espaço vai tratar o operador
		je		proximo_d1
		cmp     dl,'$'
		je      ler_op1
		mov     ah, 02h
		int		21h					; imprime no ecran e vai buscar proximo digito do primeiro dado
		    
	    sub     dl,48               ; converter char para int
	    ;xor     dh,dh
	    mov     curr_dado1, dl
	    cmp     si,0
	    je      ler_d1_fim
        ;senão for o 1 elemento do vector, analisar se é num. de 2 digitos
        push    si
        dec     si
        mov     dh,dado1[si]   ; Verificar se o digito anterior faz parte deste numero
        pop     si
        cmp     dh,' '
        je      ler_d1_fim
		        
        sub     dh,48          ; ok, entao converter o digito anterior para int
        xor     ax,ax
        ;xor     bx,bx
        mov     al,score
        inc     al             ; Estamos a trabalhar com 2 digitos. mudar pontuação
        mov     score,al
                 
        mov     al,dh
        mov     bl,10          ; e transformá-lo em "dezenas"
        mul     bl
        add     al,dl
        mov     curr_dado1,al  ; fica na parte baixa de ax
		            
		ler_d1_fim:    
		inc		si
		jmp		ler_d1
		
proximo_d1:
		inc		si					; anula o espaço
		mov		id1, si				; guarda o indice para a proxima 
		mov		si, iop1			; inicia o tratamento do operador (oper1)
ler_op1:		
		mov		dl, oper1[si]		; faz o mesmo tratamento ao operador
		cmp		dl, ' '
		je		proximo_op1
		cmp     dl,'$'
		je      ler_d2
		
		mov     curr_oper1,dl
		
		mov     ah, 02h
		int		21h
		inc		si
		jmp		ler_op1
		
proximo_op1:
		inc		si
		mov		iop1, si
		mov		si, id2
		
ler_d2:	mov		dl, dado2[si]		; faz o mesmo tratamento ao dado2
		cmp		dl, ' '
		je		ciclo_perguntas_fim
		cmp     dl,'$'
		je      ciclo_perguntas_fim
		mov     ah, 02h
		int		21h
		
		sub     dl,48               ; converter char para int
	    ;xor     dh,dh
	    mov     curr_dado2, dl
	    cmp     si,0
	    je      ler_d2_fim
        ;senão for o 1 elemento do vector, analisar se é num. de 2 digitos
        ;só aqui, altera logo o valor dos pontos
        push    si
        dec     si
        mov     dh,dado2[si]   ; Verificar se o digito anterior faz parte deste numero
        pop     si
        cmp     dh,' '
        je      ler_d2_fim
		        
        sub     dh,48          ; ok, entao converter o digito anterior para int
        xor     ax,ax
        ;xor     bx,bx        
        mov     al,score
        inc     al             ; Estamos a trabalhar com 2 digitos. mudar pontuação
        mov     score,al
        
        mov     al,dh
        mov     bl,10          ; e transformá-lo em "dezenas"
        mul     bl
        add     al,dl
        mov     curr_dado2,al  ; fica na parte baixa de ax
		            
		ler_d2_fim:
		
		inc		si
		jmp		ler_d2		
		
ciclo_perguntas_fim:
        ;NewLine
		inc		si
		mov		id2, si
		
		PRINT equals		
		mov 	cx, contador
		
		;imprimir pontos
		goto_xy	35,3
	    PRINT	str_Pontos
	    mov      ax,totalScore
	    CALL     PRINT_NUM			
	    goto_xy	20,10
	    
		;###
		xor ax,ax
		;Preapara resultado (fazer)
		cmp curr_oper1, '+'
        je faz_soma
        
        cmp curr_oper1, '-'
        je faz_sub
        
        cmp curr_oper1, '*'
        je faz_mult
        
        cmp curr_oper1, '/'
        je faz_div
        
        jmp final_op
        
        faz_soma:
    		mov al,curr_dado1
    		add al,curr_dado2
    		jmp final_op
    	faz_sub:
        	mov al,curr_dado1
    		sub al,curr_dado2
    		jmp final_op
		faz_mult:
		    ;multiplicação e divisao valem mais pontos
		    mov al,score
		    mov bl,2
		    mul bl
		    
		    mov al,curr_dado1
		    mov bl,curr_dado2
		    mul bl
		    jmp final_op
		faz_div:
		    mov al,score
		    mov bl,2
		    mul bl
		    
		    mov al,curr_dado1
		    mov bl,curr_dado2
		    div bl
		    jmp final_op
		final_op:

		MOV curr_result,ax
		call TeclaNum
		mov ax,curr_result
		mov input_result, dx
		
		cmp ax,dx
		je correct
		jmp incorrect
		
		correct:
		    PRINT str_correct
		    
		    mov ax,totalScore
		    xor bx,bx
		    mov bl,score
		    add ax,bx
		    mov totalScore,AX
		    
		    jmp validation_skip
		incorrect:
		    print str_incorrect
		    
		    mov ax,totalScore
		    cmp ax,2
		    Jb validation_skip
		        xor ax,ax
		        mov ax,2
		        sub totalScore,ax     
		validation_skip:
		    dec cx
		    jnz 	ciclo_perguntas		; faz este ciclo varias vezes
		termina_jogo:
		    ;	
sai_newgame:
        ret
NEWGAME ENDP
;------------------------------------------------------------------------
TeclaNum  proc

NOVON:	
		mov		NUMDIG, 0			; inícia leitura de novo número
		mov		cx, 20
		XOR		BX,BX
LIMPA_N: 	
		mov		NUMERO[bx], ' '	
		inc		bx
		loop 	LIMPA_N
		
		mov		al, 20
		mov		POSx,al
		mov		al, 10
		mov		POSy,al				; (POSx,POSy) é posição do cursor
		goto_xy	POSx,POSy
		PRINT	NUM_SP	

CICLO:	goto_xy	POSx,POSy
	
		call 	LE_TECLA		; lê uma nova tecla
		cmp		ah,1			; verifica se é tecla extendida
		je		ESTEND
		CMP 	AL,27			; caso seja tecla ESCAPE sai do programa
		JE		FIM
		CMP 	AL,13			; Pressionando ENTER vai para OKNUM
		JE		OKNUM		
		CMP 	AL,8			; Teste BACK SPACE <- (apagar digito)
		JNE		NOBACK
		mov		bl,NUMDIG		; Se Pressionou BACK SPACE 
		CMP		bl,0			; Verifica se não tem digitos no numero
		JE		NOBACK			; se não tem digitos continua então não apaga e salta para NOBACK

		dec		NUMDIG			; Retira um digito (BACK SPACE)
		dec		POSx			; Retira um digito	

		xor		bx,bx
		mov		bl, NUMDIG
		mov		NUMERO[bx],' '	; Retira um digito		
		goto_xy	POSx,POSy
		mov		ah,02h			; imprime SPACE na possicão do cursor
		mov		dl,32			; que equivale a colocar SPACE 
		int		21H

NOBACK:	
		CMP		AL,30h			; se for menor que tecla do ZERO
		jb		CICLO
		CMP		AL,39h			; ou se for maior que tecla do NOVE 
		ja		CICLO			; é rejeitado e vai buscar nova tecla 
		
		mov		bl,MAXDIG		; se atigido numero máximo de digitos ?	
		CMP		bl,NUMDIG	
		jbe		CICLO			; não aceita mais digitos
		xor		Bx, Bx			; caso contrario coloca digito na matriz NUMERO
		mov		bl, NUMDIG
		MOV		NUMERO[bx], al		
		mov		ah,02h			; imprime digito 
		mov		dl,al			; na possicão do cursor
		int		21H

		inc		POSx			; avança o cursor e
		inc		NUMDIG			; incrementa o numero de digitos

ESTEND:	jmp	CICLO			; Tecla extendida não é tratada neste programa 

OKNUM:	goto_xy	20,16
		PRINT	NUM_SP			
		goto_xy	20,16		
		xor		bx,bx
		mov		bl, NUMDIG
		;inc 	bl
		MOV		NUMERO[bx], '$'			
		;PRINT	NUMERO 
		;jmp		NOVON		; Vai ler novo numero
		
		;converte o numero para inteiro
        XOR AX,AX
        XOR DX,DX
        XOR si,si
        
        top_atoi:
            
            MOV AL,NUMERO[si]    ; AL -> digito (char format)
            
            sub AL, 48 ; converter para num.
            add DX, AX ; Adiciona o digito actual a dx
            
            inc si     ;avança o indice
            
            MOV AL,NUMERO[si]
            cmp al, '$' ; Acabou?
            je  fim
            
            mov ax,dx            
            mov bl,10            ; multiplica ax por 10 e guarda resultado em dx
            mul bl
            MOV DX,AX
            
        jmp top_atoi ; until done

fim:
    ret

TeclaNum ENDP
;------------------------------------------------------------------------
LE_TECLA	PROC
sem_tecla:
		Call SecondCounter
		mov al,gameSecs
		cmp al,120
		jae fim_jogo
		
		MOV	AH,0BH
		INT 21h
		cmp AL,0
		je	sem_tecla
		
		goto_xy	POSx,POSy
		
		MOV	AH,08H
		INT	21H
		MOV	AH,0
		CMP	AL,0
		JNE	SAI_TECLA
		MOV	AH, 08H
		INT	21H
		MOV	AH,1
		
		jmp sai_tecla

fim_jogo:
        print str_endgame
SAI_TECLA:	
		RET
LE_TECLA	ENDP
;------------------------------------------------------------------------
Ler_TEMPO PROC	
 
        PUSH AX
		PUSH BX
		PUSH CX
		PUSH DX
	
		PUSHF
		
        MOV AH, 2CH             ; Buscar a hORAS
		INT 21H                 
		
        XOR AX,AX
        MOV AL, DH              ; segundos para al
        mov Segundos, AX		; guarda segundos na variavel correspondente
		
        XOR AX,AX
        MOV AL, CL              ; Minutos para al
        mov Minutos, AX         ; guarda MINUTOS na variavel correspondente
		
        XOR AX,AX
        MOV AL, CH              ; Horas para al
        mov Horas,AX			; guarda HORAS na variavel correspondente
 
		POPF
		POP DX
		POP CX
		POP BX
		POP AX
 		RET 
Ler_TEMPO   ENDP
;------------------------------------------------------------------------
PRINT_NUM       PROC    NEAR
        PUSH    DX
        PUSH    AX

        CMP     AX, 0
        JNZ     not_zero

        PUTC    '0'
        JMP     printed

not_zero:
        CMP     AX, 0
        JNS     positive
        NEG     AX
        PUTC    '-'

positive:
        CALL    PRINT_NUM_UNS
printed:
        POP     AX
        POP     DX
        RET
PRINT_NUM       ENDP
PRINT_NUM_UNS   PROC    NEAR
        PUSH    AX
        PUSH    BX
        PUSH    CX
        PUSH    DX

        MOV     CX, 1
        MOV     BX, 10000
        CMP     AX, 0
        JZ      print_zero

inicio_print:

        CMP     BX,0
        JZ      fim_print
        CMP     CX, 0
        JE      calc
        CMP     AX, BX
        JB      skip
calc:
        MOV     CX, 0
        MOV     DX, 0
        DIV     BX
        ADD     AL, 30h    ; converter para ASCII.
        PUTC    AL

        MOV     AX, DX  ; ir buscar o resto ao dx.

skip:
        PUSH    AX
        MOV     DX, 0
        MOV     AX, BX
        MOV     BX,10
        DIV     BX
        
        MOV     BX, AX
        POP     AX

        JMP     inicio_print
        
print_zero:
        PUTC    '0'
        
fim_print:

        POP     DX
        POP     CX
        POP     BX
        POP     AX
        RET
PRINT_NUM_UNS   ENDP

;****************************************************************
;*	historico escreve uma linha no file	
;***************************************************************


EscreverHistorico PROC
mov		ah, 3ch				        ; Abrir o ficheiro para escrita
        mov		cx, 00H				; Define o tipo de ficheiro ??
        lea		dx, fhistorico		; DX aponta para o nome do ficheiro 
        int		21h					; Abre efectivamente o ficheiro (AX fica com o Handle do ficheiro)
        jnc		appendfile			; Se não existir erro escreve no ficheiro
	
		mov		ah, 09h
		lea		dx, Erro_Open
		int		21h
	    
appendfile:
        lea dx,fhistorico
        mov al,1
        mov ah,3dh
        int 21h
        
        
        mov bx,ax
        mov cx,0            ;offsetfinal  da linha
        mov dx,0            ;offsetinicial da linha
        mov ah,42h
        mov al,2
        int 21h
        jnc     escreve
        
        mov		ah, 09h
		lea		dx, Erro_Open
		int		21h
		

escreve:   
        
		;mov		bx, HandleFich		; Coloca em BX o Handle
		
    					; indica que é para escrever   
    	
    	
		lea		dx, stringTeste			; DX aponta para a infromação a escrever 
		;len equ stringTeste
    	mov		cx, 10			    ; CX fica com o numero de bytes a escrever(necessario verificar na rotina)
    	mov		ah, 40h
		int		21h					    ; Chama a rotina de escrita           
		
		
		jnc		close				    ; Se não existir erro na escrita fecha o ficheiro
	
		mov		ah, 09h
		lea		dx, Erro_Ler_Msg
		int		21h
close:
		mov		ah,3eh				    ; fecha o ficheiro
		int		21h
		ret		
		
EscreverHistorico ENDP		
 
;****************************************************************
;*	ler file historico
;***************************************************************     

LerHistorico PROC

abrirficheiro:
        mov     ah,3dh
        mov     al,0
        lea     dx,fhistorico
        int     21h				; Chama a rotina de abertura de ficheiro (AX fica com Handle)
        ;jc      erro_abrir
        mov     fhandler,ax
		;xor		si,si			; indice da matriz dado1 inicia a zero
        jnc     ler


        mov     ah,09h
        lea     dx,Erro_Open
        int     21h
            
ler:
        mov	ah,3fh 
        mov bx,fhandler 
        mov cx,240 
        lea dx,historico 
        int 21h 
        jnc		close_f				    ; Se não existir erro na escrita fecha o ficheiro
	
		mov		ah, 09h
		lea		dx, Erro_Ler_Msg
		int		21h
close_f:
		mov		ah,3eh				    ; fecha o ficheiro
		int		21h
        ret
       
       
LerHistorico ENDP

;****************************************************************
;*	ler referencias
;***************************************************************
 LerReferencias PROC

abrirreffile:
        mov     ah,3dh
        mov     al,00h
        lea     dx,fref
        int     21h				; Chama a rotina de abertura de ficheiro (AX fica com Handle)
        
        mov     fhandler,ax
		
        jnc     lerrefs


        mov     ah,09h
        lea     dx,Erro_Open
        int     21h
        ;jmp     sai    
lerrefs:
        mov	ah,3fh 
        mov bx,fhandler 
        mov cx,len 
        lea dx,refs 
        int 21h 
        jnc		close_refs				    ; Se não existir erro na escrita fecha o ficheiro
	
		mov		ah, 09h
		lea		dx, Erro_Ler_Msg
		int		21h
close_refs:
		mov		ah,3eh				    ; fecha o ficheiro
		int		21h
        ret
       
       
LerReferencias ENDP
;****************************************************************
;*	escrever referencias
;***************************************************************  
EscreverRef PROC
        mov		ah, 3ch			    ; Abrir o ficheiro para escrita
        mov		cx, 00H				; Define o tipo de ficheiro ??
        lea		dx, fref		    ; DX aponta para o nome do ficheiro 
        int		21h					; Abre efectivamente o ficheiro (AX fica com o Handle do ficheiro)
        jnc		escrever			; Se não existir erro escreve no ficheiro
	
		mov		ah, 09h
		lea		dx, Erro_Open
		int		21h
	    
		

escrever:   
        
		 
    	
    	mov     bx,ax
		lea		dx, refs			; DX aponta para a informação a escrever 
		
    	mov		cx, len			        ; CX fica com o numero de bytes a escrever(necessario verificar na rotina)
    	mov		ah, 40h
		int		21h					    ; Chama a rotina de escrita           
		
		
		jnc		fechar				    ; Se não existir erro na escrita fecha o ficheiro
	
		mov		ah, 09h
		lea		dx, Erro_Ler_Msg
		int		21h
fechar:
		mov		ah,3eh				    ; fecha o ficheiro
		int		21h
		ret 
		
EscreverRef ENDP


;****************************************************************
;*	alterar referencias  preciso de adicionar um jogo as refs
;***************************************************************    
AlterarRefs PROC
        ;call    LerRef                  ;ler o txt
       
       
       
       
AlterarRefs ENDP   

;****************************************************************
;*	preenche as refs com os dados
;*************************************************************** 

PreencheRefs PROC
		;converter data, pontos,respostas
preenche:        
        mov     refs[si],'a'
        mov		dl, refs[si]		; vai buscar um caracter a refs
		cmp		si, 50
		mov     refs[si+1],'$'
		inc		si
		cmp		si, 50 
		je fim_ret
						
		
		
        jmp preenche  
fim_ret:   
    inc si
    mov len,si
    
    ret

PreencheRefs ENDP
cseg	ends
end     MAIN