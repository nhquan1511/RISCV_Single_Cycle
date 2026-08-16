// Register (PIPO)
// Module: Register (PIPO)
// Date: 20/6/2026
// Update: 20/6/2026
//============================================
module register_32 #(
  parameter WIDTH = 32
)(
  input wire  [WIDTH-1:0]  d_i,
  input wire               clk_i,
  input wire               rst_i,
  input wire               wr_i,
  output wire [WIDTH-1:0]  q_o
);
//============================================
genvar i;
generate
    for (i = 0; i < WIDTH; i++) begin : GEN_DFF
        d_flip_flop dff (
            .d_i  (d_i[i]),
            .clk_i(clk_i),
            .rst_i(rst_i),
            .wr_i (wr_i),
            .q_o  (q_o[i])
        );
    end
endgenerate
endmodule