        ; --- Início em $1000 ---
START: 

        ; Teste PHA / PLA (dados)
        LDA #$AA        ; A=$AA
        PHA             ; [01FF]=$AA, SP=$FE
        LDA #$BB        ; A=$BB (só para sujar)
        PLA             ; A=$AA, SP=$FF  (recupera valor original)

        ; Preparar flags conhecidos e testar PHP / PLP
        CLC             ; C=0
        CLD             ; D=0
        CLI             ; I=0
        CLV             ; V=0
        LDA #$00        ; Z=1, N=0
        SEC             ; C=1
        SEI             ; I=1
        SED             ; D=1
        PHP             ; empilha PS ≈ %00111111 = $3F (B=1, bit5=1), SP=$FE

        ; Sujar flags e A, depois restaurar com PLP
        LDA #$80        ; Z=0, N=1
        CLC             ; C=0
        CLD             ; D=0
        CLI             ; I=0
        CLV             ; V=0
        PLP             ; puxa $3F => PS: N=0, Z=1, C=1, I=1, D=1, V=0, bit5=1, B=1; SP=$FF

        ; Testar RTS com uma subrotina simples que faz push/pull
        JSR SUB         ; deve voltar para a próxima instrução
        LDA #$EE        ; A=$EE, executada após o RTS

END:    
      LDA #$EA
      JMP END         ; loop final

; --- Subrotina ---
SUB:
        LDA #$11        ; A=$11
        PHA             ; push $11 (SP-- -> $FE)
        PLA             ; A=$11, SP volta a $FF
        RTS             ; retorna para depois do JSR
