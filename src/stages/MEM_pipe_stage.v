module MEM_pipe_stage (
    input         clk,
    input         MemRead,
    input         MemWrite,
    input  [31:0] ALUResult,
    input  [31:0] WriteData,
    output [31:0] ReadData
);

    data_memory #(.MEM_DEPTH(256)) dmem (
        .clk(clk),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .addr(ALUResult),
        .WriteData(WriteData),
        .ReadData(ReadData)
    );

endmodule
