module lab7_tb();
	
	reg [3:0]KEY;
	reg [9:0] SW;
	wire [9:0] LEDR;
	wire [6:0] HEX0,HEX1,HEX2,HEX3,HEX4,HEX5;
	
	lab7_top dut(KEY,SW,LEDR,HEX0,HEX1,HEX2,HEX3,HEX4,HEX5);
	
	initial forever begin //clk
	KEY[0] = 0;
	#10
	KEY[0] = 1;
	#10;
	end
	
	initial begin
		KEY[1] = 0; //reset
		#30
		KEY[1] =1;
		#10;
	end
endmodule
