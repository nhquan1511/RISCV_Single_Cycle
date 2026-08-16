// D Flip Flop
// Module: D Flip Flop
// Date: 20/06/2026
// Updated: 20/06/2026
//============================================
module d_flip_flop(
  input wire d_i,
  input wire clk_i,
  input wire rst_i,
  input wire wr_i,
  output reg q_o,
  output reg qn_o
);
// Only write when wr_i is high
  wire d_mux;
  assign d_mux = (~wr_i & q_o) | (wr_i & d_i);
//===========================================
  always_ff @(posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
      q_o <= 0;
      qn_o <= 1;
    end else begin
      q_o <= d_mux;
      qn_o <= ~d_mux;
    end
  end
endmodule