## --- SİSTEM SAATİ (100 MHz) ---
# Nexys A7'de osilatör E3 pinindedir.
set_property -dict { PACKAGE_PIN E3    IOSTANDARD LVCMOS33 } [get_ports { clk_in1_0 }];
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports { clk_in1_0 }];

## --- SİSTEM RESETİ (SW0 Kullanıyoruz) ---
# Nexys A7'de en sağdaki anahtar (SW0) J15 pinindedir[cite: 4].
# SW0 AŞAĞI (OFF) = 0 -> Sistem RESET DURUMUNDA (Durur)
# SW0 YUKARI (ON) = 1 -> Sistem ÇALIŞIR
set_property -dict { PACKAGE_PIN J15   IOSTANDARD LVCMOS33 } [get_ports { resetn_0 }];

## --- UART GİRİŞİ (USB-RS232) ---
# Bilgisayardan gelen veri (TX), FPGA'nın RX'ine (C4) girer[cite: 135].
# DİKKAT: Arty'de A9 idi, Nexys'de C4. En kritik yer burasıydı!
set_property -dict { PACKAGE_PIN C4    IOSTANDARD LVCMOS33 } [get_ports { rx_0 }];

## --- DAC 1 (AD5791) ÇIKIŞLARI (Pmod Header JA) ---
# Nexys A7'nin JA Portu (Ethernet'in yanındaki)[cite: 64, 65, 66, 67].

# JA1 (Üst Sıra Pin 1) -> SCLK
set_property -dict { PACKAGE_PIN C17   IOSTANDARD LVCMOS33 } [get_ports { sclk_0 }];

# JA2 (Üst Sıra Pin 2) -> SDIN
set_property -dict { PACKAGE_PIN D18   IOSTANDARD LVCMOS33 } [get_ports { sdin_0 }];

# JA3 (Üst Sıra Pin 3) -> SYNC#
set_property -dict { PACKAGE_PIN E18   IOSTANDARD LVCMOS33 } [get_ports { sync_n_0 }];

# JA4 (Üst Sıra Pin 4) -> LDAC#
set_property -dict { PACKAGE_PIN G17   IOSTANDARD LVCMOS33 } [get_ports { ldac_n_0 }];

# JA7 (Alt Sıra Pin 1) -> CLR#
set_property -dict { PACKAGE_PIN D17   IOSTANDARD LVCMOS33 } [get_ports { clr_n_0 }];

## --- YAPILANDIRMA AYARLARI ---
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]