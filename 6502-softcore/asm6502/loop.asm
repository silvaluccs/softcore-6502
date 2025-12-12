START:
    LDA #$42        ; Carrega 0x42 no acumulador

    TAX             ; Transfere A para X
    CPX #$42       ; Compara X com 5
    BEQ LOOP        ; Se igual, vai para LOOP
    JMP END
LOOP:
    INY             ; Incrementa Y
    CPY #$03       ; Compara X com 0
    BNE LOOP        ; Se X != 0, volta
    JMP END       ; Loop infinito
END:
   
