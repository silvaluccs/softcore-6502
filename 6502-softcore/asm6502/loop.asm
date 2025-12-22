; --- TESTE JMP (INDIRECT) ---

; Configurando o endereço indireto
LDA #$00
STA $00        ; Endereço baixo
LDA #$05
STA $01        ; Endereço alto

; Salvando o endereço do destino no endereço indireto
LDA #$EE
STA $0500      ; Destino do JMP
LDA #$05
STA $0501      ; Continuando destino do JMP

; Realiza o salto indireto
JMP ($00)

SUCESSO:
    LDA #$EE
    JMP SUCESSO

FALHA:
    LDA #$FF
    JMP FALHA

