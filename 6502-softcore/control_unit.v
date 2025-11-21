`include "alu_defines.vh"

module control_unit(
    input  wire        clk,
    input  wire        reset,
    output wire [7:0]  A_out,
    output wire [15:0] PC_out
);

    // --- ESTADOS DA FSM ---
    localparam FETCH     = 3'd0,
               DECODE    = 3'd1,
               READ      = 3'd2,
               EXECUTE   = 3'd3,
               WRITEBACK = 3'd4;

    // Sub-estágios
    localparam SUB_SET_ADDR = 2'd0, // Coloca endereço na RAM
               SUB_WAIT     = 2'd1, // Espera a RAM responder
               SUB_CAPTURE  = 2'd2; // Captura o dado

    localparam I_LDA = 3'd0, I_STA = 3'd1, I_ADC = 3'd2, I_SBC = 3'd3,
               I_AND = 3'd4, I_JMP = 3'd5, I_INX = 3'd6;

    // Registradores de Estado
    reg [2:0] current_stage, next_stage;
    reg [1:0] current_sub, next_sub;

    // Sinais Internos
    reg        we_a_sig, we_x_sig, we_y_sig, we_sp_sig, we_pc_sig, we_ps_sig;
    reg  [7:0] cpu_data_in;
    wire [7:0] A, X, Y, SP, PS;
    wire [15:0] PC;
    reg  [15:0] pc_in_reg;

    // Instâncias
    cpu_register cpu_register_inst (
        .clk(clk), .reset(reset),
        .we_a(we_a_sig), .we_x(we_x_sig), .we_y(we_y_sig),
        .we_sp(we_sp_sig), .we_pc(we_pc_sig), .we_ps(we_ps_sig),
        .data_in(cpu_data_in), .pc_in(pc_in_reg),
        .A(A), .X(X), .Y(Y), .SP(SP), .PC(PC), .PS(PS)
    );

    reg  [15:0] ram_address;
    reg  [7:0]  ram_data_in;
    wire [7:0]  ram_data_out;
    reg         r_ram, w_ram;

    ram ram16k (
        .address(ram_address), .clock(clk), .data(ram_data_in),
        .rden(r_ram), .wren(w_ram), .q(ram_data_out)
    );

    reg  [7:0] opcode;
    wire [4:0] alu_op_sig;
    wire       use_alu_sig, mem_read_sig, mem_write_sig;
    wire [1:0] addr_mode_sig, instr_size_sig;
    wire [2:0] instr_type_sig;

    decoder decoder_inst (
        .opcode(opcode), .alu_op(alu_op_sig), .use_alu(use_alu_sig),
        .mem_read(mem_read_sig), .mem_write(mem_write_sig),
        .addr_mode(addr_mode_sig), .instr_size(instr_size_sig), .instr_type(instr_type_sig)
    );

    reg [15:0] temp_pc;
    reg [7:0]  operand_lo, operand_hi, operand_val;
    reg [1:0]  operand_count; // Contador: 0, 1, 2, 3

    reg  [7:0] alu_reg1, alu_reg2;
    reg        alu_cin;
    wire [7:0] alu_result;
    wire [3:0] alu_flags;

    alu alu_inst (
        .alu_op(alu_op_sig), .reg1(alu_reg1), .reg2(alu_reg2),
        .carry_in(alu_cin), .result(alu_result), .flags(alu_flags)
    );

    assign A_out = A;
    assign PC_out = PC;

    // ----------------------------------------------------------------
    // LÓGICA SEQUENCIAL (Captura de Dados)
    // ----------------------------------------------------------------
    always @(posedge clk) begin
        if (reset) begin
            current_stage <= FETCH;
            current_sub   <= SUB_SET_ADDR;
            opcode        <= 8'd0;
            temp_pc       <= 16'h1000;
            operand_lo    <= 8'd0; operand_hi <= 8'd0; operand_val <= 8'd0;
            operand_count <= 2'd0;
        end else begin
            current_stage <= next_stage;
            current_sub   <= next_sub;

            // FETCH: Captura Opcode
            if (current_stage == FETCH && current_sub == SUB_CAPTURE) begin
                opcode <= ram_data_out;
            end
            
            // DECODE: Prepara Temp PC
            if (current_stage == DECODE) begin
                operand_count <= 2'd0;
                temp_pc <= PC + 16'd1; 
            end

            // READ: Captura
            if (current_stage == READ && current_sub == SUB_CAPTURE) begin
                // CASO 1: Lendo Bytes da Instrução (Endereço, Operando Imediato, etc)
                if (operand_count < (instr_size_sig - 1)) begin
                    if (operand_count == 2'd0) operand_lo <= ram_data_out;
                    else operand_hi <= ram_data_out;
                    
                    operand_count <= operand_count + 2'd1; // Incrementa contador de bytes lidos
                    temp_pc <= temp_pc + 16'd1; 
                end 
                // CASO 2: Lendo Dado Efetivo da Memória (Zero Page / Absolute)
                else begin
                    if (mem_read_sig) begin
                        operand_val <= ram_data_out;
                        operand_count <= operand_count + 2'd1; // Marca que já leu o dado
                    end
                end
            end
        end
    end

    // ----------------------------------------------------------------
    // LÓGICA COMBINACIONAL
    // ----------------------------------------------------------------
    always @(*) begin
        // Defaults
        ram_address = 16'd0; ram_data_in = 8'd0; r_ram = 0; w_ram = 0;
        we_a_sig = 0; we_x_sig = 0; we_y_sig = 0; we_sp_sig = 0; we_pc_sig = 0; we_ps_sig = 0;
        cpu_data_in = 8'd0; pc_in_reg = PC;
        
        alu_reg1 = A; 
        alu_reg2 = (addr_mode_sig == 2'd1) ? operand_lo : operand_val;
        alu_cin = PS[0];

        next_stage = current_stage;
        next_sub   = current_sub;

        case (current_stage)
            // --- FETCH ---
            FETCH: begin
                case (current_sub)
                    SUB_SET_ADDR: begin ram_address = PC; r_ram = 1; next_sub = SUB_WAIT; end
                    SUB_WAIT:     begin ram_address = PC; r_ram = 1; next_sub = SUB_CAPTURE; end
                    SUB_CAPTURE:  begin next_stage = DECODE; next_sub = SUB_SET_ADDR; end
                    default: next_sub = SUB_SET_ADDR;
                endcase
            end

            DECODE: begin
                if (instr_size_sig == 2'd1) next_stage = EXECUTE;
                else next_stage = READ;
                next_sub = SUB_SET_ADDR;
            end

            // --- READ ---
            READ: begin
                case (current_sub)
                    SUB_SET_ADDR: begin
                        // Lógica de Endereçamento:
                        // 1. Se ainda não lemos a instrução toda, leia do PC Temporário
                        if (operand_count < (instr_size_sig - 1)) begin
                            ram_address = temp_pc;
                        end 
                        // 2. Se já lemos a instrução e precisamos ler a MEMÓRIA (mem_read=1)
                        else if (mem_read_sig) begin
                            // Zero Page: Endereço é {00, operand_lo}
                            if (instr_size_sig == 2'd2) ram_address = {8'd0, operand_lo};
                            // Absolute: Endereço é {operand_hi, operand_lo}
                            else ram_address = {operand_hi, operand_lo};
                        end
                        
                        r_ram = 1;
                        next_sub = SUB_WAIT;
                    end

                    SUB_WAIT: begin
                        // Mantém o endereço estável
                        if (operand_count < (instr_size_sig - 1)) ram_address = temp_pc;
                        else begin
                            if (instr_size_sig == 2'd2) ram_address = {8'd0, operand_lo};
                            else ram_address = {operand_hi, operand_lo};
                        end
                        r_ram = 1; 
                        next_sub = SUB_CAPTURE;
                    end

                    SUB_CAPTURE: begin
                        // Decisão para onde ir depois de capturar
                        
                        // A. Ainda falta ler byte de instrução? (Ex: leu LO, falta HI do JMP)
                        if (operand_count < (instr_size_sig - 1)) begin
                             next_sub = SUB_SET_ADDR; // Volta para ler o próximo
                        end 
                        // B. Instrução lida. Precisa ler DADO da memória? (E ainda não leu)
                        else if (mem_read_sig && operand_count == (instr_size_sig - 1)) begin
                             next_sub = SUB_SET_ADDR; // Vai ler o dado efetivo
                        end
                        // C. Tudo pronto.
                        else begin
                             next_stage = EXECUTE; next_sub = SUB_SET_ADDR;
                        end
                    end
                    default: next_sub = SUB_SET_ADDR;
                endcase
            end

            EXECUTE: begin
                next_stage = WRITEBACK;
            end

            WRITEBACK: begin
                if (instr_type_sig == I_INX) begin alu_reg1 = X; alu_reg2 = 8'd0; end

                case (instr_type_sig)
                    I_LDA: begin
                        we_a_sig = 1; we_ps_sig = 1;
                        // Se Imediato, usa operand_lo. Se ZP/ABS, usa operand_val
                        cpu_data_in = (addr_mode_sig == 2'd1) ? operand_lo : operand_val;
                    end
                    I_STA: begin
                        w_ram = 1; ram_data_in = A; 
                        // Endereço de escrita
                        if (addr_mode_sig == 2'd2) ram_address = {8'd0, operand_lo}; // ZP
                        else ram_address = {operand_hi, operand_lo}; // ABS
                    end
                    I_ADC, I_SBC, I_AND: begin
                        we_a_sig = 1; we_ps_sig = 1; cpu_data_in = alu_result;
                    end
                    I_INX: begin
                        we_x_sig = 1; we_ps_sig = 1; cpu_data_in = alu_result;
                    end
                endcase

                we_pc_sig = 1'b1;
                if (instr_type_sig == I_JMP) pc_in_reg = {operand_hi, operand_lo};
                else begin
                    if (instr_size_sig == 2'd1) pc_in_reg = PC + 16'd1;
                    else if (instr_size_sig == 2'd2) pc_in_reg = PC + 16'd2;
                    else pc_in_reg = PC + 16'd3;
                end

                next_stage = FETCH;
                next_sub = SUB_SET_ADDR;
            end
            default: next_stage = FETCH;
        endcase
    end
endmodule