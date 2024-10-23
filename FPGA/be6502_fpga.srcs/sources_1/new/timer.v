`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//
// Just a timer that I was planning to use for a project on the board.
// Each tick is 81.92us. Overflows 32b every 4 days.
//
//////////////////////////////////////////////////////////////////////////////////


module timer(
    input clk,
    input resetn,
    input [1:0] ADDR,
    output [7:0] DO
);


reg [31:0] counter; // actual count register
reg [11:0] tick_divider; // clock divider
wire timertick;

// Crude calculation. clk=50MHz, 12bit divider. Each timertick is 81.92us.
always @ (posedge clk) begin
    if(~resetn)
        tick_divider <= 'b0;
    else
        tick_divider <= tick_divider + 1'b1;
end

// Into a 32bit counter, it overflows every ~4 days.
assign timertick = (tick_divider == 'b0); // every overflow
always @ (posedge clk) begin
    if(~resetn)
        counter <= 31'h0; // Reset
    else
        if (timertick)
            counter <= counter + 1'b1;
end
//                                 ADDR=11          ADDR=10                    ADDR=01         ADDR=00
assign DO = ADDR[1] ? ADDR[0] ? counter[31:24] : counter[23:16] : ADDR[0] ? counter[15:8] : counter[7:0] ; 

endmodule
