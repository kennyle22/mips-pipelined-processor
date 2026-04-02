`timescale 1ns/1ps

module tb_MEM_WB;

    reg clk;
    always #5 clk = ~clk;

    // ── MEM Stage ─────────────────────────────────────────
    reg         MemRead, MemWrite;
    reg  [31:0] ALUResult, WriteData;
    wire [31:0] MemReadData;

    MEM_pipe_stage mem_stage (
        .clk(clk), .MemRead(MemRead), .MemWrite(MemWrite),
        .ALUResult(ALUResult), .WriteData(WriteData),
        .ReadData(MemReadData)
    );

    // ── MEM/WB Register ───────────────────────────────────
    reg         MemToReg_in, RegWrite_in;
    reg  [4:0]  WriteReg_in;
    reg  [31:0] ALUResult_wb;
    wire        MemToReg_out, RegWrite_out;
    wire [31:0] ReadData_out, ALUResult_out;
    wire [4:0]  WriteReg_out;

    pipe_reg_MEM_WB mem_wb (
        .clk(clk), .rst(1'b0), .flush(1'b0), .stall(1'b0),
        .MemToReg_in(MemToReg_in), .RegWrite_in(RegWrite_in),
        .ReadData_in(MemReadData), .ALUResult_in(ALUResult_wb),
        .WriteReg_in(WriteReg_in),
        .MemToReg_out(MemToReg_out), .RegWrite_out(RegWrite_out),
        .ReadData_out(ReadData_out), .ALUResult_out(ALUResult_out),
        .WriteReg_out(WriteReg_out)
    );

    // ── WB Stage ──────────────────────────────────────────
    wire [31:0] WB_WriteData;

    WB_pipe_stage wb_stage (
        .MemToReg(MemToReg_out),
        .ReadData(ReadData_out),
        .ALUResult(ALUResult_out),
        .WriteData(WB_WriteData)
    );

    integer errors = 0;

    task check;
        input [127:0] name;
        input [31:0]  expected;
        begin
            if (WB_WriteData !== expected) begin
                $display("FAIL [%s]: got=%h expected=%h", name, WB_WriteData, expected);
                errors = errors + 1;
            end else
                $display("PASS [%s]", name);
        end
    endtask

    initial begin
        clk = 0; MemRead = 0; MemWrite = 0;

        // ── SW then LW: write 0xDEADBEEF to addr 0, read it back ──
        ALUResult = 32'h00000000; WriteData = 32'hDEADBEEF; MemWrite = 1;
        @(posedge clk); #1; MemWrite = 0;

        MemRead = 1; ALUResult = 32'h00000000;
        // MEM/WB: forward as MemToReg=1 (LW result)
        MemToReg_in = 1; RegWrite_in = 1; WriteReg_in = 5'd8; ALUResult_wb = 32'h0;
        @(posedge clk); #1; MemRead = 0;
        check("LW writeback", 32'hDEADBEEF);

        // ── ALU result writeback: MemToReg=0 ─────────────
        MemToReg_in = 0; ALUResult_wb = 32'hCAFEBABE; RegWrite_in = 1; WriteReg_in = 5'd3;
        @(posedge clk); #1;
        check("ALU writeback", 32'hCAFEBABE);

        // ── RegWrite=0: WB_WriteData value doesn't matter, just verify register won't be written ──
        RegWrite_in = 0; ALUResult_wb = 32'h12345678;
        @(posedge clk); #1;
        if (RegWrite_out !== 0) begin
            $display("FAIL [RegWrite=0 gating]");
            errors = errors + 1;
        end else
            $display("PASS [RegWrite=0 gating]");

        if (errors == 0)
            $display("\n*** ALL TESTS PASSED ***");
        else
            $display("\n*** %0d TEST(S) FAILED ***", errors);

        $finish;
    end

endmodule
