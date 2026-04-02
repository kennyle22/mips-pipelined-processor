`timescale 1ns/1ps

module tb_register_file;

    reg         clk, RegWrite;
    reg  [4:0]  rs, rt, rd;
    reg  [31:0] WriteData;
    wire [31:0] ReadData1, ReadData2;

    integer errors = 0;

    register_file uut (
        .clk(clk), .RegWrite(RegWrite),
        .rs(rs), .rt(rt), .rd(rd),
        .WriteData(WriteData),
        .ReadData1(ReadData1), .ReadData2(ReadData2)
    );

    always #5 clk = ~clk;

    task write_reg;
        input [4:0]  reg_addr;
        input [31:0] data;
        begin
            rd = reg_addr; WriteData = data; RegWrite = 1;
            @(posedge clk); #1;
            RegWrite = 0;
        end
    endtask

    task check;
        input [127:0] name;
        input [31:0]  exp1, exp2;
        begin
            #1;
            if (ReadData1 !== exp1 || ReadData2 !== exp2) begin
                $display("FAIL [%s]: got RD1=%h RD2=%h | expected RD1=%h RD2=%h",
                         name, ReadData1, ReadData2, exp1, exp2);
                errors = errors + 1;
            end else begin
                $display("PASS [%s]", name);
            end
        end
    endtask

    initial begin
        clk = 0; RegWrite = 0;
        rs = 0; rt = 0; rd = 0; WriteData = 0;

        // Write to registers 1 and 2
        write_reg(5'd1, 32'hDEADBEEF);
        write_reg(5'd2, 32'hCAFEBABE);

        // Read both back simultaneously
        rs = 5'd1; rt = 5'd2;
        check("Read r1,r2", 32'hDEADBEEF, 32'hCAFEBABE);

        // $0 always reads as 0, even after write attempt
        write_reg(5'd0, 32'hFFFFFFFF);
        rs = 5'd0; rt = 5'd0;
        check("$zero always 0", 32'h0, 32'h0);

        // Write disabled: RegWrite=0 should not update register
        rd = 5'd3; WriteData = 32'hAAAAAAAA; RegWrite = 0;
        @(posedge clk); #1;
        rs = 5'd3; rt = 5'd0;
        check("No write when RegWrite=0", 32'h0, 32'h0);

        // Overwrite an existing register
        write_reg(5'd1, 32'h12345678);
        rs = 5'd1; rt = 5'd2;
        check("Overwrite r1", 32'h12345678, 32'hCAFEBABE);

        // Write all 31 general-purpose registers and verify
        begin: verify_all
            integer k;
            for (k = 1; k < 32; k = k + 1) begin
                rd = k[4:0]; WriteData = k * 32'h01010101; RegWrite = 1;
                @(posedge clk); #1;
                RegWrite = 0;
            end
            for (k = 1; k < 32; k = k + 1) begin
                rs = k[4:0]; rt = 5'd0;
                #1;
                if (ReadData1 !== k * 32'h01010101) begin
                    $display("FAIL [reg %0d]: got %h expected %h", k, ReadData1, k * 32'h01010101);
                    errors = errors + 1;
                end
            end
            if (errors == 0) $display("PASS [All 31 registers]");
        end

        if (errors == 0)
            $display("\n*** ALL TESTS PASSED ***");
        else
            $display("\n*** %0d TEST(S) FAILED ***", errors);

        $finish;
    end

endmodule
