`include "alu_defines.vh" 
module alu(

    input wire [4:0] alu_op,
    
    input wire [7:0] reg1,
    input wire [7:0] reg2,
    
    input wire carry_in,
    
    output reg [7:0] result,
    output wire [3:0] flags
);

    reg carry_out;
    reg flag_v;


    always @(*) begin
        
        carry_out = 1'b0;
        result = 8'd0;
        flag_v = 1'b0;
        
        case (alu_op)
        
            ALU_OP_ADD: begin
                {carry_out, result} = reg1 + reg2 + carry_in;
                flag_v = (~(reg1[7] ^ reg2[7])) & (reg1[7] ^ result[7]);
            end
            
            ALU_OP_SUB: begin
                {carry_out, result} = reg1 - reg2 - (~carry_in);
                flag_v =  (reg1[7] ^ reg2[7]) & (reg1[7] ^ result[7]);
            end
            
            ALU_OP_AND: result = reg1 & reg2;
            ALU_OP_OR:  result = reg1 | reg2;
            ALU_OP_XOR: result = reg1 ^ reg2;
            
            ALU_OP_INC: result = reg1 + 1;
            ALU_OP_DEC: result = reg1 - 1;
            
            ALU_OP_ASL: begin
                carry_out = reg1[7];
                result = reg1 << 1;
            end
            
            ALU_OP_LSR: begin
                carry_out = reg1[0];
                result = reg1 >> 1;
            end
            
            ALU_OP_ROL: begin
                carry_out = reg1[7];
                result = (reg1 << 1);
                result[0] = carry_in;
            end 
            
            ALU_OP_ROR: begin
                carry_out = reg1[0];
                result = (reg1 >> 1);
                result[7] = carry_in;
            end
				ALU_OP_PASS: begin
					 result = reg2;
				end
				default: begin
				end
        endcase
    end

    assign flags[3] = result[7];         // N
    assign flags[2] = flag_v;            // V
    assign flags[1] = (result == 8'd0);  // Z
    assign flags[0] = carry_out;         // C

endmodule
