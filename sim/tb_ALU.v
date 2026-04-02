`timescale 1ns/1ps

module tb_ALU;

    reg  [31:0] A, B;
    reg  [3:0]  ALUControl;
    reg  [4:0]  shamt;
    wire [31:0] Result;
    wire        Zero;

    integer errors = 0;

    ALU uut (
        .A(A), .B(B),
        .ALUControl(ALUControl),
        .shamt(shamt),
        .Result(Result),
        .Zero(Zero)
    );

    task check;
        input [127:0] name;
        input [31:0]  expected_result;
        input         expected_zero;
        begin
            #1;
            if (Result !== expected_result || Zero !== expected_zero) begin
                $display("FAIL [%s]: A=%h B=%h shamt=%0d | got Result=%h Zero=%b | expected Result=%h Zero=%b",
                         name, A, B, shamt, Result, Zero, expected_result, expected_zero);
                errors = errors + 1;
            end else begin
                $display("PASS [%s]", name);
            end
        end
    endtask

    initial begin
        shamt = 0;

        // ── AND ──────────────────────────────────────────
        ALUControl = 4'b0000;
        A = 32'hFF00FF00; B = 32'h0F0F0F0F; check("AND basic",      32'h0F000F00, 0);
        A = 32'hFFFFFFFF; B = 32'h00000000; check("AND zero result", 32'h00000000, 1);

        // ── OR ───────────────────────────────────────────
        ALUControl = 4'b0001;
        A = 32'hF0F0F0F0; B = 32'h0F0F0F0F; check("OR all ones",   32'hFFFFFFFF, 0);
        A = 32'h00000000; B = 32'h00000000; check("OR zero result", 32'h00000000, 1);

        // ── ADD ──────────────────────────────────────────
        ALUControl = 4'b0010;
        A = 32'd15;       B = 32'd10;       check("ADD basic",    32'd25,       0);
        A = 32'hFFFFFFFF; B = 32'h00000001; check("ADD overflow", 32'h00000000, 1);
        A = 32'h00000000; B = 32'h00000000; check("ADD zeros",    32'h00000000, 1);

        // ── SUB ──────────────────────────────────────────
        ALUControl = 4'b0110;
        A = 32'd20;       B = 32'd5;        check("SUB basic",       32'd15,       0);
        A = 32'd5;        B = 32'd5;        check("SUB zero result",  32'd0,        1);
        A = 32'd0;        B = 32'd1;        check("SUB negative",     32'hFFFFFFFF, 0);

        // ── SLT ──────────────────────────────────────────
        ALUControl = 4'b0111;
        A = 32'd3;        B = 32'd5;        check("SLT true",    32'd1, 0);
        A = 32'd5;        B = 32'd3;        check("SLT false",   32'd0, 1);
        A = 32'hFFFFFFFF; B = 32'd0;        check("SLT neg<pos", 32'd1, 0);
        A = 32'd0;        B = 32'hFFFFFFFF; check("SLT pos<neg", 32'd0, 1);

        // ── SLL ──────────────────────────────────────────
        ALUControl = 4'b1000;
        A = 32'h0; B = 32'h00000001; shamt = 4;  check("SLL by 4",  32'h00000010, 0);
        A = 32'h0; B = 32'h00000001; shamt = 31; check("SLL by 31", 32'h80000000, 0);
        A = 32'h0; B = 32'h00000001; shamt = 0;  check("SLL by 0",  32'h00000001, 0);

        // ── SRL ──────────────────────────────────────────
        ALUControl = 4'b1001;
        A = 32'h0; B = 32'h80000000; shamt = 1; check("SRL by 1", 32'h40000000, 0);
        A = 32'h0; B = 32'h00000010; shamt = 4; check("SRL by 4", 32'h00000001, 0);
        A = 32'h0; B = 32'h00000001; shamt = 1; check("SRL to 0", 32'h00000000, 1);

        // ── LUI ──────────────────────────────────────────
        ALUControl = 4'b1010; shamt = 0;
        A = 32'h0; B = 32'h0000ABCD; check("LUI basic", 32'hABCD0000, 0);
        A = 32'h0; B = 32'h00000000; check("LUI zero",  32'h00000000, 1);

        // ── NOR ──────────────────────────────────────────
        ALUControl = 4'b1100;
        A = 32'h00000000; B = 32'h00000000; check("NOR all zeros", 32'hFFFFFFFF, 0);
        A = 32'hFFFFFFFF; B = 32'h00000000; check("NOR mixed",     32'h00000000, 1);

        // ── Default ──────────────────────────────────────
        ALUControl = 4'b1111;
        A = 32'hDEADBEEF; B = 32'hDEADBEEF; check("DEFAULT zero", 32'h00000000, 1);

        // ── Summary ──────────────────────────────────────
        if (errors == 0)
            $display("\n*** ALL TESTS PASSED ***");
        else
            $display("\n*** %0d TEST(S) FAILED ***", errors);

        $finish;
    end

endmodule
