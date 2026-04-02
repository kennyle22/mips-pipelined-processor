module IF_pipe_stage (
    input         clk,
    input         rst,
    input         stall,
    input         PCSrc,
    input         Jump,
    input  [31:0] PCBranch,
    input  [31:0] PCJump,
    output [31:0] PC4,
    output [31:0] instr
);

    reg [31:0] PC;

    wire [31:0] PC_next = Jump    ? PCJump   :
                          PCSrc   ? PCBranch :
                                    PC + 4;

    always @(posedge clk) begin
        if (rst)
            PC <= 32'b0;
        else if (!stall)
            PC <= PC_next;
    end

    assign PC4 = PC + 4;

    instruction_mem #(.MEM_DEPTH(256)) imem (
        .addr(PC),
        .instr(instr)
    );

endmodule
