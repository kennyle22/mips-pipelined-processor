module EX_pipe_stage (
    // Control signals from ID/EX
    input        RegDst,
    input        ALUSrc,
    input  [1:0] ALUOp,
    // Data from ID/EX
    input  [31:0] ReadData1,
    input  [31:0] ReadData2,
    input  [31:0] SignImm,
    input  [4:0]  rs, rt, rd,
    input  [4:0]  shamt,
    input  [5:0]  funct,
    input  [5:0]  opcode,
    // Forwarding inputs
    input  [31:0] EX_MEM_ALUResult,
    input  [31:0] MEM_WB_WriteData,
    input  [4:0]  EX_MEM_Rd,
    input  [4:0]  MEM_WB_Rd,
    input         EX_MEM_RegWrite,
    input         MEM_WB_RegWrite,
    // Outputs
    output [31:0] ALUResult,
    output        Zero,
    output [31:0] WriteDataOut,   // forwarded rt value (for SW)
    output [4:0]  WriteReg        // rd or rt depending on RegDst
);

    wire [1:0] ForwardA, ForwardB;

    EX_Forwarding_unit fwd (
        .rs(rs), .rt(rt),
        .EX_MEM_Rd(EX_MEM_Rd), .MEM_WB_Rd(MEM_WB_Rd),
        .EX_MEM_RegWrite(EX_MEM_RegWrite), .MEM_WB_RegWrite(MEM_WB_RegWrite),
        .ForwardA(ForwardA), .ForwardB(ForwardB)
    );

    // ALU input A MUX: 00=RegFile, 01=MEM/WB, 10=EX/MEM
    wire [31:0] ALU_A = (ForwardA == 2'b10) ? EX_MEM_ALUResult :
                        (ForwardA == 2'b01) ? MEM_WB_WriteData  :
                                              ReadData1;

    // ALU input B MUX: forwarded rt first, then ALUSrc selects imm vs register
    wire [31:0] ForwardedB = (ForwardB == 2'b10) ? EX_MEM_ALUResult :
                             (ForwardB == 2'b01) ? MEM_WB_WriteData  :
                                                   ReadData2;

    wire [31:0] ALU_B = ALUSrc ? SignImm : ForwardedB;

    wire [3:0] ALUControl;

    alu_control alu_ctrl (
        .ALUOp(ALUOp),
        .funct(funct),
        .opcode(opcode),
        .ALUControl(ALUControl)
    );

    ALU alu (
        .A(ALU_A), .B(ALU_B),
        .ALUControl(ALUControl),
        .shamt(shamt),
        .Result(ALUResult),
        .Zero(Zero)
    );

    assign WriteDataOut = ForwardedB;
    assign WriteReg     = RegDst ? rd : rt;

endmodule
