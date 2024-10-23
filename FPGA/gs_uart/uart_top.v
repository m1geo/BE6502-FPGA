`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
//
// Simple UART Wrapper for 8-bit system
// Wraps UART modules from https://github.com/ben-marshall/uart/
//
//////////////////////////////////////////////////////////////////////////////////

module gs_uart_top (
    input clk,           // Top level system clock input.
    input resetn,        // System reset (active low)
    input ADDR,          // Single bit address (0=data,1=status)
    input CS,            // Chip select (active high)
    input WE,            // active high
    input [7:0] DI,      // data bus in
    output [7:0] DO,     // data bus out
    output IRQ,          // IRQ active high (reading status register clears this)
    input uart_rxd,      // UART Recieve pin.
    output uart_txd      // UART transmit pin.
);

// UART parameters
// Clock frequency in hertz.
parameter CLK_HZ = 50000000;
parameter BIT_RATE = 115200;
parameter PAYLOAD_BITS = 8; // if not 8, sanity check the DO mux.

// UART RX (https://github.com/ben-marshall/uart)
wire [PAYLOAD_BITS-1:0] uart_rx_data;
wire uart_rx_valid;
wire uart_rx_break;
uart_rx #(
    .BIT_RATE(BIT_RATE),
    .PAYLOAD_BITS(PAYLOAD_BITS),
    .CLK_HZ(CLK_HZ)
) i_uart_rx(
    .clk          (clk),           // Top level system clock input.
    .resetn       (resetn),        // Asynchronous active low reset.
    .uart_rxd     (uart_rxd),      // UART Recieve pin.
    .uart_rx_en   (1'b1),          // Recieve enable
    .uart_rx_break(uart_rx_break), // Did we get a BREAK message?
    .uart_rx_valid(uart_rx_valid), // Valid data recieved and available.
    .uart_rx_data (uart_rx_data)   // The recieved data.
);

// UART TX (https://github.com/ben-marshall/uart)
wire [PAYLOAD_BITS-1:0]  uart_tx_data;
wire uart_tx_busy;
wire uart_tx_en;
uart_tx #(
    .BIT_RATE(BIT_RATE),
    .PAYLOAD_BITS(PAYLOAD_BITS),
    .CLK_HZ(CLK_HZ)
) i_uart_tx(
    .clk          (clk),           // Top level system clock input.
    .resetn       (resetn),        // Asynchronous active low reset.
    .uart_txd     (uart_txd),      // UART transmit pin.
    .uart_tx_en   (uart_tx_en),    // Send the data on uart_tx_data
    .uart_tx_busy (uart_tx_busy),  // Module busy sending previous item.
    .uart_tx_data (uart_tx_data)   // The data to be sent
);

// Databus CPU-Read Logic
reg uart_rx_break_r;
reg uart_rx_valid_r;
always @ (posedge clk) begin
    // Latch UART Break
    if (uart_rx_break)
        uart_rx_break_r <= 1'b1;
    else if ((CS & ADDR) | ~resetn)
        uart_rx_break_r <= 1'b0;
    // Latch UART RX Valid
    if (uart_rx_valid)
        uart_rx_valid_r <= 1'b1;
    else if ((CS & ADDR) | ~resetn)
        uart_rx_valid_r <= 1'b0;
end


wire [7:0] status_register;
assign status_register = {1'b0, 1'b0, 1'b0, uart_tx_busy, 1'b0, 1'b0, uart_rx_break_r, uart_rx_valid_r};
assign DO = ADDR ? status_register : uart_rx_data[7:0]; // ADDR=1: status, ADDR=0: uart data.

// Generate IRQ output
assign IRQ = uart_rx_break_r | uart_rx_valid_r;

// Databus CPU-Write Logic
assign uart_tx_data = DI;
assign uart_tx_en = (CS & WE & ~ADDR); // on write to ADDR0.

endmodule
