module data_memory #(parameter MEM_DEPTH = 256) (
    input         clk,
    input         MemRead,
    input         MemWrite,
    input  [31:0] addr,
    input  [31:0] WriteData,
    output [31:0] ReadData
);

    reg [31:0] mem [0:MEM_DEPTH-1];

    integer i;
    initial begin
        for (i = 0; i < MEM_DEPTH; i = i + 1)
            mem[i] = 32'b0;
    end

    // Synchronous write
    always @(posedge clk) begin
        if (MemWrite)
            mem[addr[31:2]] <= WriteData;
    end

    // Asynchronous read
    assign ReadData = MemRead ? mem[addr[31:2]] : 32'b0;

endmodule
