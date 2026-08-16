// Immediate Generator
// Module: Immediate Generator
// Date: 5/7/2026
// Updated: 10/7/2026
//========================================
module immgen #(
  parameter WIDTH = 32 
)(
  input  wire [WIDTH-1:0] instr_i,
  input  wire             immsel_i[0:4],
  output reg  [WIDTH-1:0] imm_o
);
//========================================
  wire [WIDTH-1:0] itype_imm;
  wire [WIDTH-1:0] stype_imm;
  wire [WIDTH-1:0] btype_imm;
  wire [WIDTH-1:0] utype_imm;
  wire [WIDTH-1:0] jtype_imm;

  assign itype_imm = {{20{instr_i[WIDTH-1]}}, instr_i[WIDTH-1:20]} & {WIDTH{immsel_i[0]}};
  assign stype_imm = {{20{instr_i[WIDTH-1]}}, instr_i[WIDTH-1:25], instr_i[11:7]} & {WIDTH{immsel_i[1]}};
  assign btype_imm = {{19{instr_i[WIDTH-1]}}, instr_i[WIDTH-1], instr_i[7], instr_i[30:25], instr_i[11:8], 1'b0} & {WIDTH{immsel_i[2]}};
  assign utype_imm = {instr_i[WIDTH-1:12], 12'b0} & {WIDTH{immsel_i[3]}};
  assign jtype_imm = {{11{instr_i[WIDTH-1]}}, instr_i[31], instr_i[19:12], instr_i[20], instr_i[30:21], 1'b0} & {WIDTH{immsel_i[4]}};

//========================================
  always_comb begin
    imm_o = itype_imm | stype_imm | btype_imm | utype_imm | jtype_imm;
  end
endmodule