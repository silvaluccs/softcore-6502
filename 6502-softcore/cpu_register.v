module cpu_register(
	input wire clk, 				
	input wire reset,
	
	input wire we_a,
	input wire we_x,
	input wire we_y,
	input wire we_sp,
	input wire we_pc,
	input wire we_ps,
	
	input  wire [7:0]  data_in,
	input  wire [7:0]  flags_in,
   input  wire [15:0] pc_in,
	
	output reg [7:0] A,
	output reg [7:0] X,
	output reg [7:0] Y,
	output reg [7:0] SP,
	output reg [15:0] PC,
	output reg [7:0] PS
	
	
);



	always @(posedge clk or posedge reset) begin
		
		if (reset) begin
			   A  <= 8'h00;
            X  <= 8'h00;
            Y  <= 8'h00;
            SP <= 8'hFF;     // SP inicial do 6502 real
            PS  <= 8'h34;     // padrão de reset
            PC <= 16'h1000;  
		end else begin
			  A <= we_a ? data_in : A;
			  X <= we_x ? data_in : X;
			  Y <= we_y ? data_in : Y;
			  SP <= we_sp ? data_in : SP;
			  PC <= we_pc ? pc_in : PC;
			  PS <= we_ps ? flags_in : PS;
		end
	
	end



endmodule
