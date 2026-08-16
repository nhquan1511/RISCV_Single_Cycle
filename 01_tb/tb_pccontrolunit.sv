`timescale 1ns/1ps

module tb_pccontrolunit;

  parameter WIDTH = 32;

  logic [WIDTH-1:0] r1_i;
  logic [WIDTH-1:0] r2_i;
  logic [2:0]       funct3_i;
  logic             branchsel_i [0:1];

  wire en_o;

  pccontrolunit #(
    .WIDTH(WIDTH)
  ) dut (
    .r1_i        (r1_i),
    .r2_i        (r2_i),
    .funct3_i    (funct3_i),
    .branchsel_i (branchsel_i),
    .en_o        (en_o)
  );

  // =====================================================
  // funct3 values for branch instructions
  // =====================================================
  localparam F3_BEQ  = 3'b000;
  localparam F3_BNE  = 3'b001;
  localparam F3_BLT  = 3'b100;
  localparam F3_BGE  = 3'b101;
  localparam F3_BLTU = 3'b110;
  localparam F3_BGEU = 3'b111;

  // branchsel_i meaning:
  // branchsel_i[0] = conditional branch instruction
  // branchsel_i[1] = JAL / unconditional PC + imm jump

  task check_pcctrl(
    input [31:0] a,
    input [31:0] b,
    input [2:0]  f3,
    input        branch_en,
    input        jal_en,
    input        expected,
    input string name
  );
    begin
      r1_i = a;
      r2_i = b;
      funct3_i = f3;
      branchsel_i[0] = branch_en;
      branchsel_i[1] = jal_en;

      #1;

      if (en_o === expected) begin
        $display("PASS %-20s r1=%h r2=%h funct3=%b branch=%b jal=%b en=%b",
                 name, r1_i, r2_i, funct3_i, branchsel_i[0], branchsel_i[1], en_o);
      end
      else begin
        $display("FAIL %-20s", name);
        $display("  r1_i         = %h", r1_i);
        $display("  r2_i         = %h", r2_i);
        $display("  funct3_i     = %b", funct3_i);
        $display("  branchsel[0] = %b", branchsel_i[0]);
        $display("  branchsel[1] = %b", branchsel_i[1]);
        $display("  en_o         = %b expected = %b", en_o, expected);
      end
    end
  endtask

  initial begin
    $fsdbDumpfile("dump.fsdb");
    $fsdbDumpvars(0, tb_pccontrolunit, "+all");
  end

  initial begin
    r1_i = 32'b0;
    r2_i = 32'b0;
    funct3_i = 3'b000;
    branchsel_i[0] = 1'b0;
    branchsel_i[1] = 1'b0;

    #5;

    $display("========================================");
    $display("PC Control Unit Test");
    $display("========================================");

    // =====================================================
    // No branch / no JAL
    //
    // Even if funct3 and r1/r2 satisfy a condition,
    // en_o should stay 0 when branchsel_i[0] = 0
    // and branchsel_i[1] = 0.
    // =====================================================
    check_pcctrl(
      32'h0000_0005,
      32'h0000_0005,
      F3_BEQ,
      1'b0,
      1'b0,
      1'b0,
      "NO BRANCH"
    );

    // =====================================================
    // JAL
    //
    // branchsel_i[1] forces en_o = 1.
    // This does not depend on r1, r2, or funct3.
    // =====================================================
    check_pcctrl(
      32'h1234_5678,
      32'h8765_4321,
      F3_BEQ,
      1'b0,
      1'b1,
      1'b1,
      "JAL force jump"
    );

    // =====================================================
    // BEQ
    //
    // BEQ takes branch when r1 == r2.
    // =====================================================
    check_pcctrl(
      32'h0000_000A,
      32'h0000_000A,
      F3_BEQ,
      1'b1,
      1'b0,
      1'b1,
      "BEQ equal"
    );

    check_pcctrl(
      32'h0000_000A,
      32'h0000_000B,
      F3_BEQ,
      1'b1,
      1'b0,
      1'b0,
      "BEQ not equal"
    );

    // =====================================================
    // BNE
    //
    // BNE takes branch when r1 != r2.
    // =====================================================
    check_pcctrl(
      32'h0000_000A,
      32'h0000_000B,
      F3_BNE,
      1'b1,
      1'b0,
      1'b1,
      "BNE not equal"
    );

    check_pcctrl(
      32'h0000_000A,
      32'h0000_000A,
      F3_BNE,
      1'b1,
      1'b0,
      1'b0,
      "BNE equal"
    );

    // =====================================================
    // BLT signed
    //
    // Signed comparison:
    // -1 < 1 is true.
    // 5 < -1 is false.
    // =====================================================
    check_pcctrl(
      32'hFFFF_FFFF, // -1 signed
      32'h0000_0001, //  1 signed
      F3_BLT,
      1'b1,
      1'b0,
      1'b1,
      "BLT -1 < 1"
    );

    check_pcctrl(
      32'h0000_0005, //  5 signed
      32'hFFFF_FFFF, // -1 signed
      F3_BLT,
      1'b1,
      1'b0,
      1'b0,
      "BLT 5 < -1"
    );

    check_pcctrl(
      32'h8000_0000, // most negative signed number
      32'h0000_0001,
      F3_BLT,
      1'b1,
      1'b0,
      1'b1,
      "BLT min < 1"
    );

    // =====================================================
    // BGE signed
    //
    // Signed comparison:
    // 5 >= -1 is true.
    // -1 >= 1 is false.
    // Equal should also be true.
    // =====================================================
    check_pcctrl(
      32'h0000_0005,
      32'hFFFF_FFFF,
      F3_BGE,
      1'b1,
      1'b0,
      1'b1,
      "BGE 5 >= -1"
    );

    check_pcctrl(
      32'hFFFF_FFFF,
      32'h0000_0001,
      F3_BGE,
      1'b1,
      1'b0,
      1'b0,
      "BGE -1 >= 1"
    );

    check_pcctrl(
      32'hFFFF_FFFF,
      32'hFFFF_FFFF,
      F3_BGE,
      1'b1,
      1'b0,
      1'b1,
      "BGE equal"
    );

    // =====================================================
    // BLTU unsigned
    //
    // Unsigned comparison:
    // 1 < 2 is true.
    // FFFFFFFF < 1 is false.
    //
    // This assumes your add_subtract cout_o is reversed:
    // cout_o = 1 means borrow happened.
    // =====================================================
    check_pcctrl(
      32'h0000_0001,
      32'h0000_0002,
      F3_BLTU,
      1'b1,
      1'b0,
      1'b1,
      "BLTU 1 < 2"
    );

    check_pcctrl(
      32'hFFFF_FFFF,
      32'h0000_0001,
      F3_BLTU,
      1'b1,
      1'b0,
      1'b0,
      "BLTU FFFF < 1"
    );

    // =====================================================
    // BGEU unsigned
    //
    // Unsigned comparison:
    // FFFFFFFF >= 1 is true.
    // 1 >= 2 is false.
    // Equal should be true.
    // =====================================================
    check_pcctrl(
      32'hFFFF_FFFF,
      32'h0000_0001,
      F3_BGEU,
      1'b1,
      1'b0,
      1'b1,
      "BGEU FFFF >= 1"
    );

    check_pcctrl(
      32'h0000_0001,
      32'h0000_0002,
      F3_BGEU,
      1'b1,
      1'b0,
      1'b0,
      "BGEU 1 >= 2"
    );

    check_pcctrl(
      32'h1234_5678,
      32'h1234_5678,
      F3_BGEU,
      1'b1,
      1'b0,
      1'b1,
      "BGEU equal"
    );

    // =====================================================
    // Branch condition true, but branchsel_i[0] disabled
    //
    // This should not branch.
    // =====================================================
    check_pcctrl(
      32'h0000_0001,
      32'h0000_0002,
      F3_BLTU,
      1'b0,
      1'b0,
      1'b0,
      "BLTU disabled"
    );

    // =====================================================
    // JAL has priority because it ORs into en_o.
    //
    // Even if branch condition is false, JAL should make en_o = 1.
    // =====================================================
    check_pcctrl(
      32'h0000_000A,
      32'h0000_000B,
      F3_BEQ,
      1'b1,
      1'b1,
      1'b1,
      "JAL priority"
    );

    $display("========================================");
    $display("PC Control Unit Test Finished");
    $display("========================================");

    #20;
    $finish;
  end

endmodule