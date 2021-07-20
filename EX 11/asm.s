        PUBLIC  __iar_program_start
        PUBLIC  __vector_table

        SECTION .text:CODE:REORDER(1)
        
        ;; Keep vector table even if it's not referenced
        REQUIRE __vector_table
        
        THUMB
        
__iar_program_start
        
main    MOV R0, #5 ;numero a ser calculado           
        BL fat
        B       .

fat     
        MOV R1, #0
        MOV R1, R0 ; registrador auxiliar
        SUB R1, R1, #1 ; decrementa auxiliar em 1
        CMP R0, #13 ; compara o número a ser calculado >= 13
                    ; se sim, irá ocorrer overflow
        BHS fat_fim     ; finaliza o cálculo
        CMP R0, #1  ; compara o número a ser calculado com 1
                    ; se for == 1, então ñ é necessário cálculo
        BEQ fat_fim     ; finaliza o cálculo        

fat_loop        
        MUL R0, R1 ; R0 = R0 * R1
        SUBS R1, R1, #1 ; decrementa auxiliar em 1 
        BNE fat_loop ; Enquando R1 != 0 salta para sub rotina fatorial
        BL fat_fim
        
fat_fim    
        BX LR

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
