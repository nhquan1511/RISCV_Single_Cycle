// Control Unit
// Module: Control Unit
// Date: 4/7/2026
// Updated: 4/7/2026
//========================================
module controlunit(
  input  wire [6:0] opcode_i,
  output reg  [1:0] aluop_o,

  output reg        memread_o,
  output reg        memwrite_o,

  output reg        wb_o [0:1],
  output reg        alusrc2_o,
  output reg        alusrc1_o,
  output reg        regwrite_o,
  output reg        immsel_o [0:4],
  output reg        branchsel_o [0:2],
  output reg        uppersel_o
);
//========================================
// Format type detection
  wire rtype_detect;
  wire btype_detect;
  wire itype_detect;
  wire stype_detect;
  wire utype_detect;
  wire jtype_detect;

  assign rtype_detect =  ~opcode_i[6] &  opcode_i[5] &  opcode_i[4] & ~opcode_i[3] & ~opcode_i[2];
  assign btype_detect =   opcode_i[6] &  opcode_i[5] & ~opcode_i[4] & ~opcode_i[3] & ~opcode_i[2];
  assign itype_detect = (~opcode_i[6] & ~opcode_i[5] &                ~opcode_i[3] & ~opcode_i[2]) |
                        ( opcode_i[6] &  opcode_i[5] & ~opcode_i[4] & ~opcode_i[3] &  opcode_i[2]);
  assign stype_detect =  ~opcode_i[6] &  opcode_i[5] & ~opcode_i[4] & ~opcode_i[3] & ~opcode_i[2];
  assign utype_detect =  ~opcode_i[6] &                 opcode_i[4] & ~opcode_i[3] &  opcode_i[2];
  assign jtype_detect =   opcode_i[6] &  opcode_i[5] & ~opcode_i[4] &  opcode_i[3] &  opcode_i[2];

//==========================================
  always_comb begin
// ALU operation
    aluop_o[0] = rtype_detect;
    aluop_o[1] = itype_detect & opcode_i[4];

// Immediate selection
    immsel_o[0] = itype_detect;
    immsel_o[1] = stype_detect;
    immsel_o[2] = btype_detect;
    immsel_o[3] = utype_detect;
    immsel_o[4] = jtype_detect;
  
// Branch selection
    branchsel_o[0] = btype_detect;
    branchsel_o[1] = jtype_detect;
    branchsel_o[2] = itype_detect & opcode_i[6];

// ALU Source
    alusrc2_o = itype_detect | utype_detect;
    alusrc1_o = utype_detect;

// Register Write
    regwrite_o = rtype_detect | itype_detect | jtype_detect | utype_detect;
  
// Write Back
    wb_o[1] = branchsel_o[1] | branchsel_o[2];
    wb_o[0] = itype_detect & ~opcode_i[4] & ~opcode_i[5];
 
// Upper Immediate Selection
    uppersel_o = utype_detect & opcode_i[5];

// Data Memory
    memread_o  = itype_detect & ~opcode_i[4] & ~opcode_i[5];
    memwrite_o = stype_detect;
  end
//========================================
endmodule