// LCD
// Module: LCD
// Date: 28/7/2026
//=================================
module lcd #(
  parameter WIDTH = 32
)(
  input  wire             clk_i,
  input  wire             rst_i,
  input  wire             memwrite_i,
  input  wire [WIDTH-1:0] addr_i,
  input  wire [WIDTH-1:0] d_i,
  output wire [WIDTH-1:0] d_o,
  output reg  [WIDTH-1:0] load_lcd
);

  wire hit_lcd;
  assign hit_lcd = ~(|{addr_i[31:29], ~addr_i[28], addr_i[27:15], ~addr_i[14], addr_i[13:12]});

  register_32 #(
    .WIDTH(WIDTH)
  ) lcd_reg (
    .d_i(d_i),
    .clk_i(clk_i),
    .rst_i(rst_i),
    .wr_i(hit_lcd & memwrite_i),
    .q_o(d_o)
  );
  
  always_comb begin
    load_lcd = d_o & {WIDTH{hit_lcd}};
  end
endmodule