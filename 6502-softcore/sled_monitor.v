// Removidos os comentários em Chinês para clareza.

module sled_monitor(
    input  wire        clk,
    input  wire        reset,
    input  wire [15:0] data_in,  // Dados de 16 bits a serem exibidos (PC ou A)
    
    output reg  [7:0]  seg,      // Segmentos (a, b, c, d, e, f, g, dp)
    output reg  [3:0]  dig       // Posições/Dígitos (varredura)
);

    // Contadores de varredura e frequência
    reg [1:0]  digit_idx;    // Índice do dígito (0 a 3)
    reg [19:0] scan_count;   // Contador para a varredura do display (~10ms)
    
    // Mapeamento dos códigos de 7 segmentos (Anodo Comum)
    reg [7:0] seg_map [0:15];
    
    // Inicializa o mapeamento (feito em uma inicialização ou bloco always)
    initial begin
        // Seu Mapeamento: 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, A, B, C, D, E, F
        seg_map[4'h0] = 8'hc0; // 0
        seg_map[4'h1] = 8'hf9; // 1
        seg_map[4'h2] = 8'ha4; // 2
        seg_map[4'h3] = 8'hb0; // 3
        seg_map[4'h4] = 8'h99; // 4
        seg_map[4'h5] = 8'h92; // 5
        seg_map[4'h6] = 8'h82; // 6
        seg_map[4'h7] = 8'hf8; // 7
        seg_map[4'h8] = 8'h80; // 8
        seg_map[4'h9] = 8'h90; // 9
        seg_map[4'ha] = 8'h88; // A
        seg_map[4'hb] = 8'h83; // b
        seg_map[4'hc] = 8'hc6; // C
        seg_map[4'hd] = 8'ha1; // d
        seg_map[4'he] = 8'h86; // E
        seg_map[4'hf] = 8'h8e; // F
    end

    // --------------------
    // Lógica de Varredura (Multiplexação)
    // --------------------

    // Varredura de 4 dígitos (ex: 50MHz / 50000 = 1kHz => 1ms por dígito)
    always @(posedge clk) begin
        if (reset) begin
            scan_count <= 20'd0;
            digit_idx <= 2'd0;
        end else begin
            scan_count <= scan_count + 1'b1;
            
            if (scan_count == 20'd50000) begin // Muda o dígito a cada ~1ms (depende da sua clk)
                scan_count <= 20'd0;
                digit_idx <= digit_idx + 2'd1;
            end
        end
    end
    
    // --------------------
    // Lógica de Exibição
    // --------------------
always @(*) begin
        // Padrão: Apaga tudo
        seg = 8'hff; 
        dig = 4'hf;  
        
        // --- CORREÇÃO: INVERTENDO A ORDEM DOS DÍGITOS ---
        case (digit_idx)
            // Antes o dígito 0 pegava os bits [15:12], agora vamos inverter a seleção física
            
            // Se o seu display é [3][2][1][0] e estava aparecendo ao contrário:
            
            2'd0: begin // Dígito da ESQUERDA (Milhar)
                // Teste: se continuar espelhado, troque o valor de 'dig' aqui
                // Geralmente o digito mais a esquerda é o bit mais baixo do vetor dig (ex: 4'b1110 ou 4'b0111)
                dig = 4'b0111; // Tente inverter a lógica de seleção do anodo aqui se necessário
                seg = seg_map[data_in[15:12]]; // Bits mais altos (ex: 1 do 1000)
            end
            
            2'd1: begin // Centena
                dig = 4'b1011; 
                seg = seg_map[data_in[11:8]];
            end
            
            2'd2: begin // Dezena
                dig = 4'b1101; 
                seg = seg_map[data_in[7:4]];
            end
            
            2'd3: begin // Dígito da DIREITA (Unidade)
                dig = 4'b1110; 
                seg = seg_map[data_in[3:0]]; // Bits mais baixos
            end
            
            default: begin
                dig = 4'hf;
                seg = 8'hff;
            end
        endcase
    end
endmodule