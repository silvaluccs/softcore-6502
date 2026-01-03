TEST_JSR_RTS:
    LDX #$00       ; Initialize X register to 0
    LDY #$01       ; Initialize Y register to 1
    JSR SUBROUTINE ; Jump to subroutine

    LDA #$AA       ; Clear Accumulator A
    ; After returning from JSR, check if the accumulators are preserved
    NOP            ; No operation to check for correct behavior

    JMP END        ; Jump to the end of the program

SUBROUTINE:
    TXA            ; Transfer X to Accumulator
    INX            ; Increment X register
    TYA            ; Transfer Y to Accumulator
    INY            ; Increment Y register
    CPX #$05       ; Compare X register with 5 (end condition)
    BNE RECURSE    ; If not equal, branch to RECURSE
    RTS            ; Return from Subroutine

RECURSE:
    JSR SUBROUTINE ; Recursive call to subroutine
    RTS            ; Return from Subroutine

END:
    JMP END       ; Infinite loop to end the program

