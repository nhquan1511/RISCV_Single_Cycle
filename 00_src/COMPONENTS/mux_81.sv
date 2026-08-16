// Mux 8:1
// Module: Mux 8:1
// Date: 20/6/2026
// Update: 20/6/2026
//============================================
module mux_81 #(
  parameter WIDTH = 32
)(
  input   wire [WIDTH-1:0] i_i [0:7],
  input   wire [2:0]       s_i,
  output  reg  [WIDTH-1:0] y_o
);
//============================================
  wire [WIDTH-1:0] m0_y;
  wire [WIDTH-1:0] m1_y;
//============================================
  mux_41 m0 (
    .i_i(i_i[0:3]),
    .s_i(s_i[1:0]),
    .y_o(m0_y)
  );
  mux_41 m1 (
    .i_i(i_i[4:7]),
    .s_i(s_i[1:0]),
    .y_o(m1_y)
  );
//============================================
  always_comb begin
    y_o = (~{WIDTH{ s_i[2] }} & m0_y) | ({WIDTH{ s_i[2] }} & m1_y);
  end
endmodule