// RISC-V Core (Without Imem and Dmem)
// Module: RISC-V Core
// Date 18/7/2026
// Updated: 19/7/2026
//==============================================
module riscv_core #(
  parameter WIDTH = 32
)(
  input   wire             clk_i,
  input   wire             rst_i,

  // Imem Interface
  output  wire [WIDTH-1:0] imem_addr_o,
  input   wire [WIDTH-1:0] instr_i,

  // Dmem Interface
  output  wire [WIDTH-1:0] memd_o,
  output  wire [WIDTH-1:0] memd_misaligned_o,
  input   wire [WIDTH-1:0] q_addr_i,
  input   wire [WIDTH-1:0] q_addradd1_i,

  output  wire [WIDTH-1:0] dmem_addr_o,
  output  wire             memwrite_o
);
//=================================================
// Internal Signals

  wire              memread;
  wire [1:0]        aluop;
  wire              wb [0:1];
  wire              alusrc1;
  wire              alusrc2;
  wire              regwrite;
  wire              immsel [0:4];
  wire              branchsel [0:2];
  wire              uppersel;
  wire [WIDTH-1:0]  imm;
  wire              en;
  wire [WIDTH-1:0]  temp_pcadd4;
  wire [WIDTH-1:0]  temp_pcaddimm;
  wire [WIDTH-1:0]  temp_rs1addimm;
  wire [WIDTH-1:0]  temp1_i[0:1];
  wire [WIDTH-1:0]  y1;
  wire [WIDTH-1:0]  temp2_i[0:1];
  wire [WIDTH-1:0]  next_pc;
  wire [WIDTH-1:0]  r1;
  wire [WIDTH-1:0]  r2;
  wire [3:0]        aluctrl;
  wire [WIDTH-1:0]  temp_ui [0:1];
  wire [WIDTH-1:0]  ui;
  wire [WIDTH-1:0]  temp_alusrc1 [0:1];
  wire [WIDTH-1:0]  r1_alu;
  wire [WIDTH-1:0]  temp_alusrc2 [0:1];
  wire [WIDTH-1:0]  r2_alu;
  wire [WIDTH-1:0]  result;
  wire [WIDTH-1:0]  load_d;
  wire [WIDTH-1:0]  temp_wb1 [0:1];
  wire [WIDTH-1:0]  wb1;
  wire [WIDTH-1:0]  temp_wb2 [0:1];
  wire [WIDTH-1:0]  d_regfile;

//=================================================
// Control Unit

  controlunit cu (
    .opcode_i(instr_i[6:0]),
    .aluop_o(aluop),
    .memread_o(memread),
    .memwrite_o(memwrite_o),
    .wb_o(wb),
    .alusrc1_o(alusrc1),
    .alusrc2_o(alusrc2),
    .regwrite_o(regwrite),
    .immsel_o(immsel),
    .branchsel_o(branchsel),
    .uppersel_o(uppersel)
  );
//====================================================
// Immediate Generator

  immgen #(
    .WIDTH(WIDTH)
  ) immgen (
    .instr_i(instr_i),
    .immsel_i(immsel),
    .imm_o(imm)
  );
//=====================================================
// Register File

  register_file #(
    .WIDTH(WIDTH)
  ) regfile (
    .clk_i(clk_i),
    .rst_i(rst_i),
    .rd_i(instr_i[11:7]),
    .d_i(d_regfile),
    .wr_i(regwrite),
    .rs1_i(instr_i[19:15]),
    .rs2_i(instr_i[24:20]),
    .r1_o(r1),
    .r2_o(r2)
  );   
//====================================================
// PC

  pccontrolunit #(
    .WIDTH(WIDTH)
  ) pccu (
    .funct3_i(instr_i[14:12]),
    .branchsel_i(branchsel[0:1]),
    .r1_i(r1_alu),
    .r2_i(r2_alu),
    .en_o(en)
  );

  add_subtract #(
    .WIDTH(WIDTH)
  ) pcadd4 (
    .a_i(imem_addr_o),
    .b_i(32'd4),
    .mode_i(1'b0),
    .s_o(temp_pcadd4),
    .cout_o(),
    .overflow()
  );

  add_subtract #(
    .WIDTH(WIDTH)
  ) pcaddimm (
    .a_i(imem_addr_o),
    .b_i(imm),
    .mode_i(1'b0),
    .s_o(temp_pcaddimm),
    .cout_o(),
    .overflow()
  ); 

  add_subtract #(
    .WIDTH(WIDTH)
  ) rs1addimm (
    .a_i(r1_alu),
    .b_i(imm),
    .mode_i(1'b0),
    .s_o(temp_rs1addimm),
    .cout(),
    .overflow()
  );

  assign temp1_i[0] = temp_pcadd4;
  assign temp1_i[1] = temp_pcaddimm;
  mux_21 branchmux1(
    .i_i(temp1_i),
    .s_i(en),
    .y_o(y1)
  );

  assign temp2_i[0] = y1;
  assign temp2_i[1] = temp_rs1addimm;
  mux_21 branchmux2(
    .i_i(temp2_i),
    .s_i(branchsel[2]),
    .y_o(next_pc)
  );
  
  pc #(
    .WIDTH(WIDTH)
    ) pc (
    .next_pc_i(next_pc),
    .clk_i(clk_i),
    .rst_i(rst_i),
    .pc_o(imem_addr_o)
  );
//=======================================================
// ALU

  aluctrl u_aluctrl (
    .funct7_i(instr_i[31:25]),
    .funct3_i(instr_i[14:12]),
    .aluop_i(aluop),
    .aluctrl_o(aluctrl)
  );

  assign temp_ui[0] = imem_addr_o;
  assign temp_ui[1] = 32'b0;
  mux_21 u_ui (
    .i_i(temp_ui),
    .s_i(uppersel),
    .y_o(ui)
  );

  assign temp_alusrc1[0] = r1;
  assign temp_alusrc1[1] = ui;
  mux_21 u_alusrc1 (
    .i_i(temp_alusrc1),
    .s_i(alusrc1),
    .y_o(r1_alu)
  );

  assign temp_alusrc2[0] = r2;
  assign temp_alusrc2[1] = imm;
  mux_21 u_alusrc2 (
    .i_i(temp_alusrc2),
    .s_i(alusrc2),
    .y_o(r2_alu)
  );

  alu #(
    .WIDTH(WIDTH)
  ) alu (
    .r1_i(r1_alu),
    .r2_i(r2_alu),
    .aluctrl_i(aluctrl),
    .result_o(result)
  );
//====================================================
// LSU

  lsu #(
    .WIDTH(WIDTH)
  ) u_lsu (
    .funct3(instr_i[14:12]),
    .addr_i(result),
    .memread_i(memread),
    .store_d_i(r2),
    .q_addr_i(q_addr_i),
    .q_addradd1_i(q_addradd1_i),
    .memd_o(memd_o),
    .memd_misaligned_o(memd_misaligned_o),
    .wb_d_o(load_d)
  );

  assign dmem_addr_o = result;
//======================================================
// Write Back

  assign temp_wb1[0] = result;
  assign temp_wb1[1] = load_d;
  mux_21 wbmux1 (
    .i_i(temp_wb1),
    .s_i(wb[0]),
    .y_o(wb1)
  );

  assign temp_wb2[0] = wb1;
  assign temp_wb2[1] = temp_pcadd4;
  mux_21 wbmux2 (
    .i_i(temp_wb2),
    .s_i(wb[1]),
    .y_o(d_regfile)
  );
endmodule