module instruction_mem #(parameter MEM_DEPTH = 256) (
    input  [31:0] addr,
    output [31:0] instr
);

    reg [31:0] mem [0:MEM_DEPTH-1];

    initial $readmemh("sim/test_programs/program.hex", mem);

    // Word-addressed: drop bottom 2 bits
    assign instr = mem[addr[31:2]];

endmodule
