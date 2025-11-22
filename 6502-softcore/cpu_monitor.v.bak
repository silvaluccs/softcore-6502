/*******************************************************************
** Módulo de Monitoramento de Registradores
** Objetivo: Receber 4 botões e exibir A ou PC em hexadecimal.
********************************************************************/

module cpu_monitor(
    input  wire        clk,
    input  wire        reset,
    
    // Entradas do Processador (deve vir da sua Control Unit ou Register File)
    input  wire [7:0]  A_reg,       // Valor do Acumulador (A)
    input  wire [15:0] PC_reg,      // Valor do Program Counter (PC)
    
    // Entradas de Botões (Ativos em Nível Baixo/Zero)
    input  wire [3:0]  btn_n,       // Botoes: btn_n[0], btn_n[1], btn_n[2], btn_n[3]
    
    // Saídas para o Módulo SLED (Display de 7 segmentos)
    output wire [7:0] seg,         // Saída do segmento (a, b, c, d, e, f, g, dp)
    output wire [3:0] dig          // Saída do dígito/posição (ânodo comum)
);

    // --------------------------cpu_monitor--------------------------------------
    // 1. Lógica de Seleção de Dados (Baseada nos botões)
    // ----------------------------------------------------------------

    // Registrador para armazenar o valor de 16 bits a ser exibido
    reg [15:0] display_value;
    
    // Sinal combinado para identificar qual botão está ativo (prioridade)
    wire [1:0] button_sel;

    // Seleção de Valor (Escolhe entre A_reg e PC_reg)
    always @(*) begin
        // Padrão: Nenhum botão (ou mais de um) pressionado, mostra PC
        display_value = PC_reg; 

        if (btn_n[0] == 1'b0) begin
            // Botão 0: Mostrar PC (16 bits)
            display_value = PC_reg;
        end else if (btn_n[1] == 1'b0) begin
            // Botão 1: Mostrar A (8 bits), o resto alto é 0
            display_value = {8'h00, A_reg};
        end
        // btn_n[2] e btn_n[3] podem ser usados para outras funções (X, Y, SP)
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