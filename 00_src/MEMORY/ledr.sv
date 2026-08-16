// Red LEDs
// Module: LEDr
// Date: 26/7/2026
//=====================================
module ledr #(
  parameter WIDTH = 32
)(
  input  wire             clk_i,
  input  wire             rst_i,
  input  wire             memwrite_i,
  input  wire [WIDTH-1:0] addr_i,
  input  wire [WIDTH-1:0] d_i,
  output wire [WIDTH-1:0] d_o,
  output reg  [WIDTH-1:0] load_ledr
);

  wire hit_ledr;
  assign hit_ledr = ~(|{addr_i[31:29], ~addr_i[28], addr_i[27:12]});

  register_32 #(
    .WIDTH(WIDTH)
  ) ledr_reg (
    .d_i(d_i),
    .clk_i(clk_i),
    .rst_i(rst_i),
    .wr_i(hit_ledr & memwrite_i),
    .q_o(d_o)
  );

  always_comb begin
    load_ledr = d_o & {WIDTH{hit_ledr}};
  end
endmodule