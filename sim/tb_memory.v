`timescale 1ns/1ps

module tb_memory;

    // ── Instruction Memory ────────────────────────────────
    reg  [31:0] addr;
    wire [31:0] instr;

    instruction_mem #(.MEM_DEPTH(256)) imem (
        .addr(addr), .instr(instr)
    );

    // ── Data Memory ───────────────────────────────────────
    reg         clk, MemRead, MemWrite;
    reg  [31:0] daddr, WriteData;
    wire [31:0] ReadData;

    data_memory #(.MEM_DEPTH(256)) dmem (
        .clk(clk), .MemRead(MemRead), .MemWrite(MemWrite),
        .addr(daddr), .WriteData(WriteData), .ReadData(ReadData)
    );

    always #5 clk = ~clk;

    integer errors = 0;

    task check_imem;
        input [127:0] name;
        input [31:0]  expected;
        begin
            #1;
            if (instr !== expected) begin
                $display("FAIL IMEM [%s]: addr=%h got=%h expected=%h", name, addr, instr, expected);
                errors = errors + 1;
            end else
                $display("PASS IMEM [%s]", name);
        end
    endtask

    task check_dmem;
        input [127:0] name;
        input [31:0]  expected;
        begin
            #1;
            if (ReadData !== expected) begin
                $display("FAIL DMEM [%s]: addr=%h got=%h expected=%h", name, daddr, ReadData, expected);
                errors = errors + 1;
            end else
                $display("PASS DMEM [%s]", name);
        end
    endtask

    initial begin
        clk = 0; MemRead = 0; MemWrite = 0;

        // ── Instruction Memory: read program.hex words ────
        addr = 32'h00000000; check_imem("instr[0]", 32'h20010005); // addi $1,$0,5
        addr = 32'h00000004; check_imem("instr[1]", 32'h20020003); // addi $2,$0,3
        addr = 32'h00000008; check_imem("instr[2]", 32'h00221020); // add  $2,$1,$2

        // ── Data Memory: write then read ──────────────────
        daddr = 32'h00000000; WriteData = 32'hDEADBEEF; MemWrite = 1;
        @(posedge clk); #1; MemWrite = 0;
        MemRead = 1; check_dmem("DMEM write/read", 32'hDEADBEEF);

        // Write second location, verify no aliasing
        daddr = 32'h00000004; WriteData = 32'hCAFEBABE; MemWrite = 1;
        @(posedge clk); #1; MemWrite = 0;
        daddr = 32'h00000000; check_dmem("DMEM no alias [0]", 32'hDEADBEEF);
        daddr = 32'h00000004; check_dmem("DMEM no alias [4]", 32'hCAFEBABE);

        // MemRead=0 should return 0
        MemRead = 0; daddr = 32'h00000000;
        check_dmem("DMEM MemRead=0", 32'h00000000);

        // MemWrite=0: value must not change
        daddr = 32'h00000008; WriteData = 32'hFFFFFFFF; MemWrite = 0;
        @(posedge clk); #1;
        MemRead = 1; check_dmem("DMEM no write", 32'h00000000);

        if (errors == 0)
            $display("\n*** ALL TESTS PASSED ***");
        else
            $display("\n*** %0d TEST(S) FAILED ***", errors);

        $finish;
    end

endmodule
