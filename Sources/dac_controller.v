module dac_controller(
    input  wire        clk,
    input  wire        rst_n,

    // --- FIFO Tarafı ---
    input  wire [31:0] s_axis_tdata,   
    input  wire        s_axis_tvalid,  
    output reg         s_axis_tready,  // Reg görünümlü wire (always @* içinde)

    // --- SPI Master Tarafı ---
    output reg  [23:0] m_axis_tdata,   
    output reg         m_axis_tvalid,  
    input  wire        m_axis_tready   
);

    localparam STATE_INIT   = 1'b0;
    localparam STATE_STREAM = 1'b1;

    reg state;

    // 1. BASİT DURUM MAKİNESİ (Sadece State Değişimi)
    // Sadece "Ayar bitti mi?" kontrolü yapar.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= STATE_INIT;
        end else begin
            case (state)
                STATE_INIT: begin
                    // SPI Master veriyi kabul ettiyse (Ready=1) Stream'e geç
                    // (Biz zaten Valid=1 basıyoruz aşağıda)
                    if (m_axis_tready) begin
                        state <= STATE_STREAM;
                    end
                end
                
                STATE_STREAM: begin
                    // Sonsuza kadar burada kal
                    state <= STATE_STREAM;
                end
            endcase
        end
    end

    // 2. ÇIKIŞ MANTIĞI (KABLO MODU)
    // Saat beklemez, giriş neyse çıkış odur.
    always @(*) begin
        
        if (state == STATE_STREAM) begin
            // --- STREAM MODU (DOĞRUDAN BAĞLANTI) ---
            
            // FIFO'nun Valid sinyalini direkt SPI'ya ver
            m_axis_tvalid = s_axis_tvalid;
            
            // SPI'ın Ready sinyalini direkt FIFO'ya ver (Tıkanıklığı çözen yer burası)
            s_axis_tready = m_axis_tready;
            
            // Veriyi paketle ve yolla
            // Header: 0001 (DAC Register Yaz) + Data
            m_axis_tdata  = {4'b0001, s_axis_tdata[19:0]};
            
        end else begin
            // --- INIT MODU (AYARLAMA) ---
            
            // FIFO'yu durdur (Beklesin)
            s_axis_tready = 1'b0;
            
            // SPI'ya "Verim var" de
            m_axis_tvalid = 1'b1;
            
            // AYAR KOMUTU: 0x200008
            // Control Register(010), Clamp Off, Buffer On
            m_axis_tdata  = 24'h200008;
        end
    end

endmodule