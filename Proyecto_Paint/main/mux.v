module mux(in0, sel, out0);

input  [23:0]    in0;
input  [1:0]     sel;
output reg [5:0] out0;

always @(*) begin
  case (sel)
    2'b00: out0 = {in0[20], in0[16], in0[12], in0[8],  in0[4], in0[0]};
    2'b01: out0 = {in0[21], in0[17], in0[13], in0[9],  in0[5], in0[1]};
    2'b10: out0 = {in0[22], in0[18], in0[14], in0[10], in0[6], in0[2]};
    2'b11: out0 = {in0[23], in0[19], in0[15], in0[11], in0[7], in0[3]};
    default: out0 = {in0[20], in0[16], in0[12], in0[8], in0[4], in0[0]};
  endcase
end

endmodule