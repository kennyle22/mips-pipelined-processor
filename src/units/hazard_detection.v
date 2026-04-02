module hazard_detection (
    input        ID_EX_MemRead,
    input  [4:0] ID_EX_Rt,
    input  [4:0] IF_ID_Rs,
    input  [4:0] IF_ID_Rt,
    output reg   PCWrite,       // 0 = stall PC
    output reg   IF_ID_Write,   // 0 = stall IF/ID register
    output reg   ControlMux     // 1 = flush control signals (insert bubble into ID/EX)
);

    // Load-use hazard: LW in EX, dependent instruction in ID
    wire load_use = ID_EX_MemRead &&
                    (ID_EX_Rt == IF_ID_Rs || ID_EX_Rt == IF_ID_Rt);

    always @(*) begin
        if (load_use) begin
            PCWrite    = 1'b0;
            IF_ID_Write = 1'b0;
            ControlMux = 1'b1;
        end else begin
            PCWrite    = 1'b1;
            IF_ID_Write = 1'b1;
            ControlMux = 1'b0;
        end
    end

endmodule
