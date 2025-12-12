/*******************************************************************
** Módulo de Monitoramento de Registradores
** Objetivo: Receber 4 botões e exibir A ou PC em hexadecimal.
********************************************************************/

module cpu_monitor(
    input  wire           clk,
    input  wire           reset,
    
    // Entradas do Processador
    input  wire [7:0]   A_reg,     // Valor do Acumulador (A)
    input  wire [7:0]   X_reg,     // <--- NOVO: Valor do Registrador X
    input  wire [7:0]   Y_reg,     // <--- NOVO: Valor do Registrador Y
    input  wire [15:0]  PC_reg,    // Valor do Program Counter (PC)
    
    // Entradas de Botões (Ativos em Nível Baixo/Zero)
    input  wire [3:0]   btn_n,     // Botoes: btn_n[0], btn_n[1], btn_n[2], btn_n[3]
    
    // Saídas para o Módulo SLED
    output wire [7:0] seg,         
    output wire [3:0] dig          
);
  
    

    // ----------------------------------------------------------------
    // 1. Lógica de Seleção de Dados (Baseada nos botões)
    // ----------------------------------------------------------------

    // Registrador para armazenar o valor de 16 bits a ser exibido
    reg [15:0] display_value;
    
    // Seleção de Valor (Incluindo X e Y)
    always @(*) begin
        // Padrão: Nenhum botão pressionado, mostra PC
        display_value = PC_reg; 

        if (btn_n[0] == 1'b0) begin
            // Botão 0: Mostrar PC (16 bits) -> PC, A, X, Y
            display_value = {8'h00, Y_reg};
        end else if (btn_n[1] == 1'b0) begin
            // Botão 1: Mostrar A (8 bits)
            display_value = {8'h00, A_reg};
        end else if (btn_n[2] == 1'b0) begin // <--- NOVO
            // Botão 2: Mostrar X (8 bits)
            display_value = {8'h00, X_reg};
        end else begin
				display_value = PC_reg; 
		  end
    end
    // ----------------------------------------------------------------
    // 2. Instância do Módulo de Display
    // ----------------------------------------------------------------

    // A lógica de varredura (multiplexação) do display será adicionada no sled_monitor

    // Instanciando o monitor/multiplexador de display
    sled_monitor sled_inst (
        .clk(clk),
        .reset(reset),
        .data_in(display_value), // O valor de 16 bits que queremos exibir
        .seg(seg),               // Segmentos para o display
        .dig(dig)                // Dígitos para a varredura
    );

endmodule
