module paint_top(clk, rst, uart_rx, LP_CLK, LATCH, NOE, ROW, RGB0, RGB1);

input         clk;
input         rst;
input         uart_rx;
output        LP_CLK;
output        LATCH;
output        NOE;
output [4:0]  ROW;
output [2:0]  RGB0;
output [2:0]  RGB1;

parameter NUM_COLS = 64;
parameter NUM_ROWS = 64;
parameter NUM_PIXELS = NUM_COLS * NUM_ROWS;
parameter HALF_SCREEN = NUM_PIXELS / 2;
parameter DELAY = 25;

wire       btn_left, btn_right, btn_middle;
wire [7:0] uart_delta_x, uart_delta_y;
wire       data_valid;

reg signed [8:0] pos_x;
reg signed [8:0] pos_y;

wire        wr0, wr1;
wire [11:0] wdata;
wire [11:0] m2s_address;
wire [11:0] b_rdata0, b_rdata1;
wire        paint_permanent;

wire w_ZR, w_ZC, w_ZD, w_ZI;
wire w_LD, w_SHD;
wire w_RST_R, w_RST_C, w_RST_D, w_RST_I;
wire w_INC_R, w_INC_C, w_INC_D, w_INC_I;
wire [10:0] count_delay, delay;
wire [1:0]  index;
wire [5:0]  COL;
wire        PX_CLK_EN;
wire        tmp_noe, tmp_latch;
wire [10:0] PIX_ADDR;
wire [23:0] mem_rdata;

reg  clk1;
reg  [4:0] clk_counter;

always @(posedge clk) begin
  if (rst) begin
    clk_counter <= 0;
    clk1 <= 0;
  end else begin
    if (clk_counter == 2) begin
      clk1 <= ~clk1;
      clk_counter <= 0;
    end else
      clk_counter <= clk_counter + 1;
  end
end

mouse_rx #(.CLK_FREQ(50000000), .BAUD(115200)) uart0 (
  .clk(clk), .rst_n(~rst), .rx_pin(uart_rx),
  .btn_left(btn_left), .btn_right(btn_right), .btn_middle(btn_middle),
  .delta_x(uart_delta_x), .delta_y(uart_delta_y), .data_valid(data_valid)
);

localparam signed [8:0] POS_MIN = 9'sd0;
localparam signed [8:0] POS_MAX = 9'sd63;

wire signed [8:0] delta_x_signed = {{1{uart_delta_x[7]}}, uart_delta_x};
wire signed [8:0] delta_y_signed = {{1{uart_delta_y[7]}}, uart_delta_y};
wire signed [9:0] new_x = pos_x + delta_x_signed;
wire signed [9:0] new_y = pos_y + delta_y_signed;

always @(posedge clk) begin
  if (rst) begin
    pos_x <= 9'd32;
    pos_y <= 9'd32;
  end else if (data_valid) begin
    if (new_x > POS_MAX)
      pos_x <= POS_MAX;
    else if (new_x < POS_MIN)
      pos_x <= POS_MIN;
    else
      pos_x <= new_x[8:0];
    
    if (new_y > POS_MAX)
      pos_y <= POS_MAX;
    else if (new_y < POS_MIN)
      pos_y <= POS_MIN;
    else
      pos_y <= new_y[8:0];
  end
end

ctrl_paint #(.X_MAX(63), .Y_MAX(63), .NUM_COLS(64), .HALF_ROWS(32), .CURSOR_COLOR(12'hFFF)) paint0 (
  .clk(clk), .reset(rst),
  .PS2_Xdata(pos_x), .PS2_Ydata(pos_y),
  .btn_left(btn_left), .btn_right(btn_right), .btn_middle(btn_middle),
  .b_rdata0(b_rdata0), .b_rdata1(b_rdata1),
  .wr0(wr0), .wr1(wr1), .wdata(wdata), .address(m2s_address),
  .paint_permanent(paint_permanent)
);

assign PIX_ADDR = {ROW, COL};

memory #(.size(HALF_SCREEN - 1), .width($clog2(NUM_PIXELS) - 2)) mem0 (
  .clk(clk),
  .addr_read(PIX_ADDR), .rd(1'b1), .rdata(mem_rdata),
  .addr_write(m2s_address[10:0]), .wr0(wr0), .wr1(wr1), .wdata(wdata),
  .paint_permanent(paint_permanent), .b_rdata0(b_rdata0), .b_rdata1(b_rdata1)
);

assign LP_CLK = clk1 & PX_CLK_EN;
assign LATCH = ~tmp_latch;
assign NOE = tmp_noe;

count #(.width(4)) count_row (.clk(clk1), .reset(w_RST_R), .inc(w_INC_R), .outc(ROW), .zero(w_ZR));
count #(.width(5)) count_col (.clk(clk1), .reset(w_RST_C), .inc(w_INC_C), .outc(COL), .zero(w_ZC));
count #(.width(10)) cnt_delay (.clk(clk1), .reset(w_RST_D), .inc(w_INC_D), .outc(count_delay));
count #(.width(1)) count_index (.clk(clk1), .reset(w_RST_I), .inc(w_INC_I), .outc(index), .zero(w_ZI));

lsr_led #(.init_value(DELAY), .width(10)) lsr0 (.clk(clk1), .load(w_LD), .shift(w_SHD), .s_A(delay));
comp_4k #(.width(10)) comp0 (.in1(delay), .in2(count_delay), .out(w_ZD));
mux mux0 (.in0(mem_rdata), .out0({RGB0, RGB1}), .sel(index));

ctrl_panel ctrl0 (
  .clk(clk1), .rst(rst), .init(1'b1),
  .ZR(w_ZR), .ZC(w_ZC), .ZD(w_ZD), .ZI(w_ZI),
  .RST_R(w_RST_R), .RST_C(w_RST_C), .RST_D(w_RST_D), .RST_I(w_RST_I),
  .INC_R(w_INC_R), .INC_C(w_INC_C), .INC_D(w_INC_D), .INC_I(w_INC_I),
  .LD(w_LD), .SHD(w_SHD), .LATCH(tmp_latch), .NOE(tmp_noe), .PX_CLK_EN(PX_CLK_EN)
);

endmodule
