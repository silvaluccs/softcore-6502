; Programa de exemplo para o Mini Assembler 6502
; Este programa demonstra várias instruções e modos de endereçamento

; Início do programa (endereço 0x1000 é o padrão)

START:
    LDA #$42        ; Carrega valor 0x42 no acumulador
    LDX #$00        ; Inicializa X com 0
    LDY #$10        ; Inicializa Y com 16

    STA $50         ; Armazena A na página zero (endereço $50)

LOOP:
    INX             ; Incrementa X
    DEY             ; Decrementa Y
    BNE LOOP        ; Se Y != 0, volta para LOOP

    ; Operações com memória absoluta
    LDA $2000       ; Carrega de endereço absoluto
    STA $2001       ; Armazena em endereço absoluto

    ; Operações com indexação
    LDA $10,X       ; Página zero indexada por X
    STA $20,X       ; Página zero indexada por X

    ; Aritmética
    CLC             ; Limpa carry
    ADC #$05        ; Adiciona 5 ao acumulador
    SEC             ; Seta carry
    SBC #$02        ; Subtrai 2 do acumulador

    ; Operações lógicas
    AND #$0F        ; AND com máscara
    ORA #$F0        ; OR com máscara
    EOR #$FF        ; XOR (inverte bits)

    ; Stack operations
    PHA             ; Push A na pilha
    PHP             ; Push flags na pilha
    PLP             ; Pull flags da pilha
    PLA             ; Pull A da pilha

    ; Transfers
    TAX             ; A -> X
    TXA             ; X -> A
    TAY             ; A -> Y
    TYA             ; Y -> A

    ; Shift e rotate
    ASL A           ; Shift left acumulador
    LSR A           ; Shift right acumulador
    ROL A           ; Rotate left acumulador
    ROR A           ; Rotate right acumulador

    ; Comparações
    CMP #$10        ; Compara A com $10
    CPX #$05        ; Compara X com $05
    CPY #$00        ; Compara Y com $00

    ; Salto para subrotina
    JSR SUBROTINA   ; Chama subrotina

    ; Loop infinito
INFINITE:
    JMP INFINITE    ; Loop infinito

; Subrotina de exemplo
SUBROTINA:
    NOP             ; No operation
    NOP
    RTS             ; Retorna da subrotina

; Dados na memória
.BYTE $01, $02, $03, $04, $05

; Palavras (little endian)
.WORD $1234, $5678

