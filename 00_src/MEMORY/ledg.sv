// Green LEDs
// Module: LEDg
// Date: 26/7/2026
//=====================================
module ledg #(
  parameter WIDTH = 32
)(
  input  wire             clk_i,
  input  wire             rst_i,
  input  wire             memwrite_i,
  input  wire [WIDTH-1:0] addr_i,
  input  wire [WIDTH-1:0] d_i,
  output wire [WIDTH-1:0] d_o,
  output reg  [WIDTH-1:0] load_ledg
);

  wire hit_ledg;
  assign hit_ledg = ~(|{addr_i[31:29], ~addr_i[28], addr_i[27:13], ~addr_i[12]});

  register_32 #(
    .WIDTH(WIDTH)
  ) ledg_reg (
    .d_i(d_i),
    .clk_i(clk_i),
    .rst_i(rst_i),
    .wr_i(hit_ledg & memwrite_i),
    .q_o(d_o)
  );

  always_comb begin
    load_ledg = d_o & {WIDTH{hit_ledg}};
  end
endmodule