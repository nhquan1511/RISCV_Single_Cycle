// PC Control Unit
// Module: PC Control Unit
// Date: 8/7/2026
// Updated: 10/7/2026
//==================================
module pccontrolunit #(
    parameter WIDTH = 32
  )(
    input  wire [WIDTH-1:0] r1_i,
    input  wire [WIDTH-1:0] r2_i,
    input  wire [2:0]       funct3_i,
    input  wire             branchsel_i [0:1],
    output reg              en_o
  );

  wire [WIDTH-1:0] sub;
  wire             cout;
  wire             overflow;
  add_subtract #(
    .WIDTH(WIDTH)
  ) subtractor (
    .a_i(r1_i),
    .b_i(r2_i),
    .mode_i(1'b1),
    .s_o(sub),
    .cout_o(cout),
    .overflow_o(overflow)
  );

//===================================
// Instruction Detector
  wire beq_detect;
  wire bne_detect;
  wire blt_detect;
  wire bge_detect;
  wire bltu_detect;
  wire bgeu_detect;

  assign beq_detect  = ~funct3_i[2] & ~funct3_i[1] & ~funct3_i[0];
  assign bne_detect  = ~funct3_i[2] & ~funct3_i[1] &  funct3_i[0];
  assign blt_detect  =  funct3_i[2] & ~funct3_i[1] & ~funct3_i[0];
  assign bge_detect  =  funct3_i[2] & ~funct3_i[1] &  funct3_i[0];
  assign bltu_detect =  funct3_i[2] &  funct3_i[1] & ~funct3_i[0];
  assign bgeu_detect =  funct3_i[2] &  funct3_i[1] &  funct3_i[0];

//===================================
  wire en_beq;
  assign en_beq = (&(~sub)) & ~overflow & beq_detect;

  wire en_bne;
  assign en_bne = ((|sub) | overflow) & bne_detect;

  wire en_blt;
  assign en_blt = (sub[WIDTH-1] ^ overflow) & blt_detect;

  wire en_bge;
  assign en_bge = (sub[WIDTH-1] ^~ overflow) & bge_detect;

  wire en_bltu;
  assign en_bltu = cout & bltu_detect;

  wire en_bgeu;
  assign en_bgeu = ~cout & bgeu_detect;

//============================================
  always_comb begin
    en_o = ((en_beq | en_bne | en_blt | en_bge | en_bltu | en_bgeu) & branchsel_i[0]) | branchsel_i[1];
  end
endmodule
