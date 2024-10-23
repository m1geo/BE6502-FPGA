// Verilog implementation of the VIA 6522 chip - by CompuSAR
// https://github.com/CompuSAR/6522/blob/main/6522.srcs/sources_1/new/6522.v

`timescale 1ns / 1ps

module via6522(
    input cs,           // Chip select. The real VIA has CS1 and nCS2. You can get the same functionality by defining this cs to be (cs1 & !cs2)
    input phi2,         // Phase 2 Internal Clock
    input nReset,       // Reset (active low)
    input [3:0]rs,      // Register select
    input rWb,          // read (high) write (low)

    input [7:0]dataIn,
    output reg [7:0]dataOut,

    input  [7:0]paIn,   // Peripheral data port A input
    output reg [7:0]paOut,  // Peripheral data port A
    output reg [7:0]paMask, // Peripheral data port A mask: 0 - input, 1 - output
    input  [7:0]pbIn,   // Peripheral data port B
    output reg [7:0]pbOut,  // Peripheral data port B
    output reg [7:0]pbMask,

    output reg nIrq);       // Interrupt request

initial begin
    reset();
end

always@(posedge phi2, negedge nReset)
begin
    if( ~nReset )
    begin
        reset();
    end else begin
        if( cs )
        begin
            // This is a clock edge and we're chip selected
            if( ~rWb ) begin
                // Rising edge of clock on write operation
                case( rs )
                4'd0: begin
                    writePb();
                end
                4'd1: begin
                    writePa();
                end
                4'd2: begin
                    writePbDir();
                end
                4'd3: begin
                    writePaDir();
                end
                default: begin
                    // All other registers are not yet implemented
                    dataOut <= 0;
                end
                endcase
            end else begin
                // Falling edge of clock on read operation
                // Well, fudge. It seems FPGAs can't trigger on both positive and negative edges of same signal. The 6522 datasheet requires that
                // we make the results available on the falling edge of the clock. The reason it requires this, however, is to give the CPU time
                // to put the data bus in high impedance mode. Since we're using separate in and out lines, we'll load the the data on the rising
                // edge and no one should be the wiser of it. 
                case( rs )
                4'd0: begin
                    readPb();
                end
                4'd1: begin
                    readPa();
                end
                4'd2: begin
                    readPbDir();
                end
                4'd3: begin
                    readPaDir();
                end
                default: begin
                    // All other registers are not yet implemented
                end
                endcase
            end
        end
    end
end

task readPb();
begin 
    // Read. Give true input where applicable, and *desired* output elsewhere. See section 2.1 of the datasheet
    dataOut <= (pbIn & ~pbMask) | (pbOut & pbMask);
end
endtask

task writePb();
    pbOut <= dataIn;
endtask

task readPa();
    dataOut <= paIn;
endtask

task writePa();
    paOut <= dataIn;
endtask

task readPbDir();
    dataOut <= pbMask;
endtask

task writePbDir();
    pbMask <= dataIn;
endtask

task readPaDir();
    dataOut <= paMask;
endtask

task writePaDir();
    paMask <= dataIn;
endtask

task reset();
begin
    dataOut <= 0;    // High impedance on start
    nIrq <= 1;       // Don't request interrupt
    paOut <= 0;
    paMask <= 0;
    pbOut <= 0;
    pbMask <= 0;
end
endtask

endmodule