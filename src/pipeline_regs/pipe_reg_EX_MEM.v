// EX/MEM pipeline register
module pipe_reg_EX_MEM (
    input         clk, rst, flush, stall,
    // Control inputs
    input         MemRead_in, MemWrite_in, MemToReg_in, RegWrite_in, Branch_in, Jump_in,
    // Data inputs
    input  [31:0] ALUResult_in,
    input         Zero_in,
    input  [31:0] WriteData_in,
    input  [4:0]  WriteReg_in,
    input  [31:0] PCBranch_in, PCJump_in,
    // Control outputs
    output        MemRead_out, MemWrite_out, MemToReg_out, RegWrite_out, Branch_out, Jump_out,
    // Data outputs
    output [31:0] ALUResult_out,
    output        Zero_out,
    output [31:0] WriteData_out,
    output [4:0]  WriteReg_out,
    output [31:0] PCBranch_out, PCJump_out
);

    // 6 ctrl + 32 + 1 + 32 + 5 + 32 + 32 = 140 bits
    localparam W = 140;
    wire [W-1:0] dout;

    pipe_reg #(.WIDTH(W)) reg_inst (
        .clk(clk), .rst(rst), .flush(flush), .stall(stall),
        .din({MemRead_in, MemWrite_in, MemToReg_in, RegWrite_in, Branch_in, Jump_in,
              ALUResult_in, Zero_in, WriteData_in, WriteReg_in, PCBranch_in, PCJump_in}),
        .dout(dout)
    );

    assign {MemRead_out, MemWrite_out, MemToReg_out, RegWrite_out, Branch_out, Jump_out,
            ALUResult_out, Zero_out, WriteData_out, WriteReg_out,
            PCBranch_out, PCJump_out} = dout;

endmodule
