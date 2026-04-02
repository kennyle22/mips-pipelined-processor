`timescale 1ns/1ps

module tb_EX_stage;

    reg        RegDst, ALUSrc;
    reg  [1:0] ALUOp;
    reg  [31:0] ReadData1, ReadData2, SignImm;
    reg  [4:0]  rs, rt, rd, shamt;
    reg  [5:0]  funct, opcode_r;
    reg  [31:0] EX_MEM_ALUResult, MEM_WB_WriteData;
    reg  [4:0]  EX_MEM_Rd, MEM_WB_Rd;
    reg         EX_MEM_RegWrite, MEM_WB_RegWrite;

    wire [31:0] ALUResult, WriteDataOut;
    wire        Zero;
    wire [4:0]  WriteReg;

    integer errors = 0;

    EX_pipe_stage dut (
        .RegDst(RegDst), .ALUSrc(ALUSrc), .ALUOp(ALUOp),
        .ReadData1(ReadData1), .ReadData2(ReadData2), .SignImm(SignImm),
        .rs(rs), .rt(rt), .rd(rd), .shamt(shamt),
        .funct(funct), .opcode(opcode_r),
        .EX_MEM_ALUResult(EX_MEM_ALUResult), .MEM_WB_WriteData(MEM_WB_WriteData),
        .EX_MEM_Rd(EX_MEM_Rd), .MEM_WB_Rd(MEM_WB_Rd),
        .EX_MEM_RegWrite(EX_MEM_RegWrite), .MEM_WB_RegWrite(MEM_WB_RegWrite),
        .ALUResult(ALUResult), .Zero(Zero),
        .WriteDataOut(WriteDataOut), .WriteReg(WriteReg)
    );

    task check;
        input [127:0] name;
        input [31:0]  exp_result;
        input         exp_zero;
        input [4:0]   exp_wreg;
        begin
            #1;
            if (ALUResult !== exp_result || Zero !== exp_zero || WriteReg !== exp_wreg) begin
                $display("FAIL [%s]: ALUResult=%h Zero=%b WriteReg=%0d | exp %h %b %0d",
                         name, ALUResult, Zero, WriteReg, exp_result, exp_zero, exp_wreg);
                errors = errors + 1;
            end else
                $display("PASS [%s]", name);
        end
    endtask

    initial begin
        // Disable forwarding for basic tests
        EX_MEM_RegWrite=0; MEM_WB_RegWrite=0;
        EX_MEM_Rd=5'd0; MEM_WB_Rd=5'd0;
        EX_MEM_ALUResult=0; MEM_WB_WriteData=0;
        shamt=0; opcode_r=6'd0;

        // ── R-type ADD: $3 = $1 + $2 ─────────────────────
        RegDst=1; ALUSrc=0; ALUOp=2'b10;
        ReadData1=32'd10; ReadData2=32'd5;
        rs=5'd1; rt=5'd2; rd=5'd3;
        funct=6'd32;
        check("R-type ADD", 32'd15, 0, 5'd3);

        // ── R-type SUB producing zero ─────────────────────
        ReadData1=32'd7; ReadData2=32'd7;
        funct=6'd34;
        check("R-type SUB zero", 32'd0, 1, 5'd3);

        // ── I-type ADDI: rt=$2, uses SignImm ─────────────
        RegDst=0; ALUSrc=1; ALUOp=2'b11;
        ReadData1=32'd100; SignImm=32'd42;
        rs=5'd1; rt=5'd2; rd=5'd0;
        funct=6'd0; opcode_r=6'd8; // ADDI
        check("ADDI", 32'd142, 0, 5'd2);

        // ── LW address calc: uses ADD via ALUOp=00 ───────
        ALUOp=2'b00; ALUSrc=1; RegDst=0;
        ReadData1=32'd200; SignImm=32'd8;
        check("LW addr", 32'd208, 0, 5'd2);

        // ── Forwarding: EX/MEM forward to A ──────────────
        RegDst=1; ALUSrc=0; ALUOp=2'b10;
        ReadData1=32'd0; ReadData2=32'd3;
        rs=5'd5; rt=5'd6; rd=5'd7;
        EX_MEM_RegWrite=1; EX_MEM_Rd=5'd5; EX_MEM_ALUResult=32'd50;
        funct=6'd32; opcode_r=6'd0;
        check("EX/MEM fwd A", 32'd53, 0, 5'd7);

        // ── Forwarding: MEM/WB forward to B ──────────────
        EX_MEM_RegWrite=0; EX_MEM_Rd=5'd0;
        MEM_WB_RegWrite=1; MEM_WB_Rd=5'd6; MEM_WB_WriteData=32'd20;
        ReadData1=32'd10;
        check("MEM/WB fwd B", 32'd30, 0, 5'd7);

        if (errors == 0)
            $display("\n*** ALL TESTS PASSED ***");
        else
            $display("\n*** %0d TEST(S) FAILED ***", errors);

        $finish;
    end

endmodule
