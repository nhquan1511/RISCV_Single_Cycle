// Top Layer
// Module: Top
// Date: 19/7/2026
// Updated:
//========================================
module top #(
  parameter WIDTH = 32
)(
  input  wire             clk_i,
  input  wire             rst_i,

  output wire [WIDTH-1:0] pc_debug_o,
  output wire             insn_vld_o,
  output wire [WIDTH-1:0] io_ledr_o,
  output wire [WIDTH-1:0] io_ledg_o,
  output wire [6:0]       io_hex0_o,
  output wire [6:0]       io_hex1_o,
  output wire [6:0]       io_hex2_o,
  output wire [6:0]       io_hex3_o,
  output wire [6:0]       io_hex4_o,
  output wire [6:0]       io_hex5_o,
  output wire [6:0]       io_hex6_o,
  output wire [6:0]       io_hex7_o,
  output wire [WIDTH-1:0] io_lcd_o,
  input  wire [WIDTH-1:0] io_sw_i
);
//=================================
// Internal Signals
  
  wire [WIDTH-1:0]  imem_addr;
  wire [WIDTH-1:0]  instr;
  
  wire [WIDTH-1:0]  memd;
  wire [WIDTH-1:0]  memd_misaligned;
  wire [WIDTH-1:0]  q_addr;
  wire [WIDTH-1:0]  q_addradd1;
  wire [WIDTH-1:0]  dmem_addr;
  wire              memwrite;
  wire [6:0]        hex_temp [0:7];
  wire [WIDTH-1:0]  load_ledr;
  wire [WIDTH-1:0]  load_ledg;
  wire [WIDTH-1:0]  load_lcd;
  wire [WIDTH-1:0]  load_hex7seg_0to3;
  wire [WIDTH-1:0]  load_hex7seg_4to7;
  wire [WIDTH-1:0]  load_switches;

//==================================

  imem instrmem (
    .addr_i(imem_addr),
    .instr_o(instr)
  );

  dmem datamem (
    .addr_i(dmem_addr),
    .clk_i(clk_i),
    .rst_i(~rst_i),
    .d_i(memd),
    .d_misaligned_i(memd_misaligned),
    .memwrite_i(memwrite),
    .q_addr_o(q_addr),
    .q_addradd1_o(q_addradd1)
  );

  riscv_core core (
    .clk_i(clk_i),
    .rst_i(~rst_i),
    .imem_addr_o(imem_addr),
    .instr_i(instr),
    .memd_o(memd),
    .memd_misaligned_o(memd_misaligned),
    .q_addr_i(q_addr | load_ledr | load_ledg | load_hex7seg_0to3 | load_hex7seg_4to7 | load_lcd | load_switches),
    .q_addradd1_i(q_addradd1),
    .dmem_addr_o(dmem_addr),
    .memwrite_o(memwrite)
  );
//=========================================
  assign pc_debug_o = imem_addr;
  assign insn_vld_o = rst_i;

  ledr redled (
    .clk_i(clk_i),
    .rst_i(~rst_i),
    .memwrite_i(memwrite),
    .addr_i(dmem_addr),
    .d_i(memd),
    .d_o(io_ledr_o),
    .load_ledr(load_ledr)
  );
  
  ledg greenled (
    .clk_i(clk_i),
    .rst_i(~rst_i),
    .memwrite_i(memwrite),
    .addr_i(dmem_addr),
    .d_i(memd),
    .d_o(io_ledg_o),
    .load_ledg(load_ledg) 
  );
   
  
  assign io_hex0_o = hex_temp[0];
  assign io_hex1_o = hex_temp[1];
  assign io_hex2_o = hex_temp[2];
  assign io_hex3_o = hex_temp[3];
  assign io_hex4_o = hex_temp[4];
  assign io_hex5_o = hex_temp[5];
  assign io_hex6_o = hex_temp[6];
  assign io_hex7_o = hex_temp[7];
  hex7seg sev_segled (
    .clk_i(clk_i),
    .rst_i(~rst_i),
    .memwrite_i(memwrite),
    .addr_i(dmem_addr),
    .d_i(memd),
    .d_o(hex_temp),
    .load_hex7seg_0to3(load_hex7seg_0to3),
    .load_hex7seg_4to7(load_hex7seg_4to7)
  );

  lcd u_lcd (
    .clk_i(clk_i),
    .rst_i(~rst_i),
    .memwrite_i(memwrite),
    .addr_i(dmem_addr),
    .d_i(memd),
    .d_o(io_lcd_o),
    .load_lcd(load_lcd)    
  );

  switches sw (
    .addr_i(dmem_addr),
    .d_i(io_sw_i),
    .load_switches(load_switches)
  );
endmodule