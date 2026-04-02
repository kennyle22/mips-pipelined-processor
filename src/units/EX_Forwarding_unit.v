module EX_Forwarding_unit (
    input  [4:0] rs,
    input  [4:0] rt,
    input  [4:0] EX_MEM_Rd,
    input  [4:0] MEM_WB_Rd,
    input        EX_MEM_RegWrite,
    input        MEM_WB_RegWrite,
    output reg [1:0] ForwardA,
    output reg [1:0] ForwardB
);

    // ForwardA/B encoding:
    // 2'b00 = no forward, use register file output
    // 2'b10 = forward from EX/MEM (most recent result)
    // 2'b01 = forward from MEM/WB (one cycle older)

    always @(*) begin
        // ForwardA: source for ALU input A (rs)
        if (EX_MEM_RegWrite && EX_MEM_Rd != 5'b0 && EX_MEM_Rd == rs)
            ForwardA = 2'b10;
        else if (MEM_WB_RegWrite && MEM_WB_Rd != 5'b0 && MEM_WB_Rd == rs)
            ForwardA = 2'b01;
        else
            ForwardA = 2'b00;

        // ForwardB: source for ALU input B (rt)
        if (EX_MEM_RegWrite && EX_MEM_Rd != 5'b0 && EX_MEM_Rd == rt)
            ForwardB = 2'b10;
        else if (MEM_WB_RegWrite && MEM_WB_Rd != 5'b0 && MEM_WB_Rd == rt)
            ForwardB = 2'b01;
        else
            ForwardB = 2'b00;
    end

endmodule
