`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//
// Simple Async RAM that the tools can impliment however.
//
//////////////////////////////////////////////////////////////////////////////////

module ram(
    input clk,
    input [13:0] ADDR,
    input WE, // active high
    input CS, // active high
    input [7:0] DI,
    output [7:0] DO
    );
    
    reg [7:0] ram[0:16383]; // 16kbyte RAM - Uninitialised RAM will be 'hXX.
    
    always @ (posedge clk) begin
        if (WE & CS)
            ram[ADDR] <= DI;
    end
    
    assign DO = CS ? (WE ? DI : ram[ADDR]) : 8'hFF; // Output RAM value if reading or DI if writing. If not chip selected, output 0xFF.

endmodule
