module lab7_tb();
	
	reg [3:0]KEY;
	reg [9:0] SW;
	wire [9:0] LEDR;
	wire [6:0] HEX0,HEX1,HEX2,HEX3,HEX4,HEX5;
	
	reg err;

	lab7_top DUT(KEY,SW,LEDR,HEX0,HEX1,HEX2,HEX3,HEX4,HEX5);
	
	initial forever begin //clk
	KEY[0] = 0;
	#2
	KEY[0] = 1;
	#2;
	end
	
	initial begin
		KEY[1] = 0; //reset
		#4
		KEY[1] = 1;
		#4

	err = 0;

	if (DUT.CPU.PC !== 9'b0) begin err = 1; $display("FAILED: PC is not reset to zero."); $stop; end
    @(posedge DUT.CPU.PC or negedge DUT.CPU.PC);  // wait here until PC changes; autograder expects PC set to 1 *before* executing MOV R0, X
    @(posedge DUT.CPU.PC or negedge DUT.CPU.PC);  // wait here until PC changes; autograder expects PC set to 1 *before* executing MOV R0, X
  
    @(posedge DUT.CPU.PC or negedge DUT.CPU.PC);  // wait here until PC changes; autograder expects PC set to 1 *before* executing MOV R0, X

    if (DUT.CPU.PC !== 9'h3) begin err = 1; $display("FAILED: PC should be 1."); $stop; end
    if (DUT.CPU.DP.REGFILE.R0 !== 16'h0007) begin err = 1; $display("FAILED: R0 should be 5."); $stop; end  // because MOV R0, X should have occurred

    @(posedge DUT.CPU.PC or negedge DUT.CPU.PC);  // wait here until PC changes; autograder expects PC set to 2 *after* executing MOV R0, X

    if (DUT.CPU.PC !== 9'h4) begin err = 1; $display("FAILED: PC should be 2."); $stop; end
    if (DUT.CPU.DP.REGFILE.R1 !== 16'h000E) begin err = 1; $display("FAILED: R0 should be 5."); $stop; end  // because MOV R0, X should have occurred

    @(posedge DUT.CPU.PC or negedge DUT.CPU.PC);  // wait here until PC changes; autograder expects PC set to 3 *after* executing LDR R1, [R0]

    if (DUT.CPU.PC !== 9'h5) begin err = 1; $display("FAILED: PC should be 3."); $stop; end
    if (DUT.CPU.DP.REGFILE.R2 !== 16'h0011) begin err = 1; $display("FAILED: R1 should be 0xABCD. Looks like your LDR isn't working."); $stop; end

    @(posedge DUT.CPU.PC or negedge DUT.CPU.PC);  // wait here until PC changes; autograder expects PC set to 4 *after* executing MOV R2, Y

    if (DUT.CPU.PC !== 9'h6) begin err = 1; $display("FAILED: PC should be 4."); $stop; end
    if (DUT.CPU.DP.Z !== 1'b1) begin err = 1; $display("FAILED: R2 should be 6."); $stop; end

    @(posedge DUT.CPU.PC or negedge DUT.CPU.PC);  // wait here until PC changes; autograder expects PC set to 5 *after* executing STR R1, [R2]
    @(posedge DUT.CPU.PC or negedge DUT.CPU.PC);  // wait here until PC changes; autograder expects PC set to 1 *before* executing MOV R0, X

    if (DUT.CPU.PC !== 9'h7) begin err = 1; $display("FAILED: PC should be 5."); $stop; end
    if (DUT.CPU.DP.REGFILE.R4 !== 16'b1001011110111100) begin err = 1; $display("FAILED: mem[6] wrong; looks like your STR isn't working"); $stop; end
    
    @(posedge DUT.CPU.PC or negedge DUT.CPU.PC);  // wait here until PC changes; autograder expects PC set to 4 *after* executing MOV R2, Y

    if (DUT.CPU.DP.REGFILE.R5 !== ~(16'b1001011110111100)) begin err = 1; $display("FAILED: R2 should be 6."); $stop; end

    @(posedge DUT.CPU.PC or negedge DUT.CPU.PC);  // wait here until PC changes; autograder expects PC set to 4 *after* executing MOV R2, Y

    if (DUT.CPU.DP.REGFILE.R6 !== 4'h0000) begin err = 1; $display("FAILED: R2 should be 6."); $stop; end

    #1000
    $stop;

	end
endmodule
