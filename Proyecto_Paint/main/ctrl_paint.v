module ctrl_paint #(
    parameter X_MAX = 63,         
    parameter Y_MAX = 63,         
    parameter IMG_DIV = 32,       
    parameter CURSOR_COLOR = 12'h000,  // Color del cursor (negro)
    parameter PAINT_COLOR = 12'hF00    // Color de pintado (rojo)
)(
    input              clk,
    input              reset,      
    input signed [8:0] PS2_Xdata,
    input signed [8:0] PS2_Ydata,
    input              btn_left,   
    input  [11:0]      b_rdata0,
    input  [11:0]      b_rdata1,
    output reg         wr0,
    output reg         wr1,
    output reg [11:0]  wdata,
    output reg [11:0]  address,
    output reg         paint_permanent
);

    // Estados simplificados
    localparam IDLE         = 3'd0;
    localparam RESTORE      = 3'd1;
    localparam PAINT_PERM   = 3'd2;
    localparam PAINT_CURSOR = 3'd3;
    
    reg [2:0] estado;
    reg [11:0] dir_anterior;
    reg        mem_anterior;
    reg        painting;
    
    reg [5:0] x_fin;
    reg [5:0] y_fin;
    reg [5:0] y_offset;
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
        
        sel_mem_actual = (y_fin > IMG_DIV);
        
        if (sel_mem_actual)
            y_offset = y_fin - 6'd33; 
        else
            y_offset = y_fin;
    end
    wire [11:0] dir_actual = {y_offset, x_fin};
    
    wire movimiento = (dir_actual != dir_anterior) || (sel_mem_actual != mem_anterior);
    
    always @(posedge clk) begin
        wr0 <= 1'b0;
        wr1 <= 1'b0;
        paint_permanent <= 1'b0;
        
        if (reset) begin
            estado <= IDLE;
            dir_anterior <= 12'd0;
            mem_anterior <= 1'b0;
            painting <= 1'b0;
        end else begin
            case (estado)
                IDLE: begin
                    if (movimiento) begin
                        painting <= btn_left;  // Capturar estado del botón
                        estado <= RESTORE;
                    end
                end
                
                RESTORE: begin
                    address <= dir_anterior;
                    if (mem_anterior == 1'b0) begin
                        wdata <= b_rdata0;
                        wr0 <= 1'b1;
                    end else begin
                        wdata <= b_rdata1;
                        wr1 <= 1'b1;
                    end
                    
                    if (painting)
                        estado <= PAINT_PERM;
                    else
                        estado <= PAINT_CURSOR;
                end
                
                PAINT_PERM: begin
                    address <= dir_actual;
                    wdata <= PAINT_COLOR;
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
                    address <= dir_actual;
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
