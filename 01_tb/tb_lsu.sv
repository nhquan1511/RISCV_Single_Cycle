`timescale 1ns/1ps

module lsu_tb;

  parameter WIDTH = 32;

  logic [2:0]       funct3;
  logic [WIDTH-1:0] addr_i;
  logic             memread_i;
  logic [WIDTH-1:0] store_d_i;

  logic [WIDTH-1:0] q_addr_i;
  logic [WIDTH-1:0] q_addradd1_i;

  wire [WIDTH-1:0] memd_o;
  wire [WIDTH-1:0] memd_misaligned_o;
  wire [WIDTH-1:0] wb_d_o;

  lsu #(
    .WIDTH(WIDTH)
  ) dut (
    .funct3            (funct3),
    .addr_i            (addr_i),
    .memread_i         (memread_i),
    .store_d_i         (store_d_i),
    .q_addr_i          (q_addr_i),
    .q_addradd1_i      (q_addradd1_i),
    .memd_o            (memd_o),
    .memd_misaligned_o (memd_misaligned_o),
    .wb_d_o            (wb_d_o)
  );

  // FSDB waveform
  initial begin
    $fsdbDumpfile("dump.fsdb");
    $fsdbDumpvars(0, lsu_tb, "+all");
  end

  // funct3 values
  localparam F3_LB_SB  = 3'b000;
  localparam F3_LH_SH  = 3'b001;
  localparam F3_LW_SW  = 3'b010;
  localparam F3_LBU    = 3'b100;
  localparam F3_LHU    = 3'b101;

  // Example old memory data
  localparam OLD_WORD      = 32'hAABB_CCDD;
  localparam OLD_NEXT_WORD = 32'h1122_3344;
  localparam STORE_DATA    = 32'h5566_7788;

  task check_store(
    input [2:0]       f3,
    input [1:0]       offset,
    input [31:0]      expected_memd,
    input [31:0]      expected_memd_mis,
    input string      test_name
  );
    begin
      funct3       = f3;
      addr_i       = {30'b0, offset};
      memread_i    = 1'b0;
      store_d_i    = STORE_DATA;
      q_addr_i     = OLD_WORD;
      q_addradd1_i = OLD_NEXT_WORD;

      #1;

      if ((memd_o === expected_memd) &&
          (memd_misaligned_o === expected_memd_mis) &&
          (wb_d_o === 32'h0000_0000)) begin
        $display("PASS STORE %-12s offset=%b memd=%h memd_mis=%h",
                 test_name, offset, memd_o, memd_misaligned_o);
      end
      else begin
        $display("FAIL STORE %-12s offset=%b", test_name, offset);
        $display("  memd_o            = %h expected = %h", memd_o, expected_memd);
        $display("  memd_misaligned_o = %h expected = %h", memd_misaligned_o, expected_memd_mis);
        $display("  wb_d_o            = %h expected = 00000000", wb_d_o);
      end
    end
  endtask

  task check_load(
    input [2:0]       f3,
    input [1:0]       offset,
    input [31:0]      expected_wb,
    input string      test_name
  );
    begin
      funct3       = f3;
      addr_i       = {30'b0, offset};
      memread_i    = 1'b1;
      store_d_i    = STORE_DATA;
      q_addr_i     = OLD_WORD;
      q_addradd1_i = OLD_NEXT_WORD;

      #1;

      if (wb_d_o === expected_wb) begin
        $display("PASS LOAD  %-12s offset=%b wb=%h",
                 test_name, offset, wb_d_o);
      end
      else begin
        $display("FAIL LOAD  %-12s offset=%b", test_name, offset);
        $display("  wb_d_o = %h expected = %h", wb_d_o, expected_wb);
      end
    end
  endtask

  initial begin
    funct3       = 3'b000;
    addr_i       = 32'b0;
    memread_i    = 1'b0;
    store_d_i    = 32'b0;
    q_addr_i     = 32'b0;
    q_addradd1_i = 32'b0;

    #5;

    $display("====================================");
    $display("Testing LSU store unit");
    $display("OLD_WORD      = %h", OLD_WORD);
    $display("OLD_NEXT_WORD = %h", OLD_NEXT_WORD);
    $display("STORE_DATA    = %h", STORE_DATA);
    $display("====================================");

    // =====================================================
    // Store byte: store low byte 0x88
    // OLD_WORD = AABBCCDD
    // byte offset 0 -> AABBCC88
    // byte offset 1 -> AABB88DD
    // byte offset 2 -> AA88CCDD
    // byte offset 3 -> 88BBCCDD
    // misaligned output should keep OLD_NEXT_WORD
    // =====================================================
    check_store(F3_LB_SB, 2'b00, 32'hAABB_CC88, OLD_NEXT_WORD, "SB");
    check_store(F3_LB_SB, 2'b01, 32'hAABB_88DD, OLD_NEXT_WORD, "SB");
    check_store(F3_LB_SB, 2'b10, 32'hAA88_CCDD, OLD_NEXT_WORD, "SB");
    check_store(F3_LB_SB, 2'b11, 32'h88BB_CCDD, OLD_NEXT_WORD, "SB");

    // =====================================================
    // Store halfword: store low half 0x7788
    // offset 00 -> AABB7788
    // offset 01 -> AA7788DD
    // offset 10 -> 7788CCDD
    // offset 11 -> current 88BBCCDD, next 11223377
    // =====================================================
    check_store(F3_LH_SH, 2'b00, 32'hAABB_7788, OLD_NEXT_WORD, "SH");
    check_store(F3_LH_SH, 2'b01, 32'hAA77_88DD, OLD_NEXT_WORD, "SH");
    check_store(F3_LH_SH, 2'b10, 32'h7788_CCDD, OLD_NEXT_WORD, "SH");
    check_store(F3_LH_SH, 2'b11, 32'h88BB_CCDD, 32'h1122_3377, "SH");

    // =====================================================
    // Store word: store 0x55667788
    // offset 00 -> current 55667788, next unchanged
    // offset 01 -> current 667788DD, next 11223355
    // offset 10 -> current 7788CCDD, next 11225566
    // offset 11 -> current 88BBCCDD, next 11556677
    // =====================================================
    check_store(F3_LW_SW, 2'b00, 32'h5566_7788, OLD_NEXT_WORD, "SW");
    check_store(F3_LW_SW, 2'b01, 32'h6677_88DD, 32'h1122_3355, "SW");
    check_store(F3_LW_SW, 2'b10, 32'h7788_CCDD, 32'h1122_5566, "SW");
    check_store(F3_LW_SW, 2'b11, 32'h88BB_CCDD, 32'h1155_6677, "SW");

    $display("====================================");
    $display("Testing LSU load unit");
    $display("q_addr_i     = %h", OLD_WORD);
    $display("q_addradd1_i = %h", OLD_NEXT_WORD);
    $display("====================================");

    // =====================================================
    // Load byte signed
    // OLD_WORD = AABBCCDD
    // byte0 = DD -> sign extend -> FFFFFFDD
    // byte1 = CC -> sign extend -> FFFFFFCC
    // byte2 = BB -> sign extend -> FFFFFFBB
    // byte3 = AA -> sign extend -> FFFFFFAA
    // =====================================================
    check_load(F3_LB_SB, 2'b00, 32'hFFFF_FFDD, "LB");
    check_load(F3_LB_SB, 2'b01, 32'hFFFF_FFCC, "LB");
    check_load(F3_LB_SB, 2'b10, 32'hFFFF_FFBB, "LB");
    check_load(F3_LB_SB, 2'b11, 32'hFFFF_FFAA, "LB");

    // =====================================================
    // Load halfword signed
    // offset 00 -> CCDD -> FFFFCCDD
    // offset 01 -> BBCC -> FFFFBBCC
    // offset 10 -> AABB -> FFFFAABB
    // offset 11 -> 44AA -> 000044AA
    // =====================================================
    check_load(F3_LH_SH, 2'b00, 32'hFFFF_CCDD, "LH");
    check_load(F3_LH_SH, 2'b01, 32'hFFFF_BBCC, "LH");
    check_load(F3_LH_SH, 2'b10, 32'hFFFF_AABB, "LH");
    check_load(F3_LH_SH, 2'b11, 32'h0000_44AA, "LH");

    // =====================================================
    // Load word
    // offset 00 -> AABBCCDD
    // offset 01 -> 44AABBCC
    // offset 10 -> 3344AABB
    // offset 11 -> 223344AA
    // =====================================================
    check_load(F3_LW_SW, 2'b00, 32'hAABB_CCDD, "LW");
    check_load(F3_LW_SW, 2'b01, 32'h44AA_BBCC, "LW");
    check_load(F3_LW_SW, 2'b10, 32'h3344_AABB, "LW");
    check_load(F3_LW_SW, 2'b11, 32'h2233_44AA, "LW");

    // =====================================================
    // Load byte unsigned
    // =====================================================
    check_load(F3_LBU, 2'b00, 32'h0000_00DD, "LBU");
    check_load(F3_LBU, 2'b01, 32'h0000_00CC, "LBU");
    check_load(F3_LBU, 2'b10, 32'h0000_00BB, "LBU");
    check_load(F3_LBU, 2'b11, 32'h0000_00AA, "LBU");

    // =====================================================
    // Load halfword unsigned
    // =====================================================
    check_load(F3_LHU, 2'b00, 32'h0000_CCDD, "LHU");
    check_load(F3_LHU, 2'b01, 32'h0000_BBCC, "LHU");
    check_load(F3_LHU, 2'b10, 32'h0000_AABB, "LHU");
    check_load(F3_LHU, 2'b11, 32'h0000_44AA, "LHU");

    // memread off test
    memread_i = 1'b0;
    funct3    = F3_LW_SW;
    addr_i    = 32'b0;
    q_addr_i  = OLD_WORD;
    #1;

    if (wb_d_o === 32'h0000_0000)
      $display("PASS memread_i=0 wb_d_o = 0");
    else
      $display("FAIL memread_i=0 wb_d_o = %h expected 00000000", wb_d_o);

    #10;
    $finish;
  end

endmodule