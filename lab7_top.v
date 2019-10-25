module lab7_top(KEY,SW,LEDR,HEX0,HEX1,HEX2,HEX3,HEX4,HEX5);
	input[3:0] KEY;
	input[9:0] SW;
	output[9:0] LEDR;
	output[6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
	
	wire [1:0] mem_cmd;
	wire [8:0] mem_addr;
	wire [15:0] read_data, write_data;
	
	RAM MEM(clk,mem_addr,mem_addr,write,din,dout); // TODO idk how to connect write dout din
	
   cpu U(clk, reset, read_data, mem_cmd, write_data, mem_addr);
	
endmodule