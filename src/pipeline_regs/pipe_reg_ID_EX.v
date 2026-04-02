// ID/EX pipeline register: carries all control signals and data from decode stage
module pipe_reg_ID_EX (
    input         clk, rst, flush, stall,
    // Control inputs
    input         RegDst_in, ALUSrc_in, MemToReg_in, RegWrite_in,
    input         MemRead_in, MemWrite_in, Branch_in, Jump_in,
    input  [1:0]  ALUOp_in,
    // Data inputs
    input  [31:0] ReadData1_in, ReadData2_in, SignImm_in,
    input  [4:0]  rs_in, rt_in, rd_in, shamt_in,
    input  [31:0] PCBranch_in, PCJump_in,
    // Control outputs
    output        RegDst_out, ALUSrc_out, MemToReg_out, RegWrite_out,
    output        MemRead_out, MemWrite_out, Branch_out, Jump_out,
    output [1:0]  ALUOp_out,
    // Data outputs
    output [31:0] ReadData1_out, ReadData2_out, SignImm_out,
    output [4:0]  rs_out, rt_out, rd_out, shamt_out,
    output [31:0] PCBranch_out, PCJump_out
);

    // Pack all signals: 10 ctrl bits (8x1 + ALUOp[1:0]) + 180 data bits = 190 bits
    localparam W = 190;

    wire [W-1:0] dout;

    pipe_reg #(.WIDTH(W)) reg_inst (
        .clk(clk), .rst(rst), .flush(flush), .stall(stall),
        .din({RegDst_in, ALUSrc_in, MemToReg_in, RegWrite_in,
              MemRead_in, MemWrite_in, Branch_in, Jump_in, ALUOp_in,
              ReadData1_in, ReadData2_in, SignImm_in,
              rs_in, rt_in, rd_in, shamt_in,
              PCBranch_in, PCJump_in}),
        .dout(dout)
    );

    assign {RegDst_out, ALUSrc_out, MemToReg_out, RegWrite_out,
            MemRead_out, MemWrite_out, Branch_out, Jump_out, ALUOp_out,
            ReadData1_out, ReadData2_out, SignImm_out,
            rs_out, rt_out, rd_out, shamt_out,
            PCBranch_out, PCJump_out} = dout;

endmodule
