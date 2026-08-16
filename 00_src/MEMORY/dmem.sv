// Data Memory
// Module: Dmem
// Date: 15/7/2026
// Updated: 15/7/2026
//==============================
module dmem #(
  parameter WORDS = 512, WIDTH = 32
)(
  input  wire [WIDTH-1:0] addr_i,
  input  wire             clk_i,
  input  wire             rst_i,
  input  wire             memwrite_i,

  input  wire [WIDTH-1:0] d_i,
  input  wire [WIDTH-1:0] d_misaligned_i,

  output reg  [WIDTH-1:0] q_addr_o,
  output reg  [WIDTH-1:0] q_addradd1_o
);

  wire hit_dmem;
  assign hit_dmem = ~(|addr_i[31:12]);

//===========================================
// Decoder
  reg temp1 [0:WORDS-1];
  reg temp2 [0:WORDS-1];
  reg wr    [0:WORDS-1];

  wire [8:0] addradd1;
  wire       wraparound_detect;
  add_subtract #(
    .WIDTH(9)
  ) add1 (
    .a_i(addr_i[10:2]),
    .b_i(9'd1),
    .mode_i(1'b0),
    .s_o(addradd1),
    .cout_o(wraparound_detect),
    .overflow_o()
  );

  int j;
  always_comb begin
    for(j = 0; j < WORDS; j++) begin
      temp1[j] = 1'b0;
      temp2[j] = 1'b0;
    end
    temp1[addr_i[10:2]] = 1'b1;
    temp2[addradd1] = 1'b1;

    for(j = 0; j < WORDS; j++) begin
      wr[j] = temp1[j] | (temp2[j] & ~wraparound_detect);
    end
  end

//===========================================
// Input Select
  wire [WIDTH-1:0] d_select [0:WORDS-1];
  genvar k;
  generate
    for (k = 0; k < WORDS; k++) begin: GEN_MUX
      assign d_select[k] = temp2[k] ? d_misaligned_i : d_i;
    end
  endgenerate

//===========================================
  wire [WIDTH-1:0] mem [0:WORDS-1];
  genvar i;
  generate
    for (i = 0; i < WORDS; i++) begin : GEN_REG
        register_32 regi (
          .d_i  (d_select[i]),
          .clk_i(clk_i),
          .rst_i(rst_i),
          .wr_i (hit_dmem & memwrite_i & wr[i]),
          .q_o  (mem[i])
        );
      end
  endgenerate
//==========================================
  always_comb begin
    q_addr_o = hit_dmem ? mem[addr_i[10:2]] : 32'b0;
    q_addradd1_o = (~wraparound_detect & hit_dmem) ? mem[addradd1] : 32'b0;
  end
endmodule
