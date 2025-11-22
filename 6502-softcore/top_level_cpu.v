module top_level_cpu(
    input  wire clk_50mhz,
    input  wire reset_n,      // Reset Ativo em Nível Baixo
    input  wire [3:0] btn_n,
    
    output wire [7:0] seg,
    output wire [3:0] dig
);

    // ----------------------------------------------------------------
    // 1. GERAÇÃO DE CLOCK LENTO (Clock Divider)
    // ----------------------------------------------------------------
    // Vamos criar um contador grande. O bit mais alto vai piscar devagar.
    // 25 bits: 2^25 = ~33 milhões. Em 50MHz, isso dá ~1.5 segundos por ciclo.
    reg [24:0] clk_counter;
    
    always @(posedge clk_50mhz) begin
        clk_counter <= clk_counter + 1'b1;
    end

    // Este será o clock da CPU (lento para você ver os números mudando)
    wire cpu_slow_clk;
    assign cpu_slow_clk = clk_counter[23]; // Ajuste o bit: [24] é muito lento, [23] é médio, [20] é rápido.

    // ----------------------------------------------------------------
    // 2. SINAIS DE CONTROLE
    // ----------------------------------------------------------------
    wire reset;
    wire [7:0] A_debug;
    wire [15:0] PC_debug;
	 wire [7:0] X_debug;  // <--- NOVO: Sinal para X
    wire [7:0] Y_debug;  // <--- NOVO: Sinal para Y

    // Inverte o reset (para ativo alto)
    assign reset = ~reset_n; 
    
    // ----------------------------------------------------------------
    // 3. INSTÂNCIA DA CPU (Com Clock LENTO)
    // ----------------------------------------------------------------
    // A CPU recebe o clock lento para andar passo-a-passo
    control_unit cpu_inst (
        .clk(cpu_slow_clk), 
        .reset(reset),
        .A_out(A_debug),   
        .X_out(X_debug),   // <--- NOVO: Conecta X_out
        .Y_out(Y_debug),   // <--- NOVO: Conecta Y_out
        .PC_out(PC_debug) 
    );
    
    // ----------------------------------------------------------------
    // 4. INSTÂNCIA DO MONITOR (Com Clock RÁPIDO)
    // ----------------------------------------------------------------
    // O monitor precisa do clock rápido para varrer os dígitos (multiplexação)
    // senão o display vai piscar visivelmente.
    cpu_monitor monitor_logic (
        .clk(clk_50mhz),
        .reset(reset),
        .A_reg(A_debug),
        .X_reg(X_debug),   // <--- NOVO: Passa X para o monitor
        .Y_reg(Y_debug),   // <--- NOVO: Passa Y para o monitor
        .PC_reg(PC_debug),
        .btn_n(btn_n),
        .seg(seg),
        .dig(dig)
    );

endmodule