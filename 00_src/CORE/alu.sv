//ALU 32 bits
//Module: ALU 32 bits
//Date: 1/7/2026
//Updated: 1/7/2026
//========================================
module alu #(
  parameter WIDTH = 32
)(
  input  wire [WIDTH-1:0] r1_i,
  input  wire [WIDTH-1:0] r2_i,
  input  wire [3:0]       aluctrl_i,
  output wire [WIDTH-1:0] result_o
);
//========================================
  wire             add_subtract_cout;
  wire             overflow;
  wire [WIDTH-1:0] add_subtract_result;

  add_subtract #(
  .WIDTH(WIDTH)
  ) as (
  .a_i   (r1_i),
  .b_i   (r2_i),
  .mode_i(aluctrl_i[0]), // 0 is add, 1 is subtract
  .s_o   (add_subtract_result),
  .cout_o(add_subtract_cout),
  .overflow_o(overflow)
  );
//========================================
  wire [WIDTH-1:0] temp_slt;
  assign temp_slt = {{WIDTH-1{1'b0}}, overflow ^ add_subtract_result[WIDTH-1]};

  wire [WIDTH-1:0] temp_sltu;
  assign temp_sltu = {{WIDTH-1{1'b0}}, add_subtract_cout};
//========================================
  wire [WIDTH-1:0] shift_result;
  barrel_shifter #(
  .WIDTH(WIDTH)
  ) bs (
  .r1_i(r1_i), 
  .r2_i(r2_i),
  .dir_i(aluctrl_i[2]), // 0: left shift, 1: right shift
  .arith_i(aluctrl_i[3]), // 0: logical shift, 1: arithmetic shift
  .y_o(shift_result)
  );
  
//========================================
  wire [WIDTH-1:0] temp_result [0:15];

  assign temp_result[0] = add_subtract_result; // ADD
  assign temp_result[1] = add_subtract_result; // SUB
  assign temp_result[2] = r1_i & r2_i; // AND
  assign temp_result[5] = r1_i | r2_i; // OR
  assign temp_result[7] = r1_i ^ r2_i; // XOR
  assign temp_result[9] = temp_sltu; // SLTU
  assign temp_result[11]= temp_slt; // SLT
  assign temp_result[3] = shift_result; // SLL
  assign temp_result[4] = shift_result; // SRL
  assign temp_result[12]= shift_result; // SRA
  assign temp_result[6] = {WIDTH{1'b0}};
  assign temp_result[8] = {WIDTH{1'b0}};
  assign temp_result[10]= {WIDTH{1'b0}};
  assign temp_result[13]= {WIDTH{1'b0}};
  assign temp_result[14]= {WIDTH{1'b0}};
  assign temp_result[15]= {WIDTH{1'b0}};

  mux_161 #(
  .WIDTH(WIDTH)
  ) m (
  .i_i(temp_result),
  .s_i(aluctrl_i[3:0]),
  .y_o(result_o)
  );
endmodule
