`timescale 1ns/1ps

module lsu_memory_io_tb;

  parameter WIDTH = 32;
  parameter WORDS = 512;

  logic clk_i;
  logic rst_i;

  logic [2:0]       funct3;
  logic [WIDTH-1:0] addr_i;
  logic             memread_i;
  logic             memwrite_i;
  logic [WIDTH-1:0] store_d_i;

  wire [WIDTH-1:0] q_addr_dmem;
  wire [WIDTH-1:0] q_addradd1_dmem;

  wire [WIDTH-1:0] memd_o;
  wire [WIDTH-1:0] memd_misaligned_o;
  wire [WIDTH-1:0] wb_d_o;

  wire [WIDTH-1:0] io_ledr_o;
  wire [WIDTH-1:0] io_ledg_o;
  wire [WIDTH-1:0] io_lcd_o;
  wire [6:0]       io_hex_o [0:7];

  logic [WIDTH-1:0] io_sw_i;

  wire [WIDTH-1:0] load_ledr;
  wire [WIDTH-1:0] load_ledg;
  wire [WIDTH-1:0] load_hex7seg_0to3;
  wire [WIDTH-1:0] load_hex7seg_4to7;
  wire [WIDTH-1:0] load_lcd;
  wire [WIDTH-1:0] load_switches;

  wire [WIDTH-1:0] q_addr_combined;

  assign q_addr_combined = q_addr_dmem |
                           load_ledr |
                           load_ledg |
                           load_hex7seg_0to3 |
                           load_hex7seg_4to7 |
                           load_lcd |
                           load_switches;

  // funct3
  localparam F3_LB_SB = 3'b000;
  localparam F3_LH_SH = 3'b001;
  localparam F3_LW_SW = 3'b010;
  localparam F3_LBU   = 3'b100;
  localparam F3_LHU   = 3'b101;

  // Memory map
  localparam ADDR_DMEM0       = 32'h0000_0000;
  localparam ADDR_DMEM1       = 32'h0000_0004;

  localparam ADDR_LEDR        = 32'h1000_0000;
  localparam ADDR_LEDG        = 32'h1000_1000;
  localparam ADDR_HEX_0TO3    = 32'h1000_2000;
  localparam ADDR_HEX_4TO7    = 32'h1000_3000;
  localparam ADDR_LCD         = 32'h1000_4000;
  localparam ADDR_SWITCHES    = 32'h1001_0000;

  // =========================================================
  // DUTs
  // =========================================================

  dmem #(
    .WORDS(WORDS),
    .WIDTH(WIDTH)
  ) u_dmem (
    .addr_i          (addr_i),
    .clk_i           (clk_i),
    .rst_i           (rst_i),
    .memwrite_i      (memwrite_i),
    .d_i             (memd_o),
    .d_misaligned_i  (memd_misaligned_o),
    .q_addr_o        (q_addr_dmem),
    .q_addradd1_o    (q_addradd1_dmem)
  );

  lsu #(
    .WIDTH(WIDTH)
  ) u_lsu (
    .funct3            (funct3),
    .addr_i            (addr_i),
    .memread_i         (memread_i),
    .store_d_i         (store_d_i),
    .q_addr_i          (q_addr_combined),
    .q_addradd1_i      (q_addradd1_dmem),
    .memd_o            (memd_o),
    .memd_misaligned_o (memd_misaligned_o),
    .wb_d_o            (wb_d_o)
  );

  ledr #(
    .WIDTH(WIDTH)
  ) u_ledr (
    .clk_i       (clk_i),
    .rst_i       (rst_i),
    .memwrite_i  (memwrite_i),
    .addr_i      (addr_i),
    .d_i         (memd_o),
    .d_o         (io_ledr_o),
    .load_ledr   (load_ledr)
  );

  ledg #(
    .WIDTH(WIDTH)
  ) u_ledg (
    .clk_i       (clk_i),
    .rst_i       (rst_i),
    .memwrite_i  (memwrite_i),
    .addr_i      (addr_i),
    .d_i         (memd_o),
    .d_o         (io_ledg_o),
    .load_ledg   (load_ledg)
  );

  hex7seg #(
    .WIDTH(WIDTH)
  ) u_hex7seg (
    .clk_i              (clk_i),
    .rst_i              (rst_i),
    .memwrite_i         (memwrite_i),
    .addr_i             (addr_i),
    .d_i                (memd_o),
    .d_o                (io_hex_o),
    .load_hex7seg_0to3  (load_hex7seg_0to3),
    .load_hex7seg_4to7  (load_hex7seg_4to7)
  );

  lcd #(
    .WIDTH(WIDTH)
  ) u_lcd (
    .clk_i       (clk_i),
    .rst_i       (rst_i),
    .memwrite_i  (memwrite_i),
    .addr_i      (addr_i),
    .d_i         (memd_o),
    .d_o         (io_lcd_o),
    .load_lcd    (load_lcd)
  );

  switches #(
    .WIDTH(WIDTH)
  ) u_switches (
    .addr_i        (addr_i),
    .d_i           (io_sw_i),
    .load_switches (load_switches)
  );

  // =========================================================
  // Clock
  // =========================================================

  initial begin
    clk_i = 1'b0;
    forever #5 clk_i = ~clk_i;
  end

  // =========================================================
  // Waveform
  // =========================================================

  initial begin
    $fsdbDumpfile("dump.fsdb");
    $fsdbDumpvars(0, lsu_memory_io_tb, "+all");
  end

  // =========================================================
  // Tasks
  // =========================================================

  task reset_dut;
    begin
      rst_i       = 1'b1;
      funct3      = 3'b000;
      addr_i      = 32'b0;
      memread_i   = 1'b0;
      memwrite_i  = 1'b0;
      store_d_i   = 32'b0;
      io_sw_i     = 32'b0;

      repeat (2) @(posedge clk_i);
      #1;
      rst_i = 1'b0;
      repeat (1) @(posedge clk_i);
      #1;
    end
  endtask

  task store_word(
    input [31:0] addr,
    input [31:0] data,
    input string name
  );
    begin
      @(negedge clk_i);
      funct3      = F3_LW_SW;
      addr_i      = addr;
      store_d_i   = data;
      memread_i   = 1'b0;
      memwrite_i  = 1'b1;

      #1;
      $display("STORE %-16s addr=%h data=%h memd=%h memd_mis=%h",
               name, addr, data, memd_o, memd_misaligned_o);

      @(posedge clk_i);
      #1;

      @(negedge clk_i);
      memwrite_i = 1'b0;
      store_d_i  = 32'b0;
      #1;
    end
  endtask

  task load_word_check(
    input [31:0] addr,
    input [31:0] expected,
    input string name
  );
    begin
      @(negedge clk_i);
      funct3      = F3_LW_SW;
      addr_i      = addr;
      store_d_i   = 32'b0;
      memwrite_i  = 1'b0;
      memread_i   = 1'b1;

      #1;

      if (wb_d_o === expected) begin
        $display("PASS LOAD  %-16s addr=%h wb=%h", name, addr, wb_d_o);
      end
      else begin
        $display("FAIL LOAD  %-16s addr=%h", name, addr);
        $display("  q_addr_dmem       = %h", q_addr_dmem);
        $display("  load_ledr         = %h", load_ledr);
        $display("  load_ledg         = %h", load_ledg);
        $display("  load_hex7seg_0to3 = %h", load_hex7seg_0to3);
        $display("  load_hex7seg_4to7 = %h", load_hex7seg_4to7);
        $display("  load_lcd          = %h", load_lcd);
        $display("  load_switches     = %h", load_switches);
        $display("  q_addr_combined   = %h", q_addr_combined);
        $display("  wb_d_o            = %h expected = %h", wb_d_o, expected);
      end

      @(negedge clk_i);
      memread_i = 1'b0;
      #1;
    end
  endtask

  task check_signal32(
    input [31:0] actual,
    input [31:0] expected,
    input string name
  );
    begin
      if (actual === expected) begin
        $display("PASS CHECK %-16s value=%h", name, actual);
      end
      else begin
        $display("FAIL CHECK %-16s value=%h expected=%h", name, actual, expected);
      end
    end
  endtask

  task check_hex7(
    input [6:0] actual,
    input [6:0] expected,
    input string name
  );
    begin
      if (actual === expected) begin
        $display("PASS CHECK %-16s value=%b", name, actual);
      end
      else begin
        $display("FAIL CHECK %-16s value=%b expected=%b", name, actual, expected);
      end
    end
  endtask

  task store_any(
  input [2:0]  f3,
  input [31:0] addr,
  input [31:0] data,
  input string name
);
  begin
    @(negedge clk_i);
    funct3      = f3;
    addr_i      = addr;
    store_d_i   = data;
    memread_i   = 1'b0;
    memwrite_i  = 1'b1;

    #1;
    $display("STORE %-16s addr=%h data=%h memd=%h memd_mis=%h",
             name, addr, data, memd_o, memd_misaligned_o);

    @(posedge clk_i);
    #1;

    @(negedge clk_i);
    memwrite_i = 1'b0;
    store_d_i  = 32'b0;
    #1;
  end
endtask


task load_any_check(
  input [2:0]  f3,
  input [31:0] addr,
  input [31:0] expected,
  input string name
);
  begin
    @(negedge clk_i);
    funct3      = f3;
    addr_i      = addr;
    store_d_i   = 32'b0;
    memwrite_i  = 1'b0;
    memread_i   = 1'b1;

    #1;

    if (wb_d_o === expected) begin
      $display("PASS LOAD  %-16s addr=%h wb=%h", name, addr, wb_d_o);
    end
    else begin
      $display("FAIL LOAD  %-16s addr=%h", name, addr);
      $display("  q_addr_combined   = %h", q_addr_combined);
      $display("  q_addradd1_dmem   = %h", q_addradd1_dmem);
      $display("  wb_d_o            = %h expected = %h", wb_d_o, expected);
    end

    @(negedge clk_i);
    memread_i = 1'b0;
    #1;
  end
endtask
  // =========================================================
  // Main test
  // =========================================================

  initial begin
    reset_dut();

    $display("========================================");
    $display("LSU + DMem + MMIO integration test");
    $display("========================================");

    // =====================================================
    // 1. Normal DMem test
    // =====================================================
    store_word(ADDR_DMEM0, 32'hAABB_CCDD, "DMEM word 0");
    load_word_check(ADDR_DMEM0, 32'hAABB_CCDD, "DMEM word 0");

    store_word(ADDR_DMEM1, 32'h1122_3344, "DMEM word 1");
    load_word_check(ADDR_DMEM1, 32'h1122_3344, "DMEM word 1");

    // Misaligned store/load through DMem + LSU
    store_word(ADDR_DMEM0, 32'hAABB_CCDD, "preload mem0");
    store_word(ADDR_DMEM1, 32'h1122_3344, "preload mem1");

    store_word(32'h0000_0001, 32'h5566_7788, "SW misal +1");

    load_word_check(ADDR_DMEM0, 32'h6677_88DD, "mem0 after +1");
    load_word_check(ADDR_DMEM1, 32'h1122_3355, "mem1 after +1");
    load_word_check(32'h0000_0001, 32'h5566_7788, "LW misal +1");

    // =====================================================
    // 2. LEDR MMIO
    // =====================================================
    store_word(ADDR_LEDR, 32'h1234_5678, "LEDR");
    check_signal32(io_ledr_o, 32'h1234_5678, "io_ledr_o");
    load_word_check(ADDR_LEDR, 32'h1234_5678, "LEDR readback");

    // =====================================================
    // 3. LEDG MMIO
    // =====================================================
    store_word(ADDR_LEDG, 32'h8765_4321, "LEDG");
    check_signal32(io_ledg_o, 32'h8765_4321, "io_ledg_o");
    load_word_check(ADDR_LEDG, 32'h8765_4321, "LEDG readback");

    // =====================================================
    // 4. HEX0-3 MMIO
    //
    // Your design maps:
    // HEX0 = q_0to3[6:0]
    // HEX1 = q_0to3[14:8]
    // HEX2 = q_0to3[22:16]
    // HEX3 = q_0to3[30:24]
    //
    // Data = 32'h7A_5B_3C_1D
    // HEX0 expects 0x1D[6:0]
    // HEX1 expects 0x3C[6:0]
    // HEX2 expects 0x5B[6:0]
    // HEX3 expects 0x7A[6:0]
    // =====================================================
    store_word(ADDR_HEX_0TO3, 32'h7A5B_3C1D, "HEX0-3");

    check_hex7(io_hex_o[0], 7'h1D, "HEX0");
    check_hex7(io_hex_o[1], 7'h3C, "HEX1");
    check_hex7(io_hex_o[2], 7'h5B, "HEX2");
    check_hex7(io_hex_o[3], 7'h7A, "HEX3");

    load_word_check(ADDR_HEX_0TO3, 32'h7A5B_3C1D, "HEX0-3 readback");

    // =====================================================
    // 5. HEX4-7 MMIO
    // =====================================================
    store_word(ADDR_HEX_4TO7, 32'h7060_5040, "HEX4-7");

    check_hex7(io_hex_o[4], 7'h40, "HEX4");
    check_hex7(io_hex_o[5], 7'h50, "HEX5");
    check_hex7(io_hex_o[6], 7'h60, "HEX6");
    check_hex7(io_hex_o[7], 7'h70, "HEX7");

    load_word_check(ADDR_HEX_4TO7, 32'h7060_5040, "HEX4-7 readback");

    // =====================================================
    // 6. LCD MMIO
    // =====================================================
    store_word(ADDR_LCD, 32'hCAFE_BABE, "LCD");
    check_signal32(io_lcd_o, 32'hCAFE_BABE, "io_lcd_o");
    load_word_check(ADDR_LCD, 32'hCAFE_BABE, "LCD readback");

    // =====================================================
    // 7. Switches MMIO
    //
    // Switches are input-only.
    // No store needed.
    // CPU load from switch address should return io_sw_i.
    // =====================================================
    io_sw_i = 32'h0F0F_A5A5;
    load_word_check(ADDR_SWITCHES, 32'h0F0F_A5A5, "SWITCH read");

    io_sw_i = 32'hDEAD_BEEF;
    load_word_check(ADDR_SWITCHES, 32'hDEAD_BEEF, "SWITCH read 2");

    // =====================================================
    // 8. Check unrelated address does not read IO
    // =====================================================
    load_word_check(32'h1002_0000, 32'h0000_0000, "unmapped IO");

    $display("========================================");
    $display("Test finished");
    $display("========================================");

    // =====================================================
// 9. Misaligned MMIO tests
//
// These tests check what your current design actually does.
// For MMIO, only q_addr_combined is available.
// q_addradd1_dmem is usually 0 because MMIO is outside DMem.
//
// So:
// - Misaligned SB/SH/SW store can modify the current IO register.
// - Misaligned LW/LH crossing into "next word" cannot fully reconstruct
//   because there is no next IO register connected to q_addradd1_i.
// =====================================================

$display("========================================");
$display("Misaligned MMIO tests");
$display("========================================");

// -----------------------------------------------------
// LEDR: SB at offset 2
//
// Start:
// LEDR = AABBCCDD
//
// SB 0x88 at address 1000_0002
//
// Expected LEDR:
// AA88CCDD
// -----------------------------------------------------
store_word(ADDR_LEDR, 32'hAABB_CCDD, "LEDR preload");

store_any(F3_LB_SB, ADDR_LEDR + 32'd2, 32'h0000_0088, "LEDR SB +2");

check_signal32(io_ledr_o, 32'hAA88_CCDD, "LEDR after SB+2");

load_any_check(F3_LB_SB, ADDR_LEDR + 32'd2, 32'hFFFF_FF88, "LEDR LB +2");
load_any_check(F3_LBU,   ADDR_LEDR + 32'd2, 32'h0000_0088, "LEDR LBU +2");


// -----------------------------------------------------
// LEDR: SH at offset 1
//
// Start:
// LEDR = AABBCCDD
//
// SH 0x7788 at address 1000_0001
//
// Expected LEDR:
// AA7788DD
//
// This does not cross into next word, so LH should work.
// -----------------------------------------------------
store_word(ADDR_LEDR, 32'hAABB_CCDD, "LEDR preload");

store_any(F3_LH_SH, ADDR_LEDR + 32'd1, 32'h0000_7788, "LEDR SH +1");

check_signal32(io_ledr_o, 32'hAA77_88DD, "LEDR after SH+1");

load_any_check(F3_LH_SH, ADDR_LEDR + 32'd1, 32'h0000_7788, "LEDR LH +1");
load_any_check(F3_LHU,   ADDR_LEDR + 32'd1, 32'h0000_7788, "LEDR LHU +1");


// -----------------------------------------------------
// LEDR: SH at offset 3
//
// Start:
// LEDR = AABBCCDD
//
// SH 0x7788 at address 1000_0003
//
// LSU current-word result:
// LEDR becomes 88BBCCDD
//
// The high byte 0x77 would go to q_addradd1,
// but your LEDR module does not use d_misaligned_i.
// So that byte is lost for MMIO.
//
// LH from +3 sees:
// low byte  = LEDR[31:24] = 0x88
// high byte = q_addradd1_dmem[7:0] = 0x00
//
// Expected LH result:
// 00000088
// -----------------------------------------------------
store_word(ADDR_LEDR, 32'hAABB_CCDD, "LEDR preload");

store_any(F3_LH_SH, ADDR_LEDR + 32'd3, 32'h0000_7788, "LEDR SH +3");

check_signal32(io_ledr_o, 32'h88BB_CCDD, "LEDR after SH+3");

load_any_check(F3_LH_SH, ADDR_LEDR + 32'd3, 32'h0000_0088, "LEDR LH +3 current behavior");
load_any_check(F3_LHU,   ADDR_LEDR + 32'd3, 32'h0000_0088, "LEDR LHU +3 current behavior");


// -----------------------------------------------------
// LEDR: SW at offset 1
//
// Start:
// LEDR = AABBCCDD
//
// SW 55667788 at address 1000_0001
//
// Current IO register becomes:
// 667788DD
//
// The top byte 0x55 would go to next word,
// but MMIO next-word path is not implemented.
// So aligned LEDR readback = 667788DD.
//
// LW from +1 gives:
// {q_addradd1_dmem[7:0], LEDR[31:8]}
// = {00, 667788}
// = 00667788
// -----------------------------------------------------
store_word(ADDR_LEDR, 32'hAABB_CCDD, "LEDR preload");

store_any(F3_LW_SW, ADDR_LEDR + 32'd1, 32'h5566_7788, "LEDR SW +1");

check_signal32(io_ledr_o, 32'h6677_88DD, "LEDR after SW+1");

load_any_check(F3_LW_SW, ADDR_LEDR,        32'h6677_88DD, "LEDR aligned after SW+1");
load_any_check(F3_LW_SW, ADDR_LEDR + 32'd1, 32'h0066_7788, "LEDR LW +1 current behavior");


// -----------------------------------------------------
// Switches: misaligned reads
//
// Switches are input-only.
// q_addr_combined = io_sw_i when address hits switches.
// q_addradd1_dmem = 0 because switches are outside DMem.
// -----------------------------------------------------
io_sw_i = 32'hAABB_CCDD;

load_any_check(F3_LB_SB, ADDR_SWITCHES + 32'd0, 32'hFFFF_FFDD, "SW LB +0");
load_any_check(F3_LBU,   ADDR_SWITCHES + 32'd1, 32'h0000_00CC, "SW LBU +1");
load_any_check(F3_LH_SH, ADDR_SWITCHES + 32'd1, 32'hFFFF_BBCC, "SW LH +1");
load_any_check(F3_LHU,   ADDR_SWITCHES + 32'd2, 32'h0000_AABB, "SW LHU +2");

// Crossing boundary at offset 3.
// q_addradd1_dmem = 0, so result becomes 000000AA.
load_any_check(F3_LH_SH, ADDR_SWITCHES + 32'd3, 32'h0000_00AA, "SW LH +3 current behavior");

// Misaligned LW at +1:
// {00, AABBCC} = 00AABBCC
load_any_check(F3_LW_SW, ADDR_SWITCHES + 32'd1, 32'h00AA_BBCC, "SW LW +1 current behavior");
    #20;
    $finish;
  end

endmodule