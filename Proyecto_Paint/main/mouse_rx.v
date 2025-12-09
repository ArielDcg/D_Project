module mouse_rx(clk, rst_n, rx_pin, btn_left, btn_right, btn_middle, delta_x, delta_y, data_valid);

parameter CLK_FREQ = 50000000;
parameter BAUD = 9600;

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

parameter WAIT_BYTE0 = 2'd0;
parameter WAIT_BYTE1 = 2'd1;
parameter WAIT_BYTE2 = 2'd2;
parameter PROCESS    = 2'd3;

reg [1:0] state;
reg [7:0] byte_buffer [0:2];
reg [23:0] timeout_counter;
localparam TIMEOUT_MAX = CLK_FREQ / 10;

always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    state <= WAIT_BYTE0;
    rx_ack <= 1'b0;
    data_valid <= 1'b0;
    btn_left <= 1'b0;
    btn_right <= 1'b0;
    btn_middle <= 1'b0;
    delta_x <= 8'd0;
    delta_y <= 8'd0;
    timeout_counter <= 24'd0;
  end else begin
    rx_ack <= 1'b0;
    data_valid <= 1'b0;
    
    if (state != WAIT_BYTE0) begin
      if (timeout_counter < TIMEOUT_MAX)
        timeout_counter <= timeout_counter + 1'b1;
      else begin
        state <= WAIT_BYTE0;
        timeout_counter <= 24'd0;
      end
    end
    
    case (state)
      WAIT_BYTE0: begin
        timeout_counter <= 24'd0;
        if (rx_avail) begin
          byte_buffer[0] <= rx_data;
          rx_ack <= 1'b1;
          state <= WAIT_BYTE1;
        end
      end
      
      WAIT_BYTE1: begin
        if (rx_avail) begin
          byte_buffer[1] <= rx_data;
          rx_ack <= 1'b1;
          state <= WAIT_BYTE2;
          timeout_counter <= 24'd0;
        end
      end
      
      WAIT_BYTE2: begin
        if (rx_avail) begin
          byte_buffer[2] <= rx_data;
          rx_ack <= 1'b1;
          state <= PROCESS;
          timeout_counter <= 24'd0;
        end
      end
      
      PROCESS: begin
        btn_left <= byte_buffer[0][0];
        btn_right <= byte_buffer[0][1];
        btn_middle <= byte_buffer[0][2];
        delta_x <= byte_buffer[1];
        delta_y <= byte_buffer[2];
        data_valid <= 1'b1;
        state <= WAIT_BYTE0;
      end
      
      default: state <= WAIT_BYTE0;
    endcase
  end
end

endmodule
