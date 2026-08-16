`timescale 1ns/1ps

module tb_pc_imem;

  parameter WIDTH = 32;

  logic clk_i;
  logic rst_i;

  wire [WIDTH-1:0] pc_o;
  wire [WIDTH-1:0] instr_o;
  wire [WIDTH-1:0] next_pc_i;

  assign next_pc_i = pc_o + 32'd4;

  pc #(
    .WIDTH(WIDTH)
  ) u_pc (
    .next_pc_i (next_pc_i),
    .clk_i     (clk_i),
    .rst_i     (rst_i),
    .pc_o      (pc_o)
  );

  imem #(
    .WIDTH(WIDTH),
    .WORDS(512)
  ) u_imem (
    .addr_i  (pc_o),
    .instr_o (instr_o)
  );

  initial begin
    clk_i = 1'b0;
    forever #5 clk_i = ~clk_i;
  end

  initial begin
    $fsdbDumpfile("dump.fsdb");
    $fsdbDumpvars(0, tb_pc_imem, "+all");
  end

  task check_pc_instr(
    input [31:0] expected_pc,
    input [31:0] expected_instr,
    input string name
  );
    begin
      #1;

      if ((pc_o === expected_pc) && (instr_o === expected_instr)) begin
        $display("PASS %-10s pc=%h instr=%h", name, pc_o, instr_o);
      end
      else begin
        $display("FAIL %-10s", name);
        $display("  pc_o    = %h expected = %h", pc_o, expected_pc);
        $display("  instr_o = %h expected = %h", instr_o, expected_instr);
      end
    end
  endtask

  initial begin
    rst_i = 1'b1;

    $display("========================================");
    $display("PC + IMem Test");
    $display("========================================");

    // Reset PC to 0
    repeat (2) @(posedge clk_i);
    check_pc_instr(32'h0000_0000, 32'h0050_0093, "reset");

    // Release reset
    @(negedge clk_i);
    rst_i = 1'b0;

    @(posedge clk_i);
    check_pc_instr(32'h0000_0004, 32'h00A0_0113, "PC 4");

    @(posedge clk_i);
    check_pc_instr(32'h0000_0008, 32'h0020_81B3, "PC 8");

    @(posedge clk_i);
    check_pc_instr(32'h0000_000C, 32'h0030_2023, "PC 12");

    @(posedge clk_i);
    check_pc_instr(32'h0000_0010, 32'h0000_2203, "PC 16");

    @(posedge clk_i);
    check_pc_instr(32'h0000_0014, 32'h0000_0013, "PC 20");

    $display("========================================");
    $display("PC + IMem Test Finished");
    $display("========================================");

    #20;
    $finish;
  end

endmodule