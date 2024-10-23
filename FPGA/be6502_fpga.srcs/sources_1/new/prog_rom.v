`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//
// Simple Async ROM that the tools can impliment however.
// You must use a MEM file format (not the BIN format) for Vivado to import
// Errors importing ROMs tend to fail silently, so be careful when starting out.
//
//////////////////////////////////////////////////////////////////////////////////

module prog_rom(
    input [14:0] ADDR, // 15bit
    input CS, // active high
    output [7:0] DO // 8bit
    );
    
    reg [7:0] rom[0:32767]; // 32kbyte RAM
    
    // Code to import the data. This is finicky. If you have no ROM, it's probably this line! 
    initial $readmemh("/home/george/Desktop/BE6502-FPGA/Software/msbasic/tmp/eater.mem", rom, 0, 32767);
    
    assign DO = CS ? rom[ADDR] : 8'hFF; // Output RAM value if reading or DI if writing. If not chip selected, output 0xFF.

endmodule
