`timescale 1ns/1ps

module tb_ID_stage;

    reg         clk, RegWrite;
    reg  [31:0] instr, PC4, WriteData;
    reg  [4:0]  WriteReg;

    wire        RegDst, ALUSrc, MemToReg, RegWrite_out;
    wire        MemRead, MemWrite, Branch, Jump;
    wire [1:0]  ALUOp;
    wire [31:0] ReadData1, ReadData2, SignImm, PCBranch, PCJump;
    wire [4:0]  rs, rt, rd, shamt;

    integer errors = 0;

    ID_pipe_stage dut (
        .clk(clk), .RegWrite(RegWrite),
        .instr(instr), .PC4(PC4),
        .WriteReg(WriteReg), .WriteData(WriteData),
        .RegDst(RegDst), .ALUSrc(ALUSrc), .MemToReg(MemToReg),
        .RegWrite_out(RegWrite_out), .MemRead(MemRead), .MemWrite(MemWrite),
        .Branch(Branch), .Jump(Jump), .ALUOp(ALUOp),
        .ReadData1(ReadData1), .ReadData2(ReadData2),
        .SignImm(SignImm), .PCBranch(PCBranch), .PCJump(PCJump),
        .rs(rs), .rt(rt), .rd(rd), .shamt(shamt)
    );

    always #5 clk = ~clk;

    task check_ctrl;
        input [127:0] name;
        input exp_RegDst, exp_ALUSrc, exp_RegWrite, exp_MemRead, exp_MemWrite, exp_Branch;
        input [1:0] exp_ALUOp;
        begin
            #1;
            if (RegDst     !== exp_RegDst  || ALUSrc    !== exp_ALUSrc  ||
                RegWrite_out !== exp_RegWrite || MemRead !== exp_MemRead  ||
                MemWrite   !== exp_MemWrite || Branch    !== exp_Branch   ||
                ALUOp      !== exp_ALUOp) begin
                $display("FAIL ctrl [%s]", name);
                errors = errors + 1;
            end else
                $display("PASS ctrl [%s]", name);
        end
    endtask

    task check_data;
        input [127:0] name;
        input [31:0] exp_SignImm, exp_PCBranch, exp_PCJump;
        begin
            #1;
            if (SignImm !== exp_SignImm || PCBranch !== exp_PCBranch || PCJump !== exp_PCJump) begin
                $display("FAIL data [%s]: SignImm=%h PCBranch=%h PCJump=%h | exp %h %h %h",
                         name, SignImm, PCBranch, PCJump, exp_SignImm, exp_PCBranch, exp_PCJump);
                errors = errors + 1;
            end else
                $display("PASS data [%s]", name);
        end
    endtask

    initial begin
        clk = 0; RegWrite = 0; WriteReg = 0; WriteData = 0;
        PC4 = 32'h00000008; // assume PC+4 = 8

        // ── R-type: add $3,$1,$2 (opcode=0, funct=32) ────
        // Instruction: 000000 00001 00010 00011 00000 100000
        instr = 32'b000000_00001_00010_00011_00000_100000;
        check_ctrl("R-type ctrl", 1,0,1,0,0,0, 2'b10);
        if (rd !== 5'd3 || rs !== 5'd1 || rt !== 5'd2)
            $display("FAIL [R-type fields]");
        else $display("PASS [R-type fields]");

        // ── LW: lw $5, 4($2) (opcode=35) ─────────────────
        // Instruction: 100011 00010 00101 0000000000000100
        instr = 32'b100011_00010_00101_0000000000000100;
        check_ctrl("LW ctrl", 0,1,1,1,0,0, 2'b00);
        check_data("LW imm/branch/jump",
            32'h00000004,   // SignImm = sign_ext(4) = 4
            32'h00000018,   // PCBranch = PC4(8) + (4<<2) = 24
            32'h01140010);  // PCJump = {PC4[31:28]=0, instr[25:0]<<2}

        // ── SW: sw $5, -4($2) (opcode=43, imm=0xFFFC) ────
        instr = 32'b101011_00010_00101_1111111111111100;
        check_ctrl("SW ctrl", 0,1,0,0,1,0, 2'b00);
        if (SignImm !== 32'hFFFFFFFC)
            $display("FAIL [SW sign-extend negative]");
        else $display("PASS [SW sign-extend negative]");

        // ── BEQ: beq $1,$2, offset=3 (opcode=4) ──────────
        instr = 32'b000100_00001_00010_0000000000000011;
        check_ctrl("BEQ ctrl", 0,0,0,0,0,1, 2'b01);
        if (PCBranch !== 32'h00000008 + (32'h3 << 2))
            $display("FAIL [BEQ PCBranch]");
        else $display("PASS [BEQ PCBranch]");

        // ── Register writeback via register file ──────────
        WriteReg = 5'd7; WriteData = 32'hABCD1234; RegWrite = 1;
        @(posedge clk); #1; RegWrite = 0;
        instr = 32'b000000_00111_00000_00000_00000_100000; // rs=$7
        #1;
        if (ReadData1 !== 32'hABCD1234)
            $display("FAIL [RegFile writeback]");
        else $display("PASS [RegFile writeback]");

        if (errors == 0)
            $display("\n*** ALL TESTS PASSED ***");
        else
            $display("\n*** %0d TEST(S) FAILED ***", errors);

        $finish;
    end

endmodule
