module WB_pipe_stage (
    input         MemToReg,
    input  [31:0] ReadData,
    input  [31:0] ALUResult,
    output [31:0] WriteData
);

    assign WriteData = MemToReg ? ReadData : ALUResult;

endmodule
