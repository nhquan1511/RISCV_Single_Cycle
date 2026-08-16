`timescale 1ns/1ps

module tb_immgen;

  parameter WIDTH = 32;

  logic [WIDTH-1:0] instr_i;
  logic             immsel_i [0:4];
  wire  [WIDTH-1:0] imm_o;

  immgen #(
    .WIDTH(WIDTH)
  ) dut (
    .instr_i   (instr_i),
    .immsel_i  (immsel_i),
    .imm_o     (imm_o)
  );

  // immsel index meaning:
  // immsel_i[0] = I-type
  // immsel_i[1] = S-type
  // immsel_i[2] = B-type
  // immsel_i[3] = U-type
  // immsel_i[4] = J-type

  task clear_immsel;
    begin
      immsel_i[0] = 1'b0;
      immsel_i[1] = 1'b0;
      immsel_i[2] = 1'b0;
      immsel_i[3] = 1'b0;
      immsel_i[4] = 1'b0;
    end
  endtask

  task check_imm(
    input [31:0] instr,
    input integer sel,
    input [31:0] expected,
    input string name
  );
    begin
      instr_i = instr;
      clear_immsel();
      immsel_i[sel] = 1'b1;

      #1;

      if (imm_o === expected) begin
        $display("PASS %-16s instr=%h imm=%h", name, instr_i, imm_o);
      end
      else begin
        $display("FAIL %-16s instr=%h", name, instr_i);
        $display("  imm_o    = %h", imm_o);
        $display("  expected = %h", expected);
      end
    end
  endtask

  task check_no_select(
    input [31:0] instr
  );
    begin
      instr_i = instr;
      clear_immsel();

      #1;

      if (imm_o === 32'h0000_0000) begin
        $display("PASS no immediate selected imm=%h", imm_o);
      end
      else begin
        $display("FAIL no immediate selected");
        $display("  imm_o    = %h", imm_o);
        $display("  expected = 00000000");
      end
    end
  endtask

  initial begin
    $fsdbDumpfile("dump.fsdb");
    $fsdbDumpvars(0, tb_immgen, "+all");
  end

  initial begin
    instr_i = 32'b0;
    clear_immsel();

    #5;

    $display("========================================");
    $display("Immediate Generator Test");
    $display("========================================");

    // =====================================================
    // I-type immediate
    //
    // addi x1, x0, 12
    // imm = 12 = 0x0000000C
    //
    // Encoding:
    // imm[11:0] = 000000001100
    // rs1       = x0
    // funct3    = 000
    // rd        = x1
    // opcode    = 0010011
    //
    // instr = 0x00C00093
    // =====================================================
    check_imm(32'h00C0_0093, 0, 32'h0000_000C, "I addi +12");

    // =====================================================
    // I-type negative immediate
    //
    // addi x1, x0, -1
    // imm[11:0] = 0xFFF
    // sign-extended imm = 0xFFFFFFFF
    //
    // instr = 0xFFF00093
    // =====================================================
    check_imm(32'hFFF0_0093, 0, 32'hFFFF_FFFF, "I addi -1");

    // =====================================================
    // I-type load immediate
    //
    // lw x5, 20(x2)
    // imm = 20 = 0x14
    //
    // instr = 0x01412283
    // =====================================================
    check_imm(32'h0141_2283, 0, 32'h0000_0014, "I lw +20");

    // =====================================================
    // S-type immediate
    //
    // sw x5, 8(x2)
    // imm = 8
    //
    // S immediate = {instr[31:25], instr[11:7]}
    //
    // instr = 0x00512423
    // =====================================================
    check_imm(32'h0051_2423, 1, 32'h0000_0008, "S sw +8");

    // =====================================================
    // S-type negative immediate
    //
    // sw x5, -4(x2)
    // imm = -4 = 0xFFFFFFFC
    //
    // imm[11:0] = 0xFFC
    //
    // instr = 0xFE512E23
    // =====================================================
    check_imm(32'hFE51_2E23, 1, 32'hFFFF_FFFC, "S sw -4");

    // =====================================================
    // B-type immediate
    //
    // beq x1, x2, +16
    // Branch immediates are multiples of 2.
    // Expected immediate = 16 = 0x00000010
    //
    // instr = 0x00208863
    // =====================================================
    check_imm(32'h0020_8863, 2, 32'h0000_0010, "B beq +16");

    // =====================================================
    // B-type negative immediate
    //
    // beq x1, x2, -4
    // Expected immediate = -4 = 0xFFFFFFFC
    //
    // instr = 0xFE208EE3
    // =====================================================
    check_imm(32'hFE20_8EE3, 2, 32'hFFFF_FFFC, "B beq -4");

    // =====================================================
    // U-type immediate
    //
    // lui x3, 0x12345
    // imm = 0x12345000
    //
    // instr = 0x123451B7
    // =====================================================
    check_imm(32'h1234_51B7, 3, 32'h1234_5000, "U lui 12345");

    // =====================================================
    // U-type with sign bit high
    //
    // lui x3, 0xFFFFF
    // imm = 0xFFFFF000
    //
    // U-type is not sign-extended here.
    // It is directly instr[31:12] << 12.
    //
    // instr = 0xFFFFF1B7
    // =====================================================
    check_imm(32'hFFFF_F1B7, 3, 32'hFFFF_F000, "U lui FFFFF");

    // =====================================================
    // J-type immediate
    //
    // jal x1, +32
    // Expected immediate = 32 = 0x00000020
    //
    // instr = 0x020000EF
    // =====================================================
    check_imm(32'h0200_00EF, 4, 32'h0000_0020, "J jal +32");

    // =====================================================
    // J-type negative immediate
    //
    // jal x1, -4
    // Expected immediate = -4 = 0xFFFFFFFC
    //
    // instr = 0xFFDFF0EF
    // =====================================================
    check_imm(32'hFFDFF_0EF, 4, 32'hFFFF_FFFC, "J jal -4");

    // =====================================================
    // No immediate selected
    // =====================================================
    check_no_select(32'hFFFF_FFFF);

    $display("========================================");
    $display("Immediate Generator Test Finished");
    $display("========================================");

    #20;
    $finish;
  end

endmodule