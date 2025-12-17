; --- PREPARAÇÃO DOS DADOS ---
START:
LDA #$C0          ; Valor %11000000 (Bits 7 e 6 ligados)
STA $40           ; Guarda na Zero Page (Endereço $0040)
STA $0200         ; Guarda no modo Absolute (Endereço $0200)

; --- INÍCIO DOS TESTES ---

; 1. Testando Zero Page
LDA #$00          ; Limpa A para não interferir
BIT $40           ; Modo Zero Page (Opcode $24)
BPL FALHA         ; Se Bit 7 = 0, pula para FALHA
BVC FALHA         ; Se Bit 7 = 0, pula para FALHA

; 2. Testando Absolute
BIT $0200         ; Modo Absolute (Opcode $2C)
BPL FALHA         ; Se Bit 7 = 0, pula para FALHA
BVC FALHA         ; Se Bit 6 = 0, pula para FALHA

SUCESSO:
    LDA #$EE      ; Ambos os testes passaram (Bits 7 e 6 em ambos os locais)
    JMP SUCESSO

FALHA:
    LDA #$FF      ; Um dos testes falhou
    JMP FALHA

