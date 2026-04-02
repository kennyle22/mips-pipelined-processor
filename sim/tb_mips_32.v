`timescale 1ns/1ps

// Integration testbench: runs programs through the full 5-stage pipeline
// and probes the register file write-back to verify results.
module tb_mips_32;

    reg clk, rst;
    always #5 clk = ~clk;

    mips_32 dut (.clk(clk), .rst(rst));

    // Probe register file inside the ID stage for result checking
    // Path: dut -> id_stage -> rf -> regs
    wire [31:0] reg1  = dut.id_stage.rf.regs[1];
    wire [31:0] reg2  = dut.id_stage.rf.regs[2];
    wire [31:0] reg3  = dut.id_stage.rf.regs[3];
    wire [31:0] reg8  = dut.id_stage.rf.regs[8];

    integer errors = 0;

    task check_reg;
        input [127:0] name;
        input [31:0]  actual, expected;
        begin
            if (actual !== expected) begin
                $display("FAIL [%s]: got %h expected %h", name, actual, expected);
                errors = errors + 1;
            end else
                $display("PASS [%s]", name);
        end
    endtask

    // ── Test 1: basic_rtype.hex ───────────────────────────
    // addi $1,$0,5  → $1=5
    // addi $2,$0,3  → $2=3
    // add  $3,$1,$2 → $3=8  (EX/MEM forward)
    // sub  $3,$1,$2 → $3=2
    // and  $3,$1,$2 → $3=1
    // or   $3,$1,$2 → $3=7
    task test_basic_rtype;
        integer i;
        begin
            $display("\n=== Test: basic R-type + forwarding ===");
            // Load program
            $readmemh("sim/test_programs/basic_rtype.hex", dut.if_stage.imem.mem);

            rst = 1; @(posedge clk); @(posedge clk); #1;
            rst = 0;

            // Pipeline needs ~10 cycles to drain all 6 instructions
            repeat(12) @(posedge clk);
            #1;

            check_reg("$1 = 5",  reg1, 32'd5);
            check_reg("$2 = 3",  reg2, 32'd3);
            check_reg("$3 = 7",  reg3, 32'd7); // last OR result
        end
    endtask

    initial begin
        clk = 0; rst = 1;

        test_basic_rtype;

        #10;
        if (errors == 0)
            $display("\n*** ALL INTEGRATION TESTS PASSED ***");
        else
            $display("\n*** %0d INTEGRATION TEST(S) FAILED ***", errors);

        $finish;
    end

endmodule
