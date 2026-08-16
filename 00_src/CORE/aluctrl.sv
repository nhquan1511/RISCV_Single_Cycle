// ALU Control
// Module: ALU Control
// Date: 4/7/2026
//Updated: 4/7/2026
//========================================
module aluctrl (
  input  wire [6:0] funct7_i,
  input  wire [2:0] funct3_i,
  input  wire [1:0] aluop_i,
  output wire  [3:0] aluctrl_o
);
//========================================
  wire add_detect;
  wire sub_detect;
  wire and_detect;
  wire or_detect;
  wire xor_detect;
  wire sll_detect;
  wire srl_detect;
  wire sra_detect;
  wire slt_detect;
  wire sltu_detect;

  assign add_detect = ~funct7_i[5] & ~funct3_i[2] & ~funct3_i[1] & ~funct3_i[0];
  assign sub_detect =  funct7_i[5] & ~funct3_i[2] & ~funct3_i[1] & ~funct3_i[0];
  assign and_detect =  funct3_i[2] &  funct3_i[1] &  funct3_i[0];
  assign or_detect =   funct3_i[2] &  funct3_i[1] & ~funct3_i[0];
  assign xor_detect =  funct3_i[2] & ~funct3_i[1] & ~funct3_i[0];
  assign sll_detect = ~funct7_i[5] & ~funct3_i[2] & ~funct3_i[1] &  funct3_i[0];
  assign srl_detect = ~funct7_i[5] &  funct3_i[2] & ~funct3_i[1] &  funct3_i[0];
  assign sra_detect =  funct7_i[5] &  funct3_i[2] & ~funct3_i[1] &  funct3_i[0];
  assign slt_detect = ~funct3_i[2] &  funct3_i[1] & ~funct3_i[0];
  assign sltu_detect= ~funct3_i[2] &  funct3_i[1] &  funct3_i[0];

//=======================================
  wire [3:0] aluctrl_temp [0:3];

  assign aluctrl_temp[0] = 4'b0000; // ADD
  assign aluctrl_temp[1] = (4'b0000 & {4{add_detect}}) | (4'b0001 & {4{sub_detect}}) | (4'b0111 & {4{xor_detect}}) | (4'b0010 & {4{and_detect}}) | 
                           (4'b0101 & {4{or_detect}})  | (4'b0011 & {4{sll_detect}}) | (4'b0100 & {4{srl_detect}}) | (4'b1100 & {4{sra_detect}}) |
                           (4'b1011 & {4{slt_detect}}) | (4'b1001 & {4{sltu_detect}});
  assign aluctrl_temp[2] = (4'b0000 & ({4{add_detect}} | {4{sub_detect}})) | (4'b0111 & {4{xor_detect}}) | (4'b0010 & {4{and_detect}}) | 
                           (4'b0101 & {4{or_detect}})  | (4'b0011 & {4{sll_detect}}) | (4'b0100 & {4{srl_detect}}) | (4'b1100 & {4{sra_detect}}) |
                           (4'b1011 & {4{slt_detect}}) | (4'b1001 & {4{sltu_detect}});
  assign aluctrl_temp[3] = 4'b0000;
  
  mux_41 #(
    .WIDTH(4)
  ) mux_aluop (
    .i_i(aluctrl_temp),
    .s_i(aluop_i),
    .y_o(aluctrl_o)
  );
endmodule
