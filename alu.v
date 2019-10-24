module ALU(Ain,Bin,ALUop,out,Z);
  input [15:0] Ain, Bin;
  input [1:0] ALUop;
  output [15:0] out;
  output [2:0] Z; //if the main 16-bit result of ALU is 0, Z = 1 else Z = 0
  
  reg [15:0] result;
  assign out = result;
  assign Z[0] = ( result === 16'b0000_0000_0000_0000 );
  assign Z[1] = (result[15] === 1'b1);
  assign Z[2] = ( ((Ain[15] ~^ Bin[15]) & (Bin[15] ^ result[15]) & ~ALUop[0] ) 
                | ((Ain[15] ^ Bin[15]) & (Bin[15] == result[15]) & ALUop[0])); //unsure if overflow matters in op 10 and op 11
  
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