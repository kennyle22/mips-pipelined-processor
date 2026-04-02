`timescale 1ns/1ps

module tb_IF_stage;

    reg  clk, rst, stall, PCSrc, Jump;
    reg  [31:0] PCBranch, PCJump;
    wire [31:0] PC4, instr;

    // IF/ID register wires
    wire [31:0] IF_ID_PC4, IF_ID_instr;

    integer errors = 0;

    IF_pipe_stage dut (
        .clk(clk), .rst(rst), .stall(stall),
        .PCSrc(PCSrc), .Jump(Jump),
        .PCBranch(PCBranch), .PCJump(PCJump),
        .PC4(PC4), .instr(instr)
    );

    pipe_reg_IF_ID if_id (
        .clk(clk), .rst(rst), .flush(1'b0), .stall(stall),
        .PC4_in(PC4), .instr_in(instr),
        .PC4_out(IF_ID_PC4), .instr_out(IF_ID_instr)
    );

    always #5 clk = ~clk;

    task check;
        input [127:0] name;
        input [31:0]  exp_pc4, exp_instr;
        begin
            if (IF_ID_PC4 !== exp_pc4 || IF_ID_instr !== exp_instr) begin
                $display("FAIL [%s]: PC4=%h instr=%h | expected PC4=%h instr=%h",
                         name, IF_ID_PC4, IF_ID_instr, exp_pc4, exp_instr);
                errors = errors + 1;
            end else
                $display("PASS [%s]", name);
        end
    endtask

    initial begin
        clk = 0; rst = 1; stall = 0; PCSrc = 0; Jump = 0;
        PCBranch = 0; PCJump = 0;

        // Release reset — PC starts at 0
        @(posedge clk); #1; rst = 0;

        // Cycle 1: fetch instr[0] (0x20010005 = addi $1,$0,5)
        @(posedge clk); #1;
        check("Fetch instr[0]", 32'h4, 32'h20010005);

        // Cycle 2: sequential fetch instr[1]
        @(posedge clk); #1;
        check("Fetch instr[1]", 32'h8, 32'h20020003);

        // Stall: IF/ID register should hold
        stall = 1;
        @(posedge clk); #1;
        check("Stall hold", 32'h8, 32'h20020003);
        stall = 0;

        // Branch: redirect PC to address 0x10
        PCSrc = 1; PCBranch = 32'h10;
        @(posedge clk); #1; PCSrc = 0;
        @(posedge clk); #1;
        check("Branch redirect", 32'h14, 32'h00221024); // PC=0x10 → PC4=0x14, instr[4]

        // Jump: redirect PC to address 0x0
        Jump = 1; PCJump = 32'h0;
        @(posedge clk); #1; Jump = 0;
        @(posedge clk); #1;
        check("Jump to 0", 32'h4, 32'h20010005);

        if (errors == 0)
            $display("\n*** ALL TESTS PASSED ***");
        else
            $display("\n*** %0d TEST(S) FAILED ***", errors);

        $finish;
    end

endmodule
