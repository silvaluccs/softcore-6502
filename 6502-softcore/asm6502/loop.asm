; --- PREPARAÇÃO ---
LDA #$05
STA $40         ; ZP: $40 = 05
STA $0200       ; ABS: $0200 = 05
LDX #$0A        ; Registrador X = 10
LDY #$0A        ; Registrador Y = 10

; --- TESTE INC/DEC (Memória) ---

; 1. INC ZP ($E6) e ZPX ($F6)
INC $40         ; $40 vira 06
LDX #$01
INC $3F,X       ; $40 vira 07 (ZP,X: $3F + 1 = $40)

; 2. INC ABS ($EE) e ABX ($FE)
INC $0200       ; $0200 vira 06
LDX #$01
INC $01FF,X     ; $0200 vira 07 (ABS,X: $01FF + 1 = $0200)

; 3. DEC ZP ($C6) e ABS ($CE)
DEC $40         ; $40 volta para 06
DEC $0200       ; $0200 volta para 06

; Validação do INC/DEC: O valor final em $40 deve ser 06
LDA $40
CMP #$06
BNE FALHA

; --- TESTE CPX (Compare X Register) ---

; 4. CPX Imm ($E0), ZP ($E4), ABS ($EC)
LDX #$10        ; X = 16
CPX #$10        ; Immediate: 16 == 16? (Z=1)
BNE FALHA

STX $50         ; Salva 16 na ZP $50
CPX $50         ; Zero Page: X == Mem?
BNE FALHA

STX $0300       ; Salva 16 no ABS $0300
CPX $0300       ; Absolute: X == Mem?
BNE FALHA

; --- TESTE CPY (Compare Y Register) ---

; 5. CPY Imm ($C0), ZP ($C4), ABS ($CC)
LDY #$20        ; Y = 32
CPY #$20        ; Immediate
BNE FALHA

STY $60         ; Salva 32 na ZP $60
CPY $60         ; Zero Page
BNE FALHA

STY $0400       ; Salva 32 no ABS $0400
CPY $0400       ; Absolute
BNE FALHA

SUCESSO:
    LDA #$EE
    JMP SUCESSO

FALHA:
    LDA #$FF
    JMP FALHA
