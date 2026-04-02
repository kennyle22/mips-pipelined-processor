// MEM/WB pipeline register
module pipe_reg_MEM_WB (
    input         clk, rst, flush, stall,
    // Control inputs
    input         MemToReg_in, RegWrite_in,
    // Data inputs
    input  [31:0] ReadData_in,
    input  [31:0] ALUResult_in,
    input  [4:0]  WriteReg_in,
    // Control outputs
    output        MemToReg_out, RegWrite_out,
    // Data outputs
    output [31:0] ReadData_out,
    output [31:0] ALUResult_out,
    output [4:0]  WriteReg_out
);

    // 2 ctrl + 32 + 32 + 5 = 71 bits
    localparam W = 71;
    wire [W-1:0] dout;

    pipe_reg #(.WIDTH(W)) reg_inst (
        .clk(clk), .rst(rst), .flush(flush), .stall(stall),
        .din({MemToReg_in, RegWrite_in, ReadData_in, ALUResult_in, WriteReg_in}),
        .dout(dout)
    );

    assign {MemToReg_out, RegWrite_out, ReadData_out, ALUResult_out, WriteReg_out} = dout;

endmodule
