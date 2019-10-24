module shifter(in,shift,sout);
  input [15:0] in;
  input [1:0] shift;
  output [15:0] sout;
  
  reg [15:0] result;
  assign sout = result;
  
  always @(*) begin
    case (shift)
	   2'b00: result = in;
		2'b01: result = {in[14:0], 1'b0};
		2'b10: result = {1'b0, in[15:1]};
		2'b11: result = {in[15], in[15:1]};
		default: result = 16'bxxxx_xxxx_xxxx_xxxx;
    endcase
  end
  
endmodule