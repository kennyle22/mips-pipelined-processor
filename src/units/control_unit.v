module control_unit (
    input  [5:0] opcode,
    output reg   RegDst,
    output reg   ALUSrc,
    output reg   MemToReg,
    output reg   RegWrite,
    output reg   MemRead,
    output reg   MemWrite,
    output reg   Branch,
    output reg   Jump,
    output reg [1:0] ALUOp
);

    localparam R_TYPE = 6'd0;
    localparam LW     = 6'd35;
    localparam SW     = 6'd43;
    localparam BEQ    = 6'd4;
    localparam BNE    = 6'd5;
    localparam ADDI   = 6'd8;
    localparam SLTI   = 6'd10;
    localparam ANDI   = 6'd12;
    localparam ORI    = 6'd13;
    localparam LUI    = 6'd15;
    localparam J      = 6'd2;

    // ALUOp encoding: 00=ADD, 01=SUB, 10=R-type (use funct), 11=I-type ALU
    always @(*) begin
        {RegDst, ALUSrc, MemToReg, RegWrite, MemRead, MemWrite, Branch, Jump, ALUOp} = 11'b0;
        case (opcode)
            R_TYPE: {RegDst, RegWrite, ALUOp}            = {1'b1, 1'b1, 2'b10};
            LW:     {ALUSrc, MemToReg, RegWrite, MemRead} = 4'b1111;
            SW:     {ALUSrc, MemWrite}                    = 2'b11;
            BEQ, BNE:             {Branch, ALUOp}           = {1'b1, 2'b01};
            ADDI, SLTI, ANDI,
            ORI,  LUI:            {ALUSrc, RegWrite, ALUOp} = {1'b1, 1'b1, 2'b11};
            J:                    Jump                      = 1'b1;
        endcase
    end

endmodule
