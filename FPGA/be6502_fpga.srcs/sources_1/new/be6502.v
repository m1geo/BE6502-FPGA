`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Ben Eater 6502 Based System based on the accompanying YouTube series
// https://www.youtube.com/watch?v=mpIFag8zSWo
// 
// FPGA by George Smart, M1GEO.
// https://github.com/m1geo/BE6502-FPGA
//
// This file is the design top file.
//
// This project is a mix of other people's work. See inline links.
//
// Create Date: 13/Oct/2024 09:56:03 PM
//
// Notes:
//   * Uses UART via the MicroUSB cable (Same port as JTAG).
//   * UART speed 115200, 8-N-1. No flowcontrol (yet).
//   * Boots to Wozmon. MSBASIC at address $8000.
//   * Builds without critial warnings or errors.
//   * Uses 21% of RAM/ROM and 1% of Flops in XC7A35T.
//
//////////////////////////////////////////////////////////////////////////////////

module be6502(
    input board_clk100mhz,
    input btn,
    input uart_rx_in, // FTDI TX
    output uart_tx_out, // FTDI RX
    output [3:0] led,
    input  [3:0] sw
);

// CPU CLOCK & RESET
// 100MHz input, 5MHz output
wire board_clk50mhz;
wire board_resetn;
clk_wiz_0 cpu_clk (
  .resetn(~btn), // push button is active high
  .clk100mhz(board_clk100mhz), // Clock in ports
  .cpu_clk(board_clk50mhz), // Clock out ports
  .cpu_rst(board_resetn) // PLL locked, reset (active low)
);

// 65C02 CPU by Arlet Ottens
// https://github.com/Arlet/verilog-65C02-microcode
wire [15:0] address_bus_unregistered;
reg  [15:0] address_bus;
wire [7:0] cpu_data_in; // delayed for sync memory 
wire [7:0] cpu_data_out;
wire       cpu_irq_in;
wire cpu_write_en;
wire VIA_CS;
wire ROM_CS;
wire RAM_CS;
wire UART_CS;
wire TIME_CS;

cpu cpu( 
    .clk(board_clk50mhz),           // CPU clock
    .RST(~board_resetn),            // RST signal. Active high.
    .RDY(1'b1),                     // Ready signal. Pauses CPU when RDY=0.
    .IRQ(cpu_irq_in),               // interrupt request. Active high.
    .NMI(1'b0),                     // non-maskable interrupt request. Active high.
    .AD(address_bus_unregistered),  // address bus (combinatorial) - next value, register for async operations
    .DI(cpu_data_in),               // data bus input
    .DO(cpu_data_out),              // data bus output (only valid on WE) 
    .WE(cpu_write_en),              // write enable
    .sync(),                        // start of new instruction
    .debug()                        // debug for simulation
);

// "When using external asynchronous memory, you should register the "AD" signals"
always @(posedge board_clk50mhz) address_bus <= address_bus_unregistered;

wire [7:0] rom_data_out;
prog_rom prog_rom (
    //.clk(board_clk50mhz),
    .ADDR(address_bus[14:0]),       // 15bit
    .CS(ROM_CS),
    .DO(rom_data_out)               // 8bit
);

wire [7:0] ram_data_out;
ram ram (
    .clk(board_clk50mhz),
    .ADDR(address_bus[13:0]),       // 14bit
    .WE(cpu_write_en),              // active high
    .CS(RAM_CS),                    // active high
    .DI(cpu_data_out),
    .DO(ram_data_out)
);

// Verilog 65C22 by CompuSAR
// 
wire [7:0] via_data_out;
wire via_irq_n;
via6522 via6522 (
    .cs(VIA_CS),                    // Chip select. The real VIA has CS1 and nCS2. You can get the same functionality by defining this cs to be (cs1 & !cs2)
    .phi2(board_clk50mhz),          // Phase 2 Internal Clock (same clock as CPU)
    .nReset(board_resetn),          // Reset (active low)
    .rs(address_bus[3:0]),          // Register select
    .rWb(~cpu_write_en),            // VIA-read (high) VIA-write (low)
    .dataIn(cpu_data_out),          // Data Bus - In to VIA (only valid when cpu_write_en=HIGH) 
    .dataOut(via_data_out),         // Data Bus - Out of VIA
    .paIn(sw[3:0]),                 // Peripheral data port A input
    .paOut(led[3:0]),               // Peripheral data port A
    .paMask(),                      // Peripheral data port A mask: 0 - input, 1 - output
    .pbIn(),                        // Peripheral data port B
    .pbOut(),                       // Peripheral data port B
    .pbMask(),
    .nIrq(via_irq_n)                // Not implimented in this 65C22. Always high (active low)
);

// GS Simple UART
// Based around https://github.com/ben-marshall/uart
// Status register: {x, x, x, 4:uart_tx_busy, x, x, 1:uart_rx_break, 0:uart_rx_valid};
// Note the status register is different from the 6551 ACIA that Ben uses. Assembly is changed accordinly.
wire [7:0] uart_data_out;
wire uart_irq;
gs_uart_top #(
    .CLK_HZ(50E6),
    .BIT_RATE(115200),
    .PAYLOAD_BITS(8)
) gs_uart (
    .clk(board_clk50mhz),           // Top level system clock input.
    .resetn(board_resetn),          // System reset (active low)
    .ADDR(address_bus[0]),          // Single bit address (0=data,1=status)
    .CS(UART_CS),                   // chip select active high  
    .WE(cpu_write_en & UART_CS),    // write enable active high
    .DI(cpu_data_out),              // data bus in
    .DO(uart_data_out),             // data bus out
    .IRQ(uart_irq),                 // IRQ from UART (active high) - read status register to clear
    .uart_rxd(uart_rx_in),          // UART Recieve pin.
    .uart_txd(uart_tx_out)          // UART transmit pin.
);

// Simple 8-bit LFSR for Randomness
wire [7:0] rnd_data_out;
LFSR lfsr(
    .clk(board_clk50mhz),
    .resetn(board_resetn),
    .ADDR(address_bus[0]),
    .DO(rnd_data_out)
);

// Simple 32-bit timer
wire [7:0] time_data_out;
timer timer (
    .clk(board_clk50mhz),
    .resetn(board_resetn & ~(TIME_CS & cpu_write_en)), // either a resetn or a write to the addressspace resets it.
    .ADDR(address_bus[1:0]), // 2 bits
    .DO(time_data_out) // 8 bits
);

// CPU Interrupt ORing
assign cpu_irq_in = ~via_irq_n | uart_irq; // CPU input is active high

// CPU DIN MUX
assign RAM_CS  = (address_bus >= 16'h0000) & (address_bus <= 16'h3FFF);
assign UART_CS = (address_bus >= 16'h5000) & (address_bus <= 16'h500F);
assign VIA_CS  = (address_bus >= 16'h6000) & (address_bus <= 16'h600F);
assign RND_CS  = (address_bus >= 16'h7000) & (address_bus <= 16'h7001);
assign TIME_CS = (address_bus >= 16'h7010) & (address_bus <= 16'h7013);
assign ROM_CS  = (address_bus >= 16'h8000) & (address_bus <= 16'hFFFF);
assign cpu_data_in = ROM_CS  ? rom_data_out  : 
                     RAM_CS  ? ram_data_out  : 
                     VIA_CS  ? via_data_out  : 
                     UART_CS ? uart_data_out : 
                     RND_CS  ? rnd_data_out  : 
                     TIME_CS ? time_data_out  :8'hXX;
/*
// Xilinx ILA - not used as slows down Synthesis and most debugging is done in the simulator.
ila_0 ila (
    .clk(board_clk50mhz),
    .probe0(address_bus),  // 16bit (address)
    .probe1(cpu_data_in),  // 8bit (data in)
    .probe2(cpu_data_out),  // 8bit (data out)
    .probe3(uart_tx_out),  // 1bit (uart FPGA TX)
    .probe4(uart_rx_in),  // 1bit (uart FPGA RX)
    .probe5(cpu_write_en),  // 1bit (cpu write enable)
    .probe6(board_resetn)  // 1bit (reset)
);
*/
endmodule
