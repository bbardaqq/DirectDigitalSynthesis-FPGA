`timescale 1ns / 1ps

module tb_system_sim();

    // --- SİNYALLER ---
    reg sys_clock;
    reg sys_reset_n;  // Active Low Reset (Clocking Wizard genelde high ister ama biz external yaptık)
    reg uart_rx_in;   // FPGA'nın RX bacağına giden kablo

    // Çıkışları gözlemlemek için (Wire)
    wire sclk;
    wire sdin;
    wire sync_n;
    wire ldac_n;

    // --- AYARLAR ---
    // UART Hızı (Senin tasarımındakiyle AYNI olmalı!)
    parameter BAUD_RATE = 115200; 
    parameter BIT_PERIOD = 1000000000 / BAUD_RATE; // Nanosaniye cinsinden 1 bit süresi

    // --- TASARIMI ÇAĞIRMA (Instantiation) ---
    // Buradaki isim "design_1_wrapper" olmalı. 
    // Port isimlerini Block Design'daki "External" isimlerine göre düzeltmen gerekebilir.
    design_1_wrapper uut (
        .clk_in1_0    (sys_clock),    // Clocking wizard giriş pini ismi
        .resetn_0    (sys_reset_n),  // Reset pini ismi (Block design'da neyse o)
        .rx_0         (uart_rx_in),   // UART RX pini ismi
        
        // SPI Çıkışları
        .sclk_0       (sclk),
        .sdin_0       (sdin),
        .sync_n_0     (sync_n),
        .ldac_n_0     (ldac_n)
    );

    // --- SAAT ÜRETİMİ (100 MHz) ---
    always begin
        sys_clock = 0; #5; // 5ns Low
        sys_clock = 1; #5; // 5ns High -> Toplam 10ns periyot = 100 MHz
    end

    // --- UART GÖNDERME GÖREVİ (TASK) ---
    // Bu küçük fonksiyon, bir baytlık veriyi UART protokolüne uygun (Start, Data, Stop) gönderir.
    task send_byte;
        input [7:0] data;
        integer i;
        begin
            // 1. Start Bit (Low)
            uart_rx_in = 0;
            #(BIT_PERIOD);
            
            // 2. Data Bits (LSB'den MSB'ye)
            for (i=0; i<8; i=i+1) begin
                uart_rx_in = data[i];
                #(BIT_PERIOD);
            end
            
            // 3. Stop Bit (High)
            uart_rx_in = 1;
            #(BIT_PERIOD);
        end
    endtask

    // --- SENARYO BAŞLIYOR ---
    initial begin
        // 1. Başlangıç Durumu
        sys_reset_n = 0; // Reset basılı
        uart_rx_in = 1;  // UART hattı boşta (Idle High)
        
        #200; // Biraz bekle
        sys_reset_n = 1; // Reseti bırak (Sistem çalışmaya başlasın)
        #500;

        // 2. FREKANS GÖNDERME PAKETİ
        // Hedef: 1 MHz
        // Hesaplanan PIN: 42.949.673 -> Hex: 02 8F 5C 28
        
        #1000; // Resetten sonra biraz bekle
        $display("UART Paket Gonderimi Basliyor...");

        send_byte(8'hAA); // Header
        send_byte(8'h01); // Komut: Frekans
        
        // Veri (Big Endian)
        send_byte(8'h02); // MSB
        send_byte(8'h8F);
        send_byte(8'h5C);
        send_byte(8'h28); // LSB
        
        send_byte(8'h55); // Footer
        
        $display("Paket Bitti. Sinyal bekleniyor...");

        // 3. Simülasyonu bir süre daha çalıştır ki sinüs oluşsun
        #200000; // 200 us bekle
        
        $stop; // Simülasyonu durdur
    end

endmodule