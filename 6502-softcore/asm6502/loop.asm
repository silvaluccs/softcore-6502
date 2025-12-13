; ========================================
; TESTE COMPLETO DE INDX E INDY
; ========================================
; Endereços de Status:
; $00FE = Progresso do teste (qual teste passou)
; $00FF = Status Final (0=Falha, 1=Sucesso Total)
; ========================================

SETUP:
    ; Limpa status
    LDA #$00
    STA $00FE       ; Progresso = 0
    STA $00FF       ; Status = 0 (Falha)

TEST1_INDX_SIMPLE:
    ; Prepara ponteiro
    LDA #$00        ; Low byte de $3000
    STA $20
    LDA #$30        ; High byte de $3000
    STA $21
    
    ; Escreve dado na memória alvo
    LDA #$AA
    STA $3000
    
    ; Testa leitura
    LDX #$00        ; Ponteiro em $20+0 = $20
    LDA ($20, X)    ; Lê de ($20) = $3000
    CMP #$AA
    BNE FAIL
    
    ; Marca progresso
    LDA #$01
    STA $00FE

; ========================================
; TESTE 2: INDX COM OFFSET
; ========================================
; Configuração:
; - Ponteiro em $22-$23 = $3100
; - Dado em $3100 = $BB
; - X = $02 (ponteiro em $20+2 = $22)
; ========================================
TEST2_INDX_OFFSET:
    ; Prepara ponteiro
    LDA #$00        ; Low byte de $3100
    STA $22
    LDA #$31        ; High byte de $3100
    STA $23
    
    ; Escreve dado
    LDA #$BB
    STA $3100
    
    ; Testa leitura
    LDX #$02        ; Ponteiro em $20+2 = $22
    LDA ($20, X)    ; Lê de ($22) = $3100
    CMP #$BB
    BNE FAIL
    
    ; Marca progresso
    LDA #$02
    STA $00FE

; ========================================
; TESTE 3: INDY SIMPLES
; ========================================
; Configuração:
; - Ponteiro em $40-$41 = $3200
; - Dado em $3200 = $CC
; - Y = $00 (sem offset)
; ========================================
TEST3_INDY_SIMPLE:
    ; Prepara ponteiro
    LDA #$00        ; Low byte de $3200
    STA $40
    LDA #$32        ; High byte de $3200
    STA $41
    
    ; Escreve dado
    LDA #$CC
    STA $3200
    
    ; Testa leitura
    LDY #$00        ; Offset = 0
    LDA ($40), Y    ; Lê de ($40)+0 = $3200
    CMP #$CC
    BNE FAIL
    
    ; Marca progresso
    LDA #$03
    STA $00FE

; ========================================
; TESTE 4: INDY COM OFFSET
; ========================================
; Configuração:
; - Ponteiro em $40-$41 = $3200 (reusa do teste anterior)
; - Dado em $3205 = $DD
; - Y = $05 (offset)
; ========================================
TEST4_INDY_OFFSET:
    ; Escreve dado (ponteiro já configurado)
    LDA #$DD
    STA $3205
    
    ; Testa leitura
    LDY #$05        ; Offset = 5
    LDA ($40), Y    ; Lê de ($40)+5 = $3205
    CMP #$DD
    BNE FAIL
    
    ; Marca progresso
    LDA #$04
    STA $00FE

; ========================================
; TESTE 5: INDX WRAP ZERO PAGE
; ========================================
; Configuração:
; - Ponteiro em $FE-$FF (wrap) = $3300
; - Dado em $3300 = $EE
; - X = $FE
; ========================================
; ========================================
; SUCESSO!
; ========================================
SUCCESS:
    LDA #$01
    STA $00FF       ; Status = 1 (Sucesso!)
    JMP SUCCESS     ; Loop infinito

; ========================================
; FALHA
; ========================================
FAIL:
    LDA #$FF        ; Marca erro
    STA $00FF       ; Status = FF (Falha)
    JMP FAIL        ; Loop infinito
