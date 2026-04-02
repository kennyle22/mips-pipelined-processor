module register_file (
    input         clk,
    input         RegWrite,
    input  [4:0]  rs, rt, rd,
    input  [31:0] WriteData,
    output [31:0] ReadData1,
    output [31:0] ReadData2
);

    reg [31:0] regs [31:0];

    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1)
            regs[i] = 32'b0;
    end

    // Synchronous write, register 0 hardwired to 0
    always @(posedge clk) begin
        if (RegWrite && rd != 5'b0)
            regs[rd] <= WriteData;
    end

    // Asynchronous read; $0 always returns 0
    assign ReadData1 = (rs == 5'b0) ? 32'b0 : regs[rs];
    assign ReadData2 = (rt == 5'b0) ? 32'b0 : regs[rt];

endmodule
