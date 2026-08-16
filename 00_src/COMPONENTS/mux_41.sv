// Mux 4:1
// Module: Mux 4:1
// Date: 20/6/2026
// Update: 20/6/2026
//============================================
module mux_41 #(
  parameter WIDTH = 32
)(
  input  wire [WIDTH-1:0] i_i [0:3],
  input  wire [1:0]       s_i,
  output reg  [WIDTH-1:0] y_o
);
//============================================
  wire [WIDTH-1:0] m0_y;
  wire [WIDTH-1:0] m1_y;
//============================================
  mux_21 m0 (
    .i_i(i_i[0:1]),
    .s_i(s_i[0]),
    .y_o(m0_y)
  );
  mux_21 m1 (
    .i_i(i_i[2:3]),
    .s_i(s_i[0]),
    .y_o(m1_y)
  );
//============================================
  always_comb begin
    y_o = (~{WIDTH{ s_i[1] }} & m0_y) | ({WIDTH{ s_i[1] }} & m1_y);
  end
endmodule