`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
//
// A really simple testbench. Boots machine. Waits for Wozmon startup prompt.
// Then sends ESC key over UART. You can see 4-bytes sent back
// (Escape echoed, Newline, the "\", and another newline)
//
//////////////////////////////////////////////////////////////////////////////////


module be6502_tb();

// Simple Clock & reset
reg board_clk;
reg board_rstn;
reg test_uart_tx = 1'b1;
initial begin
    board_clk = 1'b0;
    forever begin
        #5 board_clk = ~board_clk; // very 10ns, toggle state, period=10ns=100MHz.
    end
end

initial begin
    board_rstn = 1'b1;
    #50 board_rstn = 1'b0;
end

initial begin
    test_uart_tx = 1'b1;
    #10_300_321;   // wait 10.3ms till startup message has been sent
          test_uart_tx = 1'b0; // start of start bit                   
    #8681 test_uart_tx = 1'b1; // bit-0 of data-ESCAPE
    #8681 test_uart_tx = 1'b1; // bit-1 of data-ESCAPE
    #8681 test_uart_tx = 1'b0; // bit-2 of data-ESCAPE
    #8681 test_uart_tx = 1'b1; // bit-3 of data-ESCAPE
    #8681 test_uart_tx = 1'b1; // bit-4 of data-ESCAPE
    #8681 test_uart_tx = 1'b0; // bit-5 of data-ESCAPE
    #8681 test_uart_tx = 1'b0; // bit-6 of data-ESCAPE
    #8681 test_uart_tx = 1'b0; // bit-7 of data-ESCAPE
    #8681 test_uart_tx = 1'b1; // start of stop bit
end

be6502 dut (
    .btn(board_rstn),
    .board_clk100mhz(board_clk),
    .uart_rx_in(test_uart_tx)
);

endmodule
