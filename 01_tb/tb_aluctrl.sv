`timescale 1ns/1ps

module tb_aluctrl;

  logic [6:0] funct7_i;
  logic [2:0] funct3_i;
  logic [1:0] aluop_i;

  wire [3:0] aluctrl_o;

  aluctrl dut (
    .funct7_i  (funct7_i),
    .funct3_i  (funct3_i),
    .aluop_i   (aluop_i),
    .aluctrl_o (aluctrl_o)
  );

  // =====================================================
  // ALUOp meaning in your design
  // =====================================================
  localparam ALUOP_DEFAULT = 2'b00; // LOAD/STORE/BRANCH/AUIPC address/add
  localparam ALUOP_RTYPE   = 2'b01; // R-type instruction
  localparam ALUOP_ITYPE   = 2'b10; // I-type ALU instruction

  // =====================================================
  // ALU control values in your ALU
  // =====================================================
  localparam CTRL_ADD  = 4'b0000;
  localparam CTRL_SUB  = 4'b0001;
  localparam CTRL_AND  = 4'b0010;
  localparam CTRL_SLL  = 4'b0011;
  localparam CTRL_SRL  = 4'b0100;
  localparam CTRL_OR   = 4'b0101;
  localparam CTRL_XOR  = 4'b0111;
  localparam CTRL_SLTU = 4'b1001;
  localparam CTRL_SLT  = 4'b1011;
  localparam CTRL_SRA  = 4'b1100;

  task check_aluctrl(
    input [6:0] f7,
    input [2:0] f3,
    input [1:0] op,
    input [3:0] expected,
    input string name
  );
    begin
      funct7_i = f7;
      funct3_i = f3;
      aluop_i  = op;

      #1;

      if (aluctrl_o === expected) begin
        $display("PASS %-16s aluop=%b funct7=%b funct3=%b ctrl=%b",
                 name, aluop_i, funct7_i, funct3_i, aluctrl_o);
      end
      else begin
        $display("FAIL %-16s aluop=%b funct7=%b funct3=%b",
                 name, aluop_i, funct7_i, funct3_i);
        $display("  aluctrl_o = %b expected = %b", aluctrl_o, expected);
      end
    end
  endtask

  initial begin
    $fsdbDumpfile("dump.fsdb");
    $fsdbDumpvars(0, tb_aluctrl, "+all");
  end

  initial begin
    funct7_i = 7'b0;
    funct3_i = 3'b0;
    aluop_i  = 2'b0;

    #5;

    $display("========================================");
    $display("ALU Control Test");
    $display("========================================");

    // =====================================================
    // ALUOp = 00
    //
    // Used for load/store address calculation, branch target,
    // AUIPC, etc. It should always output ADD.
    // =====================================================
    check_aluctrl(
      7'b0000000,
      3'b000,
      ALUOP_DEFAULT,
      CTRL_ADD,
      "ALUOP00 ADD"
    );

    check_aluctrl(
      7'b0100000,
      3'b101,
      ALUOP_DEFAULT,
      CTRL_ADD,
      "ALUOP00 still ADD"
    );

    // =====================================================
    // R-type instructions
    //
    // Reference RV32I:
    // add/sub/xor/or/and/sll/srl/sra/slt/sltu
    // =====================================================

    check_aluctrl(
      7'b0000000,
      3'b000,
      ALUOP_RTYPE,
      CTRL_ADD,
      "R ADD"
    );

    check_aluctrl(
      7'b0100000,
      3'b000,
      ALUOP_RTYPE,
      CTRL_SUB,
      "R SUB"
    );

    check_aluctrl(
      7'b0000000,
      3'b111,
      ALUOP_RTYPE,
      CTRL_AND,
      "R AND"
    );

    check_aluctrl(
      7'b0000000,
      3'b110,
      ALUOP_RTYPE,
      CTRL_OR,
      "R OR"
    );

    check_aluctrl(
      7'b0000000,
      3'b100,
      ALUOP_RTYPE,
      CTRL_XOR,
      "R XOR"
    );

    check_aluctrl(
      7'b0000000,
      3'b001,
      ALUOP_RTYPE,
      CTRL_SLL,
      "R SLL"
    );

    check_aluctrl(
      7'b0000000,
      3'b101,
      ALUOP_RTYPE,
      CTRL_SRL,
      "R SRL"
    );

    check_aluctrl(
      7'b0100000,
      3'b101,
      ALUOP_RTYPE,
      CTRL_SRA,
      "R SRA"
    );

    check_aluctrl(
      7'b0000000,
      3'b010,
      ALUOP_RTYPE,
      CTRL_SLT,
      "R SLT"
    );

    check_aluctrl(
      7'b0000000,
      3'b011,
      ALUOP_RTYPE,
      CTRL_SLTU,
      "R SLTU"
    );

    // =====================================================
    // I-type ALU instructions
    //
    // addi/xori/ori/andi/slli/srli/srai/slti/sltiu
    //
    // Important:
    // For ADDI, funct7_i comes from immediate bits.
    // So even if funct7_i[5] is 1, ADDI must still produce ADD.
    // Your aluctrl_temp[2] handles this.
    // =====================================================

    check_aluctrl(
      7'b0000000,
      3'b000,
      ALUOP_ITYPE,
      CTRL_ADD,
      "I ADDI"
    );

    check_aluctrl(
      7'b1111111,
      3'b000,
      ALUOP_ITYPE,
      CTRL_ADD,
      "I ADDI imm high"
    );

    check_aluctrl(
      7'b0000000,
      3'b111,
      ALUOP_ITYPE,
      CTRL_AND,
      "I ANDI"
    );

    check_aluctrl(
      7'b0000000,
      3'b110,
      ALUOP_ITYPE,
      CTRL_OR,
      "I ORI"
    );

    check_aluctrl(
      7'b0000000,
      3'b100,
      ALUOP_ITYPE,
      CTRL_XOR,
      "I XORI"
    );

    check_aluctrl(
      7'b0000000,
      3'b001,
      ALUOP_ITYPE,
      CTRL_SLL,
      "I SLLI"
    );

    check_aluctrl(
      7'b0000000,
      3'b101,
      ALUOP_ITYPE,
      CTRL_SRL,
      "I SRLI"
    );

    check_aluctrl(
      7'b0100000,
      3'b101,
      ALUOP_ITYPE,
      CTRL_SRA,
      "I SRAI"
    );

    check_aluctrl(
      7'b0000000,
      3'b010,
      ALUOP_ITYPE,
      CTRL_SLT,
      "I SLTI"
    );

    check_aluctrl(
      7'b0000000,
      3'b011,
      ALUOP_ITYPE,
      CTRL_SLTU,
      "I SLTIU"
    );

    // =====================================================
    // ALUOp = 11
    //
    // Your design sets aluctrl_temp[3] = ADD.
    // This may be unused, but test it anyway.
    // =====================================================
    check_aluctrl(
      7'b0100000,
      3'b101,
      2'b11,
      CTRL_ADD,
      "ALUOP11 ADD"
    );

    $display("========================================");
    $display("ALU Control Test Finished");
    $display("========================================");

    #20;
    $finish;
  end

endmodule