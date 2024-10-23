// Simple 16-bit LFSR
// todo: make a write to register re-seed it?

module LFSR(
    input clk,
    input resetn,
    input ADDR,
    output [7:0] DO
);

reg [15:0] lfsr;

always @ (posedge clk) begin
    if(~resetn)
        lfsr <= 16'hBABE; // Any non-zero seed will work.
    else
        lfsr = {lfsr[14:0], (lfsr[15]^lfsr[13]^lfsr[12]^lfsr[10])};
end

assign DO = ADDR ? lfsr[15:8] : lfsr[7:0];

endmodule
