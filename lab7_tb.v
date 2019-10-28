module lab7_tb();
	
	reg clk, reset;
	//wire [15:0] dout;
	
	lab7_top dut(clk, reset);
	
	initial forever begin
	clk = 0;
	#10
	clk = 1;
	#10;
	end
	
	initial begin
		reset = 1;
		#30
		reset =0;
		#10;
	end
endmodule
