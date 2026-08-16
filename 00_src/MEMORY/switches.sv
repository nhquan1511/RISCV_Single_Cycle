// Switches
// Module: Switches
// Date: 28/7/2026
//=================================
module switches #(
  parameter WIDTH = 32
)(
  input  wire [WIDTH-1:0] addr_i,
  input  wire [WIDTH-1:0] d_i,
  output reg  [WIDTH-1:0] load_switches
);
  wire hit_sw;
  assign hit_sw = ~({addr_i[31:29], ~addr_i[28], addr_i[27:17], ~addr_i[16], addr_i[15:12]});

  always_comb begin
    load_switches = d_i & {WIDTH{hit_sw}};
  end
endmodule