`timescale 1ns/1ps

module tb_register_file;

  parameter WIDTH = 32;

  logic             clk_i;
  logic             rst_i;
  logic [4:0]       rd_i;
  logic [WIDTH-1:0] d_i;
  logic             wr_i;
  logic [4:0]       rs1_i;
  logic [4:0]       rs2_i;
  wire  [WIDTH-1:0] r1_o;
  wire  [WIDTH-1:0] r2_o;

  // DUT
  register_file #(
    .WIDTH(WIDTH)
  ) dut (
    .clk_i(clk_i),
    .rst_i(rst_i),
    .rd_i(rd_i),
    .d_i(d_i),
    .wr_i(wr_i),
    .rs1_i(rs1_i),
    .rs2_i(rs2_i),
    .r1_o(r1_o),
    .r2_o(r2_o)
  );

  // Clock: 10ns period
  initial begin
    clk_i = 1'b0;
    forever #5 clk_i = ~clk_i;
  end

  // FSDB waveform for Verdi
  initial begin
    $fsdbDumpfile("dump.fsdb");
    $fsdbDumpvars(0, tb_register_file);
  end

  // Write task
  task write_reg(input [4:0] rd, input [31:0] data);
    begin
      @(posedge clk_i);      // prepare before posedge
      rd_i = rd;
      d_i  = data;
      wr_i = 1'b1;

      @(posedge clk_i);      // register writes here
      #1;

      @(posedge clk_i);
      wr_i = 1'b0;
      rd_i = 5'd0;
      d_i  = 32'd0;
    end
  endtask

  // Read task
  task read_regs(input [4:0] rs1, input [4:0] rs2);
    begin
      rs1_i = rs1;
      rs2_i = rs2;
      #1; // wait for combinational mux
    end
  endtask

  initial begin
    // Initial values
    rst_i = 1'b1;
    rd_i  = 5'd0;
    d_i   = 32'd0;
    wr_i  = 1'b0;
    rs1_i = 5'd0;
    rs2_i = 5'd0;

    // Reset for 2 cycles
    repeat (2) @(posedge clk_i);
    rst_i = 1'b0;
    #1;

    // Test 1: read x0
    read_regs(5'd0, 5'd0);
    $display("Read x0: r1_o = %h, r2_o = %h, expected = 00000000", r1_o, r2_o);

    // Test 2: write x1
    write_reg(5'd1, 32'hAAAA1111);
    read_regs(5'd1, 5'd0);
    $display("Read x1: r1_o = %h, expected = AAAA1111", r1_o);

    // Test 3: write x2
    write_reg(5'd2, 32'hBBBB2222);
    read_regs(5'd1, 5'd2);
    $display("Read x1: r1_o = %h, expected = AAAA1111", r1_o);
    $display("Read x2: r2_o = %h, expected = BBBB2222", r2_o);

    // Test 4: write x31
    write_reg(5'd31, 32'h12345678);
    read_regs(5'd31, 5'd2);
    $display("Read x31: r1_o = %h, expected = 12345678", r1_o);
    $display("Read x2 : r2_o = %h, expected = BBBB2222", r2_o);

    // Test 5: try writing x0
    write_reg(5'd0, 32'hFFFFFFFF);
    read_regs(5'd0, 5'd0);
    $display("After writing x0: r1_o = %h, r2_o = %h, expected = 00000000", r1_o, r2_o);

    // Finish
    #20;
    $finish;
  end

endmodule