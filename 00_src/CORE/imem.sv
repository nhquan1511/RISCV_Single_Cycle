// Instrution Memory
// Module: Imem
// Date: 11/7/2026
// Updated: 11/7/2026
//=======================================
module imem #(
  parameter WIDTH = 32, WORDS = 512
)(
  input   wire [WIDTH-1:0] addr_i,
  output  reg  [WIDTH-1:0] instr_o
);

//=======================================
  reg [WIDTH-1:0] mem [0:WORDS-1];

  initial begin
    $readmemh("program.hex", mem);
  end

  always_comb begin
    instr_o = mem[addr_i[WIDTH-1:2]];
  end
endmodule
