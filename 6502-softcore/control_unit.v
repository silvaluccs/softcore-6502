`include "alu_defines.vh"

module control_unit(
    input  wire          clk,
    input  wire          reset,
    output wire [7:0]    A_out,
    output wire [15:0]   PC_out,
    output wire [7:0]    X_out,
    output wire [7:0]    Y_out
);
   
    // Addressing modes
    localparam IMPL = 4'd0;
    localparam IMM  = 4'd1; 
    localparam ZP   = 4'd2;
    localparam ABS  = 4'd3;
    localparam ZPX  = 4'd4;
    localparam ZPY  = 4'd5;
    localparam ABX  = 4'd6;
    localparam ABY  = 4'd7;
    localparam INDX = 4'd8;
    localparam INDY = 4'd9;

    // --- ESTADOS DA FSM ---
    localparam FETCH         = 3'd0,
               DECODE        = 3'd1,
               READ          = 3'd2,
               EXECUTE       = 3'd3,
               WRITEBACK     = 3'd4;

    // Sub-estágios gerais (SET_ADDR -> WAIT -> CAPTURE)
    localparam SUB_SET_ADDR = 2'd0,
               SUB_WAIT     = 2'd1,
               SUB_CAPTURE  = 2'd2;

    // Sub-estágios para endereçamento indireto
    // Cada leitura precisa: SET_ADDR -> WAIT -> CAPTURE (3 ciclos)
    localparam SUB_IND_READ_LO   = 3'd0,  // Fase 1: Lê byte LOW do ponteiro
               SUB_IND_READ_HI   = 3'd1,  // Fase 2: Lê byte HIGH do ponteiro  
               SUB_IND_READ_DATA = 3'd2,  // Fase 3: Lê dado final do endereço
               SUB_IND_COMPLETE  = 3'd3;  // Completo

    // Instruction types
    localparam I_LDA = 8'd0, I_STA = 8'd1, I_ADC = 8'd2, I_SBC = 8'd3,
               I_AND = 8'd4, I_JMP = 8'd5, I_INX = 8'd6, I_ORA = 8'd7,  
               I_XOR = 8'd8, I_INC = 8'd9, I_ASL = 8'd10, I_LSR = 8'd11,
               I_ROL = 8'd12, I_ROR = 8'd13, I_BEQ = 8'd14, I_BNE = 8'd15,
               I_BCS = 8'd16, I_BCC = 8'd17, I_BMI = 8'd18, I_BPL = 8'd19, 
               I_BVC = 8'd20, I_BVS = 8'd21, I_TA = 8'd22, I_TX = 8'd23, 
               I_TY = 8'd24, I_TS = 8'd25, I_CMP = 8'd26, I_CPX = 8'd27, 
               I_CPY = 8'd28, I_SET_CARRY = 8'd29, I_CLR_CARRY = 8'd30,
               I_SET_IRQ = 8'd31, I_CLR_IRQ = 8'd32, I_SET_CLD = 8'd33, 
               I_CLR_CLD = 8'd34, I_CLR_CLV = 8'd35;

    // Register Destinations
    localparam DEST_NONE = 3'd0;
    localparam DEST_A    = 3'd1;
    localparam DEST_X    = 3'd2;
    localparam DEST_Y    = 3'd3;
    localparam DEST_MEM  = 3'd4;
    localparam DEST_SP   = 3'd5;
    localparam DEST_PS   = 3'd6;

    // Registradores de Estado
    reg [2:0] current_stage, next_stage;
    reg [1:0] current_sub, next_sub;
    reg [2:0] current_ind_sub, next_ind_sub;  // 3 bits para 4 estados do indireto

    // Sinais Internos
    reg           we_a_sig, we_x_sig, we_y_sig, we_sp_sig, we_pc_sig, we_ps_sig;
    reg  [7:0]    cpu_data_in;
    wire [7:0]    A, X, Y, SP, PS;
    wire [15:0]   PC;
    reg  [15:0]   pc_in_reg;
    reg  [7:0]    flags_in_sig;

    // Instância do banco de registradores
    cpu_register cpu_register_inst (
        .clk(clk), .reset(reset),
        .we_a(we_a_sig), .we_x(we_x_sig), .we_y(we_y_sig),
        .we_sp(we_sp_sig), .we_pc(we_pc_sig), .we_ps(we_ps_sig),
        .data_in(cpu_data_in), .pc_in(pc_in_reg), .flags_in(flags_in_sig),
        .A(A), .X(X), .Y(Y), .SP(SP), .PC(PC), .PS(PS)
    );
    
    // Interface com a RAM
    reg  [15:0] ram_address;
    reg  [7:0]  ram_data_in;
    wire [7:0]  ram_data_out;
    reg         r_ram, w_ram;

    ram ram16k (
        .address(ram_address), .clock(clk), .data(ram_data_in),
        .rden(r_ram), .wren(w_ram), .q(ram_data_out)
    );

    // Decoder
    reg  [7:0] opcode;
    wire [4:0] alu_op_sig;
    wire        use_alu_sig, mem_read_sig, mem_write_sig;
    wire [1:0] instr_size_sig;
    wire [3:0] addr_mode_sig;
    wire [7:0] instr_type_sig;
    wire [2:0] reg_dest_sig; 

    decoder decoder_inst (
        .opcode(opcode), .alu_op(alu_op_sig), .use_alu(use_alu_sig),
        .mem_read(mem_read_sig), .mem_write(mem_write_sig),
        .addr_mode(addr_mode_sig), .instr_size(instr_size_sig), 
        .instr_type(instr_type_sig),
        .reg_dest(reg_dest_sig) 
    );

    // Operandos e temporários
    reg [15:0] temp_pc;
    reg [7:0]  operand_lo, operand_hi, operand_val;
    reg [1:0]  operand_count;
    
    // Temporários para endereçamento indireto
    reg [7:0]  indirect_lo, indirect_hi;
    reg [15:0] effective_addr;

    // ALU
    reg  [7:0] alu_reg1, alu_reg2;
    reg        alu_cin;
    wire [7:0] alu_result;
    wire [3:0] alu_flags;

    alu alu_inst (
        .alu_op(alu_op_sig), .reg1(alu_reg1), .reg2(alu_reg2),
        .carry_in(alu_cin), .result(alu_result), .flags(alu_flags)
    );

    // Cálculo de offset para branches
    wire [7:0]  off = operand_lo;
    wire [15:0] offset16 = (off[7] ? {8'hFF, off} : {8'h00, off}) + 16'd2;

    // Saídas
    assign A_out  = A;
    assign PC_out = PC;
    assign X_out  = X;    
    assign Y_out  = Y;    

    // ----------------------------------------------------------------
    // LÓGICA SEQUENCIAL (Captura de Dados e Atualização de Estado)
    // ----------------------------------------------------------------
    always @(posedge clk) begin
        if (reset) begin
            current_stage    <= FETCH;
            current_sub      <= SUB_SET_ADDR;
            current_ind_sub  <= SUB_IND_READ_LO;
            opcode           <= 8'd0;
            temp_pc          <= 16'h1000;
            operand_lo       <= 8'd0;
            operand_hi       <= 8'd0;
            operand_val      <= 8'd0;
            operand_count    <= 2'd0;
            indirect_lo      <= 8'd0;
            indirect_hi      <= 8'd0;
            effective_addr   <= 16'd0;
        end else begin
            current_stage    <= next_stage;
            current_sub      <= next_sub;
            current_ind_sub  <= next_ind_sub;

            // FETCH: Captura Opcode
            if (current_stage == FETCH && current_sub == SUB_CAPTURE) begin
                opcode <= ram_data_out;
            end
            
            // DECODE: Prepara Temp PC e reseta indiretos
            if (current_stage == DECODE) begin
                operand_count <= 2'd0;
                temp_pc       <= PC + 16'd1; 
                indirect_lo   <= 8'd0;
                indirect_hi   <= 8'd0;
                effective_addr <= 16'd0;
            end

            // READ: Captura de operandos
            if (current_stage == READ && current_sub == SUB_CAPTURE) begin
                // CASO 1: Lendo bytes da instrução (operandos imediatos/endereços)
                if (operand_count < (instr_size_sig - 1)) begin
                    if (operand_count == 2'd0) 
                        operand_lo <= ram_data_out;
                    else 
                        operand_hi <= ram_data_out;
                    
                    operand_count <= operand_count + 2'd1; 
                    temp_pc       <= temp_pc + 16'd1; 
                end 
                // CASO 2: Lendo para INDX/INDY (3 fases: LOW, HIGH, DATA)
                // CORREÇÃO: Remoção de atribuições a next_ind_sub aqui (movido para lógica combinacional)
                else if ((addr_mode_sig == INDX || addr_mode_sig == INDY)) begin
                    case (current_ind_sub)
                        SUB_IND_READ_LO: begin
                            // Captura byte LOW do ponteiro
                            indirect_lo <= ram_data_out;
                        end
                        SUB_IND_READ_HI: begin
                            // Captura byte HIGH do ponteiro e calcula endereço efetivo
                            indirect_hi <= ram_data_out;
                            if (addr_mode_sig == INDY)
                                effective_addr <= {ram_data_out, indirect_lo} + {8'd0, Y};
                            else
                                effective_addr <= {ram_data_out, indirect_lo};
                        end
                        SUB_IND_READ_DATA: begin
                            // Captura o dado final
                            operand_val <= ram_data_out;
                            operand_count <= operand_count + 2'd1;
                        end
                        default: begin end
                    endcase
                end
                // CASO 3: Lendo dado efetivo para outros modos
                else if (mem_read_sig) begin
                    operand_val   <= ram_data_out;
                    operand_count <= operand_count + 2'd1; 
                end
            end
            
            // WRITEBACK: Captura para endereçamento indireto durante escrita
            if (current_stage == WRITEBACK && mem_write_sig && 
                (addr_mode_sig == INDX || addr_mode_sig == INDY) &&
                current_sub == SUB_CAPTURE) begin
                // CORREÇÃO: Remoção de atribuições a next_ind_sub aqui (movido para lógica combinacional)
                if (current_ind_sub == SUB_IND_READ_LO) begin
                    indirect_lo <= ram_data_out;
                end else if (current_ind_sub == SUB_IND_READ_HI) begin
                    indirect_hi <= ram_data_out;
                    if (addr_mode_sig == INDY)
                        effective_addr <= {ram_data_out, indirect_lo} + {8'd0, Y};
                    else
                        effective_addr <= {ram_data_out, indirect_lo};
                end
            end
        end
    end

    // ----------------------------------------------------------------
    // LÓGICA COMBINACIONAL (Próximo Estado e Saídas)
    // ----------------------------------------------------------------
    always @(*) begin
        // Defaults
        ram_address  = 16'd0;
        ram_data_in  = 8'd0;
        r_ram        = 0;
        w_ram        = 0;
        we_a_sig     = 0;
        we_x_sig     = 0;
        we_y_sig     = 0;
        we_sp_sig    = 0;
        we_pc_sig    = 0;
        we_ps_sig    = 0;
        cpu_data_in  = 8'd0;
        pc_in_reg    = PC;
        flags_in_sig = PS;
        
        // --- Seleção de alu_reg1 ---
        if (instr_type_sig == I_INC) begin
            alu_reg1 = operand_val;
        end 
        else if (instr_type_sig == I_INX) begin
            if (reg_dest_sig == DEST_Y) 
                alu_reg1 = Y; 
            else 
                alu_reg1 = X; 
        end 
        else if (instr_type_sig == I_TX || instr_type_sig == I_CPX) begin
            alu_reg1 = X;
        end
        else if (instr_type_sig == I_TY || instr_type_sig == I_CPY) begin
            alu_reg1 = Y;
        end
        else if (instr_type_sig == I_TS) begin
            alu_reg1 = SP;
        end
        else if (instr_type_sig == I_TA) begin
            alu_reg1 = A;
        end
        else begin
            alu_reg1 = A;
        end
        
        // --- Seleção de alu_reg2 ---
        if (instr_type_sig == I_TA) begin
            alu_reg2 = A;
        end else if (instr_type_sig == I_TX) begin
            alu_reg2 = X;
        end else if (instr_type_sig == I_TY) begin
            alu_reg2 = Y;
        end else if (instr_type_sig == I_TS) begin
            alu_reg2 = SP;
        end else begin
            alu_reg2 = (addr_mode_sig == IMM) ? operand_lo : operand_val;
        end
        
        // --- Carry in para ALU ---
        if (instr_type_sig == I_CMP || instr_type_sig == I_CPX || instr_type_sig == I_CPY) begin
            alu_cin = 1'b1;
        end else begin
            alu_cin = PS[0];
        end

        next_stage    = current_stage;
        next_sub      = current_sub;
        next_ind_sub  = current_ind_sub;

        case (current_stage)
            // --- FETCH ---
            FETCH: begin
                case (current_sub)
                    SUB_SET_ADDR: begin 
                        ram_address = PC; 
                        r_ram       = 1; 
                        next_sub    = SUB_WAIT; 
                    end
                    SUB_WAIT: begin 
                        ram_address = PC; 
                        r_ram       = 1; 
                        next_sub    = SUB_CAPTURE; 
                    end
                    SUB_CAPTURE: begin 
                        next_stage = DECODE; 
                        next_sub   = SUB_SET_ADDR; 
                    end
                    default: next_sub = SUB_SET_ADDR;
                endcase
            end

            // --- DECODE ---
            DECODE: begin
                if (instr_size_sig == 2'd1) 
                    next_stage = EXECUTE;
                else 
                    next_stage = READ;
                next_sub = SUB_SET_ADDR;
                next_ind_sub = SUB_IND_READ_LO; // Reset do sub-estágio indireto
            end

            // --- READ ---
            READ: begin
                case (current_sub)
                    SUB_SET_ADDR: begin
                        r_ram = 1;
                        
                        // Lendo bytes da instrução
                        if (operand_count < (instr_size_sig - 1)) begin
                            ram_address = temp_pc;
                            next_sub    = SUB_WAIT;
                        end 
                        // Lendo da memória (se necessário)
                        else if (mem_read_sig) begin
                            case (addr_mode_sig)
                                IMPL, IMM: begin
                                    ram_address = 16'd0;
                                    next_stage  = EXECUTE;
                                    next_sub    = SUB_SET_ADDR;
                                end
                                
                                ZP:  ram_address = {8'd0, operand_lo};
                                ABS: ram_address = {operand_hi, operand_lo};
                                ZPX: ram_address = {8'd0, (operand_lo + X)};
                                ZPY: ram_address = {8'd0, (operand_lo + Y)};
                                ABX: ram_address = {operand_hi, operand_lo} + {8'd0, X};
                                ABY: ram_address = {operand_hi, operand_lo} + {8'd0, Y};

                                INDX, INDY: begin
                                    case (current_ind_sub)
                                        SUB_IND_READ_LO: begin
                                            if (addr_mode_sig == INDX) 
                                                ram_address = {8'd0, (operand_lo + X)};
                                            else
                                                ram_address = {8'd0, operand_lo};
                                        end
                                        
                                        SUB_IND_READ_HI: begin
                                            if (addr_mode_sig == INDX)
                                                ram_address = {8'd0, (operand_lo + X + 8'd1)};
                                            else
                                                ram_address = {8'd0, (operand_lo + 8'd1)};
                                        end
                                        
                                        SUB_IND_READ_DATA: begin
                                            ram_address = effective_addr;
                                        end
                                        
                                        SUB_IND_COMPLETE: begin
                                            ram_address = effective_addr;
                                            next_stage = EXECUTE;
                                            next_sub = SUB_SET_ADDR;
                                        end
                                        
                                        default: ram_address = 16'd0;
                                    endcase
                                end
                                
                                default: ram_address = 16'd0;
                            endcase
                            
                            // Se não for completo ou imediato/implícito, vai para wait
                            if (addr_mode_sig != IMPL && addr_mode_sig != IMM) begin
                                if ((addr_mode_sig == INDX || addr_mode_sig == INDY) && 
                                     current_ind_sub == SUB_IND_COMPLETE) begin
                                     // Já tratado acima no case
                                end else begin
                                     next_sub = SUB_WAIT;
                                end
                            end
                        end
                        else begin
                            next_stage = EXECUTE;
                            next_sub   = SUB_SET_ADDR;
                        end
                    end

                    SUB_WAIT: begin
                        r_ram = 1;
                        
                        if (operand_count < (instr_size_sig - 1)) begin
                            ram_address = temp_pc;
                        end 
                        else if (mem_read_sig) begin
                            case (addr_mode_sig)
                                ZP:  ram_address = {8'd0, operand_lo};
                                ABS: ram_address = {operand_hi, operand_lo};
                                ZPX: ram_address = {8'd0, (operand_lo + X)};
                                ZPY: ram_address = {8'd0, (operand_lo + Y)};
                                ABX: ram_address = {operand_hi, operand_lo} + {8'd0, X};
                                ABY: ram_address = {operand_hi, operand_lo} + {8'd0, Y};

                                INDX, INDY: begin
                                    case (current_ind_sub)
                                        SUB_IND_READ_LO: begin
                                            if (addr_mode_sig == INDX) 
                                                ram_address = {8'd0, (operand_lo + X)};
                                            else
                                                ram_address = {8'd0, operand_lo};
                                        end
                                        
                                        SUB_IND_READ_HI: begin
                                            if (addr_mode_sig == INDX)
                                                ram_address = {8'd0, (operand_lo + X + 8'd1)};
                                            else
                                                ram_address = {8'd0, (operand_lo + 8'd1)};
                                        end
                                        
                                        SUB_IND_READ_DATA: begin
                                            ram_address = effective_addr;
                                        end
                                        
                                        SUB_IND_COMPLETE: begin
                                            ram_address = effective_addr;
                                        end
                                        
                                        default: ram_address = 16'd0;
                                    endcase
                                end
                                
                                default: ram_address = 16'd0;
                            endcase
                        end
                        
                        next_sub = SUB_CAPTURE;
                    end

                    SUB_CAPTURE: begin
                        if (operand_count < (instr_size_sig - 1)) begin
                            // Continua lendo operandos da instrução
                            next_sub = SUB_SET_ADDR;
                        end 
                        else if (mem_read_sig && 
                                 (addr_mode_sig == INDX || addr_mode_sig == INDY) &&
                                 current_ind_sub != SUB_IND_COMPLETE) begin
                            // Continua no modo indireto (precisa de mais ciclos)
                            next_sub = SUB_SET_ADDR;

                            // CORREÇÃO: Lógica de transição next_ind_sub adicionada aqui
                            case (current_ind_sub)
                                SUB_IND_READ_LO:   next_ind_sub = SUB_IND_READ_HI;
                                SUB_IND_READ_HI:   next_ind_sub = SUB_IND_READ_DATA;
                                SUB_IND_READ_DATA: next_ind_sub = SUB_IND_COMPLETE;
                                default:           next_ind_sub = current_ind_sub;
                            endcase
                        end
                        else if (mem_read_sig && operand_count == (instr_size_sig - 1)) begin
                            // Terminou de ler tudo (modos normais)
                            next_sub = SUB_SET_ADDR;
                        end
                        else begin
                            // Vai para EXECUTE
                            next_stage = EXECUTE;
                            next_sub   = SUB_SET_ADDR;
                        end
                    end
                    
                    default: next_sub = SUB_SET_ADDR;
                endcase
            end

            // --- EXECUTE ---
            EXECUTE: begin
                next_stage = WRITEBACK;
            end

            // --- WRITEBACK ---
            WRITEBACK: begin
                next_stage = FETCH;
                next_sub   = SUB_SET_ADDR;
                
                // Escrita em registradores
                we_a_sig  = (reg_dest_sig == DEST_A)  && (!mem_write_sig);
                we_x_sig  = (reg_dest_sig == DEST_X)  && (!mem_write_sig);
                we_y_sig  = (reg_dest_sig == DEST_Y)  && (!mem_write_sig);
                we_sp_sig = (reg_dest_sig == DEST_SP) && (!mem_write_sig);
                
                // Atualização de flags
                we_ps_sig = (reg_dest_sig != DEST_NONE) && 
                           (instr_type_sig != I_JMP) && 
                           (!mem_write_sig);

                // Seleção de flags
                if (instr_type_sig == I_SET_CARRY) begin
                    flags_in_sig    = PS;
                    flags_in_sig[0] = 1'b1;
                end else if (instr_type_sig == I_CLR_CARRY) begin
                    flags_in_sig    = PS;
                    flags_in_sig[0] = 1'b0;
                end else if (instr_type_sig == I_SET_IRQ) begin
                    flags_in_sig    = PS;
                    flags_in_sig[2] = 1'b1;
                end else if (instr_type_sig == I_CLR_IRQ) begin
                    flags_in_sig    = PS;
                    flags_in_sig[2] = 1'b0;
                end else if (instr_type_sig == I_SET_CLD) begin
                    flags_in_sig    = PS;
                    flags_in_sig[3] = 1'b0;
                end else if (instr_type_sig == I_CLR_CLD) begin
                    flags_in_sig    = PS;
                    flags_in_sig[3] = 1'b1;
                end else if (instr_type_sig == I_CLR_CLV) begin
                    flags_in_sig    = PS;
                    flags_in_sig[6] = 1'b0;
                end else if (use_alu_sig) begin
                    flags_in_sig[0] = alu_flags[0];
                    flags_in_sig[1] = alu_flags[1];
                    flags_in_sig[6] = alu_flags[2];
                    flags_in_sig[7] = alu_flags[3];
                    flags_in_sig[2] = PS[2];
                    flags_in_sig[3] = PS[3];
                    flags_in_sig[4] = PS[4];
                    flags_in_sig[5] = 1'b1;
                end else begin
                    flags_in_sig = PS;
                end

                // Escrita na memória
                if (mem_write_sig) begin
                    // Dados a escrever
                    if (instr_type_sig == I_STA) begin 
                        case (reg_dest_sig)
                            DEST_A:  ram_data_in = A;
                            DEST_X:  ram_data_in = X;
                            DEST_Y:  ram_data_in = Y;
                            DEST_SP: ram_data_in = SP;
                            default: ram_data_in = A;
                        endcase
                    end
                    else if (reg_dest_sig == DEST_MEM) begin
                        ram_data_in = alu_result;
                    end
                    
                    // Endereço e controle
                    if (addr_mode_sig != INDX && addr_mode_sig != INDY) begin
                        w_ram = 1;
                        case (addr_mode_sig)
                            ZP:  ram_address = {8'd0, operand_lo};
                            ABS: ram_address = {operand_hi, operand_lo};
                            ZPX: ram_address = {8'd0, (operand_lo + X)};
                            ZPY: ram_address = {8'd0, (operand_lo + Y)};
                            ABX: ram_address = {operand_hi, operand_lo} + {8'd0, X};
                            ABY: ram_address = {operand_hi, operand_lo} + {8'd0, Y};
                            default: ram_address = 16'd0;
                        endcase
                    end
                    else begin
                        // Endereçamento indireto na escrita
                        case (current_ind_sub)
                            SUB_IND_READ_LO: begin
                                r_ram = 1;
                                w_ram = 0;
                                if (addr_mode_sig == INDX) 
                                    ram_address = {8'd0, (operand_lo + X)};
                                else
                                    ram_address = {8'd0, operand_lo};
                                next_ind_sub = SUB_IND_READ_HI;
                                next_stage   = WRITEBACK;
                                next_sub     = SUB_SET_ADDR;
                            end
                            
                            SUB_IND_READ_HI: begin
                                r_ram = 1;
                                w_ram = 0;
                                if (addr_mode_sig == INDX)
                                    ram_address = {8'd0, (operand_lo + X + 8'd1)};
                                else
                                    ram_address = {8'd0, (operand_lo + 8'd1)};
                                next_ind_sub = SUB_IND_READ_DATA;
                                next_stage   = WRITEBACK;
                                next_sub     = SUB_WAIT;
                            end
                            
                            SUB_IND_READ_DATA: begin
                                r_ram = 0;
                                w_ram = 1;
                                ram_address = effective_addr;
                                next_ind_sub = SUB_IND_READ_LO;
                                next_stage   = FETCH;
                                next_sub     = SUB_SET_ADDR;
                            end
                            
                            default: begin
                                ram_address = 16'd0;
                                w_ram = 0;
                            end
                        endcase
                    end
                end

                // Dado de entrada para registradores
                if (reg_dest_sig == DEST_A || reg_dest_sig == DEST_X || 
                    reg_dest_sig == DEST_Y || reg_dest_sig == DEST_SP) begin
                    if (instr_type_sig == I_LDA) begin
                        cpu_data_in = (addr_mode_sig == IMM) ? operand_lo : operand_val;
                    end else if (use_alu_sig) begin
                        cpu_data_in = alu_result;
                    end
                end

                // Atualização do PC
                we_pc_sig = 1'b1;
                
                if (instr_type_sig == I_JMP) 
                    pc_in_reg = {operand_hi, operand_lo};
                else if (instr_type_sig == I_BEQ && PS[1]) 
                    pc_in_reg = PC + offset16;
                else if (instr_type_sig == I_BNE && !PS[1]) 
                    pc_in_reg = PC + offset16;
                else if (instr_type_sig == I_BCS && PS[0]) 
                    pc_in_reg = PC + offset16;
                else if (instr_type_sig == I_BCC && !PS[0]) 
                    pc_in_reg = PC + offset16;
                else if (instr_type_sig == I_BMI && PS[7]) 
                    pc_in_reg = PC + offset16;
                else if (instr_type_sig == I_BPL && !PS[7]) 
                    pc_in_reg = PC + offset16;
                else if (instr_type_sig == I_BVC && !PS[6]) 
                    pc_in_reg = PC + offset16;
                else if (instr_type_sig == I_BVS && PS[6]) 
                    pc_in_reg = PC + offset16;
                else begin
                    case (instr_size_sig)
                        2'd1:    pc_in_reg = PC + 16'd1;
                        2'd2:    pc_in_reg = PC + 16'd2;
                        default: pc_in_reg = PC + 16'd3;
                    endcase
                end
            end
            
            default: next_stage = FETCH;
        endcase
    end

endmodule
