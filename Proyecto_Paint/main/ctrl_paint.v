module ctrl_paint #(
    parameter X_MAX = 63,
    parameter Y_MAX = 63,
    parameter NUM_COLS = 64,
    parameter HALF_ROWS = 32,
    parameter CURSOR_COLOR = 12'h000
)(
    input              clk,
    input              reset,
    input signed [8:0] PS2_Xdata,
    input signed [8:0] PS2_Ydata,
    input              btn_left,
    input              btn_right,
    input              btn_middle,
    input  [11:0]      b_rdata0,
    input  [11:0]      b_rdata1,
    output reg         wr0,
    output reg         wr1,
    output reg [11:0]  wdata,
    output reg [11:0]  address,
    output reg         paint_permanent
);

    localparam COLOR_RED    = 12'hF00;
    localparam COLOR_GREEN  = 12'h0F0;
    localparam COLOR_YELLOW = 12'hFF0;
    localparam COLOR_BLACK  = 12'h000;
    localparam COLOR_WHITE  = 12'hFFF;

    reg [1:0] color_index;
    reg btn_middle_prev;
    wire btn_middle_edge = btn_middle && !btn_middle_prev;

    reg [11:0] current_paint_color;
    always @(*) begin
        case (color_index)
            2'd0: current_paint_color = COLOR_RED;
            2'd1: current_paint_color = COLOR_GREEN;
            2'd2: current_paint_color = COLOR_YELLOW;
            2'd3: current_paint_color = COLOR_BLACK;
        endcase
    end

    localparam IDLE         = 3'd0;
    localparam RESTORE      = 3'd1;
    localparam PAINT_PERM   = 3'd2;
    localparam ERASE        = 3'd3;
    localparam PAINT_CURSOR = 3'd4;
    
    reg [2:0] estado;
    reg [10:0] dir_anterior;
    reg        mem_anterior;
    reg        painting;
    reg        erasing;
    
    reg [5:0] x_fin;
    reg [5:0] y_fin;
    reg [4:0] y_offset;
    reg       sel_mem_actual;
    
    always @(*) begin
        if (PS2_Xdata > X_MAX)
            x_fin = X_MAX[5:0];
        else if (PS2_Xdata < 0)
            x_fin = 6'd0;
        else
            x_fin = PS2_Xdata[5:0];
        
        if (PS2_Ydata > Y_MAX)
            y_fin = Y_MAX[5:0];
        else if (PS2_Ydata < 0)
            y_fin = 6'd0;
        else
            y_fin = PS2_Ydata[5:0];
        
        sel_mem_actual = (y_fin >= HALF_ROWS);
        
        if (sel_mem_actual)
            y_offset = y_fin[4:0];
        else
            y_offset = y_fin[4:0];
    end
    
    wire [10:0] dir_actual = {y_offset, x_fin};
    
    wire movimiento = (dir_actual != dir_anterior) || (sel_mem_actual != mem_anterior);
    
    always @(posedge clk) begin
        wr0 <= 1'b0;
        wr1 <= 1'b0;
        paint_permanent <= 1'b0;
        
        if (reset) begin
            estado <= IDLE;
            dir_anterior <= 11'd0;
            mem_anterior <= 1'b0;
            painting <= 1'b0;
            erasing <= 1'b0;
            color_index <= 2'd0;
            btn_middle_prev <= 1'b0;
        end else begin
            btn_middle_prev <= btn_middle;
            if (btn_middle_edge)
                color_index <= color_index + 1'b1;
            
            case (estado)
                IDLE: begin
                    if (movimiento) begin
                        painting <= btn_left;
                        erasing <= btn_right;
                        estado <= RESTORE;
                    end
                end
                
                RESTORE: begin
                    address <= {1'b0, dir_anterior};
                    if (mem_anterior == 1'b0) begin
                        wdata <= b_rdata0;
                        wr0 <= 1'b1;
                    end else begin
                        wdata <= b_rdata1;
                        wr1 <= 1'b1;
                    end
                    
                    if (painting)
                        estado <= PAINT_PERM;
                    else if (erasing)
                        estado <= ERASE;
                    else
                        estado <= PAINT_CURSOR;
                end
                
                PAINT_PERM: begin
                    address <= {1'b0, dir_actual};
                    wdata <= current_paint_color;
                    paint_permanent <= 1'b1;
                    
                    if (sel_mem_actual == 1'b0)
                        wr0 <= 1'b1;
                    else
                        wr1 <= 1'b1;
                    
                    dir_anterior <= dir_actual;
                    mem_anterior <= sel_mem_actual;
                    
                    estado <= PAINT_CURSOR;
                end
                
                ERASE: begin
                    address <= {1'b0, dir_actual};
                    wdata <= COLOR_WHITE;
                    paint_permanent <= 1'b1;
                    
                    if (sel_mem_actual == 1'b0)
                        wr0 <= 1'b1;
                    else
                        wr1 <= 1'b1;
                    
                    dir_anterior <= dir_actual;
                    mem_anterior <= sel_mem_actual;
                    
                    estado <= PAINT_CURSOR;
                end
                
                PAINT_CURSOR: begin
                    address <= {1'b0, dir_actual};
                    wdata <= CURSOR_COLOR;
                    
                    if (sel_mem_actual == 1'b0)
                        wr0 <= 1'b1;
                    else
                        wr1 <= 1'b1;
                
                    dir_anterior <= dir_actual;
                    mem_anterior <= sel_mem_actual;
                    
                    estado <= IDLE;
                end
                
                default: estado <= IDLE;
            endcase
        end
    end

endmodule
