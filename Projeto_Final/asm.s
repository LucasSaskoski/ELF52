        PUBLIC  __iar_program_start
        EXTERN  __vector_table

        SECTION .text:CODE:REORDER(2)
        
        ;; Keep vector table even if it's not referenced
        REQUIRE __vector_table
        
        THUMB

; System Control definitions
SYSCTL_BASE             EQU     0x400FE000
SYSCTL_RCGCGPIO         EQU     0x0608
SYSCTL_PRGPIO		EQU     0x0A08
SYSCTL_RCGCUART         EQU     0x0618
SYSCTL_PRUART           EQU     0x0A18
; System Control bit definitions
PORTA_BIT               EQU     000000000000001b ; bit  0 = Port A
PORTF_BIT               EQU     000000000100000b ; bit  5 = Port F
PORTJ_BIT               EQU     000000100000000b ; bit  8 = Port J
PORTN_BIT               EQU     001000000000000b ; bit 12 = Port N
UART0_BIT               EQU     00000001b        ; bit  0 = UART 0

; NVIC definitions
NVIC_BASE               EQU     0xE000E000
NVIC_EN1                EQU     0x0104
VIC_DIS1                EQU     0x0184
NVIC_PEND1              EQU     0x0204
NVIC_UNPEND1            EQU     0x0284
NVIC_ACTIVE1            EQU     0x0304
NVIC_PRI12              EQU     0x0430

; GPIO Port definitions
GPIO_PORTA_BASE         EQU     0x40058000
GPIO_PORTF_BASE    	EQU     0x4005D000
GPIO_PORTJ_BASE    	EQU     0x40060000
GPIO_PORTN_BASE    	EQU     0x40064000
GPIO_DIR                EQU     0x0400
GPIO_IS                 EQU     0x0404
GPIO_IBE                EQU     0x0408
GPIO_IEV                EQU     0x040C
GPIO_IM                 EQU     0x0410
GPIO_RIS                EQU     0x0414
GPIO_MIS                EQU     0x0418
GPIO_ICR                EQU     0x041C
GPIO_AFSEL              EQU     0x0420
GPIO_PUR                EQU     0x0510
GPIO_DEN                EQU     0x051C
GPIO_PCTL               EQU     0x052C

; UART definitions
UART_PORT0_BASE         EQU     0x4000C000
UART_FR                 EQU     0x0018
UART_IBRD               EQU     0x0024
UART_FBRD               EQU     0x0028
UART_LCRH               EQU     0x002C
UART_CTL                EQU     0x0030
UART_CC                 EQU     0x0FC8
;UART bit definitions
TXFE_BIT                EQU     10000000b ; TX FIFO full
RXFF_BIT                EQU     01000000b ; RX FIFO empty
BUSY_BIT                EQU     00001000b ; Busy


; PROGRAMA PRINCIPAL

__iar_program_start


main:   
        
        MOV R2, #(UART0_BIT)
	BL UART_enable          ; habilita clock ao port 0 de UART

        MOV R2, #(PORTA_BIT)
	BL GPIO_enable          ; habilita clock ao port A de GPIO
        
	LDR R0, =GPIO_PORTA_BASE
        MOV R1, #00000011b      ; bits 0 e 1 como especiais
        BL GPIO_special

	MOV R1, #0xFF           ; máscara das funções especiais no port A (bits 1 e 0)
        MOV R2, #0x11           ; funções especiais RX e TX no port A (UART)
        BL GPIO_select

	LDR R0, =UART_PORT0_BASE
        BL UART_config          ; configura periférico UART0
        
        ; recepção e envio de dados pela UART utilizando sondagem (polling)
        ; resulta em um "eco": dados recebidos são retransmitidos pela UART
        
        ; inicializa alguns registradores importantes
        MOV R6, #1
        MOV R3, #0
        MOV R5, #10


loop: 
        
wrx:    LDR R2, [R0, #UART_FR]  ; status da UART
        TST R2, #RXFF_BIT       ; receptor cheio?
        BEQ wrx
        LDR R1, [R0]            ; lê do registrador de dados da UART0 (recebe
        
caracter_valido                 ; verifica se é número ou operador, senão for aguarda outro envio
        
        CMP R1, #0x3D           ; Se for '=' salta para o calculo
        IT EQ
        BEQ calcula   
        
        CMP R1, #0x2A           ; invalida qualquer caractere menor que 2A hexa
        IT LO
        BLO loop
        
        CMP R1, #0x39           ; invalida qualquer caractere maior que 39 hexa, exceto '='
        IT HI
        BHI loop
        
        CMP R1, #0x2C           ; invalida ','
        IT EQ
        BEQ loop
        
        CMP R1, #0x2E           ; invalida '.'
        IT EQ
        BEQ loop        
     
testa                           ; verifica se é operador, se sim armazena em R10
        CMP R1, #0x2A   ; "*"
        ITT EQ
        MOVEQ R10, R1
        MOVEQ R3, #0
        
        CMP R1, #0x2B   ; "+"
        ITT EQ
        MOVEQ R10, R1
        MOVEQ R3, #0
        
        CMP R1, #0x2D   ; "-"   
        ITT EQ
        MOVEQ R10, R1
        MOVEQ R3, #0       
        
        CMP R1, #0x2F   ; "/"   
        ITT EQ
        MOVEQ R10, R1
        MOVEQ R3, #0
              
        CMP R10, #0             ; A recepção de um operador finaliza o armazenamento do primeiro operando        
        BNE operando2               
        

operando1                       ; Recebe um caractere por vez e concatena em R4 
        PUSH {R1}      
        SUB R1, R1, #30h        ; Transforma caracter em decimal
        CMP R3, #0              ; se R3 igual a zero multiplica por 10, se não multiplica por 1.
        
        ITEE EQ
        MULEQ R4, R4, R5
        MULNE R4, R4, R6
        ADDNE R3, R3, #1
        
        ADD R4, R4, R1
        POP {R1}
        BL wtx                  ;Transmite caractere
        B loop
               
operando2                       ; Recebe um caractere por vez e concatena em R7           
        
        CMP R1, R10             ; Transmissão do operador
        ITT EQ
        BLEQ wtx
        BLEQ loop
        
        PUSH {R1}
        
        SUB R1, R1, #30h        ; Transforma caracter em decimal
        CMP R3, #1
        ITEE EQ
        MULEQ R7, R7, R5
        MULNE R7, R7, R6
        ADDNE R3, R3, #1
          
        ADD R7, R7, R1
        POP {R1}
        BL wtx        
        B loop     

calcula                         ; Faz a operaão e retorna resultado em R1 
        BL wtx                  ;Transmite =
        
        CMP R10, #0x2A          ; Calcula (R4 * R7) e retorna em R1
        IT EQ
        MULEQ R1, R4, R7
             
        CMP R10, #0x2B         ; Calcula (R4 + R7) e retorna em R1
        IT EQ
        ADDEQ R1, R4, R7
        
        CMP R10, #0x2D         ; Calcula (R4 - R7) e retorna em R1
        IT EQ
        SUBEQ R1, R4, R7
        
        CMP R10, #0x2F         ; Calcula (R4 / R7) e retorna em R1
        IT EQ
        SDIVEQ R1, R4, R7
                    
transmite_resultado           ; Decompõe resultado e envia caractere por caractere. Resultado limita-se em 6 digitos que atende o maior 
                              ; valor de oparação com dois operandos de 3 digitos, no caso (999x999 = 998001).
        CMP R1, #0
        IT LT
        BLLT negativo
        
        MOV R8, R1        
        MOV R2, #0            ; Incializa flag
        
        MOV R3, #2710h    
        MOV R11, #10       
        MUL R3, R3, R11       ; R11 recebe 100 000 decimal      
        

        UDIV R1, R8, R3       ; primeiro digito
        MUL R11, R1, R3       ; calculo do resto da divisão
        SUB R8, R8, R11       ; R8 recebe o resto da divisão   
        BL wtx2      
                 
                              
        MOV R3, #2710h        ; 10 000 decimal
        UDIV R1, R8, R3       ; segundo digito
        MUL R11, R1, R3       ; calculo do resto da divisão
        SUB R8, R8, R11       ; R8 recebe o resto da divisão
        BL wtx2 
                     
        MOV R3, #1000

        UDIV R1, R8, R3       ; terceiro digito
        MUL R11, R1, R3       ; calculo do resto da divisão
        SUB R8, R8, R11       ; R8 recebe o resto da divisão
        BL wtx2 
              
        MOV R3, #100

        UDIV R1, R8, R3       ; quarto digito
        MUL R11, R1, R3       ; calculo do resto da divisão
        SUB R8, R8, R11       ; R8 recebe o resto da divisão
        BL wtx2
        
        MOV R3, #10

        UDIV R1, R8, R3       ; quinto digito
        MUL R11, R1, R3       ; calculo do resto da divisão
        SUB R8, R8, R11       ; R8 recebe o resto da divisão
        BL wtx2     
      
        MOV R1, R8            ; sexto digito
        BL wtx2
   
finaliza_envio                ; transmite \r e \n ao final da string  
        MOV R1, #'\r' 
        BL wtx
        
        MOV R1, #'\n';
        BL wtx
 
clear                         ; limpa registradores para nova operação   
        MOV R3, #0
        MOV R4, R3
        MOV R7, R3
        MOV R10, R3
        
        B loop
        
; SUB-ROTINAS 

wtx:                           ; sub rotina para ecoar os caracteres recebidos        
        LDR R2, [R0, #UART_FR] ; status da UART
        TST R2, #TXFE_BIT      ; transmissor vazio?
        BEQ wtx  
        STR R1, [R0]           ; escreve no registrador de dados da UART0 (transmite)
        BX LR

wtx2:                          ; sub rotina para transmitir apenas dados do resultado   

                                ; Inicio da rotina para remover zero a esquerda
        MOV R11, R14            ; salva LR em R11        
        
        CMP R1, #0              ; enquanto R1 = 0 flag R2 coninua 0
        IT NE
        MOVNE R2, #1            ; se R1 != 0 seta flag ou seja primeiro caracter válido do resultado foi encontrado
        
        CMP R2, #0              ; se R2 = 0 então há zero a esquerda, portando continua decompondo o resultado
        IT EQ
        MOVEQ R15, R11          ; carrega PC com LR                 
                                ; Fim da rotina   
        
                                ; foi necessário delay, pois não estavo printando o resultado (por que?)
        PUSH {R0, LR}
        MOV R0, #0x29000        ; atraso de milissegundos
        BL SW_delay             ; sub-rotina de atraso
        POP {R0, LR}
               
        LDR R2, [R0, #UART_FR]  ; status da UART
        TST R2, #TXFE_BIT       ; transmissor vazio?
        BEQ wtx        
        
        ADD R1, R1, #30h        ; Converte para ASCII       
        STR R1, [R0]            ; escreve no registrador de dados da UART0 (transmite)
       
        BX LR
        
negativo 
        MOV R11, #-1            ; fator de multiplicação      
        MUL R1, R1, R11         ; transforma R1 em positivo novamente        
        PUSH {R1, LR}           ;        
        MOV R1, #0x2D           ; printa '-' antes do resultado
        BL wtx
        POP {R1, PC}
        
        
;----------
; UART_enable: habilita clock para as UARTs selecionadas em R2
; R2 = padrão de bits de habilitação das UARTs
; Destrói: R0 e R1
UART_enable:
        LDR R0, =SYSCTL_BASE
	LDR R1, [R0, #SYSCTL_RCGCUART]
	ORR R1, R2 ; habilita UARTs selecionados
	STR R1, [R0, #SYSCTL_RCGCUART]

waitu	LDR R1, [R0, #SYSCTL_PRUART]
	TEQ R1, R2 ; clock das UARTs habilitados?
	BNE waitu

        BX LR
        
; UART_config: configura a UART desejada
; R0 = endereço base da UART desejada
; Destrói: R1

UART_config:
        LDR R1, [R0, #UART_CTL]
        BIC R1, #0x01 ; desabilita UART (bit UARTEN = 0)
        STR R1, [R0, #UART_CTL]

        ; clock = 16MHz, baud rate = 9600 bps
        MOV R1, #104
        STR R1, [R0, #UART_IBRD]
        MOV R1, #11
        STR R1, [R0, #UART_FBRD]
        
        ;8 bits, 1 stop bit, odd parity, FIFOs disabled, no interrupts
        MOV R1, #01100010b
        STR R1, [R0, #UART_LCRH]
        
        ; clock source = system clock
        MOV R1, #0x00
        STR R1, [R0, #UART_CC]
        
        LDR R1, [R0, #UART_CTL]
        ORR R1, #0x01 ; habilita UART (bit UARTEN = 1)
        STR R1, [R0, #UART_CTL]

        BX LR

; GPIO_special: habilita funcões especiais no port de GPIO desejado
; R0 = endereço base do port desejado
; R1 = padrão de bits (1) a serem habilitados como funções especiais
; Destrói: R2
GPIO_special:
	LDR R2, [R0, #GPIO_AFSEL]
	ORR R2, R1 ; configura bits especiais
	STR R2, [R0, #GPIO_AFSEL]

	LDR R2, [R0, #GPIO_DEN]
	ORR R2, R1 ; habilita função digital
	STR R2, [R0, #GPIO_DEN]

        BX LR

; GPIO_select: seleciona funcões especiais no port de GPIO desejado
; R0 = endereço base do port desejado
; R1 = máscara de bits a serem alterados
; R2 = padrão de bits (1) a serem selecionados como funções especiais
; Destrói: R3
GPIO_select:
	LDR R3, [R0, #GPIO_PCTL]
        BIC R3, R1
	ORR R3, R2 ; seleciona bits especiais
	STR R3, [R0, #GPIO_PCTL]

        BX LR
;----------

; GPIO_enable: habilita clock para os ports de GPIO selecionados em R2
; R2 = padrão de bits de habilitação dos ports
; Destrói: R0 e R1
GPIO_enable:
        LDR R0, =SYSCTL_BASE
	LDR R1, [R0, #SYSCTL_RCGCGPIO]
	ORR R1, R2 ; habilita ports selecionados
	STR R1, [R0, #SYSCTL_RCGCGPIO]

waitg	LDR R1, [R0, #SYSCTL_PRGPIO]
	TEQ R1, R2 ; clock dos ports habilitados?
	BNE waitg

        BX LR

; GPIO_digital_output: habilita saídas digitais no port de GPIO desejado
; R0 = endereço base do port desejado
; R1 = padrão de bits (1) a serem habilitados como saídas digitais
; Destrói: R2
GPIO_digital_output:
	LDR R2, [R0, #GPIO_DIR]
	ORR R2, R1 ; configura bits de saída
	STR R2, [R0, #GPIO_DIR]

	LDR R2, [R0, #GPIO_DEN]
	ORR R2, R1 ; habilita função digital
	STR R2, [R0, #GPIO_DEN]

        BX LR

; GPIO_write: escreve nas saídas do port de GPIO desejado
; R0 = endereço base do port desejado
; R1 = máscara de bits a serem acessados
; R2 = bits a serem escritos
GPIO_write:
        STR R2, [R0, R1, LSL #2] ; escreve bits com máscara de acesso
        BX LR

; GPIO_digital_input: habilita entradas digitais no port de GPIO desejado
; R0 = endereço base do port desejado
; R1 = padrão de bits (1) a serem habilitados como entradas digitais
; Destrói: R2
GPIO_digital_input:
	LDR R2, [R0, #GPIO_DIR]
	BIC R2, R1 ; configura bits de entrada
	STR R2, [R0, #GPIO_DIR]

	LDR R2, [R0, #GPIO_DEN]
	ORR R2, R1 ; habilita função digital
	STR R2, [R0, #GPIO_DEN]

	LDR R2, [R0, #GPIO_PUR]
	ORR R2, R1 ; habilita resitor de pull-up
	STR R2, [R0, #GPIO_PUR]

        BX LR

; GPIO_read: lê as entradas do port de GPIO desejado
; R0 = endereço base do port desejado
; R1 = máscara de bits a serem acessados
; R2 = bits lidos
GPIO_read:
        LDR R2, [R0, R1, LSL #2] ; lê bits com máscara de acesso
        BX LR

; SW_delay: atraso de tempo por software
; R0 = valor do atraso
; Destrói: R0
SW_delay:
        CBZ R0, out_delay
        SUB R0, R0, #1
        B SW_delay        
out_delay:
        BX LR



        SECTION .rodata:CONST(2)
        DATA
ROM08   DC8  "Sistemas Microcontrolados"

        END
  
