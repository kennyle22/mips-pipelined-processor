module ALU (
    input  [31:0] A,
    input  [31:0] B,
    input  [3:0]  ALUControl,
    input  [4:0]  shamt,        // shift amount from instruction [10:6]
    output reg [31:0] Result,
    output Zero
);

    localparam AND = 4'b0000;
    localparam OR  = 4'b0001;
    localparam ADD = 4'b0010;
    localparam SUB = 4'b0110;
    localparam SLT = 4'b0111;
    localparam SLL = 4'b1000;
    localparam SRL = 4'b1001;
    localparam LUI = 4'b1010;
    localparam NOR = 4'b1100;

    always @(*) begin
        case (ALUControl)
            AND: Result = A & B;
            OR:  Result = A | B;
            ADD: Result = A + B;
            SUB: Result = A - B;
            SLT: Result = ($signed(A) < $signed(B)) ? 32'd1 : 32'd0;
            SLL: Result = B << shamt;
            SRL: Result = B >> shamt;
            LUI: Result = {B[15:0], 16'b0};
            NOR: Result = ~(A | B);
            default: Result = 32'b0;
        endcase
    end

    assign Zero = (Result == 32'b0);

endmodule
