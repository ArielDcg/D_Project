module mouse_rx(clk, rst_n, rx_pin, btn_left, btn_right, btn_middle, delta_x, delta_y, data_valid);

parameter CLK_FREQ = 50000000;
parameter BAUD = 9600;
parameter SYNC_BYTE = 8'hAA;

input         clk;
input         rst_n;
input         rx_pin;
output reg    btn_left;
output reg    btn_right;
output reg    btn_middle;
output reg [7:0] delta_x;
output reg [7:0] delta_y;
output reg    data_valid;

wire [7:0] rx_data;
wire       rx_avail;
reg        rx_ack;

uart #(.freq_hz(CLK_FREQ), .baud(BAUD)) uart_inst (
  .reset(~rst_n), .clk(clk), .uart_rxd(rx_pin), .uart_txd(),
  .rx_data(rx_data), .rx_avail(rx_avail), .rx_error(), .rx_ack(rx_ack),
  .tx_data(8'd0), .tx_wr(1'b0), .tx_busy()
);

parameter WAIT_SYNC = 4'd0;
parameter ACK_SYNC  = 4'd1;
parameter WAIT_BTN  = 4'd2;
parameter ACK_BTN   = 4'd3;
parameter WAIT_DX   = 4'd4;
parameter ACK_DX    = 4'd5;
parameter WAIT_DY   = 4'd6;
parameter ACK_DY    = 4'd7;
parameter PROCESS   = 4'd8;

reg [3:0] state;
reg [7:0] btn_byte;
reg [7:0] dx_byte;
reg [7:0] dy_byte;
reg [23:0] timeout_counter;
localparam TIMEOUT_MAX = CLK_FREQ / 10;

always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    state <= WAIT_SYNC;
    rx_ack <= 1'b0;
    data_valid <= 1'b0;
    btn_left <= 1'b0;
    btn_right <= 1'b0;
    btn_middle <= 1'b0;
    delta_x <= 8'd0;
    delta_y <= 8'd0;
    timeout_counter <= 24'd0;
    btn_byte <= 8'd0;
    dx_byte <= 8'd0;
    dy_byte <= 8'd0;
  end else begin
    rx_ack <= 1'b0;
    data_valid <= 1'b0;
    
    if (state != WAIT_SYNC && state != ACK_SYNC) begin
      if (timeout_counter < TIMEOUT_MAX)
        timeout_counter <= timeout_counter + 1'b1;
      else begin
        state <= WAIT_SYNC;
        timeout_counter <= 24'd0;
      end
    end
    
    case (state)
      WAIT_SYNC: begin
        timeout_counter <= 24'd0;
        if (rx_avail) begin
          rx_ack <= 1'b1;
          if (rx_data == SYNC_BYTE)
            state <= ACK_SYNC;
        end
      end
      
      ACK_SYNC: begin
        if (!rx_avail) begin
          state <= WAIT_BTN;
          timeout_counter <= 24'd0;
        end
      end
      
      WAIT_BTN: begin
        if (rx_avail) begin
          btn_byte <= rx_data;
          rx_ack <= 1'b1;
          state <= ACK_BTN;
        end
      end
      
      ACK_BTN: begin
        if (!rx_avail) begin
          state <= WAIT_DX;
          timeout_counter <= 24'd0;
        end
      end
      
      WAIT_DX: begin
        if (rx_avail) begin
          dx_byte <= rx_data;
          rx_ack <= 1'b1;
          state <= ACK_DX;
        end
      end
      
      ACK_DX: begin
        if (!rx_avail) begin
          state <= WAIT_DY;
          timeout_counter <= 24'd0;
        end
      end
      
      WAIT_DY: begin
        if (rx_avail) begin
          dy_byte <= rx_data;
          rx_ack <= 1'b1;
          state <= ACK_DY;
        end
      end
      
      ACK_DY: begin
        if (!rx_avail) begin
          state <= PROCESS;
        end
      end
      
      PROCESS: begin
        btn_left <= btn_byte[0];
        btn_right <= btn_byte[1];
        btn_middle <= btn_byte[2];
        delta_x <= dx_byte;
        delta_y <= dy_byte;
        data_valid <= 1'b1;
        state <= WAIT_SYNC;
      end
      
      default: state <= WAIT_SYNC;
    endcase
  end
end

endmodule
