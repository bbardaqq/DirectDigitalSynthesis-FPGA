`timescale 1ns / 1ps

module axis_scaler (
    input  wire        aclk,
    input  wire        aresetn,

    // Bağlantıyı bozmamak için girişi tutuyoruz ama kullanmıyoruz
    //input  wire [15:0] amp_scale, 

    // --- GİRİŞ (DDS'ten) ---
    input  wire [23:0] s_axis_tdata, 
    input  wire        s_axis_tvalid,
    output wire        s_axis_tready,

    // --- ÇIKIŞ (FIFO'ya) ---
    output wire [31:0] m_axis_tdata, 
    output wire        m_axis_tvalid,
    input  wire        m_axis_tready
);

    // --- BYPASS MANTIĞI ---
    // Çarpma yok, sadece paketleme var.
    
    // 1. DDS'ten gelen 24 bitin alt 20'sini (Sinüs) al.
    // 2. Üstüne 12 tane sıfır ekle (Padding).
    // 3. 32 bit olarak FIFO'ya ver.
    assign m_axis_tdata = {{12{s_axis_tdata[19]}}, s_axis_tdata[19:0]};

    // --- AKIŞ KONTROLÜ (KÖPRÜ) ---
    // Sinyalleri doğrudan birbirine bağlıyoruz (Kısa devre).
    // FIFO hazırsa -> DDS'e "Hazır" de.
    assign s_axis_tready = m_axis_tready;
    
    // DDS gönderiyorsa -> FIFO'ya "Geliyor" de.
    assign m_axis_tvalid = s_axis_tvalid;

endmodule