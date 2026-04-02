`timescale 1ns/1ps

module tb_control_unit;

    reg  [5:0] opcode;
    wire       RegDst, ALUSrc, MemToReg, RegWrite;
    wire       MemRead, MemWrite, Branch, Jump;
    wire [1:0] ALUOp;

    integer errors = 0;

    control_unit uut (
        .opcode(opcode),
        .RegDst(RegDst), .ALUSrc(ALUSrc), .MemToReg(MemToReg), .RegWrite(RegWrite),
        .MemRead(MemRead), .MemWrite(MemWrite), .Branch(Branch), .Jump(Jump),
        .ALUOp(ALUOp)
    );

    // Pack all outputs for easy comparison: {RegDst,ALUSrc,MemToReg,RegWrite,MemRead,MemWrite,Branch,Jump,ALUOp}
    wire [10:0] ctrl = {RegDst, ALUSrc, MemToReg, RegWrite, MemRead, MemWrite, Branch, Jump, ALUOp};

    task check;
        input [63:0]  name;
        input [10:0]  expected;
        begin
            #1;
            if (ctrl !== expected) begin
                $display("FAIL [%s]: opcode=%0d | got %b | expected %b", name, opcode, ctrl, expected);
                errors = errors + 1;
            end else begin
                $display("PASS [%s]", name);
            end
        end
    endtask

    initial begin
        // ctrl bit order: {RegDst, ALUSrc, MemToReg, RegWrite, MemRead, MemWrite, Branch, Jump, ALUOp[1:0]}
        opcode = 6'd0;  check("R-TYPE", 11'b1_0_0_1_0_0_0_0_10);
        opcode = 6'd35; check("LW",     11'b0_1_1_1_1_0_0_0_00);
        opcode = 6'd43; check("SW",     11'b0_1_0_0_0_1_0_0_00);
        opcode = 6'd4;  check("BEQ",    11'b0_0_0_0_0_0_1_0_01);
        opcode = 6'd5;  check("BNE",    11'b0_0_0_0_0_0_1_0_01);
        opcode = 6'd8;  check("ADDI",   11'b0_1_0_1_0_0_0_0_11);
        opcode = 6'd10; check("SLTI",   11'b0_1_0_1_0_0_0_0_11);
        opcode = 6'd12; check("ANDI",   11'b0_1_0_1_0_0_0_0_11);
        opcode = 6'd13; check("ORI",    11'b0_1_0_1_0_0_0_0_11);
        opcode = 6'd15; check("LUI",    11'b0_1_0_1_0_0_0_0_11);
        opcode = 6'd2;  check("J",      11'b0_0_0_0_0_0_0_1_00);
        opcode = 6'd63; check("DEFAULT",11'b0_0_0_0_0_0_0_0_00);

        if (errors == 0)
            $display("\n*** ALL TESTS PASSED ***");
        else
            $display("\n*** %0d TEST(S) FAILED ***", errors);

        $finish;
    end

endmodule
