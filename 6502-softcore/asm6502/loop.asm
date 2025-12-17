START:
    ; Test LSR A (Accumulator)
    LDA #$04        ; Load value into A
    LSR             ; Perform LSR on Accumulator
    CMP #$02        ; Compare result with expected value
    BNE FAILURE     ; Branch to FAILURE if not equal

    ; Test LSR ZP (Zero Page)
    LDA #$08        ; Load value into A
    STA $10         ; Store value into Zero Page address $10
    LSR $10         ; Perform LSR on Zero Page address $10
    LDA $10         ; Load value from Zero Page address $10
    CMP #$04        ; Compare result with expected value
    BNE FAILURE     ; Branch to FAILURE if not equal

    ; Test LSR ZPX (Zero Page,X)
    LDX #$01        ; Load X register with offset
    LDA #$10        ; Load value into A
    STA $20,X       ; Store value into Zero Page address $20 + X
    LSR $20,X       ; Perform LSR on Zero Page address $20 + X
    LDA $20,X       ; Load value from Zero Page address $20 + X
    CMP #$08        ; Compare result with expected value
    BNE FAILURE     ; Branch to FAILURE if not equal

    ; Test LSR ABS (Absolute)
    LDA #$20        ; Load value into A
    STA $1000       ; Store value into Absolute address $1000
    LSR $1000       ; Perform LSR on Absolute address $1000
    LDA $1000       ; Load value from Absolute address $1000
    CMP #$10        ; Compare result with expected value
    BNE FAILURE     ; Branch to FAILURE if not equal

    ; Test LSR ABX (Absolute,X)
    LDX #$03        ; Load X register with offset
    LDA #$40        ; Load value into A
    STA $2000,X     ; Store value into Absolute address $2000 + X
    LSR $2000,X     ; Perform LSR on Absolute address $2000 + X
    LDA $2000,X     ; Load value from Absolute address $2000 + X
    CMP #$20        ; Compare result with expected value
    BNE FAILURE     ; Branch to FAILURE if not equal

SUCCESS:
    LDA #$EE        ; All tests passed, store EE in A
    JMP SUCCESS

FAILURE:
    LDA #$FF        ; Test failed, store FF in A
    JMP FAILURE

