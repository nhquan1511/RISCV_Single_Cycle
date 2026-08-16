//7-Segment LEDs
// Module: 7SegLED
// Date: 27/7/2026
//====================================
module hex7seg #(
  parameter WIDTH = 32
)(
  input  wire             clk_i,
  input  wire             rst_i,
  input  wire             memwrite_i,
  input  wire [WIDTH-1:0] addr_i,
  input  wire [WIDTH-1:0] d_i,
  output reg  [6:0]       d_o [0:7],
  output reg  [WIDTH-1:0] load_hex7seg_0to3,
  output reg  [WIDTH-1:0] load_hex7seg_4to7
);
//===================================
  wire hit_hex7seg_0to3;
  wire hit_hex7seg_4to7;
  assign hit_hex7seg_0to3 = ~(|{addr_i[31:29], ~addr_i[28], addr_i[27:14], ~addr_i[13], addr_i[12]});
  assign hit_hex7seg_4to7 = ~(|{addr_i[31:29], ~addr_i[28], addr_i[27:14], ~addr_i[13], ~addr_i[12]});
//===================================

  wire [WIDTH-1:0] q_0to3;
  register_32 #(
    .WIDTH(WIDTH)
  ) reg0to3 (
    .d_i(d_i),
    .clk_i(clk_i),
    .rst_i(rst_i),
    .wr_i(hit_hex7seg_0to3 & memwrite_i),
    .q_o(q_0to3)
  );
  
  wire [WIDTH-1:0] q_4to7;
  register_32 #(
    .WIDTH(WIDTH)
  ) reg4to7 (
    .d_i(d_i),
    .clk_i(clk_i),
    .rst_i(rst_i),
    .wr_i(hit_hex7seg_4to7 & memwrite_i),
    .q_o(q_4to7)
  );

  always_comb begin
    d_o[0] = q_0to3[6:0];
    d_o[1] = q_0to3[14:8];
    d_o[2] = q_0to3[22:16];
    d_o[3] = q_0to3[30:24];

    d_o[4] = q_4to7[6:0];
    d_o[5] = q_4to7[14:8];
    d_o[6] = q_4to7[22:16];
    d_o[7] = q_4to7[30:24];

    load_hex7seg_0to3 = q_0to3 & {WIDTH{hit_hex7seg_0to3}};
    load_hex7seg_4to7 = q_4to7 & {WIDTH{hit_hex7seg_4to7}};
  end
endmodule