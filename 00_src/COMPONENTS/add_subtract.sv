// Add Subtract 4 bits
// Module: Add Subtract 4 bits
// Date: 20/6/2026 
// Update: 20/6/2026
//============================================
module add_subtract #(
  parameter WIDTH = 4
  )(
  input wire [WIDTH-1:0] a_i,
  input wire [WIDTH-1:0] b_i,
  input wire             mode_i, // 0 is add, 1 is subtract
  output reg [WIDTH-1:0] s_o,
  output reg             cout_o,
  output reg             overflow_o
);
//============================================
wire [WIDTH-1:0] temp;
genvar i;
generate
  for (i = 0; i < WIDTH; i++) begin : full_adder_gen
    if (i == 0) begin
      full_adder fa0 (
        .a_i   (a_i[i]),
        .b_i   (b_i[i] ^ mode_i),
        .cin_i (mode_i),
        .s_o   (s_o[i]),
        .cout_o(temp[i])
      );
    end else begin
      full_adder fai (
        .a_i   (a_i[i]),
        .b_i   (b_i[i] ^ mode_i),
        .cin_i (temp[i-1]),
        .s_o   (s_o[i]),
        .cout_o(temp[i])
      );
    end
  end
assign cout_o = temp[WIDTH-1] ^ mode_i;
assign overflow_o = temp[WIDTH-1] ^ temp[WIDTH-2];
endgenerate
endmodule