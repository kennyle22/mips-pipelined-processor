module mips_32 (
    input clk,
    input rst
);

    // ── Hazard Detection outputs ──────────────────────────
    wire PCWrite, IF_ID_Write, ControlMux;

    // ── IF Stage outputs ──────────────────────────────────
    wire [31:0] IF_PC4, IF_instr;

    // ── IF/ID Register outputs ────────────────────────────
    wire [31:0] IF_ID_PC4, IF_ID_instr;

    // ── ID Stage outputs ──────────────────────────────────
    wire        ID_RegDst, ID_ALUSrc, ID_MemToReg, ID_RegWrite;
    wire        ID_MemRead, ID_MemWrite, ID_Branch, ID_Jump;
    wire [1:0]  ID_ALUOp;
    wire [31:0] ID_ReadData1, ID_ReadData2, ID_SignImm;
    wire [31:0] ID_PCBranch, ID_PCJump;
    wire [4:0]  ID_rs, ID_rt, ID_rd, ID_shamt;

    // ── ID/EX Register outputs ────────────────────────────
    wire        ID_EX_RegDst, ID_EX_ALUSrc, ID_EX_MemToReg, ID_EX_RegWrite;
    wire        ID_EX_MemRead, ID_EX_MemWrite, ID_EX_Branch, ID_EX_Jump;
    wire [1:0]  ID_EX_ALUOp;
    wire [31:0] ID_EX_ReadData1, ID_EX_ReadData2, ID_EX_SignImm;
    wire [4:0]  ID_EX_rs, ID_EX_rt, ID_EX_rd, ID_EX_shamt;
    wire [31:0] ID_EX_PCBranch, ID_EX_PCJump;
    wire [5:0]  ID_EX_funct, ID_EX_opcode;

    // ── EX Stage outputs ──────────────────────────────────
    wire [31:0] EX_ALUResult, EX_WriteDataOut;
    wire        EX_Zero;
    wire [4:0]  EX_WriteReg;

    // ── EX/MEM Register outputs ───────────────────────────
    wire        EX_MEM_MemRead, EX_MEM_MemWrite, EX_MEM_MemToReg;
    wire        EX_MEM_RegWrite, EX_MEM_Branch, EX_MEM_Jump;
    wire [31:0] EX_MEM_ALUResult;
    wire        EX_MEM_Zero;
    wire [31:0] EX_MEM_WriteData;
    wire [4:0]  EX_MEM_WriteReg;
    wire [31:0] EX_MEM_PCBranch, EX_MEM_PCJump;

    // ── MEM Stage outputs ─────────────────────────────────
    wire [31:0] MEM_ReadData;

    // ── MEM/WB Register outputs ───────────────────────────
    wire        MEM_WB_MemToReg, MEM_WB_RegWrite;
    wire [31:0] MEM_WB_ReadData, MEM_WB_ALUResult;
    wire [4:0]  MEM_WB_WriteReg;

    // ── WB Stage output ───────────────────────────────────
    wire [31:0] WB_WriteData;

    // ── Branch/Jump control ───────────────────────────────
    wire PCSrc = EX_MEM_Branch & EX_MEM_Zero;

    // ── Hazard Detection ──────────────────────────────────
    hazard_detection hzd (
        .ID_EX_MemRead(ID_EX_MemRead),
        .ID_EX_Rt(ID_EX_rt),
        .IF_ID_Rs(IF_ID_instr[25:21]),
        .IF_ID_Rt(IF_ID_instr[20:16]),
        .PCWrite(PCWrite),
        .IF_ID_Write(IF_ID_Write),
        .ControlMux(ControlMux)
    );

    // ── IF Stage ─────────────────────────────────────────
    IF_pipe_stage if_stage (
        .clk(clk), .rst(rst),
        .stall(!PCWrite),
        .PCSrc(PCSrc),
        .Jump(EX_MEM_Jump),
        .PCBranch(EX_MEM_PCBranch),
        .PCJump(EX_MEM_PCJump),
        .PC4(IF_PC4),
        .instr(IF_instr)
    );

    // ── IF/ID Register ────────────────────────────────────
    pipe_reg_IF_ID if_id_reg (
        .clk(clk), .rst(rst),
        .flush(PCSrc | EX_MEM_Jump),
        .stall(!IF_ID_Write),
        .PC4_in(IF_PC4), .instr_in(IF_instr),
        .PC4_out(IF_ID_PC4), .instr_out(IF_ID_instr)
    );

    // ── ID Stage ─────────────────────────────────────────
    ID_pipe_stage id_stage (
        .clk(clk),
        .RegWrite(MEM_WB_RegWrite),
        .instr(IF_ID_instr),
        .PC4(IF_ID_PC4),
        .WriteReg(MEM_WB_WriteReg),
        .WriteData(WB_WriteData),
        .RegDst(ID_RegDst), .ALUSrc(ID_ALUSrc),
        .MemToReg(ID_MemToReg), .RegWrite_out(ID_RegWrite),
        .MemRead(ID_MemRead), .MemWrite(ID_MemWrite),
        .Branch(ID_Branch), .Jump(ID_Jump), .ALUOp(ID_ALUOp),
        .ReadData1(ID_ReadData1), .ReadData2(ID_ReadData2),
        .SignImm(ID_SignImm),
        .PCBranch(ID_PCBranch), .PCJump(ID_PCJump),
        .rs(ID_rs), .rt(ID_rt), .rd(ID_rd), .shamt(ID_shamt)
    );

    // ── ID/EX Register ────────────────────────────────────
    // When ControlMux=1 (load-use stall), flush control signals to insert bubble
    pipe_reg_ID_EX id_ex_reg (
        .clk(clk), .rst(rst),
        .flush(ControlMux), .stall(1'b0),
        .RegDst_in(ID_RegDst),   .ALUSrc_in(ID_ALUSrc),
        .MemToReg_in(ID_MemToReg), .RegWrite_in(ID_RegWrite),
        .MemRead_in(ID_MemRead),  .MemWrite_in(ID_MemWrite),
        .Branch_in(ID_Branch),    .Jump_in(ID_Jump),
        .ALUOp_in(ID_ALUOp),
        .ReadData1_in(ID_ReadData1), .ReadData2_in(ID_ReadData2),
        .SignImm_in(ID_SignImm),
        .rs_in(ID_rs), .rt_in(ID_rt), .rd_in(ID_rd), .shamt_in(ID_shamt),
        .PCBranch_in(ID_PCBranch), .PCJump_in(ID_PCJump),
        .funct_in(IF_ID_instr[5:0]), .opcode_in(IF_ID_instr[31:26]),
        .RegDst_out(ID_EX_RegDst),   .ALUSrc_out(ID_EX_ALUSrc),
        .MemToReg_out(ID_EX_MemToReg), .RegWrite_out(ID_EX_RegWrite),
        .MemRead_out(ID_EX_MemRead),  .MemWrite_out(ID_EX_MemWrite),
        .Branch_out(ID_EX_Branch),    .Jump_out(ID_EX_Jump),
        .ALUOp_out(ID_EX_ALUOp),
        .ReadData1_out(ID_EX_ReadData1), .ReadData2_out(ID_EX_ReadData2),
        .SignImm_out(ID_EX_SignImm),
        .rs_out(ID_EX_rs), .rt_out(ID_EX_rt), .rd_out(ID_EX_rd), .shamt_out(ID_EX_shamt),
        .PCBranch_out(ID_EX_PCBranch), .PCJump_out(ID_EX_PCJump),
        .funct_out(ID_EX_funct), .opcode_out(ID_EX_opcode)
    );

    // ── EX Stage ─────────────────────────────────────────
    EX_pipe_stage ex_stage (
        .RegDst(ID_EX_RegDst), .ALUSrc(ID_EX_ALUSrc), .ALUOp(ID_EX_ALUOp),
        .ReadData1(ID_EX_ReadData1), .ReadData2(ID_EX_ReadData2),
        .SignImm(ID_EX_SignImm),
        .rs(ID_EX_rs), .rt(ID_EX_rt), .rd(ID_EX_rd), .shamt(ID_EX_shamt),
        .funct(ID_EX_funct),
        .opcode(ID_EX_opcode),
        .EX_MEM_ALUResult(EX_MEM_ALUResult),
        .MEM_WB_WriteData(WB_WriteData),
        .EX_MEM_Rd(EX_MEM_WriteReg), .MEM_WB_Rd(MEM_WB_WriteReg),
        .EX_MEM_RegWrite(EX_MEM_RegWrite), .MEM_WB_RegWrite(MEM_WB_RegWrite),
        .ALUResult(EX_ALUResult), .Zero(EX_Zero),
        .WriteDataOut(EX_WriteDataOut), .WriteReg(EX_WriteReg)
    );

    // ── EX/MEM Register ───────────────────────────────────
    pipe_reg_EX_MEM ex_mem_reg (
        .clk(clk), .rst(rst), .flush(1'b0), .stall(1'b0),
        .MemRead_in(ID_EX_MemRead), .MemWrite_in(ID_EX_MemWrite),
        .MemToReg_in(ID_EX_MemToReg), .RegWrite_in(ID_EX_RegWrite),
        .Branch_in(ID_EX_Branch), .Jump_in(ID_EX_Jump),
        .ALUResult_in(EX_ALUResult), .Zero_in(EX_Zero),
        .WriteData_in(EX_WriteDataOut), .WriteReg_in(EX_WriteReg),
        .PCBranch_in(ID_EX_PCBranch), .PCJump_in(ID_EX_PCJump),
        .MemRead_out(EX_MEM_MemRead), .MemWrite_out(EX_MEM_MemWrite),
        .MemToReg_out(EX_MEM_MemToReg), .RegWrite_out(EX_MEM_RegWrite),
        .Branch_out(EX_MEM_Branch), .Jump_out(EX_MEM_Jump),
        .ALUResult_out(EX_MEM_ALUResult), .Zero_out(EX_MEM_Zero),
        .WriteData_out(EX_MEM_WriteData), .WriteReg_out(EX_MEM_WriteReg),
        .PCBranch_out(EX_MEM_PCBranch), .PCJump_out(EX_MEM_PCJump)
    );

    // ── MEM Stage ────────────────────────────────────────
    MEM_pipe_stage mem_stage (
        .clk(clk),
        .MemRead(EX_MEM_MemRead), .MemWrite(EX_MEM_MemWrite),
        .ALUResult(EX_MEM_ALUResult), .WriteData(EX_MEM_WriteData),
        .ReadData(MEM_ReadData)
    );

    // ── MEM/WB Register ───────────────────────────────────
    pipe_reg_MEM_WB mem_wb_reg (
        .clk(clk), .rst(rst), .flush(1'b0), .stall(1'b0),
        .MemToReg_in(EX_MEM_MemToReg), .RegWrite_in(EX_MEM_RegWrite),
        .ReadData_in(MEM_ReadData), .ALUResult_in(EX_MEM_ALUResult),
        .WriteReg_in(EX_MEM_WriteReg),
        .MemToReg_out(MEM_WB_MemToReg), .RegWrite_out(MEM_WB_RegWrite),
        .ReadData_out(MEM_WB_ReadData), .ALUResult_out(MEM_WB_ALUResult),
        .WriteReg_out(MEM_WB_WriteReg)
    );

    // ── WB Stage ────────────────────────────────────────
    WB_pipe_stage wb_stage (
        .MemToReg(MEM_WB_MemToReg),
        .ReadData(MEM_WB_ReadData),
        .ALUResult(MEM_WB_ALUResult),
        .WriteData(WB_WriteData)
    );

endmodule
