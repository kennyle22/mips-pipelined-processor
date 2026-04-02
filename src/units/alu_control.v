module alu_control (
    input  [1:0] ALUOp,
    input  [5:0] funct,
    input  [5:0] opcode,
    output reg [3:0] ALUControl
);

    // ALUOp: 00=ADD (LW/SW), 01=SUB (branch), 10=R-type (use funct), 11=I-type (use opcode)
    // ALUControl encoding matches ALU.v localparams

    localparam AND = 4'b0000;
    localparam OR  = 4'b0001;
    localparam ADD = 4'b0010;
    localparam SUB = 4'b0110;
    localparam SLT = 4'b0111;
    localparam SLL = 4'b1000;
    localparam SRL = 4'b1001;
    localparam LUI = 4'b1010;
    localparam NOR = 4'b1100;

    // R-type funct codes
    localparam F_SLL  = 6'd0;
    localparam F_SRL  = 6'd2;
    localparam F_ADD  = 6'd32;
    localparam F_SUB  = 6'd34;
    localparam F_AND  = 6'd36;
    localparam F_OR   = 6'd37;
    localparam F_NOR  = 6'd39;
    localparam F_SLT  = 6'd42;

    // I-type opcodes (used when ALUOp==11)
    localparam OP_ADDI = 6'd8;
    localparam OP_SLTI = 6'd10;
    localparam OP_ANDI = 6'd12;
    localparam OP_ORI  = 6'd13;
    localparam OP_LUI  = 6'd15;

    always @(*) begin
        case (ALUOp)
            2'b00: ALUControl = ADD;
            2'b01: ALUControl = SUB;
            2'b10: begin
                case (funct)
                    F_SLL: ALUControl = SLL;
                    F_SRL: ALUControl = SRL;
                    F_ADD: ALUControl = ADD;
                    F_SUB: ALUControl = SUB;
                    F_AND: ALUControl = AND;
                    F_OR:  ALUControl = OR;
                    F_NOR: ALUControl = NOR;
                    F_SLT: ALUControl = SLT;
                    default: ALUControl = ADD;
                endcase
            end
            2'b11: begin
                case (opcode)
                    OP_ADDI: ALUControl = ADD;
                    OP_SLTI: ALUControl = SLT;
                    OP_ANDI: ALUControl = AND;
                    OP_ORI:  ALUControl = OR;
                    OP_LUI:  ALUControl = LUI;
                    default: ALUControl = ADD;
                endcase
            end
            default: ALUControl = ADD;
        endcase
    end

endmodule
