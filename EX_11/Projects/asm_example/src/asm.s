        PUBLIC  __iar_program_start
        PUBLIC  __vector_table

        SECTION .text:CODE:REORDER(1)
        
        ;; Keep vector table even if it's not referenced
        REQUIRE __vector_table
        
        THUMB
        
__iar_program_start
        
        ;; main program begins here
main    MOV R0, #1 ;numero a ser calculado           
        MOV R1, R0 ; registrador auxiliar
        SUB R1, R1, #1 ; decrementa auxiliar em 1
        CMP R0, #13 ; compara o n�mero a ser calculado
                    ; se sim, ir� ocorrer overflow
        BHS fim     ; finaliza o c�lculo
        CMP R0, #1  ; compara o n�mero a ser calculado com 1
                    ; se for == 1, ent�o � � necess�rio c�lculo
        BEQ fim     ; finaliza o c�lculo          
        
fatorial        
       MUL R0, R1 ; R0 = R0 * R1
       SUBS R1, R1, #1 ; decrementa auxiliar em 1 
       BNE fatorial ; Enquando R1 != 0 salta para sub rotina fatorial
            
fim    B fim
        
        ;; main program ends here

        ;; Forward declaration of sections.
        SECTION CSTACK:DATA:NOROOT(3)
        SECTION .intvec:CODE:NOROOT(2)
        
        DATA

__vector_table
        DCD     sfe(CSTACK)
        DCD     __iar_program_start

        DCD     NMI_Handler
        DCD     HardFault_Handler
        DCD     MemManage_Handler
        DCD     BusFault_Handler
        DCD     UsageFault_Handler
        DCD     0
        DCD     0
        DCD     0
        DCD     0
        DCD     SVC_Handler
        DCD     DebugMon_Handler
        DCD     0
        DCD     PendSV_Handler
        DCD     SysTick_Handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Default interrupt handlers.
;;

        PUBWEAK NMI_Handler
        PUBWEAK HardFault_Handler
        PUBWEAK MemManage_Handler
        PUBWEAK BusFault_Handler
        PUBWEAK UsageFault_Handler
        PUBWEAK SVC_Handler
        PUBWEAK DebugMon_Handler
        PUBWEAK PendSV_Handler
        PUBWEAK SysTick_Handler

        SECTION .text:CODE:REORDER:NOROOT(1)
        THUMB

NMI_Handler
HardFault_Handler
MemManage_Handler
BusFault_Handler
UsageFault_Handler
SVC_Handler
DebugMon_Handler
PendSV_Handler
SysTick_Handler
Default_Handler
__default_handler
        CALL_GRAPH_ROOT __default_handler, "interrupt"
        NOCALL __default_handler
        B __default_handler

        END
