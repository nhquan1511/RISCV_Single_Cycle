//Bit Reverse
//Module: Bit Reverse
//Date: 1/7/2026
//Update: 1/7/2026
//========================================
module bit_reverse #(
  parameter WIDTH = 32
)(
  input  wire [WIDTH-1:0] rs1_i,
  input  wire             en_i,
  output wire [WIDTH-1:0] y_o
);
//========================================
  genvar i;
  wire [WIDTH-1:0] reversed_rs1;
  generate
    for (i = 0; i < WIDTH; i++) begin : bit_reverse_loop
      assign reversed_rs1[i] = rs1_i[WIDTH-1-i];
    end
  endgenerate
//========================================
  wire [WIDTH-1:0] temp_result [1:0];
  assign temp_result[0] = rs1_i;
  assign temp_result[1] = reversed_rs1;
  
  mux_21 #(
    .WIDTH(WIDTH)
  ) mux (
    .i_i(temp_result),
    .s_i(en_i),
    .y_o(y_o)
  );
endmodule
