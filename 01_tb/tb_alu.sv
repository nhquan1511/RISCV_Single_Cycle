`timescale 1ns/1ps

module alu_tb;

  parameter WIDTH = 32;

  logic [WIDTH-1:0] r1_i;
  logic [WIDTH-1:0] r2_i;
  logic [3:0]       aluctrl_i;
  wire  [WIDTH-1:0] result_o;

  // DUT = Design Under Test
  alu #(
    .WIDTH(WIDTH)
  ) dut (
    .r1_i(r1_i),
    .r2_i(r2_i),
    .aluctrl_i(aluctrl_i),
    .result_o(result_o)
  );

  // FSDB waveform for Verdi
  initial begin
    $fsdbDumpfile("dump.fsdb");
    $fsdbDumpvars(0, alu_tb, "+all");
  end

  task check_result(
    input [3:0]       ctrl,
    input [31:0]      a,
    input [31:0]      b,
    input [31:0]      expected,
    input string      test_name
  );
    begin
      aluctrl_i = ctrl;
      r1_i      = a;
      r2_i      = b;

      #1; // wait for combinational logic to settle

      if (result_o === expected) begin
        $display("PASS %-8s | ctrl=%h r1=%h r2=%h result=%h",
                 test_name, ctrl, a, b, result_o);
      end
      else begin
        $display("FAIL %-8s | ctrl=%h r1=%h r2=%h result=%h expected=%h",
                 test_name, ctrl, a, b, result_o, expected);
      end
    end
  endtask

  initial begin
    // Initial value
    r1_i      = 32'b0;
    r2_i      = 32'b0;
    aluctrl_i = 4'b0;

    #5;

    // ============================================
    // ALU control map from your alu.sv:
    //
    // 0  = ADD
    // 1  = SUB
    // 2  = AND
    // 3  = SLL
    // 4  = SRL
    // 5  = OR
    // 7  = XOR
    // 9  = SLTU
    // 11 = SLT
    // 12 = SRA
    // ============================================

    check_result(4'd0,  32'd10,       32'd20,       32'd30,       "ADD");

    check_result(4'd1,  32'd30,       32'd10,       32'd20,       "SUB");

    check_result(4'd2,  32'hF0F0_0000, 32'h0FF0_0000, 32'h00F0_0000, "AND");

    check_result(4'd5,  32'hF0F0_0000, 32'h0FF0_0000, 32'hFFF0_0000, "OR");

    check_result(4'd7,  32'hAAAA_5555, 32'hFFFF_0000, 32'h5555_5555, "XOR");

    // Shift tests
    // r2_i usually provides shift amount. For RV32I, only r2_i[4:0] matters.
    check_result(4'd3,  32'h0000_0001, 32'd4,        32'h0000_0010, "SLL");

    check_result(4'd4,  32'h0000_0080, 32'd3,        32'h0000_0010, "SRL");

    check_result(4'd12, 32'h8000_0000, 32'd4,        32'hF800_0000, "SRA");

    // Signed set-less-than
    // -1 < 1 signed, so result should be 1
    check_result(4'd11, 32'hFFFF_FFFF, 32'h0000_0001, 32'h0000_0001, "SLT");

    // 5 < -1 signed is false, so result should be 0
    check_result(4'd11, 32'h0000_0005, 32'hFFFF_FFFF, 32'h0000_0000, "SLT");

    // Unsigned set-less-than
    // 1 < 2 unsigned, result should be 1
    check_result(4'd9,  32'h0000_0001, 32'h0000_0002, 32'h0000_0001, "SLTU");

    // 0xFFFFFFFF < 1 unsigned is false, result should be 0
    check_result(4'd9,  32'hFFFF_FFFF, 32'h0000_0001, 32'h0000_0000, "SLTU");

    #10;
    $finish;
  end

endmodule