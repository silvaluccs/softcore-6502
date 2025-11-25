`include "alu_defines.vh"

module control_unit(
    input  wire         clk,
    input  wire         reset,
    output wire [7:0]   A_out,
    output wire [15:0]  PC_out,
    output wire [7:0]   X_out,  // <--- NOVO: Saída para o registrador X
    output wire [7:0]   Y_out   // <--- NOVO: Saída para o registrador Y
);
   
    // Addressing modes
    localparam IMPL = 2'd0;
    localparam IMM  = 2'd1; 
    localparam ZP   = 2'd2;
    localparam ABS  = 2'd3;

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

    // Instruction types (8 bits de largura)
    localparam I_LDA = 8'd0, I_STA = 8'd1, I_ADC = 8'd2, I_SBC = 8'd3,
               I_AND = 8'd4, I_JMP = 8'd5, I_INX = 8'd6, I_ORA = 8'd7,  
               I_XOR = 8'd8, I_INC = 8'd9, I_ASL = 8'd10, I_LSR = 8'd11,
               I_ROL = 8'd12, I_ROR = 8'd13, I_BEQ = 8'd14, I_BNE = 8'd15,
               I_BCS = 8'd16, I_BCC = 8'd17, I_BMI = 8'd18, I_BPL = 8'd19, I_BVC = 8'd20,
               I_BVS = 8'd21, I_TA = 8'd22, I_TX = 8'd23, I_TY = 8'd24, I_TS = 8'd25; // <-- PONTO E VÍRGULA CORRIGIDO (era vírgula ou faltava)
     
    // Register Destinations
    localparam DEST_NONE = 3'd0;
    localparam DEST_A    = 3'd1;
    localparam DEST_X    = 3'd2;
    localparam DEST_Y    = 3'd3;
    localparam DEST_MEM  = 3'd4;
    localparam DEST_SP   = 3'd5;

    // Registradores de Estado
    reg [2:0] current_stage, next_stage;
    reg [1:0] current_sub, next_sub;

    // Sinais Internos
    reg         we_a_sig, we_x_sig, we_y_sig, we_sp_sig, we_pc_sig, we_ps_sig;
    reg  [7:0] cpu_data_in;
    wire [7:0] A, X, Y, SP, PS;
    wire [15:0] PC;
    reg  [15:0] pc_in_reg;

    // Instâncias
    cpu_register cpu_register_inst (
        .clk(clk), .reset(reset),
        .we_a(we_a_sig), .we_x(we_x_sig), .we_y(we_y_sig),
        .we_sp(we_sp_sig), .we_pc(we_pc_sig), .we_ps(we_ps_sig),
        .data_in(cpu_data_in), .pc_in(pc_in_reg), .flags_in(flags_in_sig),
        .A(A), .X(X), .Y(Y), .SP(SP), .PC(PC), .PS(PS)
    );

    wire [7:0] flags_in_sig;
   
    assign flags_in_sig[3:0] = alu_flags; 
    
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
    wire        use_alu_sig, mem_read_sig, mem_write_sig;
    wire [1:0] addr_mode_sig, instr_size_sig;
    wire [7:0] instr_type_sig;
    wire [2:0] reg_dest_sig; 

    decoder decoder_inst (
        .opcode(opcode), .alu_op(alu_op_sig), .use_alu(use_alu_sig),
        .mem_read(mem_read_sig), .mem_write(mem_write_sig),
        .addr_mode(addr_mode_sig), .instr_size(instr_size_sig), 
        .instr_type(instr_type_sig),
        .reg_dest(reg_dest_sig) 
    );

    reg [15:0] temp_pc;
    reg [7:0]  operand_lo, operand_hi, operand_val;
    reg [1:0]  operand_count; 

    reg  [7:0] alu_reg1, alu_reg2;
    reg         alu_cin;
    wire [7:0] alu_result;
    wire [3:0] alu_flags;

    alu alu_inst (
        .alu_op(alu_op_sig), .reg1(alu_reg1), .reg2(alu_reg2),
        .carry_in(alu_cin), .result(alu_result), .flags(alu_flags)
    );
    
    wire [7:0] off = operand_lo;
    wire [15:0] offset16 = (off[7] ? {8'hFF, off} : {8'h00, off}) + 16'd2;

    assign A_out = A;
    assign PC_out = PC;
    assign X_out = X;    
    assign Y_out = Y;    

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
                // CASO 1: Lendo Bytes da Instrução
                if (operand_count < (instr_size_sig - 1)) begin
                    if (operand_count == 2'd0) operand_lo <= ram_data_out;
                    else operand_hi <= ram_data_out;
                    
                    operand_count <= operand_count + 2'd1; 
                    temp_pc <= temp_pc + 16'd1; 
                end 
                // CASO 2: Lendo Dado Efetivo da Memória
                else begin
                    if (mem_read_sig) begin
                        operand_val <= ram_data_out;
                        operand_count <= operand_count + 2'd1; 
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
        
        // --- Lógica de Seleção de alu_reg1 (Entrada 1 da ALU) ---
        // Esta lógica foi expandida para cobrir INC/DEC de memória e instruções de Transferência (TXA, TYA, etc.)
        
        if (instr_type_sig == I_INC) begin
             // INC/DEC na memória usa o valor lido da memória
             alu_reg1 = operand_val;
        end 
        else if (instr_type_sig == I_INX) begin
             // INX, DEX, INY, DEY
             if (reg_dest_sig == DEST_Y) begin
                 alu_reg1 = Y; 
             end else begin
                 alu_reg1 = X; 
             end
        end 
        // CORREÇÃO PARA TRANSFERÊNCIAS:
        else if (instr_type_sig == I_TX) begin // TXA, TXS
             alu_reg1 = X;
        end
        else if (instr_type_sig == I_TY) begin // TYA
             alu_reg1 = Y;
        end
        else if (instr_type_sig == I_TS) begin // TSX
             alu_reg1 = SP;
        end
        else if (instr_type_sig == I_TA) begin // TAX, TAY
             alu_reg1 = A;
        end
        else begin
             // Padrão (ADC, SBC, etc.) usa Acumulador
             alu_reg1 = A;
        end
        
        // --- Lógica de Seleção de alu_reg2 (Entrada 2 da ALU) ---
        // Para transferências, o reg2 recebe 0 (ou pass-through na ALU)
        // Na sua ALU, ALU_OP_PASS passa reg2. Então reg1 é ignorado? 
        // NÃO: Se for PASS, sua ALU faz 'result = reg2'. 
        // ENTÃO A LÓGICA INVERSA É NECESSÁRIA PARA TRANSFERÊNCIAS.
        
        // Vamos ajustar alu_reg2 para ser a FONTE da transferência se a ALU usar PASS em reg2.
        if (instr_type_sig == I_TA) begin
             alu_reg2 = A; // TAX, TAY (A -> X/Y)
        end else if (instr_type_sig == I_TX) begin
             alu_reg2 = X; // TXA, TXS (X -> A/S)
        end else if (instr_type_sig == I_TY) begin
             alu_reg2 = Y; // TYA (Y -> A)
        end else if (instr_type_sig == I_TS) begin
             alu_reg2 = SP; // TSX (S -> X)
        end else begin
             // Padrão para aritméticas
             alu_reg2 = (addr_mode_sig == IMM) ? operand_lo : operand_val;
        end
        
        // Nota: Como sua ALU em ALU_OP_PASS passa 'reg2', a lógica acima para alu_reg2
        // garante que a fonte correta (A, X, Y, SP) chegue na saída da ALU.
        
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
                        if (operand_count < (instr_size_sig - 1)) begin
                            ram_address = temp_pc;
                        end 
                        else if (mem_read_sig) begin
                            if (instr_size_sig == 2'd2) ram_address = {8'd0, operand_lo};
                            else ram_address = {operand_hi, operand_lo};
                        end
                        
                        r_ram = 1;
                        next_sub = SUB_WAIT;
                    end

                    SUB_WAIT: begin
                        if (operand_count < (instr_size_sig - 1)) ram_address = temp_pc;
                        else begin
                            if (instr_size_sig == 2'd2) ram_address = {8'd0, operand_lo};
                            else ram_address = {operand_hi, operand_lo};
                        end
                        r_ram = 1; 
                        next_sub = SUB_CAPTURE;
                    end

                    SUB_CAPTURE: begin
                        if (operand_count < (instr_size_sig - 1)) begin
                             next_sub = SUB_SET_ADDR; 
                        end 
                        else if (mem_read_sig && operand_count == (instr_size_sig - 1)) begin
                             next_sub = SUB_SET_ADDR; 
                        end
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
                // Ativa a escrita nos registradores
                we_a_sig = (reg_dest_sig == DEST_A) && (!mem_write_sig);
                we_x_sig = (reg_dest_sig == DEST_X) && (!mem_write_sig);
                we_y_sig = (reg_dest_sig == DEST_Y) && (!mem_write_sig);
                we_sp_sig = (reg_dest_sig == DEST_SP) && (!mem_write_sig);
                
                // Ativa escrita de flags (exceto para JMP e Stores puros)
                we_ps_sig = (reg_dest_sig != DEST_NONE) && (instr_type_sig != I_JMP) && (!mem_write_sig); 

                if (mem_write_sig) begin
                    w_ram = 1; 
                    // STA/STX/STY
                    if (instr_type_sig == I_STA) begin 
                        case (reg_dest_sig)
                            DEST_A: ram_data_in = A;
                            DEST_X: ram_data_in = X;
                            DEST_Y: ram_data_in = Y;
                            DEST_SP: ram_data_in = SP;
                            default: ram_data_in = A;
                        endcase
                    end
                    // INC/DEC Memória
                    else if (reg_dest_sig == DEST_MEM) begin
                        ram_data_in = alu_result;
                    end
                    
                    if (addr_mode_sig == 2'd2) ram_address = {8'd0, operand_lo}; 
                    else ram_address = {operand_hi, operand_lo}; 
                end

                // O dado de entrada da CPU
                if (reg_dest_sig == DEST_A || reg_dest_sig == DEST_X || reg_dest_sig == DEST_Y || reg_dest_sig == DEST_SP) begin
                    if (instr_type_sig == I_LDA) begin
                        cpu_data_in = (addr_mode_sig == IMM) ? operand_lo : operand_val;
                    end else if (use_alu_sig) begin
                        cpu_data_in = alu_result;
                    end
                end

                // Lógica de atualização do PC
                we_pc_sig = 1'b1;
                
                if (instr_type_sig == I_JMP) pc_in_reg = {operand_hi, operand_lo};
                else if (instr_type_sig == I_BEQ && PS[1]) pc_in_reg = PC + offset16;
                else if (instr_type_sig == I_BNE && !PS[1]) pc_in_reg = PC + offset16;
                else if (instr_type_sig == I_BCS && PS[0]) pc_in_reg = PC + offset16;
                else if (instr_type_sig == I_BCC && !PS[0]) pc_in_reg = PC + offset16;
                else if (instr_type_sig == I_BMI && PS[7]) pc_in_reg = PC + offset16; // N é bit 7
                else if (instr_type_sig == I_BPL && !PS[7]) pc_in_reg = PC + offset16; // N é bit 7
                else if (instr_type_sig == I_BVC && !PS[6]) pc_in_reg = PC + offset16; // V é bit 6
                else if (instr_type_sig == I_BVS && PS[6]) pc_in_reg = PC + offset16; // V é bit 6
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