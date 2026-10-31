// Program Counter
// Module: PC
// Date: 8/7/2026
// Updated: 31/10/2026
//======================================
module pc #(
  parameter WIDTH = 32
)(
  input  wire [WIDTH-1:0] next_pc_i,
  input  wire             clk_i,
  input  wire             rst_i,
  input  wire             stall_i,
  output reg  [WIDTH-1:0] pc_o
);
//======================================
  always_ff @(posedge clk_i or posedge rst_i) begin
    if (rst_i == 1'b1) begin
      pc_o <= 32'b0;
    end else if (!stall_i) begin
      pc_o  <= next_pc_i;
    end
  end
endmodule
