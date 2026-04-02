module ID_pipe_stage (
    input         clk,
    input         RegWrite,
    input  [31:0] instr,
    input  [31:0] PC4,
    input  [4:0]  WriteReg,
    input  [31:0] WriteData,
    // Control outputs
    output        RegDst,
    output        ALUSrc,
    output        MemToReg,
    output        RegWrite_out,
    output        MemRead,
    output        MemWrite,
    output        Branch,
    output        Jump,
    output [1:0]  ALUOp,
    // Data outputs
    output [31:0] ReadData1,
    output [31:0] ReadData2,
    output [31:0] SignImm,
    output [31:0] PCBranch,
    output [31:0] PCJump,
    output [4:0]  rs,
    output [4:0]  rt,
    output [4:0]  rd,
    output [4:0]  shamt
);

    assign rs    = instr[25:21];
    assign rt    = instr[20:16];
    assign rd    = instr[15:11];
    assign shamt = instr[10:6];

    // Sign-extend immediate
    assign SignImm = {{16{instr[15]}}, instr[15:0]};

    // Branch target: PC4 + sign-extended immediate << 2
    assign PCBranch = PC4 + (SignImm << 2);

    // Jump target: PC4[31:28] concatenated with instr[25:0] << 2
    assign PCJump = {PC4[31:28], instr[25:0], 2'b00};

    control_unit ctrl (
        .opcode(instr[31:26]),
        .RegDst(RegDst), .ALUSrc(ALUSrc), .MemToReg(MemToReg),
        .RegWrite(RegWrite_out), .MemRead(MemRead), .MemWrite(MemWrite),
        .Branch(Branch), .Jump(Jump), .ALUOp(ALUOp)
    );

    register_file rf (
        .clk(clk), .RegWrite(RegWrite),
        .rs(rs), .rt(rt), .rd(WriteReg),
        .WriteData(WriteData),
        .ReadData1(ReadData1), .ReadData2(ReadData2)
    );

endmodule
