
START:
    LDX #$01               ; X = 1 (Offset)
    LDY #$01               ; Y = 1 (Offset)
    
    ; --- Inicializa os bytes de dados na memória ---
    ; ZP_ADDR = $02
    ; ABS_ADDR = $2000
    ; IND_ADDR = $4000
    
    LDA #$20
    STA $02                ; ZP_ADDR
    STA $02,X              ; $03 (ZP_ADDR,X)
    STA $2000              ; ABS_ADDR
    STA $2000,X            ; $2001 (ABS_ADDR,X)
    STA $2000,Y            ; $2001 (ABS_ADDR,Y)
    
    ; Configuração dos Alvos Indiretos
    STA $4000              ; IND_ADDR 1
    STA $4000,Y            ; IND_ADDR 2

; =================================================================
; PARTE 1: TESTE SEM CARRY (CLC)
; CLC -> C=0. Esperado: $10 + $20 + 0 = $30
; =================================================================

    LDA #$10               ; Valor inicial A = $10
    CLC                    ; Clear Carry (C=0)

    ; 1. ADC IMM ($69)
    ADC #$20               ; $10 + $20 + 0 = $30
    CMP #$30
    BNE FAIL
    
    ; 2. ADC ZP ($65)
    LDA #$10
    ADC $02                ; $10 + $20 + 0 = $30
    CMP #$30
    BNE FAIL

    ; 3. ADC ZP,X ($75)
    LDA #$10
    ADC $02,X              ; $10 + $20 + 0 = $30 (Alvo $03)
    CMP #$30
    BNE FAIL
    
    ; 4. ADC ABS ($6D)
    LDA #$10
    ADC $2000              ; $10 + $20 + 0 = $30
    CMP #$30
    BNE FAIL

    ; 5. ADC ABS,X ($7D)
    LDA #$10
    ADC $2000,X            ; $10 + $20 + 0 = $30 (Alvo $2001)
    CMP #$30
    BNE FAIL
    
    ; 6. ADC ABS,Y ($79)
    LDA #$10
    ADC $2000,Y            ; $10 + $20 + 0 = $30 (Alvo $2001)
    CMP #$30
    BNE FAIL

    ; 7. ADC (INDX) ($61)
    ; PTR_BASE = $30. X=1. Endereço efetivo em $31/$32. Alvo $4000.
    LDA #$00
    STA $31                ; Salva $00 em $31 (Low byte)
    LDA #$40
    STA $32                ; Salva $40 em $32 (High byte)
    
    LDA #$10
    ADC ($30,X)            ; $10 + $20 + 0 = $30
    CMP #$30
    BNE FAIL

    ; 8. ADC (INDY) ($71)
    ; PTR_BASE = $30. Y=1. Ponteiro em $30/$31. Alvo $4000 + 1 = $4001.
    LDA #$00
    STA $30                ; Salva $00 em $30
    LDA #$40
    STA $31                ; Salva $40 em $31
    
    LDA #$10
    ADC ($30),Y            ; $10 + $20 + 0 = $30
    CMP #$30
    BNE FAIL


; =================================================================
; PARTE 2: TESTE COM CARRY (SEC) e Overflow
; SEC -> C=1. Teste de Overflow: $80 + $80 + 1 = $01 (C=1)
; =================================================================

    SEC                    ; Set Carry (C=1)

    ; 1. ADC IMM (Teste de Overflow/Carry)
    LDA #$80
    ADC #$80               ; $80 + $80 + 1 = $01 (com Carry setado)
    CMP #$01
    BNE FAIL               

    ; ADC ZP ($65) com Carry (Teste de Zero Flag e Carry)
    LDA #$00
    STA $02                ; $02 = $00
    SEC
    LDA #$FF               ; $FF (-1)
    ADC $02                ; $FF + $00 + 1 = $00 (com Carry setado)
    CMP #$00
    BNE FAIL
    

; -------------------------------------------------
; FINALIZAÇÃO
; -------------------------------------------------
SUCCESS:
    LDA #$AA               ; SUCESSO: A termina com AA
    BRK

FAIL:
    LDA #$FF               ; ERRO: A termina com FF
    BRK
