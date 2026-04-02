`timescale 1ns/1ps

module tb_pipe_reg;

    reg        clk, rst, flush, stall;
    reg  [7:0] din;
    wire [7:0] dout;

    integer errors = 0;

    pipe_reg #(.WIDTH(8)) uut (
        .clk(clk), .rst(rst), .flush(flush), .stall(stall),
        .din(din), .dout(dout)
    );

    always #5 clk = ~clk;

    task check;
        input [127:0] name;
        input [7:0]   expected;
        begin
            if (dout !== expected) begin
                $display("FAIL [%s]: got=%h expected=%h", name, dout, expected);
                errors = errors + 1;
            end else
                $display("PASS [%s]", name);
        end
    endtask

    initial begin
        clk = 0; rst = 0; flush = 0; stall = 0; din = 0;

        // Normal pass-through
        din = 8'hAB;
        @(posedge clk); #1;
        check("Normal capture", 8'hAB);

        // Stall: dout must hold, din changes are ignored
        din = 8'hFF; stall = 1;
        @(posedge clk); #1;
        check("Stall hold", 8'hAB);
        stall = 0;

        // Flush: dout zeroed regardless of din
        din = 8'h55; flush = 1;
        @(posedge clk); #1;
        check("Flush zero", 8'h00);
        flush = 0;

        // Reset: dout zeroed
        din = 8'hCC;
        @(posedge clk); #1; // capture CC
        rst = 1;
        @(posedge clk); #1;
        check("Reset zero", 8'h00);
        rst = 0;

        // Flush overrides stall
        din = 8'h77; stall = 1; flush = 1;
        @(posedge clk); #1;
        check("Flush overrides stall", 8'h00);
        stall = 0; flush = 0;

        // Resume after stall
        din = 8'h42;
        @(posedge clk); #1;
        check("Resume after stall", 8'h42);

        if (errors == 0)
            $display("\n*** ALL TESTS PASSED ***");
        else
            $display("\n*** %0d TEST(S) FAILED ***", errors);

        $finish;
    end

endmodule
