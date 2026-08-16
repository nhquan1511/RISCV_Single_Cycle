//Barrel Shifter
//Module: Barrel Shifter
//Date: 1/7/2026
//Update: 1/7/2026
//========================================
module barrel_shifter #(
  parameter WIDTH = 32
)(
  input  wire [WIDTH-1:0]  r1_i,
  input  wire [WIDTH-1:0]  r2_i,
  input  wire              dir_i, // 0: left shift, 1: right shift
  input  wire              arith_i, // 0: logical shift, 1: arithmetic shift
  output reg  [WIDTH-1:0]  y_o
);
//========================================
  wire [4:0] shift_amount;
  assign shift_amount = r2_i[4:0];
//=======================================
  wire [WIDTH-1:0] r1_reversed;
  bit_reverse #(
    .WIDTH(WIDTH)
  ) br (
    .rs1_i(r1_i),
    .en_i(dir_i),
    .y_o(r1_reversed)
  );
//=======================================
  genvar i;
  wire [WIDTH-1:0] temp_result [4:0];
//========================================
  generate 
    for (i = 0; i < WIDTH; i++) begin : shift_1
      wire temp[1:0]; 

      if (i < 1) begin
        wire temp_ari [1:0];
        wire temp_ari_result;
        assign temp_ari[0] = 1'b0;
        assign temp_ari[1] = r1_reversed[0];
        mux_21 #(
          .WIDTH(1)
        ) mux_ari (
          .i_i(temp_ari),
          .s_i(arith_i),
          .y_o(temp_ari_result)
        );
        assign temp[0] = r1_reversed[i];
        assign temp[1] = temp_ari_result;

      end else begin
        assign temp[0] = r1_reversed[i];
        assign temp[1] = r1_reversed[i-1];
      end
        mux_21 #(
          .WIDTH(1)
        ) mux (
          .i_i(temp),
          .s_i(shift_amount[0]),
          .y_o(temp_result[0][i])
        );
    end
  endgenerate
//==============================================
  generate 
    for (i = 0; i < WIDTH; i++) begin : shift_2
      wire temp[1:0];

      if (i < 2) begin
        wire temp_ari [1:0];
        wire temp_ari_result;
        assign temp_ari[0] = 1'b0;
        assign temp_ari[1] = temp_result[0][0];
        mux_21 #(
          .WIDTH(1)
        ) mux_ari (
          .i_i(temp_ari),
          .s_i(arith_i),
          .y_o(temp_ari_result)
        );
        assign temp[0] = temp_result[0][i];
        assign temp[1] = temp_ari_result;

      end else begin
        assign temp[0] = temp_result[0][i];
        assign temp[1] = temp_result[0][i-2];
      end
        mux_21 #(
          .WIDTH(1)
        ) mux (
          .i_i(temp),
          .s_i(shift_amount[1]),
          .y_o(temp_result[1][i])
        );
    end
  endgenerate
//===================================================
  generate 
    for (i = 0; i < WIDTH; i++) begin : shift_4
      wire temp[1:0];

      if (i < 4) begin
        wire temp_ari [1:0];
        wire temp_ari_result;
        assign temp_ari[0] = 1'b0;
        assign temp_ari[1] = temp_result[1][0];
        mux_21 #(
          .WIDTH(1)
        ) mux_ari (
          .i_i(temp_ari),
          .s_i(arith_i),
          .y_o(temp_ari_result)
        );
        assign temp[0] = temp_result[1][i];
        assign temp[1] = temp_ari_result;

      end else begin
        assign temp[0] = temp_result[1][i];
        assign temp[1] = temp_result[1][i-4];
      end
        mux_21 #(
          .WIDTH(1)
        ) mux (
          .i_i(temp),
          .s_i(shift_amount[2]),
          .y_o(temp_result[2][i])
        );
    end
  endgenerate
  //===================================================
  generate 
    for (i = 0; i < WIDTH; i++) begin : shift_8
      wire temp[1:0];

      if (i < 8) begin
        wire temp_ari [1:0];
        wire temp_ari_result;
        assign temp_ari[0] = 1'b0;
        assign temp_ari[1] = temp_result[2][0];
        mux_21 #(
          .WIDTH(1)
        ) mux_ari (
          .i_i(temp_ari),
          .s_i(arith_i),
          .y_o(temp_ari_result)
        );
        assign temp[0] = temp_result[2][i];
        assign temp[1] = temp_ari_result;

      end else begin
        assign temp[0] = temp_result[2][i];
        assign temp[1] = temp_result[2][i-8];
      end
        mux_21 #(
          .WIDTH(1)
        ) mux (
          .i_i(temp),
          .s_i(shift_amount[3]),
          .y_o(temp_result[3][i])
        );
    end
  endgenerate
  //===================================================
  generate 
    for (i = 0; i < WIDTH; i++) begin : shift_16
      wire temp[1:0];

      if (i < 16) begin
        wire temp_ari [1:0];
        wire temp_ari_result;
        assign temp_ari[0] = 1'b0;
        assign temp_ari[1] = temp_result[3][0];
        mux_21 #(
          .WIDTH(1)
        ) mux_ari (
          .i_i(temp_ari),
          .s_i(arith_i),
          .y_o(temp_ari_result)
        );
        assign temp[0] = temp_result[3][i];
        assign temp[1] = temp_ari_result;
        
      end else begin
        assign temp[0] = temp_result[3][i];
        assign temp[1] = temp_result[3][i-16];
      end
        mux_21 #(
          .WIDTH(1)
        ) mux (
          .i_i(temp),
          .s_i(shift_amount[4]),
          .y_o(temp_result[4][i])
        );
    end
  endgenerate
  //===================================================
  wire [WIDTH-1:0] temp_result_final;
  bit_reverse #(
    .WIDTH(WIDTH)
  ) br2 (
    .rs1_i(temp_result[4]),
    .en_i(dir_i),
    .y_o(temp_result_final)
  );
  //===================================================
  always_comb begin
    y_o = temp_result_final;
  end
endmodule