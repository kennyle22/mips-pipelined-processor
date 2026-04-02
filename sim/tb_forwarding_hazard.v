`timescale 1ns/1ps

module tb_forwarding_hazard;

    // ── Forwarding Unit ───────────────────────────────────
    reg  [4:0] rs, rt, EX_MEM_Rd, MEM_WB_Rd;
    reg        EX_MEM_RegWrite, MEM_WB_RegWrite;
    wire [1:0] ForwardA, ForwardB;

    EX_Forwarding_unit fwd (
        .rs(rs), .rt(rt),
        .EX_MEM_Rd(EX_MEM_Rd), .MEM_WB_Rd(MEM_WB_Rd),
        .EX_MEM_RegWrite(EX_MEM_RegWrite), .MEM_WB_RegWrite(MEM_WB_RegWrite),
        .ForwardA(ForwardA), .ForwardB(ForwardB)
    );

    // ── Hazard Detection Unit ─────────────────────────────
    reg        ID_EX_MemRead;
    reg  [4:0] ID_EX_Rt, IF_ID_Rs, IF_ID_Rt;
    wire       PCWrite, IF_ID_Write, ControlMux;

    hazard_detection hzd (
        .ID_EX_MemRead(ID_EX_MemRead),
        .ID_EX_Rt(ID_EX_Rt),
        .IF_ID_Rs(IF_ID_Rs), .IF_ID_Rt(IF_ID_Rt),
        .PCWrite(PCWrite), .IF_ID_Write(IF_ID_Write), .ControlMux(ControlMux)
    );

    integer errors = 0;

    task check_fwd;
        input [127:0] name;
        input [1:0] exp_A, exp_B;
        begin
            #1;
            if (ForwardA !== exp_A || ForwardB !== exp_B) begin
                $display("FAIL FWD [%s]: A=%b B=%b | exp A=%b B=%b",
                         name, ForwardA, ForwardB, exp_A, exp_B);
                errors = errors + 1;
            end else
                $display("PASS FWD [%s]", name);
        end
    endtask

    task check_hzd;
        input [127:0] name;
        input exp_PCWrite, exp_IF_ID_Write, exp_ControlMux;
        begin
            #1;
            if (PCWrite !== exp_PCWrite || IF_ID_Write !== exp_IF_ID_Write ||
                ControlMux !== exp_ControlMux) begin
                $display("FAIL HZD [%s]: PCW=%b IFW=%b CM=%b | exp %b %b %b",
                         name, PCWrite, IF_ID_Write, ControlMux,
                         exp_PCWrite, exp_IF_ID_Write, exp_ControlMux);
                errors = errors + 1;
            end else
                $display("PASS HZD [%s]", name);
        end
    endtask

    initial begin
        // ── Forwarding: no hazard ─────────────────────────
        rs=5'd1; rt=5'd2; EX_MEM_Rd=5'd3; MEM_WB_Rd=5'd4;
        EX_MEM_RegWrite=1; MEM_WB_RegWrite=1;
        check_fwd("No hazard", 2'b00, 2'b00);

        // EX/MEM forward to A (rs match)
        EX_MEM_Rd=5'd1;
        check_fwd("EX/MEM fwd A", 2'b10, 2'b00);

        // EX/MEM forward to B (rt match)
        EX_MEM_Rd=5'd2; rs=5'd3;
        check_fwd("EX/MEM fwd B", 2'b00, 2'b10);

        // MEM/WB forward to A (rs match, no EX/MEM match)
        EX_MEM_Rd=5'd5; rs=5'd1; MEM_WB_Rd=5'd1;
        check_fwd("MEM/WB fwd A", 2'b01, 2'b00);

        // EX/MEM takes priority over MEM/WB for same reg
        EX_MEM_Rd=5'd1; MEM_WB_Rd=5'd1;
        check_fwd("EX/MEM priority", 2'b10, 2'b00);

        // No forward when RegWrite=0 even if Rd matches
        EX_MEM_RegWrite=0;
        check_fwd("RegWrite=0 no fwd", 2'b01, 2'b00); // falls to MEM/WB

        // No forward to $0
        EX_MEM_RegWrite=1; EX_MEM_Rd=5'd0; MEM_WB_Rd=5'd0;
        rs=5'd0; rt=5'd0;
        check_fwd("No fwd to $0", 2'b00, 2'b00);

        // ── Hazard Detection: no hazard ───────────────────
        ID_EX_MemRead=0; ID_EX_Rt=5'd3; IF_ID_Rs=5'd1; IF_ID_Rt=5'd2;
        check_hzd("No hazard", 1,1,0);

        // Load-use: LW rd=$3, next instr uses $3 as rs
        ID_EX_MemRead=1; ID_EX_Rt=5'd3; IF_ID_Rs=5'd3; IF_ID_Rt=5'd2;
        check_hzd("Load-use rs", 0,0,1);

        // Load-use: LW rd=$3, next instr uses $3 as rt
        IF_ID_Rs=5'd1; IF_ID_Rt=5'd3;
        check_hzd("Load-use rt", 0,0,1);

        // No stall if MemRead=0 (not a load)
        ID_EX_MemRead=0; IF_ID_Rs=5'd3; IF_ID_Rt=5'd3;
        check_hzd("No stall non-load", 1,1,0);

        if (errors == 0)
            $display("\n*** ALL TESTS PASSED ***");
        else
            $display("\n*** %0d TEST(S) FAILED ***", errors);

        $finish;
    end

endmodule
