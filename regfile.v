module regfile(data_in, writenum, write, readnum, clk, data_out);
	input [15:0] data_in;
	input [2:0] writenum, readnum;
	input write, clk;
	output [15:0] data_out;
	
	wire [7:0] hot_writenum, hot_readnum;
	wire [15:0] R0, R1, R2, R3, R4, R5, R6, R7;
	wire en0, en1, en2, en3, en4, en5, en6, en7;
	
	assign en0 = write & hot_writenum[0];
	assign en1 = write & hot_writenum[1];
	assign en2 = write & hot_writenum[2];
	assign en3 = write & hot_writenum[3];
	assign en4 = write & hot_writenum[4];
	assign en5 = write & hot_writenum[5];
	assign en6 = write & hot_writenum[6];
	assign en7 = write & hot_writenum[7];
	
	decoder38a writex(writenum, hot_writenum);
   decoder38a readx(readnum, hot_readnum);

	vDFFE #(16) r0(clk, en0, data_in, R0);
	vDFFE #(16) r1(clk, en1, data_in, R1);
	vDFFE #(16) r2(clk, en2, data_in, R2);
	vDFFE #(16) r3(clk, en3, data_in, R3);
	vDFFE #(16) r4(clk, en4, data_in, R4);
	vDFFE #(16) r5(clk, en5, data_in, R5);
	vDFFE #(16) r6(clk, en6, data_in, R6);
	vDFFE #(16) r7(clk, en7, data_in, R7);
	
   mux8 outx(R0, R1, R2, R3, R4, R5, R6, R7, hot_readnum, data_out);

endmodule


//let's add some useful modules


//MUX with 2 16-bit inputs and one-hot select
module mux2(a0, a1, s, b);
	input [15:0] a0, a1;
	input s;
	output [15:0] b;
		
	assign b = s ? a1 : a0; //MUX logic, value s is concactinated 16 times to match bit size of inputs
	
endmodule


//MUX with 4 16-bit inputs and one-hot select
module mux4(a0, a1, a2, a3, s, b);
	input [15:0] a0, a1, a2, a3;
	input [3:0] s;
	output [15:0] b;
		
	assign b = ({16{s[0]}} & a0) | 
				  ({16{s[1]}} & a1) |
				  ({16{s[2]}} & a2) |
				  ({16{s[3]}} & a3) ; //MUX logic, value s is concactinated 16 times to match bit size of inputs
	
endmodule



//MUX with 8 16-bit inputs and 8-bit one-hot select
module mux8(a0, a1, a2, a3, a4, a5, a6, a7, s, b);
	input [15:0] a0, a1, a2, a3, a4, a5, a6, a7;
	input [7:0] s;
	output [15:0] b;
	
	assign b = ({16{s[0]}} & a0) | 
				  ({16{s[1]}} & a1) |
				  ({16{s[2]}} & a2) |
				  ({16{s[3]}} & a3) |
				  ({16{s[4]}} & a4) |
				  ({16{s[5]}} & a5) |
				  ({16{s[6]}} & a6) |
				  ({16{s[7]}} & a7) ;	
endmodule


//decoder module for 3 to 8 bit decoder
module decoder38a(a, b);
	input [2:0] a;
	output [7:0] b;
	
	wire [7:0] b = 1 << a; //why is wire used instead of assign. Ss6 #8
	
endmodule


//register with load enable
module vDFFE(clk, en, in, out);
	parameter n=1; //width
	input clk, en;
	input [n-1:0] in;
	output [n-1:0] out;
	
	reg [n-1:0] out;
	wire [n-1:0] next_out;
	
	assign next_out = en ? in : out; //mux (load enable part of this register)
	
	always @(posedge clk) begin
		out = next_out;	
	end
	
endmodule
