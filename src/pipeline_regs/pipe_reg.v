module pipe_reg #(parameter WIDTH = 32) (
    input                  clk,
    input                  rst,
    input                  flush,
    input                  stall,
    input      [WIDTH-1:0] din,
    output reg [WIDTH-1:0] dout
);

    always @(posedge clk) begin
        if (rst || flush)
            dout <= {WIDTH{1'b0}};
        else if (!stall)
            dout <= din;
    end

endmodule
