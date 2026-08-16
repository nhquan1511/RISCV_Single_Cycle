// Mux 2:1
// Module: Mux 2:1
// Date: 20/6/2026
// Update: 20/6/2026
//============================================
module mux_21 #(
  parameter WIDTH = 32
)(
  input  wire [WIDTH-1:0]   i_i [0:1],
  input  wire               s_i,
  output reg   [WIDTH-1:0]  y_o
);
  always_comb begin
    y_o = (~s_i & i_i[0]) | (s_i & i_i[1]);
  end
endmodule