module ALU(Ain,Bin,ALUop,out);
  input [15:0] Ain, Bin;
  input [1:0] ALUop;
  output [15:0] out;
  
  reg [15:0] result;
  assign out = result;

  always @(*) begin
    case(ALUop)
	  2'b00: result = Ain + Bin;
		2'b01: result = Ain - Bin;
		2'b10: result = Ain & Bin;
		2'b11: result = ~Bin;
	   default: result = 16'bxxxx_xxxx_xxxx_xxxx;
	 endcase
  end
  
endmodule

//need to edit the output z to be a 3 bit informational output for lab 6 Z[2] = ((Ain[15] ~^ Bin[15]) & result[15]);