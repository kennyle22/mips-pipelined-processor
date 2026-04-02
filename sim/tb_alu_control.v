`timescale 1ns/1ps

module tb_alu_control;

    reg  [1:0] ALUOp;
    reg  [5:0] funct, opcode;
    wire [3:0] ALUControl;

    integer errors = 0;

    alu_control uut (
        .ALUOp(ALUOp), .funct(funct), .opcode(opcode),
        .ALUControl(ALUControl)
    );

    task check;
        input [127:0] name;
        input [3:0]   expected;
        begin
            #1;
            if (ALUControl !== expected) begin
                $display("FAIL [%s]: ALUOp=%b funct=%0d opcode=%0d | got %b | expected %b",
                         name, ALUOp, funct, opcode, ALUControl, expected);
                errors = errors + 1;
            end else begin
                $display("PASS [%s]", name);
            end
        end
    endtask

    initial begin
        // ── ALUOp=00: always ADD (LW/SW address calc) ────
        ALUOp = 2'b00; funct = 6'd0; opcode = 6'd0;
        check("00 ADD", 4'b0010);

        // ── ALUOp=01: always SUB (branch compare) ────────
        ALUOp = 2'b01; funct = 6'd0; opcode = 6'd0;
        check("01 SUB", 4'b0110);

        // ── ALUOp=10: R-type, decode funct ───────────────
        ALUOp = 2'b10; opcode = 6'd0;
        funct = 6'd32; check("R ADD",  4'b0010);
        funct = 6'd34; check("R SUB",  4'b0110);
        funct = 6'd36; check("R AND",  4'b0000);
        funct = 6'd37; check("R OR",   4'b0001);
        funct = 6'd39; check("R NOR",  4'b1100);
        funct = 6'd42; check("R SLT",  4'b0111);
        funct = 6'd0;  check("R SLL",  4'b1000);
        funct = 6'd2;  check("R SRL",  4'b1001);
        funct = 6'd63; check("R DEF",  4'b0010); // unknown funct → ADD

        // ── ALUOp=11: I-type, decode opcode ──────────────
        ALUOp = 2'b11; funct = 6'd0;
        opcode = 6'd8;  check("ADDI",    4'b0010);
        opcode = 6'd10; check("SLTI",    4'b0111);
        opcode = 6'd12; check("ANDI",    4'b0000);
        opcode = 6'd13; check("ORI",     4'b0001);
        opcode = 6'd15; check("LUI",     4'b1010);
        opcode = 6'd63; check("I DEF",   4'b0010); // unknown opcode → ADD

        if (errors == 0)
            $display("\n*** ALL TESTS PASSED ***");
        else
            $display("\n*** %0d TEST(S) FAILED ***", errors);

        $finish;
    end

endmodule
