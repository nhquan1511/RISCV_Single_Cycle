// Full Adder
// Module: Full Adder 1 bit
// Date: 19/06/2026
// Updated: 19/06/2026
//============================================ 
module full_adder(
  input wire a_i,
  input wire b_i,
  input wire cin_i,
  output reg s_o,
  output reg cout_o
);
  always_comb begin
    s_o = a_i ^ b_i ^ cin_i; 
    cout_o = (a_i & b_i) | (cin_i & (a_i ^ b_i));
  end
endmodule