; **************************************************
; TESTE FOCADO NO CARRY FLAG (C)
; **************************************************

START:
    ; Configuração Inicial
    LDA #$05        ; 1. Carrega o valor 5 no Acumulador (A = 5)
    STA $0010       ; Salva 5 na RAM (endereço $0010)

; --------------------------------------------------
; BLOCO 1: TESTE CLC (Carry = 0)
; --------------------------------------------------
TESTE_CLC:
    CLC             ; 2. Força C = 0 (Clear Carry)
    ADC #$02        ; 3. Soma: A = A + 2 + C
                    ;    A = 5 + 2 + 0 => A = 7
    STA $0011       ; Salva o resultado $07 (A=7) na RAM $0011
    
    ; PONTO DE OBSERVAÇÃO 1: A deve ser 7. C deve ser 0.
    NOP

; --------------------------------------------------
; BLOCO 2: TESTE SEC (Carry = 1)
; --------------------------------------------------
TESTE_SEC:
    LDA $0010       ; 4. Restaura o valor 5 no Acumulador (A = 5)
    SEC             ; 5. Força C = 1 (Set Carry)
    ADC #$02        ; 6. Soma: A = A + 2 + C
                    ;    A = 5 + 2 + 1 => A = 8
    STA $0012       ; Salva o resultado $08 (A=8) na RAM $0012

    ; PONTO DE OBSERVAÇÃO 2: A deve ser 8. C deve ser 0.
    NOP

; --------------------------------------------------
; BLOCO 3: TESTE DE CARRY GERADO POR OVERFLOW
; --------------------------------------------------
TESTE_OVERFLOW:
    LDA #$FF        ; 7. Carrega $FF (255)
    CLC             ; 8. Garante C = 0
    ADC #$01        ; 9. Soma: A = $FF + 1 + 0
                    ;    A = $00 e C é gerado (C=1)

    ; PONTO DE OBSERVAÇÃO 3: A deve ser 0. C deve ser 1.
    NOP

END:
    BRK             ; Fim do Programa
