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
  always_ff @(posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
      q_o <= 0;
    end else if (wr_i) begin
      q_o <= d_i;
    end
end
endmodule
