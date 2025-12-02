START:
    LDA #$42        ; Carrega 0x42 no acumulador
    TAX            ; Transfere acumulador para X
LOOP:
    INX             ; X++
    BNE LOOP        ; Se X != 0, volta
    JMP START       ; Loop infinito

