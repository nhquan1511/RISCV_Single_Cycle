`timescale 1ns/1ps

module tb_controlunit;

  logic [6:0] opcode_i;

  wire [1:0] aluop_o;
  wire       memread_o;
  wire       memwrite_o;

  wire wb_o [0:1];
  wire alusrc2_o;
  wire alusrc1_o;
  wire regwrite_o;
  wire immsel_o [0:4];
  wire branchsel_o [0:2];
  wire uppersel_o;

  controlunit dut (
    .opcode_i    (opcode_i),
    .aluop_o     (aluop_o),

    .memread_o   (memread_o),
    .memwrite_o  (memwrite_o),

    .wb_o        (wb_o),
    .alusrc2_o   (alusrc2_o),
    .alusrc1_o   (alusrc1_o),
    .regwrite_o  (regwrite_o),
    .immsel_o    (immsel_o),
    .branchsel_o (branchsel_o),
    .uppersel_o  (uppersel_o)
  );

  // =====================================================
  // RISC-V opcodes
  // =====================================================
  localparam OPCODE_RTYPE  = 7'b0110011;
  localparam OPCODE_ITYPE  = 7'b0010011;
  localparam OPCODE_LOAD   = 7'b0000011;
  localparam OPCODE_STORE  = 7'b0100011;
  localparam OPCODE_BRANCH = 7'b1100011;
  localparam OPCODE_JAL    = 7'b1101111;
  localparam OPCODE_JALR   = 7'b1100111;
  localparam OPCODE_LUI    = 7'b0110111;
  localparam OPCODE_AUIPC  = 7'b0010111;

  // =====================================================
  // Check task
  // =====================================================
  task check_control(
    input [6:0] opcode,
    input [1:0] exp_aluop,

    input       exp_memread,
    input       exp_memwrite,

    input       exp_wb0,
    input       exp_wb1,

    input       exp_alusrc2,
    input       exp_alusrc1,
    input       exp_regwrite,

    input       exp_imm0,
    input       exp_imm1,
    input       exp_imm2,
    input       exp_imm3,
    input       exp_imm4,

    input       exp_branch0,
    input       exp_branch1,
    input       exp_branch2,

    input       exp_uppersel,

    input string name
  );
    begin
      opcode_i = opcode;
      #1;

      if (
        aluop_o        === exp_aluop    &&
        memread_o      === exp_memread  &&
        memwrite_o     === exp_memwrite &&
        wb_o[0]        === exp_wb0      &&
        wb_o[1]        === exp_wb1      &&
        alusrc2_o      === exp_alusrc2  &&
        alusrc1_o      === exp_alusrc1  &&
        regwrite_o     === exp_regwrite &&
        immsel_o[0]    === exp_imm0     &&
        immsel_o[1]    === exp_imm1     &&
        immsel_o[2]    === exp_imm2     &&
        immsel_o[3]    === exp_imm3     &&
        immsel_o[4]    === exp_imm4     &&
        branchsel_o[0] === exp_branch0  &&
        branchsel_o[1] === exp_branch1  &&
        branchsel_o[2] === exp_branch2  &&
        uppersel_o     === exp_uppersel
      ) begin
        $display("PASS %-10s opcode=%b", name, opcode_i);
      end
      else begin
        $display("FAIL %-10s opcode=%b", name, opcode_i);

        $display("  aluop_o        = %b expected = %b", aluop_o, exp_aluop);
        $display("  memread_o      = %b expected = %b", memread_o, exp_memread);
        $display("  memwrite_o     = %b expected = %b", memwrite_o, exp_memwrite);

        $display("  wb_o[0]        = %b expected = %b", wb_o[0], exp_wb0);
        $display("  wb_o[1]        = %b expected = %b", wb_o[1], exp_wb1);

        $display("  alusrc2_o      = %b expected = %b", alusrc2_o, exp_alusrc2);
        $display("  alusrc1_o      = %b expected = %b", alusrc1_o, exp_alusrc1);
        $display("  regwrite_o     = %b expected = %b", regwrite_o, exp_regwrite);

        $display("  immsel_o[0]    = %b expected = %b", immsel_o[0], exp_imm0);
        $display("  immsel_o[1]    = %b expected = %b", immsel_o[1], exp_imm1);
        $display("  immsel_o[2]    = %b expected = %b", immsel_o[2], exp_imm2);
        $display("  immsel_o[3]    = %b expected = %b", immsel_o[3], exp_imm3);
        $display("  immsel_o[4]    = %b expected = %b", immsel_o[4], exp_imm4);

        $display("  branchsel_o[0] = %b expected = %b", branchsel_o[0], exp_branch0);
        $display("  branchsel_o[1] = %b expected = %b", branchsel_o[1], exp_branch1);
        $display("  branchsel_o[2] = %b expected = %b", branchsel_o[2], exp_branch2);

        $display("  uppersel_o     = %b expected = %b", uppersel_o, exp_uppersel);
      end
    end
  endtask

  initial begin
    $fsdbDumpfile("dump.fsdb");
    $fsdbDumpvars(0, tb_controlunit, "+all");
  end

  initial begin
    opcode_i = 7'b0;

    #5;

    $display("========================================");
    $display("Control Unit Test");
    $display("========================================");

    // =====================================================
    // R-type: add/sub/and/or/xor/slt/sltu/sll/srl/sra
    //
    // ALU uses rs1 and rs2.
    // Writeback from ALU.
    // =====================================================
    check_control(
      OPCODE_RTYPE,
      2'b01,  // aluop

      1'b0,   // memread
      1'b0,   // memwrite

      1'b0,   // wb[0], memory writeback select
      1'b0,   // wb[1], PC+4 writeback select

      1'b0,   // alusrc2, rs2
      1'b0,   // alusrc1, rs1
      1'b1,   // regwrite

      1'b0,   // I imm
      1'b0,   // S imm
      1'b0,   // B imm
      1'b0,   // U imm
      1'b0,   // J imm

      1'b0,   // branch
      1'b0,   // jal
      1'b0,   // jalr

      1'b0,   // uppersel

      "R-type"
    );

    // =====================================================
    // I-type ALU: addi/andi/ori/xori/slti/sltiu/slli/srli/srai
    //
    // ALU uses rs1 and immediate.
    // Writeback from ALU.
    // =====================================================
    check_control(
      OPCODE_ITYPE,
      2'b10,

      1'b0,
      1'b0,

      1'b0,
      1'b0,

      1'b1,   // alusrc2 = imm
      1'b0,   // alusrc1 = rs1
      1'b1,   // regwrite

      1'b1,   // I imm
      1'b0,
      1'b0,
      1'b0,
      1'b0,

      1'b0,
      1'b0,
      1'b0,

      1'b0,

      "I-ALU"
    );

    // =====================================================
    // LOAD: lb/lh/lw/lbu/lhu
    //
    // Address = rs1 + imm.
    // Writeback from memory.
    // =====================================================
    check_control(
      OPCODE_LOAD,
      2'b00,

      1'b1,   // memread
      1'b0,

      1'b1,   // wb[0] = memory
      1'b0,

      1'b1,   // alusrc2 = imm
      1'b0,
      1'b1,

      1'b1,   // I imm
      1'b0,
      1'b0,
      1'b0,
      1'b0,

      1'b0,
      1'b0,
      1'b0,

      1'b0,

      "LOAD"
    );

    // =====================================================
    // STORE: sb/sh/sw
    //
    // Address = rs1 + imm.
    // No register writeback.
    //
    // Important:
    // This expects you already fixed:
    // alusrc2_o = itype_detect | stype_detect | utype_detect;
    // =====================================================
    check_control(
      OPCODE_STORE,
      2'b00,

      1'b0,
      1'b1,   // memwrite

      1'b0,
      1'b0,

      1'b1,   // alusrc2 = imm
      1'b0,   // alusrc1 = rs1
      1'b0,   // no regwrite

      1'b0,
      1'b1,   // S imm
      1'b0,
      1'b0,
      1'b0,

      1'b0,
      1'b0,
      1'b0,

      1'b0,

      "STORE"
    );

    // =====================================================
    // BRANCH: beq/bne/blt/bge/bltu/bgeu
    //
    // PC target uses B immediate.
    // No register writeback.
    // =====================================================
    check_control(
      OPCODE_BRANCH,
      2'b00,

      1'b0,
      1'b0,

      1'b0,
      1'b0,

      1'b0,
      1'b0,
      1'b0,

      1'b0,
      1'b0,
      1'b1,   // B imm
      1'b0,
      1'b0,

      1'b1,   // conditional branch
      1'b0,
      1'b0,

      1'b0,

      "BRANCH"
    );

    // =====================================================
    // JAL
    //
    // PC target = PC + J immediate.
    // rd = PC + 4.
    // =====================================================
    check_control(
      OPCODE_JAL,
      2'b00,

      1'b0,
      1'b0,

      1'b0,
      1'b1,   // wb[1] = PC + 4

      1'b0,
      1'b0,
      1'b1,   // regwrite

      1'b0,
      1'b0,
      1'b0,
      1'b0,
      1'b1,   // J imm

      1'b0,
      1'b1,   // JAL
      1'b0,

      1'b0,

      "JAL"
    );

    // =====================================================
    // JALR
    //
    // PC target = rs1 + I immediate.
    // rd = PC + 4.
    // =====================================================
    check_control(
      OPCODE_JALR,
      2'b00,

      1'b0,
      1'b0,

      1'b0,
      1'b1,   // wb[1] = PC + 4

      1'b1,   // alusrc2 = imm
      1'b0,   // alusrc1 = rs1
      1'b1,   // regwrite

      1'b1,   // I imm
      1'b0,
      1'b0,
      1'b0,
      1'b0,

      1'b0,
      1'b0,
      1'b1,   // JALR

      1'b0,

      "JALR"
    );

    // =====================================================
    // LUI
    //
    // immgen gives U immediate.
    // uppersel selects imm directly.
    // rd = imm.
    // =====================================================
    check_control(
      OPCODE_LUI,
      2'b00,

      1'b0,
      1'b0,

      1'b0,
      1'b0,

      1'b1,   // alusrc2 = imm, harmless because uppersel selects imm
      1'b1,   // alusrc1 = special upper path / PC path in your design
      1'b1,   // regwrite

      1'b0,
      1'b0,
      1'b0,
      1'b1,   // U imm
      1'b0,

      1'b0,
      1'b0,
      1'b0,

      1'b1,   // uppersel = LUI

      "LUI"
    );

    // =====================================================
    // AUIPC
    //
    // ALU result = PC + U immediate.
    // rd = ALU result.
    // =====================================================
    check_control(
      OPCODE_AUIPC,
      2'b00,

      1'b0,
      1'b0,

      1'b0,
      1'b0,

      1'b1,   // alusrc2 = imm
      1'b1,   // alusrc1 = PC
      1'b1,   // regwrite

      1'b0,
      1'b0,
      1'b0,
      1'b1,   // U imm
      1'b0,

      1'b0,
      1'b0,
      1'b0,

      1'b0,   // uppersel = 0, use ALU result

      "AUIPC"
    );

    $display("========================================");
    $display("Control Unit Test Finished");
    $display("========================================");

    #20;
    $finish;
  end

endmodule