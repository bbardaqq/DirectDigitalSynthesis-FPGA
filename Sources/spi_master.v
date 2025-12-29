`timescale 1ns / 1ps

module spi_master_ad5791 (
    input  wire        aclk,           
    input  wire        aresetn,        

    input  wire [23:0] s_axis_tdata,   
    input  wire        s_axis_tvalid,
    output reg         s_axis_tready,

    output reg         sclk,           
    output reg         sdin,           
    output reg         sync_n,         
    output reg         ldac_n,         
    output reg         clr_n           
);

    parameter CLK_DIV_MAX = 1; // 25 MHz (100MHz / 4)
    
    localparam IDLE = 0;
    localparam START = 1;
    localparam TRANSFER = 2;
    localparam QUIET = 3;
    localparam LOAD = 4;
    localparam FINISH = 5;

    reg [2:0] state;
    reg [4:0] bit_cnt;      
    reg [23:0] shift_reg;   
    reg [2:0] clk_cnt;      
    
    wire sclk_tick;
    assign sclk_tick = (clk_cnt == CLK_DIV_MAX); 


    //SCLK Uretimi
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            clk_cnt <= 0;
            sclk <= 1; // CPOL = 1 (Idle High)
        end else begin
            // Sadece veri transferi sırasında clock üret
            if (state == START || state == TRANSFER) begin 
                if (clk_cnt == CLK_DIV_MAX) begin
                    clk_cnt <= 0;
                    sclk <= ~sclk; 
                end else begin
                    clk_cnt <= clk_cnt + 1;
                end
            end else begin
                sclk <= 1; // Boşta hep HIGH
                clk_cnt <= 0;
            end
        end
    end

    // --- State Machine ---
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            state <= IDLE;
            s_axis_tready <= 0;
            sync_n <= 1;
            sdin <= 0;
            bit_cnt <= 0;
            ldac_n <= 1; // Default HIGH
            clr_n  <= 1; // Default HIGH (Reset değilse)
        end else begin
            case (state)
                IDLE: begin
                    sync_n <= 1;
                    ldac_n <= 1;
                    s_axis_tready <= 1; //veri alimi basliyor
                    
                    if (s_axis_tvalid && s_axis_tready) begin
                        s_axis_tready <= 0; //veri alindi, daha fazla alma.
                        shift_reg <= s_axis_tdata; 
                        state <= START;
                        
                        sdin <= s_axis_tdata[23]; // MSB'yi hemen bas
                        bit_cnt <= 23;
                    end
                end

                START: begin
                    sync_n <= 0;
                    
                    if (sclk_tick && sclk == 1) state <= TRANSFER; 
                end

                TRANSFER: begin
                    if (sclk_tick && sclk == 0) begin // falling edge geliyor
                        if (bit_cnt == 0) begin
                            state <= QUIET;
                        end else begin
                            bit_cnt <= bit_cnt - 1;
                            sdin <= shift_reg[bit_cnt - 1]; 
                        end
                    end
                end
                QUIET: begin
                    if(sclk_tick) begin //bir clock cycle bekleriz
                        sync_n <= 1;    //iletisim biter
                        state <= LOAD;
                    end
                end
                LOAD:begin          //dac cikisini guncelleriz
                    ldac_n <= 0;    //active low pulse
                    state <= FINISH;
                end
                FINISH: begin
                    ldac_n <= 1;    //pulse bitti
                    state <= IDLE;
                     
                end
            endcase
        end
    end
endmodule