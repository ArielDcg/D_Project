module memory(clk, addr_read, rd, rdata, addr_write, wr0, wr1, wdata, paint_permanent, b_rdata0, b_rdata1);

parameter size = 2047;
parameter width = 11;

input             clk;
input  [width:0]  addr_read;
input             rd;
output reg [23:0] rdata;
input  [width:0]  addr_write;
input             wr0;
input             wr1;
input  [11:0]     wdata;
input             paint_permanent;
output wire [11:0] b_rdata0;
output wire [11:0] b_rdata1;

reg [11:0] MEM0 [0:size];
reg [11:0] MEM1 [0:size];
reg [11:0] B_MEM0 [0:size];
reg [11:0] B_MEM1 [0:size];

assign b_rdata0 = B_MEM0[addr_write];
assign b_rdata1 = B_MEM1[addr_write];

initial begin
  $readmemh("./image0.hex", MEM0);
  $readmemh("./image1.hex", MEM1);
  $readmemh("./image0.hex", B_MEM0);
  $readmemh("./image1.hex", B_MEM1);
end

always @(posedge clk) begin
  if (wr0) begin
    MEM0[addr_write] <= wdata;
    if (paint_permanent)
      B_MEM0[addr_write] <= wdata;
  end
  if (wr1) begin
    MEM1[addr_write] <= wdata;
    if (paint_permanent)
      B_MEM1[addr_write] <= wdata;
  end
end

always @(negedge clk) begin
  if (rd) begin
    rdata[23:12] <= MEM0[addr_read];
    rdata[11:0] <= MEM1[addr_read];
  end
end

endmodule
