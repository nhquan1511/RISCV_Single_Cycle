//Register File
//Module: Register File
//Date: 27/6/2026
//Updated: 27/6/2026
//=============================================
module register_file #(
  parameter WIDTH = 32
)(
  input   wire             clk_i,
  input   wire             rst_i,
  input   wire [4:0]       rd_i,
  input   wire [WIDTH-1:0] d_i,
  input   wire             wr_i,
  input   wire [4:0]       rs1_i,
  input   wire [4:0]       rs2_i,
  output  wire [WIDTH-1:0] r1_o,
  output  wire [WIDTH-1:0] r2_o
);
//=============================================
wire de_wr [0:31];
  decoder_532 de(
    .d_i(rd_i),
    .y_o(de_wr)
  );
//==============================================
wire [WIDTH-1:0] temp_q [0:31];
genvar i;
generate
    for (i = 1; i < 32; i++) begin : GEN_PIPO
        register_32 #(
          .WIDTH(WIDTH)
        ) regi (
          .d_i(d_i),
          .clk_i(clk_i),
          .rst_i(rst_i),
          .wr_i(de_wr[i] & wr_i),
          .q_o(temp_q[i])
        );
    end
endgenerate

//x0 does not write
register_32 #(
  .WIDTH(WIDTH)
) reg0 (
  .d_i(32'b0),
  .clk_i(clk_i),
  .rst_i(rst_i),
  .wr_i(1'b0),
  .q_o(temp_q[0])
);
//=================================================
mux_321 #(
  .WIDTH(WIDTH)
) mux0(
  .i_i(temp_q),
  .s_i(rs1_i),
  .y_o(r1_o)
);
mux_321 #(
  .WIDTH(WIDTH)
) mux1 (
  .i_i(temp_q),
  .s_i(rs2_i),
  .y_o(r2_o)
);
endmodule