`include "alu_defines.vh"


module decoder (
	 input  wire [7:0] opcode,
	 output reg  [4:0] alu_op,
	 output reg        use_alu,
	 output reg        mem_read,
	 output reg        mem_write,
	 output reg  [3:0] addr_mode,    // 00=implied, 01=imm, 02=zp, 03=abs
	 output reg  [1:0] instr_size,   // 1,2,3 bytes
	 output reg  [7:0] instr_type,   // Tipo de instrução
	 output reg  [2:0] reg_dest      // NOVO: Registrador de destino
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
    localparam INDY = 4'd9;	 // Instruction types
    localparam IND = 4'd10;

	// Instruction types (8 bits de largura)
	localparam I_LDA = 8'd0, I_STA = 8'd1, I_ADC = 8'd2, I_SBC = 8'd3,
				  I_AND = 8'd4, I_JMP = 8'd5, I_INX = 8'd6, I_ORA = 8'd7,  
				  I_XOR = 8'd8, I_INC = 8'd9, I_ASL = 8'd10, I_LSR = 8'd11,
				  I_ROL = 8'd12, I_ROR = 8'd13, I_BEQ = 8'd14, I_BNE = 8'd15,
				  I_BCS = 8'd16, I_BCC=8'd17, I_BMI = 8'd18, I_BPL=8'd19, I_BVC=8'd20,
				  I_BVS=8'd21, I_TA=8'd22, I_TX=8'd23, I_TY=8'd24, I_TS=8'd25,
          I_CMP=8'd26, I_CPX=8'd27, I_CPY=8'd28, I_SET_CARRY=8'd29, I_CLR_CARRY=8'd30,
          I_SET_IRQ=8'd31, I_CLR_IRQ=8'd32, I_SET_CLD=8'd33, I_CLR_CLD=8'd34, I_CLR_CLV=8'd35,
          I_BIT=8'd36;

	 // Register Destinations (reg_dest)
	 localparam DEST_NONE = 3'd0; // Nenhuma escrita em Registrador (Ex: STA, JMP)
	 localparam DEST_A    = 3'd1; // Acumulador (A)
	 localparam DEST_X    = 3'd2; // Index X (Ex: INX)
	 localparam DEST_Y    = 3'd3; // Index Y
	 localparam DEST_MEM  = 3'd4; // Memória (Ex: INC/DEC que volta pra RAM)
	 localparam DEST_SP   = 3'd5;
   localparam DEST_PS   = 3'd6;



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

        8'h24: begin // BIT ZP
           instr_type = I_BIT; addr_mode  = ZP; instr_size = 2;
           mem_read   = 1; use_alu    = 1; 
           alu_op     = `ALU_OP_AND; reg_dest  = DEST_PS;
        end

        8'h2C: begin // BIT ABS
           instr_type = I_BIT; addr_mode  = ABS; instr_size = 3;
           mem_read   = 1; use_alu    = 1; 
           alu_op     = `ALU_OP_AND; reg_dest  = DEST_PS;
        end

        8'hB8: begin // CLV
           instr_type = I_CLR_CLV; addr_mode  = IMPL; instr_size = 1;
           reg_dest   = DEST_PS;
        end

        // Set/Clear Decimal Flag
        8'hD8: begin // CLD
           instr_type = I_CLR_CLD; addr_mode  = IMPL; instr_size = 1;
           reg_dest   = DEST_PS;
        end 

        8'hF8: begin // SED
           instr_type = I_SET_CLD; addr_mode  = IMPL; instr_size = 1;
           reg_dest   = DEST_PS;
        end

        8'h58: begin // CLI
           instr_type = I_CLR_IRQ; addr_mode  = IMPL; instr_size = 1;
           reg_dest   = DEST_PS;
        end

        8'h78: begin // SEI
           instr_type = I_SET_IRQ; addr_mode  = IMPL; instr_size = 1;
           reg_dest   = DEST_PS;
        end

        // Set/Clear Carry Flag
        8'h38: begin // SEC
           instr_type = I_SET_CARRY; addr_mode  = IMPL; instr_size = 1;
           reg_dest   = DEST_PS;
        end

        8'h18: begin // CLC
           instr_type = I_CLR_CARRY; addr_mode  = IMPL; instr_size = 1;
           reg_dest   = DEST_PS;
        end			 

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

        8'hB5: begin // zeropage,X
           instr_type = I_LDA; addr_mode  = ZPX; instr_size = 2;
           mem_read   = 1; use_alu    = 0;
           reg_dest   = DEST_A; // Salva em A
        end


        8'hAD: begin // absolute
           instr_type = I_LDA; addr_mode  = ABS; instr_size = 3;
           mem_read   = 1; use_alu    = 0;
           reg_dest   = DEST_A; // Salva em A
          
        end

        8'hBD: begin // absolute,X
           instr_type = I_LDA; addr_mode  = ABX; instr_size = 3;
           mem_read   = 1; use_alu    = 0;
           reg_dest   = DEST_A; // Salva em A
        end

        8'hB9: begin // absolute,Y
           instr_type = I_LDA; addr_mode  = ABY; instr_size = 3;
           mem_read   = 1; use_alu    = 0;
           reg_dest   = DEST_A; // Salva em A
        end

        8'hA1: begin // (indirect,X)
           instr_type = I_LDA; addr_mode  = INDX; instr_size = 2;
           mem_read   = 1; use_alu    = 0;
           reg_dest   = DEST_A; // Salva em A
        end

        8'hB1: begin // (indirect),Y
           instr_type = I_LDA; addr_mode  = INDY; instr_size = 2;
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
        8'hB6: begin // zeropage,Y
           instr_type = I_LDA; addr_mode  = ZPY; instr_size = 2;
           mem_read   = 1; use_alu    = 0;
           reg_dest   = DEST_X; // Salva em X'
        end

        8'hAE: begin // absolute
           instr_type = I_LDA; addr_mode  = ABS; instr_size = 3;
           mem_read   = 1; use_alu    = 0;
           reg_dest   = DEST_X; // Salva em X'
        end

        8'hBE: begin // absolute,Y
           instr_type = I_LDA; addr_mode  = ABY; instr_size = 3;
           mem_read   = 1; use_alu    = 0;
           reg_dest   = DEST_X; // Salva em X'
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

        8'hB4: begin // zeropage,X
           instr_type = I_LDA; addr_mode  = ZPX; instr_size = 2;
           mem_read   = 1; use_alu    = 0;
           reg_dest   = DEST_Y; // Salva em Y
        end

        8'hAC: begin // absolute
           instr_type = I_LDA; addr_mode  = ABS; instr_size = 3;
           mem_read   = 1; use_alu    = 0;
           reg_dest   = DEST_Y; // Salva em Y
        end

        8'hBC: begin // absolute,X
           instr_type = I_LDA; addr_mode  = ABX; instr_size = 3;
           mem_read   = 1; use_alu    = 0;
           reg_dest   = DEST_Y; // Salva em Y
        end

				// -------- STA --------
				8'h85: begin // zeropage
					 instr_type = I_STA; addr_mode  = ZP; instr_size = 2;
					 mem_write  = 1; reg_dest   = DEST_A; // Não salva em registrador
				end

        8'h95: begin // zeropage,X
           instr_type = I_STA; addr_mode  = ZPX; instr_size = 2;
           mem_write  = 1; reg_dest   = DEST_A; // Não salva em registrador
        end

        8'h8D: begin // absolute
           instr_type = I_STA; addr_mode  = ABS; instr_size = 3;
           mem_write  = 1; reg_dest   = DEST_A; // Não salva em registrador
        end

        8'h9D: begin // absolute,X
           instr_type = I_STA; addr_mode  = ABX; instr_size = 3;
           mem_write  = 1; reg_dest   = DEST_A; // Não salva em registrador
        end

        8'h99: begin // absolute,Y
           instr_type = I_STA; addr_mode  = ABY; instr_size = 3;
           mem_write  = 1; reg_dest   = DEST_A; // Não salva em registrador
        end

        8'h81: begin // (indirect,X)
           instr_type = I_STA; addr_mode  = INDX; instr_size = 2;
           mem_write  = 1; reg_dest   = DEST_A; // Não salva em registrador

        end

        8'h91: begin // (indirect),Y
           instr_type = I_STA; addr_mode  = INDY; instr_size = 2;
           mem_write  = 1; reg_dest   = DEST_A; // Não salva em registrador
        end

				
				 // -------- STX --------
				8'h86: begin // zeropage
					 instr_type = I_STA; addr_mode  = ZP; instr_size = 2;
					 mem_write  = 1; reg_dest   = DEST_X; // Não salva em registrador
				end

        8'h96: begin // zeropage,Y
           instr_type = I_STA; addr_mode  = ZPY; instr_size = 2;
           mem_write  = 1; reg_dest   = DEST_X; // Não salva em registrador
        end

        8'h8E: begin // absolute
           instr_type = I_STA; addr_mode  = ABS; instr_size = 3;
           mem_write  = 1; reg_dest   = DEST_X; // Não salva em registrador
        end
				
								 // -------- STY --------
				8'h84: begin // zeropage
					 instr_type = I_STA; addr_mode  = ZP; instr_size = 2;
					 mem_write  = 1; reg_dest   = DEST_Y; // Não salva em registrador
				end

        8'h94: begin // zeropage,X
           instr_type = I_STA; addr_mode  = ZPX; instr_size = 2;
           mem_write  = 1; reg_dest   = DEST_Y; // Não salva em registrador
        end
        
        8'h8C: begin // absolute
           instr_type = I_STA; addr_mode  = ABS; instr_size = 3;
           mem_write  = 1; reg_dest   = DEST_Y; // Não salva em registrador
        end

        // -------- CMP A --------
        8'hC9: begin // CMP Imm
           instr_type = I_CMP; addr_mode  = IMM; instr_size = 2;
            use_alu    = 1; alu_op     = `ALU_OP_SUB; reg_dest  = DEST_PS;
        end

        8'hC5: begin // CMP ZP
            instr_type = I_CMP; addr_mode  = ZP; instr_size = 2; mem_read   = 1;
            use_alu    = 1; alu_op     = `ALU_OP_SUB; reg_dest  = DEST_PS;
        end

        8'hD5: begin // CMP ZPX
            instr_type = I_CMP; addr_mode  = ZPX; instr_size = 2; mem_read   = 1;
            use_alu    = 1; alu_op     = `ALU_OP_SUB; reg_dest  = DEST_PS;
        end

        8'hCD: begin // CMP ABS
            instr_type = I_CMP; addr_mode  = ABS; instr_size = 3; mem_read   = 1;
            use_alu    = 1; alu_op     = `ALU_OP_SUB; reg_dest  = DEST_PS;
        end

        8'hDD: begin // CMP ABX
            instr_type = I_CMP; addr_mode  = ABX; instr_size = 3; mem_read   = 1;
            use_alu    = 1; alu_op     = `ALU_OP_SUB; reg_dest  = DEST_PS;
        end

        8'hD9: begin // CMP ABY
            instr_type = I_CMP; addr_mode  = ABY; instr_size = 3; mem_read   = 1;
            use_alu    = 1; alu_op     = `ALU_OP_SUB; reg_dest  = DEST_PS;
        end

        8'hC1: begin // CMP (INDX)
            instr_type = I_CMP; addr_mode  = INDX; instr_size = 2; mem_read   = 1;
            use_alu    = 1; alu_op     = `ALU_OP_SUB; reg_dest  = DEST_PS;
        end

        8'hD1: begin // CMP (INDY)
            instr_type = I_CMP; addr_mode  = INDY; instr_size = 2; mem_read   = 1;
            use_alu    = 1; alu_op     = `ALU_OP_SUB; reg_dest  = DEST_PS;
        end

        // -------- CPX --------
        8'hE0: begin // CPX Imm
           instr_type = I_CPX; addr_mode  = IMM; instr_size = 2;
            use_alu    = 1; alu_op     = `ALU_OP_SUB; reg_dest  = DEST_PS;
        end

        8'hE4: begin // CPX ZP
            instr_type = I_CPX; addr_mode  = ZP; instr_size = 2; mem_read   = 1;
            use_alu    = 1; alu_op     = `ALU_OP_SUB; reg_dest  = DEST_PS;
        end

        8'hEC: begin // CPX ABS
            instr_type = I_CPX; addr_mode  = ABS; instr_size = 3; mem_read   = 1;
            use_alu    = 1; alu_op     = `ALU_OP_SUB; reg_dest  = DEST_PS;
        end

        // -------- CPY --------
        8'hC0: begin // CPY Imm
           instr_type = I_CPY; addr_mode  = IMM; instr_size = 2;
            use_alu    = 1; alu_op     = `ALU_OP_SUB; reg_dest  = DEST_PS;
        end 

        8'hC4: begin // CPY ZP
            instr_type = I_CPY; addr_mode  = ZP; instr_size = 2; mem_read   = 1;
            use_alu    = 1; alu_op     = `ALU_OP_SUB; reg_dest  = DEST_PS;
        end

        8'hCC: begin // CPY ABS
            instr_type = I_CPY; addr_mode  = ABS; instr_size = 3; mem_read   = 1;
            use_alu    = 1; alu_op     = `ALU_OP_SUB; reg_dest  = DEST_PS;
        end

				// -------- ADC, SBC, AND, OR, XOR (Sempre salva em A) --------
				8'h69: begin // ADC Imm
					 instr_type = I_ADC; addr_mode  = IMM; instr_size = 2;
					 use_alu    = 1; alu_op     = `ALU_OP_ADD; reg_dest  = DEST_A;
				end

        8'h65: begin // ADC ZP
           instr_type = I_ADC; addr_mode  = ZP; instr_size = 2; mem_read   = 1;
           use_alu    = 1; alu_op     = `ALU_OP_ADD; reg_dest  = DEST_A;
        end

        8'h75: begin // ADC ZPX
           instr_type = I_ADC; addr_mode  = ZPX; instr_size = 2; mem_read   = 1;
           use_alu    = 1; alu_op     = `ALU_OP_ADD; reg_dest  = DEST_A;
        end

        8'h6D: begin // ADC ABS
           instr_type = I_ADC; addr_mode  = ABS; instr_size = 3; mem_read   = 1;
           use_alu    = 1; alu_op     = `ALU_OP_ADD; reg_dest  = DEST_A;
        end

        8'h7D: begin // ADC ABX
           instr_type = I_ADC; addr_mode  = ABX; instr_size = 3; mem_read   = 1;
           use_alu    = 1; alu_op     = `ALU_OP_ADD; reg_dest  = DEST_A;
        end

        8'h79: begin // ADC ABY
           instr_type = I_ADC; addr_mode  = ABY; instr_size = 3; mem_read   = 1;
           use_alu    = 1; alu_op     = `ALU_OP_ADD; reg_dest  = DEST_A;
        end

        8'h61: begin // ADC (INDX)
           instr_type = I_ADC; addr_mode  = INDX; instr_size = 2; mem_read   = 1;
           use_alu    = 1; alu_op     = `ALU_OP_ADD; reg_dest  = DEST_A;
        end

        8'h71: begin // ADC (INDY)
           instr_type = I_ADC; addr_mode  = INDY; instr_size = 2; mem_read   = 1;
           use_alu    = 1; alu_op     = `ALU_OP_ADD; reg_dest  = DEST_A;
        end

        // NOP 
        8'hEA: begin
           instr_type = I_LDA; addr_mode  = IMPL; instr_size = 1;
           mem_read   = 0; use_alu    = 0; 
           alu_op     = `ALU_OP_PASS;
           reg_dest   = DEST_NONE; // Nao faz nada
        end

				8'hE9: begin // SBC Imm
					 instr_type = I_SBC; addr_mode  = IMM; instr_size = 2;
					 use_alu    = 1; alu_op     = `ALU_OP_SUB; reg_dest  = DEST_A;
				end

				8'h0A: begin // ASL A
          instr_type = I_ASL; addr_mode  = IMPL; instr_size = 1;
          use_alu    = 1; alu_op     = `ALU_OP_ASL; reg_dest  = DEST_A;
          mem_read  = 0; mem_write  = 0;
        end

        8'h06: begin // ASL ZP
          instr_type = I_ASL; addr_mode  = ZP; instr_size = 2;
          use_alu    = 1; alu_op     = `ALU_OP_ASL; reg_dest  = DEST_MEM;
          mem_read   = 1; mem_write  = 1;
        end

        8'h16: begin // ASL ZPX
          instr_type = I_ASL; addr_mode  = ZPX; instr_size = 2;
          use_alu    = 1; alu_op     = `ALU_OP_ASL; reg_dest  = DEST_MEM;
          mem_read   = 1; mem_write  = 1;
        end

        8'h0E: begin // ASL ABS
          instr_type = I_ASL; addr_mode  = ABS; instr_size = 3;
          use_alu    = 1; alu_op     = `ALU_OP_ASL; reg_dest  = DEST_MEM;
          mem_read   = 1; mem_write  = 1;
        end

        8'h1E: begin // ASL ABX
          instr_type = I_ASL; addr_mode  = ABX; instr_size = 3;
          use_alu    = 1; alu_op     = `ALU_OP_ASL; reg_dest  = DEST_MEM;
          mem_read   = 1; mem_write  = 1;
        end

				8'h4A: begin // LSR A
          instr_type = I_LSR; addr_mode  = IMPL; instr_size = 1;
          use_alu    = 1; alu_op     = `ALU_OP_LSR; reg_dest  = DEST_A;
          mem_read  = 0; mem_write  = 0;
				end

        8'h46: begin // LSR ZP
          instr_type = I_LSR; addr_mode  = ZP; instr_size = 2;
          use_alu    = 1; alu_op     = `ALU_OP_LSR; reg_dest  = DEST_MEM;
          mem_read   = 1; mem_write  = 1;
        end

        8'h56: begin // LSR ZPX
          instr_type = I_LSR; addr_mode  = ZPX; instr_size = 2;
          use_alu    = 1; alu_op     = `ALU_OP_LSR; reg_dest  = DEST_MEM;
          mem_read   = 1; mem_write  = 1;
        end

        8'h4E: begin // LSR ABS
          instr_type = I_LSR; addr_mode  = ABS; instr_size = 3;
          use_alu    = 1; alu_op     = `ALU_OP_LSR; reg_dest  = DEST_MEM;
          mem_read   = 1; mem_write  = 1;
        end

        8'h5E: begin // LSR ABX
          instr_type = I_LSR; addr_mode  = ABX; instr_size = 3;
          use_alu    = 1; alu_op     = `ALU_OP_LSR; reg_dest  = DEST_MEM;
          mem_read   = 1; mem_write  = 1;
        end


				8'h29: begin // AND Imm
					 instr_type = I_AND; addr_mode  = IMM; instr_size = 2;
					 use_alu    = 1; alu_op     = `ALU_OP_AND; reg_dest  = DEST_A;
				end

        8'h25: begin // AND ZP
           instr_type = I_AND; addr_mode  = ZP; instr_size = 2; mem_read   = 1;
           use_alu    = 1; alu_op     = `ALU_OP_AND; reg_dest  = DEST_A;
        end

        8'h35: begin // AND ZPX
           instr_type = I_AND; addr_mode  = ZPX; instr_size = 2; mem_read   = 1;
           use_alu    = 1; alu_op     = `ALU_OP_AND; reg_dest  = DEST_A;
        end

        8'h2D: begin // AND ABS
           instr_type = I_AND; addr_mode  = ABS; instr_size = 3; mem_read   = 1;
           use_alu    = 1; alu_op     = `ALU_OP_AND; reg_dest  = DEST_A;
        end

        8'h3D: begin // AND ABX
           instr_type = I_AND; addr_mode  = ABX; instr_size = 3; mem_read   = 1;
           use_alu    = 1; alu_op     = `ALU_OP_AND; reg_dest  = DEST_A;
        end

        8'h39: begin // AND ABY
           instr_type = I_AND; addr_mode  = ABY; instr_size = 3; mem_read   = 1;
           use_alu    = 1; alu_op     = `ALU_OP_AND; reg_dest  = DEST_A;
        end

        8'h21: begin // AND (INDX)
           instr_type = I_AND; addr_mode  = INDX; instr_size = 2; mem_read   = 1;
           use_alu    = 1; alu_op     = `ALU_OP_AND; reg_dest  = DEST_A;
        end

        8'h31: begin // AND (INDY)
           instr_type = I_AND; addr_mode  = INDY; instr_size = 2; mem_read   = 1;
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

        8'h55: begin // XOR ZPX
           instr_type = I_XOR; addr_mode  = ZPX; instr_size = 2; mem_read   = 1;
           use_alu    = 1; alu_op     = `ALU_OP_XOR; reg_dest  = DEST_A;
        end

        8'h4D: begin // XOR ABS
           instr_type = I_XOR; addr_mode  = ABS; instr_size = 3; mem_read   = 1;
           use_alu    = 1; alu_op     = `ALU_OP_XOR; reg_dest  = DEST_A;
        end

        8'h5D: begin // XOR ABX
           instr_type = I_XOR; addr_mode  = ABX; instr_size = 3; mem_read   = 1;
           use_alu    = 1; alu_op     = `ALU_OP_XOR; reg_dest  = DEST_A;
        end

        8'h59: begin // XOR ABY
           instr_type = I_XOR; addr_mode  = ABY; instr_size = 3; mem_read   = 1;
           use_alu    = 1; alu_op     = `ALU_OP_XOR; reg_dest  = DEST_A;
        end

        8'h41: begin // XOR (INDX)
           instr_type = I_XOR; addr_mode  = INDX; instr_size = 2; mem_read   = 1;
           use_alu    = 1; alu_op     = `ALU_OP_XOR; reg_dest  = DEST_A;
        end

        8'h51: begin // XOR (INDY)
           instr_type = I_XOR; addr_mode  = INDY; instr_size = 2; mem_read   = 1;
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

        8'hF6: begin // INC ZPX
           instr_type = I_INC; addr_mode  = ZPX; instr_size = 2;
           mem_read   = 1; mem_write  = 1; use_alu    = 1;
           alu_op     = `ALU_OP_INC; reg_dest  = DEST_MEM; // Salva na Memória
        end

        8'hEE: begin // INC ABS
           instr_type = I_INC; addr_mode  = ABS; instr_size = 3;
           mem_read   = 1; mem_write  = 1; use_alu    = 1;
           alu_op     = `ALU_OP_INC; reg_dest  = DEST_MEM; // Salva na Memória
        end

        8'hFE: begin // INC ABX
           instr_type = I_INC; addr_mode  = ABX; instr_size = 3;
           mem_read   = 1; mem_write  = 1; use_alu    = 1;
           alu_op     = `ALU_OP_INC; reg_dest  = DEST_MEM; // Salva na Memória
        end


				8'hC6: begin // DEC ZP
					 instr_type = I_INC; addr_mode  = ZP; instr_size = 2; 
					 mem_read   = 1; mem_write  = 1; use_alu    = 1;
					 alu_op     = `ALU_OP_DEC; reg_dest  = DEST_MEM; // Salva na Memória
				end

        8'hD6: begin // DEC ZPX
           instr_type = I_INC; addr_mode  = ZPX; instr_size = 2; 
           mem_read   = 1; mem_write  = 1; use_alu    = 1;
           alu_op     = `ALU_OP_DEC; reg_dest  = DEST_MEM; // Salva na Memória
        end

        8'hCE: begin // DEC ABS
           instr_type = I_INC; addr_mode  = ABS; instr_size = 3; 
           mem_read   = 1; mem_write  = 1; use_alu    = 1;
           alu_op     = `ALU_OP_DEC; reg_dest  = DEST_MEM; // Salva na Memória
        end

        8'hDE: begin // DEC ABX
           instr_type = I_INC; addr_mode  = ABX; instr_size = 3; 
           mem_read   = 1; mem_write  = 1; use_alu    = 1;
           alu_op     = `ALU_OP_DEC; reg_dest  = DEST_MEM; // Salva na Memória
        end

				// -------- JMP --------
				8'h4C: begin
					 instr_type = I_JMP; addr_mode  = ABS; instr_size = 3;
					 reg_dest   = DEST_NONE; use_alu  = 0; 
				end

        8'h6C: begin // Indirect JMP
           instr_type = I_JMP; addr_mode  = IND; instr_size = 3;
           reg_dest   = DEST_NONE; mem_read  = 1; use_alu   = 0;
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
