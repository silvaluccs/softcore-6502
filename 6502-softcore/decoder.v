`include "alu_defines.vh"

module decoder (
    input  wire [7:0] opcode,
    output reg  [4:0] alu_op,
    output reg        use_alu,
    output reg        mem_read,
    output reg        mem_write,
    output reg  [1:0] addr_mode,   // 00=implied, 01=imm, 02=zp, 03=abs
    output reg  [1:0] instr_size,  // 1,2,3 bytes
    output reg  [2:0] instr_type   // 0=LDA,1=STA,2=ADC,3=SBC,4=AND,5=JMP,6=INX
);

    // Addressing modes
    localparam IMPL = 2'd0;
    localparam IMM  = 2'd1;
    localparam ZP   = 2'd2;
    localparam ABS  = 2'd3;

    // Instruction types
    localparam I_LDA = 3'd0;
    localparam I_STA = 3'd1;
    localparam I_ADC = 3'd2;
    localparam I_SBC = 3'd3;
    localparam I_AND = 3'd4;
    localparam I_JMP = 3'd5;
    localparam I_INX = 3'd6;

    always @(*) begin
        // Defaults
        alu_op     = 0;
        use_alu    = 0;
        mem_read   = 0;
        mem_write  = 0;
        instr_size = 2'd1;
        addr_mode  = IMPL;
        instr_type = I_LDA;   // default seguro

        case (opcode)

            // -------- LDA --------
            8'hA9: begin // immediate
                instr_type = I_LDA;
                addr_mode  = IMM;
                instr_size = 2;
                mem_read   = 1;
                use_alu    = 1;
                alu_op     = ALU_OP_PASS;
            end
            8'hA5: begin // zeropage
                instr_type = I_LDA;
                addr_mode  = ZP;
                instr_size = 2;
                mem_read   = 1;
                use_alu    = 1;
                alu_op     = ALU_OP_PASS;
            end

            // -------- STA --------
            8'h85: begin // zeropage
                instr_type = I_STA;
                addr_mode  = ZP;
                instr_size = 2;
                mem_write  = 1;
                // sem ALU
            end

            // -------- ADC --------
            8'h69: begin
                instr_type = I_ADC;
                addr_mode  = IMM;
                instr_size = 2;
                mem_read   = 1;
                use_alu    = 1;
                alu_op     = ALU_OP_ADD;
            end

            // -------- SBC --------
            8'hE9: begin
                instr_type = I_SBC;
                addr_mode  = IMM;
                instr_size = 2;
                mem_read   = 1;
                use_alu    = 1;
                alu_op     = ALU_OP_SUB;
            end

            // -------- AND --------
            8'h29: begin
                instr_type = I_AND;
                addr_mode  = IMM;
                instr_size = 2;
                mem_read   = 1;
                use_alu    = 1;
                alu_op     = ALU_OP_AND;
            end

            // -------- JMP --------
            8'h4C: begin
                instr_type = I_JMP;
                addr_mode  = ABS;
                instr_size = 3;
            end

            // -------- INX --------
            8'hE8: begin
                instr_type = I_INX;
                addr_mode  = IMPL;
                instr_size = 1;
                use_alu    = 1;
                alu_op     = ALU_OP_INC;
            end

            default: begin
                // Illegal / NOP
                instr_size = 1;
            end
        endcase
    end

endmodule
