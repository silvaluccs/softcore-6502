`include "alu_defines.vh"

module decoder (
	 input  wire [7:0] opcode,
	 output reg  [4:0] alu_op,
	 output reg        use_alu,
	 output reg        mem_read,
	 output reg        mem_write,
	 output reg  [1:0] addr_mode,    // 00=implied, 01=imm, 02=zp, 03=abs
	 output reg  [1:0] instr_size,   // 1,2,3 bytes
	 output reg  [7:0] instr_type,   // Tipo de instrução
	 output reg  [2:0] reg_dest      // NOVO: Registrador de destino
);

	 // Addressing modes
	 localparam IMPL = 2'd0;
	 localparam IMM  = 2'd1;
	 localparam ZP   = 2'd2;
	 localparam ABS  = 2'd3;

	 // Instruction types
	// Instruction types (8 bits de largura)
	localparam I_LDA = 8'd0, I_STA = 8'd1, I_ADC = 8'd2, I_SBC = 8'd3,
				  I_AND = 8'd4, I_JMP = 8'd5, I_INX = 8'd6, I_ORA = 8'd7,  
				  I_XOR = 8'd8, I_INC = 8'd9, I_ASL = 8'd10, I_LSR = 8'd11,
				  I_ROL = 8'd12, I_ROR = 8'd13, I_BEQ = 8'd14, I_BNE = 8'd15,
				  I_BCS = 8'd16, I_BCC=8'd17, I_BMI = 8'd18, I_BPL=8'd19, I_BVC=8'd20,
				  I_BVS=8'd21, I_TA=8'd22, I_TX=8'd23, I_TY=8'd24, I_TS=8'd25; 

	 // Register Destinations (reg_dest)
	 localparam DEST_NONE = 3'd0; // Nenhuma escrita em Registrador (Ex: STA, JMP)
	 localparam DEST_A    = 3'd1; // Acumulador (A)
	 localparam DEST_X    = 3'd2; // Index X (Ex: INX)
	 localparam DEST_Y    = 3'd3; // Index Y
	 localparam DEST_MEM  = 3'd4; // Memória (Ex: INC/DEC que volta pra RAM)
	 localparam DEST_SP   = 3'd5;


	 always @(*) begin
		  // Defaults
		  alu_op     = `ALU_OP_PASS;
		  use_alu    = 0;
		  mem_read   = 0;
		  mem_write  = 0;
		  instr_size = 2'd1;
		  addr_mode  = IMPL;
		  instr_type = I_LDA;
		  reg_dest   = DEST_NONE; // Novo default

		  case (opcode)
			 
				// -------- Shifts/Rotates (A) --------
				8'h6A: begin // ROR A
					 instr_type = I_ROR; 
					 reg_dest   = DEST_A; // Salva em A
					 use_alu    = 1;
					 alu_op     = `ALU_OP_ROR;
				end
				8'h2A: begin // ROL A
					 instr_type = I_ROL; 
					 reg_dest   = DEST_A; // Salva em A
					 use_alu    = 1;
					 alu_op     = `ALU_OP_ROL;
				end
				8'h4A: begin // LSR A
					 instr_type = I_LSR; 
					 reg_dest   = DEST_A; // Salva em A
					 use_alu    = 1;
					 alu_op     = `ALU_OP_LSR;
				end
				8'h0A: begin // ASL A
					 instr_type = I_ASL;
					 reg_dest   = DEST_A; // Salva em A
					 use_alu    = 1;
					 alu_op     = `ALU_OP_ASL;
				end

				// -------- LDA --------
				8'hA9: begin // immediate
					 instr_type = I_LDA; addr_mode  = IMM; instr_size = 2;
					 mem_read   = 0; use_alu    = 0; 
					 reg_dest   = DEST_A; // Salva em A
				end
				8'hA5: begin // zeropage
					 instr_type = I_LDA; addr_mode  = ZP; instr_size = 2;
					 mem_read   = 1; use_alu    = 0;
					 reg_dest   = DEST_A; // Salva em A
				end
				
				 // -------- LDX --------
				8'hA2: begin // immediate
					 instr_type = I_LDA; addr_mode  = IMM; instr_size = 2;
					 mem_read   = 0; use_alu    = 0; 
					 reg_dest   = DEST_X; // Salva em X
				end
				8'hA6: begin // zeropage
					 instr_type = I_LDA; addr_mode  = ZP; instr_size = 2;
					 mem_read   = 1; use_alu    = 0;
					 reg_dest   = DEST_X; // Salva em X
				end
				
								 // -------- LDY --------
				8'hA0: begin // immediate
					 instr_type = I_LDA; addr_mode  = IMM; instr_size = 2;
					 mem_read   = 0; use_alu    = 0; 
					 reg_dest   = DEST_Y; // Salva em Y
				end
				
				8'hA4: begin // zeropage
					 instr_type = I_LDA; addr_mode  = ZP; instr_size = 2;
					 mem_read   = 1; use_alu    = 0;
					 reg_dest   = DEST_Y; // Salva em Y
				end

				// -------- STA --------
				8'h85: begin // zeropage
					 instr_type = I_STA; addr_mode  = ZP; instr_size = 2;
					 mem_write  = 1; reg_dest   = DEST_A; // Não salva em registrador
				end
				
				 // -------- STX --------
				8'h86: begin // zeropage
					 instr_type = I_STA; addr_mode  = ZP; instr_size = 2;
					 mem_write  = 1; reg_dest   = DEST_X; // Não salva em registrador
				end
				
								 // -------- STY --------
				8'h84: begin // zeropage
					 instr_type = I_STA; addr_mode  = ZP; instr_size = 2;
					 mem_write  = 1; reg_dest   = DEST_Y; // Não salva em registrador
				end

				// -------- ADC, SBC, AND, OR, XOR (Sempre salva em A) --------
				8'h69: begin // ADC Imm
					 instr_type = I_ADC; addr_mode  = IMM; instr_size = 2;
					 use_alu    = 1; alu_op     = `ALU_OP_ADD; reg_dest  = DEST_A;
				end
				8'hE9: begin // SBC Imm
					 instr_type = I_SBC; addr_mode  = IMM; instr_size = 2;
					 use_alu    = 1; alu_op     = `ALU_OP_SUB; reg_dest  = DEST_A;
				end
				8'h29: begin // AND Imm
					 instr_type = I_AND; addr_mode  = IMM; instr_size = 2;
					 use_alu    = 1; alu_op     = `ALU_OP_AND; reg_dest  = DEST_A;
				end
				8'h49: begin // XOR Imm
					 instr_type = I_XOR; addr_mode  = IMM; instr_size = 2;
					 use_alu    = 1; alu_op     = `ALU_OP_XOR; reg_dest  = DEST_A;
				end
				8'h45: begin // XOR ZP
					 instr_type = I_XOR; addr_mode  = ZP; instr_size = 2; mem_read   = 1;
					 use_alu    = 1; alu_op     = `ALU_OP_XOR; reg_dest  = DEST_A;
				end
				8'h09: begin // ORA Imm
					 instr_type = I_ORA; addr_mode  = IMM; instr_size = 2;
					 use_alu    = 1; alu_op     = `ALU_OP_OR; reg_dest  = DEST_A;
				end
				8'h05: begin // ORA ZP
					 instr_type = I_ORA; addr_mode  = ZP; instr_size = 2; mem_read   = 1;
					 use_alu    = 1; alu_op     = `ALU_OP_OR; reg_dest  = DEST_A;
				end

				// -------- INC / DEC (Salva na Memória) --------
				8'hE6: begin // INC ZP
					 instr_type = I_INC; addr_mode  = ZP; instr_size = 2;
					 mem_read   = 1; mem_write  = 1; use_alu    = 1;
					 alu_op     = `ALU_OP_INC; reg_dest  = DEST_MEM; // Salva na Memória
				end
				8'hC6: begin // DEC ZP
					 instr_type = I_INC; addr_mode  = ZP; instr_size = 2; 
					 mem_read   = 1; mem_write  = 1; use_alu    = 1;
					 alu_op     = `ALU_OP_DEC; reg_dest  = DEST_MEM; // Salva na Memória
				end

				// -------- JMP --------
				8'h4C: begin
					 instr_type = I_JMP; addr_mode  = ABS; instr_size = 3;
					 reg_dest   = DEST_NONE;
				end
				
				// -------- BEQ --------
				8'hF0: begin
					 instr_type = I_BEQ; addr_mode  = IMM; instr_size = 2;
					 reg_dest   = DEST_NONE;
				end
				
				// -------- BNE --------
				8'hD0: begin
					 instr_type = I_BNE; addr_mode  = IMM; instr_size = 2;
					 reg_dest   = DEST_NONE;
				end
				
				// -------- BCS --------
				8'hB0: begin
					 instr_type = I_BCS; addr_mode  = IMM; instr_size = 2;
					 reg_dest   = DEST_NONE;
				end
				
				// -------- BCC --------
				8'h90: begin
					 instr_type = I_BCC; addr_mode  = IMM; instr_size = 2;
					 reg_dest   = DEST_NONE;
				end
				
				// -------- BMI --------
				8'h30: begin
					 instr_type = I_BMI; addr_mode  = IMM; instr_size = 2;
					 reg_dest   = DEST_NONE;
				end
				
				// -------- BPL --------
				8'h10: begin
					 instr_type = I_BPL; addr_mode  = IMM; instr_size = 2;
					 reg_dest   = DEST_NONE;
				end
				
				// -------- BVC --------
				8'h50: begin
					 instr_type = I_BVC; addr_mode  = IMM; instr_size = 2;
					 reg_dest   = DEST_NONE;
				end				
				
				
				// -------- BVS --------
				8'h70: begin
					 instr_type = I_BVS; addr_mode  = IMM; instr_size = 2;
					 reg_dest   = DEST_NONE;
				end

				// -------- INX --------
				8'hE8: begin
					 instr_type = I_INX; addr_mode  = IMPL; instr_size = 1;
					 use_alu    = 1; alu_op     = `ALU_OP_INC;
					 reg_dest   = DEST_X; // Salva em X
				end
				
				// -------- DEX --------
				8'hCA: begin
					 instr_type = I_INX; addr_mode  = IMPL; instr_size = 1;
					 use_alu    = 1; alu_op     = `ALU_OP_DEC;
					 reg_dest   = DEST_X; // Salva em X
				end

				// -------- DEY --------
				8'h88: begin
					 instr_type = I_INX; addr_mode  = IMPL; instr_size = 1;
					 use_alu    = 1; alu_op     = `ALU_OP_DEC;
					 reg_dest   = DEST_Y; // Salva em X
				end
				
				// -------- INY --------
				8'hC8: begin
					 instr_type = I_INX; addr_mode  = IMPL; instr_size = 1;
					 use_alu    = 1; alu_op     = `ALU_OP_INC;
					 reg_dest   = DEST_Y; // Salva em Y
				end

				// -------- TAY --------
				8'hA8: begin
					 instr_type = I_TA; addr_mode  = IMPL; instr_size = 1;
					 use_alu    = 1; alu_op     = `ALU_OP_PASS;
					 reg_dest   = DEST_Y; 
				end		
				
				// -------- TAX --------
				8'hAA: begin
					 instr_type = I_TA; addr_mode  = IMPL; instr_size = 1;
					 use_alu    = 1; alu_op     = `ALU_OP_PASS;
					 reg_dest   = DEST_X; 
				end				
				
				// -------- TSX --------
				8'hBA: begin
					 instr_type = I_TS; addr_mode  = IMPL; instr_size = 1;
					 use_alu    = 1; alu_op     = `ALU_OP_PASS;
					 reg_dest   = DEST_X; 
				end		
				
				// -------- TXS --------
				8'h9A: begin
					 instr_type = I_TX; addr_mode  = IMPL; instr_size = 1;
					 use_alu    = 1; alu_op     = `ALU_OP_PASS;
					 reg_dest   = DEST_SP; 
				end	
				
				// -------- TXA --------
				8'h8A: begin
					 instr_type = I_TX; addr_mode  = IMPL; instr_size = 1;
					 use_alu    = 1; alu_op     = `ALU_OP_PASS;
					 reg_dest   = DEST_A; 
				end
				
				// -------- TYA --------
				8'h98: begin
					 instr_type = I_TY; addr_mode  = IMPL; instr_size = 1;
					 use_alu    = 1; alu_op     = `ALU_OP_PASS;
					 reg_dest   = DEST_A; 
				end

				default: begin
					 instr_size = 1;
					 reg_dest   = DEST_NONE;
				end
		  endcase
	 end

endmodule