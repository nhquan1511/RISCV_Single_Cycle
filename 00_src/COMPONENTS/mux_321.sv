// Mux 32:1
// Module: Mux 32:1
// Date: 20/6/2026
// Update: 20/6/2026
//============================================
module mux_321 #(
  parameter WIDTH = 32
)(
  input   wire [WIDTH-1:0]  i_i [0:31],
  input   wire [4:0]        s_i,
  output  reg  [WIDTH-1:0]  y_o
);
//============================================
  wire [WIDTH-1:0] m0_y;
  wire [WIDTH-1:0] m1_y;
//============================================
  mux_161 m0 (
    .i_i(i_i[0:15]),
    .s_i(s_i[3:0]),
    .y_o(m0_y)
  );
  mux_161 m1 (
    .i_i(i_i[16:31]),
    .s_i(s_i[3:0]),
    .y_o(m1_y)
  );
//============================================
  always_comb begin
    y_o = (~{WIDTH{ s_i[4] }} & m0_y) | ({WIDTH{ s_i[4] }} & m1_y);
  end
endmodule