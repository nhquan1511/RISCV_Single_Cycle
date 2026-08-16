// Load-Store Unit
// Module: LSU
// Date: 13/7/2026
// Updated: 13/7/2026
//============================================
module lsu #(
  parameter WIDTH = 32
)(
  input  wire [2:0]       funct3,
  input  wire [WIDTH-1:0] addr_i,
  input  wire             memread_i,
  input  wire [WIDTH-1:0] store_d_i,          // Pre-modified

  input  wire [WIDTH-1:0] q_addr_i,           // Previous data
  input  wire [WIDTH-1:0] q_addradd1_i,       // Previous data (Misaligned)

  output reg  [WIDTH-1:0] memd_o,             // Store data to Dmem
  output reg  [WIDTH-1:0] memd_misaligned_o,  // Store misaligned data
  output reg  [WIDTH-1:0] wb_d_o              // Write back data
);

//===========================================
// Instruction Detector
  wire lb_detect;
  wire lh_detect;
  wire lw_detect;
  wire lbu_detect;
  wire lhu_detect;

  assign lb_detect  = ~funct3[2] & ~funct3[1] & ~funct3[0];
  assign lh_detect  = ~funct3[2] & ~funct3[1] &  funct3[0];
  assign lw_detect  = ~funct3[2] &  funct3[1] & ~funct3[0];
  assign lbu_detect =  funct3[2] & ~funct3[1] & ~funct3[0];
  assign lhu_detect =  funct3[2] & ~funct3[1] &  funct3[0];

  wire sb_detect;
  wire sh_detect;
  wire sw_detect;

  assign sb_detect = ~funct3[2] & ~funct3[1] & ~funct3[0];
  assign sh_detect = ~funct3[2] & ~funct3[1] &  funct3[0];
  assign sw_detect = ~funct3[2] &  funct3[1] & ~funct3[0];

//=========================================
// Store Unit 

  reg [WIDTH-1:0] mask_sb;
  reg [WIDTH-1:0] memd_sb;
  always_comb begin
    case(addr_i[1:0])
      2'b00: begin
        mask_sb = 32'h000000FF;
        memd_sb = (mask_sb & {24'b0, store_d_i[7:0]}) | (~mask_sb & q_addr_i); 
      end
      2'b01: begin
        mask_sb = 32'h0000FF00;
        memd_sb = (mask_sb & {16'b0, store_d_i[7:0], 8'b0}) | (~mask_sb & q_addr_i);
      end
      2'b10: begin
        mask_sb = 32'h00FF0000;
        memd_sb = (mask_sb & {8'b0, store_d_i[7:0], 16'b0}) | (~mask_sb & q_addr_i);
      end
      2'b11: begin
        mask_sb = 32'hFF000000;
        memd_sb = (mask_sb & {store_d_i[7:0], 24'b0}) | (~mask_sb & q_addr_i);
      end
    endcase
  end


  reg [WIDTH-1:0] mask_sh;
  reg [WIDTH-1:0] mask_sh_misaligned;
  reg [WIDTH-1:0] memd_sh;
  reg [WIDTH-1:0] memd_sh_misaligned;
  always_comb begin
    case(addr_i[1:0])
      2'b00: begin
        mask_sh = 32'h0000FFFF;
        mask_sh_misaligned = 32'h00000000;
        memd_sh = (mask_sh & {16'b0, store_d_i[15:0]}) | (~mask_sh & q_addr_i);
        memd_sh_misaligned = q_addradd1_i;
      end
      2'b01: begin
        mask_sh = 32'h00FFFF00;
        mask_sh_misaligned = 32'h00000000;
        memd_sh = (mask_sh & {8'b0, store_d_i[15:0], 8'b0}) | (~mask_sh & q_addr_i);
        memd_sh_misaligned = q_addradd1_i;
      end
      2'b10: begin
        mask_sh = 32'hFFFF0000;
        mask_sh_misaligned = 32'h00000000;
        memd_sh = (mask_sh & {store_d_i[15:0], 16'b0}) | (~mask_sh & q_addr_i);
        memd_sh_misaligned = q_addradd1_i;
      end
      2'b11: begin
        mask_sh = 32'hFF000000;
        mask_sh_misaligned = 32'h000000FF;
        memd_sh = (mask_sh & {store_d_i[7:0], 24'b0}) | (~mask_sh & q_addr_i);
        memd_sh_misaligned = (mask_sh_misaligned & {24'b0, store_d_i[15:8]}) | (~mask_sh_misaligned & q_addradd1_i);
      end
    endcase
  end


  reg [WIDTH-1:0] mask_sw;
  reg [WIDTH-1:0] mask_sw_misaligned;
  reg [WIDTH-1:0] memd_sw;
  reg [WIDTH-1:0] memd_sw_misaligned;
  always_comb begin
    case(addr_i[1:0]) 
      2'b00: begin
        mask_sw = 32'hFFFFFFFF;
        mask_sw_misaligned = 32'h00000000;
        memd_sw = store_d_i;
        memd_sw_misaligned = q_addradd1_i;
      end
      2'b01: begin
        mask_sw = 32'hFFFFFF00;
        mask_sw_misaligned = 32'h000000FF;
        memd_sw = (mask_sw & {store_d_i[23:0], 8'b0}) | (~mask_sw & q_addr_i);
        memd_sw_misaligned = (mask_sw_misaligned & {24'b0, store_d_i[31:24]}) | (~mask_sw_misaligned & q_addradd1_i);
      end 
      2'b10: begin
        mask_sw = 32'hFFFF0000;
        mask_sw_misaligned = 32'h0000FFFF;
        memd_sw = (mask_sw & {store_d_i[15:0], 16'b0}) | (~mask_sw & q_addr_i);
        memd_sw_misaligned = (mask_sw_misaligned & {16'b0, store_d_i[31:16]}) | (~mask_sw_misaligned & q_addradd1_i);
      end 
      2'b11: begin
        mask_sw = 32'hFF000000;
        mask_sw_misaligned = 32'h00FFFFFF;
        memd_sw = (mask_sw & {store_d_i[7:0], 24'b0}) | (~mask_sw & q_addr_i);
        memd_sw_misaligned = (mask_sw_misaligned & {8'b0, store_d_i[31:8]}) | (~mask_sw_misaligned & q_addradd1_i);
      end 
    endcase
  end

//=================================================

  always_comb begin
    memd_o = (memd_sb & {WIDTH{sb_detect}}) | (memd_sh & {WIDTH{sh_detect}}) | (memd_sw & {WIDTH{sw_detect}});
    memd_misaligned_o = (q_addradd1_i & {WIDTH{sb_detect}}) | (memd_sh_misaligned & {WIDTH{sh_detect}}) | (memd_sw_misaligned & {WIDTH{sw_detect}});
  end
//=======================================
// Load Unit

  reg [WIDTH-1:0] d_lb;
  always_comb begin
    case(addr_i[1:0])
      2'b00: begin
        d_lb = {{24{q_addr_i[7]}}, q_addr_i[7:0]};
      end
      2'b01: begin
        d_lb = {{24{q_addr_i[15]}}, q_addr_i[15:8]};
      end
      2'b10: begin
        d_lb = {{24{q_addr_i[23]}}, q_addr_i[23:16]};
      end
      2'b11: begin
        d_lb = {{24{q_addr_i[31]}}, q_addr_i[31:24]};
      end
    endcase
  end

  reg [WIDTH-1:0] d_lh;
  always_comb begin
    case(addr_i[1:0])
      2'b00: begin
        d_lh = {{16{q_addr_i[15]}}, q_addr_i[15:0]};
      end
      2'b01: begin
        d_lh = {{16{q_addr_i[23]}}, q_addr_i[23:8]};
      end
      2'b10: begin
        d_lh = {{16{q_addr_i[31]}}, q_addr_i[31:16]};
      end
      2'b11: begin
        d_lh = {{16{q_addradd1_i[7]}}, q_addradd1_i[7:0], q_addr_i[31:24]};
      end
    endcase
  end

  reg [WIDTH-1:0] d_lw;
  always_comb begin
    case(addr_i[1:0])
      2'b00: begin
        d_lw = q_addr_i;
      end
      2'b01: begin
        d_lw = {q_addradd1_i[7:0], q_addr_i[31:8]};
      end
      2'b10: begin
        d_lw = {q_addradd1_i[15:0], q_addr_i[31:16]};
      end
      2'b11: begin
        d_lw = {q_addradd1_i[23:0], q_addr_i[31:24]};
      end
    endcase
  end

  reg [WIDTH-1:0] d_lbu;
  always_comb begin
    case(addr_i[1:0])
      2'b00: begin
        d_lbu = {24'b0, q_addr_i[7:0]};
      end
      2'b01: begin
        d_lbu = {24'b0, q_addr_i[15:8]};
      end
      2'b10: begin
        d_lbu = {24'b0, q_addr_i[23:16]};
      end
      2'b11: begin
        d_lbu = {24'b0, q_addr_i[31:24]};
      end
    endcase
  end

  reg [WIDTH-1:0] d_lhu;
  always_comb begin
    case(addr_i[1:0])
      2'b00: begin
        d_lhu = {16'b0, q_addr_i[15:0]};
      end
      2'b01: begin
        d_lhu = {16'b0, q_addr_i[23:8]};
      end
      2'b10: begin
        d_lhu = {16'b0, q_addr_i[31:16]};
      end
      2'b11: begin
        d_lhu = {16'b0, q_addradd1_i[7:0], q_addr_i[31:24]};
      end
    endcase
  end

//==================================================
  always_comb begin
    wb_d_o = (memread_i) ? ((d_lb & {WIDTH{lb_detect}}) | (d_lh & {WIDTH{lh_detect}}) | (d_lw & {WIDTH{lw_detect}}) | 
                            (d_lbu & {WIDTH{lbu_detect}}) | (d_lhu & {WIDTH{lhu_detect}})) : 32'b0;
  end
endmodule