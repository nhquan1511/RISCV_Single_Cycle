`timescale 1ns/1ps

module lsu_dmem_tb;

  parameter WIDTH = 32;
  parameter WORDS = 512;

  logic clk_i;
  logic rst_i;

  logic [2:0]       funct3;
  logic [WIDTH-1:0] addr_i;
  logic             memread_i;
  logic             memwrite_i;
  logic [WIDTH-1:0] store_d_i;

  wire [WIDTH-1:0] q_addr_o;
  wire [WIDTH-1:0] q_addradd1_o;

  wire [WIDTH-1:0] memd_o;
  wire [WIDTH-1:0] memd_misaligned_o;
  wire [WIDTH-1:0] wb_d_o;

  // funct3
  localparam F3_LB_SB = 3'b000;
  localparam F3_LH_SH = 3'b001;
  localparam F3_LW_SW = 3'b010;
  localparam F3_LBU   = 3'b100;
  localparam F3_LHU   = 3'b101;

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
    .q_addr_o        (q_addr_o),
    .q_addradd1_o    (q_addradd1_o)
  );

  lsu #(
    .WIDTH(WIDTH)
  ) u_lsu (
    .funct3            (funct3),
    .addr_i            (addr_i),
    .memread_i         (memread_i),
    .store_d_i         (store_d_i),
    .q_addr_i          (q_addr_o),
    .q_addradd1_i      (q_addradd1_o),
    .memd_o            (memd_o),
    .memd_misaligned_o (memd_misaligned_o),
    .wb_d_o            (wb_d_o)
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
    $fsdbDumpvars(0, lsu_dmem_tb, "+all");
  end

  // =========================================================
  // Helper tasks
  // =========================================================

  task reset_dut;
    begin
      rst_i       = 1'b1;
      memread_i   = 1'b0;
      memwrite_i  = 1'b0;
      funct3      = 3'b000;
      addr_i      = 32'b0;
      store_d_i   = 32'b0;

      repeat (2) @(posedge clk_i);
      #1;
      rst_i = 1'b0;
      repeat (1) @(posedge clk_i);
      #1;
    end
  endtask

  task store_op(
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

      // Wait a little before clock edge so q_addr_o -> LSU -> memd_o settles
      #1;
      $display("STORE %-12s addr=%h data=%h q=%h q_add1=%h memd=%h memd_mis=%h",
               name, addr, data, q_addr_o, q_addradd1_o, memd_o, memd_misaligned_o);

      @(posedge clk_i);
      #1;

      @(negedge clk_i);
      memwrite_i = 1'b0;
      store_d_i  = 32'b0;
      #1;
    end
  endtask

  task load_check(
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
        $display("PASS LOAD  %-12s addr=%h wb=%h", name, addr, wb_d_o);
      end
      else begin
        $display("FAIL LOAD  %-12s addr=%h", name, addr);
        $display("  q_addr_o     = %h", q_addr_o);
        $display("  q_addradd1_o = %h", q_addradd1_o);
        $display("  wb_d_o       = %h expected = %h", wb_d_o, expected);
      end

      @(negedge clk_i);
      memread_i = 1'b0;
      #1;
    end
  endtask

  task raw_word_check(
    input [31:0] addr,
    input [31:0] expected,
    input string name
  );
    begin
      @(negedge clk_i);
      funct3      = F3_LW_SW;
      addr_i      = addr;
      memread_i   = 1'b0;
      memwrite_i  = 1'b0;
      store_d_i   = 32'b0;

      #1;

      if (q_addr_o === expected) begin
        $display("PASS RAW   %-12s addr=%h q=%h", name, addr, q_addr_o);
      end
      else begin
        $display("FAIL RAW   %-12s addr=%h q=%h expected=%h",
                 name, addr, q_addr_o, expected);
      end
    end
  endtask

  // =========================================================
  // Main tests
  // =========================================================

  initial begin
    reset_dut();

    $display("========================================");
    $display("LSU + DMem integration test");
    $display("========================================");

    // =====================================================
    // Test 1: aligned SW then aligned LW
    // mem[0] = AABBCCDD
    // =====================================================
    store_op(F3_LW_SW, 32'h0000_0000, 32'hAABB_CCDD, "SW aligned");
    load_check(F3_LW_SW, 32'h0000_0000, 32'hAABB_CCDD, "LW aligned");

    // =====================================================
    // Test 2: preload mem[0], mem[1]
    // mem[0] = AABBCCDD
    // mem[1] = 11223344
    // Then SW 55667788 at address 1.
    //
    // Expected:
    // mem[0] = 667788DD
    // mem[1] = 11223355
    //
    // Then LW from address 1 should reconstruct:
    // 55667788
    // =====================================================
    store_op(F3_LW_SW, 32'h0000_0000, 32'hAABB_CCDD, "preload mem0");
    store_op(F3_LW_SW, 32'h0000_0004, 32'h1122_3344, "preload mem1");

    store_op(F3_LW_SW, 32'h0000_0001, 32'h5566_7788, "SW misal +1");

    raw_word_check(32'h0000_0000, 32'h6677_88DD, "mem0 after SW+1");
    raw_word_check(32'h0000_0004, 32'h1122_3355, "mem1 after SW+1");

    load_check(F3_LW_SW, 32'h0000_0001, 32'h5566_7788, "LW misal +1");

    // =====================================================
    // Test 3: SW misaligned offset 2
    //
    // Reset memory region:
    // mem[0] = AABBCCDD
    // mem[1] = 11223344
    //
    // SW 55667788 at address 2.
    //
    // Expected:
    // mem[0] = 7788CCDD
    // mem[1] = 11225566
    // LW from address 2 = 55667788
    // =====================================================
    store_op(F3_LW_SW, 32'h0000_0000, 32'hAABB_CCDD, "preload mem0");
    store_op(F3_LW_SW, 32'h0000_0004, 32'h1122_3344, "preload mem1");

    store_op(F3_LW_SW, 32'h0000_0002, 32'h5566_7788, "SW misal +2");

    raw_word_check(32'h0000_0000, 32'h7788_CCDD, "mem0 after SW+2");
    raw_word_check(32'h0000_0004, 32'h1122_5566, "mem1 after SW+2");

    load_check(F3_LW_SW, 32'h0000_0002, 32'h5566_7788, "LW misal +2");

    // =====================================================
    // Test 4: SW misaligned offset 3
    //
    // Expected:
    // mem[0] = 88BBCCDD
    // mem[1] = 11556677
    // LW from address 3 = 55667788
    // =====================================================
    store_op(F3_LW_SW, 32'h0000_0000, 32'hAABB_CCDD, "preload mem0");
    store_op(F3_LW_SW, 32'h0000_0004, 32'h1122_3344, "preload mem1");

    store_op(F3_LW_SW, 32'h0000_0003, 32'h5566_7788, "SW misal +3");

    raw_word_check(32'h0000_0000, 32'h88BB_CCDD, "mem0 after SW+3");
    raw_word_check(32'h0000_0004, 32'h1155_6677, "mem1 after SW+3");

    load_check(F3_LW_SW, 32'h0000_0003, 32'h5566_7788, "LW misal +3");

    // =====================================================
    // Test 5: SH crossing word boundary at offset 3
    //
    // mem[8] = AABBCCDD
    // mem[9] = 11223344
    // SH 7788 at address 0x23.
    //
    // Address 0x20 is word index 8.
    // Address 0x24 is word index 9.
    //
    // Expected:
    // mem[8] = 88BBCCDD
    // mem[9] = 11223377
    // LH from 0x23 = 00007788
    // =====================================================
    store_op(F3_LW_SW, 32'h0000_0020, 32'hAABB_CCDD, "preload mem8");
    store_op(F3_LW_SW, 32'h0000_0024, 32'h1122_3344, "preload mem9");

    store_op(F3_LH_SH, 32'h0000_0023, 32'h0000_7788, "SH misal +3");

    raw_word_check(32'h0000_0020, 32'h88BB_CCDD, "mem8 after SH+3");
    raw_word_check(32'h0000_0024, 32'h1122_3377, "mem9 after SH+3");

    load_check(F3_LH_SH, 32'h0000_0023, 32'h0000_7788, "LH misal +3");
    load_check(F3_LHU,   32'h0000_0023, 32'h0000_7788, "LHU misal +3");

    // =====================================================
    // Test 6: SB and LB/LBU
    //
    // mem[16] = AABBCCDD
    // SB 88 at offset 2 -> mem[16] = AA88CCDD
    // LB from offset 2  -> FFFFFF88
    // LBU from offset 2 -> 00000088
    // =====================================================
    store_op(F3_LW_SW, 32'h0000_0040, 32'hAABB_CCDD, "preload mem16");

    store_op(F3_LB_SB, 32'h0000_0042, 32'h0000_0088, "SB offset 2");

    raw_word_check(32'h0000_0040, 32'hAA88_CCDD, "mem16 after SB");

    load_check(F3_LB_SB, 32'h0000_0042, 32'hFFFF_FF88, "LB offset 2");
    load_check(F3_LBU,   32'h0000_0042, 32'h0000_0088, "LBU offset 2");

    // =====================================================
    // Test 7: out-of-range address should not hit DMem
    //
    // hit_dmem = ~(|addr_i[31:12])
    // So address 0x00001000 is outside DMem.
    // q should be zero.
    // =====================================================
    raw_word_check(32'h0000_1000, 32'h0000_0000, "outside dmem");

    // =====================================================
    // Test 8: last word wraparound protection
    //
    // Last word byte address = 511 * 4 = 2044 = 0x7FC
    // Misaligned SW at 0x7FD would normally need word 512,
    // but your DMem blocks q_addradd1_o and next write.
    //
    // This test checks mem[0] is NOT corrupted.
    // =====================================================
    store_op(F3_LW_SW, 32'h0000_0000, 32'hDEAD_BEEF, "set mem0");
    store_op(F3_LW_SW, 32'h0000_07FC, 32'hAABB_CCDD, "set last word");

    store_op(F3_LW_SW, 32'h0000_07FD, 32'h5566_7788, "SW last +1");

    raw_word_check(32'h0000_0000, 32'hDEAD_BEEF, "mem0 no wrap");
    raw_word_check(32'h0000_07FC, 32'h6677_88DD, "last word only");

    // Because q_addradd1_o is blocked to zero at wraparound,
    // a misaligned load from the last word will not reconstruct full data.
    // We only check that mem[0] was not corrupted.

    $display("========================================");
    $display("LSU + DMem integration test finished");
    $display("========================================");

    #20;
    $finish;
  end
endmodule