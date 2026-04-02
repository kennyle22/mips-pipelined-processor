// IF/ID pipeline register: carries PC+4 and instruction word (64 bits total)
module pipe_reg_IF_ID (
    input         clk,
    input         rst,
    input         flush,
    input         stall,
    input  [31:0] PC4_in,
    input  [31:0] instr_in,
    output [31:0] PC4_out,
    output [31:0] instr_out
);

    wire [63:0] dout;

    pipe_reg #(.WIDTH(64)) reg_inst (
        .clk(clk), .rst(rst), .flush(flush), .stall(stall),
        .din({PC4_in, instr_in}),
        .dout(dout)
    );

    assign PC4_out   = dout[63:32];
    assign instr_out = dout[31:0];

endmodule
