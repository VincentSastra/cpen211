module lab7_tb();
	
	reg [3:0]KEY;
	reg [9:0] SW;
	wire [9:0] LEDR;
	wire [6:0] HEX0,HEX1,HEX2,HEX3,HEX4,HEX5;
	
	reg err;

	lab7_top DUT(KEY,SW,LEDR,HEX0,HEX1,HEX2,HEX3,HEX4,HEX5);
	
  initial forever begin
    KEY[0] = 1; #2;
    KEY[0] = 0; #2;
  end

	initial begin
		KEY[1] = 0; //reset
		#4
		KEY[1] = 1;
	err = 0;
	    SW[9:0] = 10'b00_1010_0110;

	    #900;

    // @(posedge DUT.CPU.PC or negedge DUT.CPU.PC);  //  wait until step over; 
	//if (DUT.CPU.PC !== 9'b0) begin err = 1; $display("FAILED: PC is not reset to zero."); end // Test if PC reset to 0
    

    // @(posedge DUT.CPU.PC or negedge DUT.CPU.PC);  //  wait until step over; 
   // if (DUT.CPU.PC !== 9'h1) begin err = 1; $display("FAILED: PC should be 1."); end // Test if PC increment
        
    // @(posedge DUT.CPU.PC or negedge DUT.CPU.PC);  //  wait until step over; 
    if (DUT.CPU.DP.REGFILE.R0 !== 16'h0007) begin err = 1; 
    $display("FAILED: R0 should be 7."); end  // because MOV R0, 7 should have occurred


    // @(posedge DUT.CPU.PC or negedge DUT.CPU.PC);  //  wait until step over; 
    if (DUT.CPU.DP.REGFILE.R1 !== 16'h000E) begin err = 1; 
    $display("FAILED: R1 should be 14."); end  // because MOV R1, R0, LSL #1 should have occurred

    // @(posedge DUT.CPU.PC or negedge DUT.CPU.PC);  //  wait until step over; 
    if (DUT.CPU.DP.REGFILE.R2 !== 16'h0011) begin err = 1; 
    $display("FAILED: R2 should be 11."); end // because ADD R2, R1, R0, LSL #1 

    // @(posedge DUT.CPU.PC or negedge DUT.CPU.PC);  //  wait until step over; 
    if (DUT.CPU.DP.Z !== 1'b1) begin err = 1; 
   	$display("FAILED: Z should be 1."); end // because CMP R0, R1, LSR #1

    // @(posedge DUT.CPU.PC or negedge DUT.CPU.PC);  // wait for R3 to load WORD address; 
    // @(posedge DUT.CPU.PC or negedge DUT.CPU.PC);  //  wait for R3 to load WORD; 
    if (DUT.CPU.DP.REGFILE.R4 !== 16'b1001011110111100) begin err = 1; 
    $display("FAILED: R4 should be 4'h97BC.");  end // because LDR R3, [R4]
    
    // @(posedge DUT.CPU.PC or negedge DUT.CPU.PC);  // wait for R7 to load LEDR address; 
    // @(posedge DUT.CPU.PC or negedge DUT.CPU.PC);  //  wait for R7 to load LEDR_BASE;     
    // @(posedge DUT.CPU.PC or negedge DUT.CPU.PC);  //  wait until step over; 
    if (LEDR[7:0] !== 8'b10111100) begin err = 1;
    $display("FAILED LEDR[7:0] should be 2'hBC"); end // because STR R3, [R7]

    // @(posedge DUT.CPU.PC or negedge DUT.CPU.PC);  //  wait until step over; 
    if (DUT.CPU.DP.REGFILE.R5 !== ~16'b1001011110111100) begin err = 1; 
    $display("FAILED: R5 should be ~4'h97BC.");  end // because MVN R4, R3

    // @(posedge DUT.CPU.PC or negedge DUT.CPU.PC);  //  wait until step over; 
    if (DUT.CPU.DP.REGFILE.R6 !== 0) begin err = 1; 
    $display("FAILED: R6 should be 0.");   end // because R3 & R4 = 0

    // @(posedge DUT.CPU.PC or negedge DUT.CPU.PC);  // wait for R7 to load SW_BASE address; 
    // @(posedge DUT.CPU.PC or negedge DUT.CPU.PC);  // wait for R7 to load SW_BASE address;
    // @(posedge DUT.CPU.PC or negedge DUT.CPU.PC);  //  wait until step over; 
    if (DUT.CPU.DP.REGFILE.R7 !== SW[7:0]) begin err = 1; 
    $display("FAILED: R7 should be the val of SW.");  end // because LDR R6, [R7] 

    // @(posedge DUT.CPU.PC or negedge DUT.CPU.PC);
   	if (DUT.CPU.con.present_state !== 8'b01110000) begin err = 1; 
    $display("Didnt go to halt state");   end // because HALT

   	if (DUT.CPU.con.present_state !== 8'b01110000) begin err = 1; 
    $display("Didnt go to halt state");   end // because HALT
    #2;
    if (~err) begin $display("TEST PASSED"); end
    
    #2;
    KEY[1] = 0; //reset
    #300
    KEY[1] = 1;

    #900;
    if (DUT.CPU.DP.REGFILE.R0 !== 16'h0007) begin err = 1; 
    $display("FAILED: R0 should be 7."); end  // because MOV R0, 7 should have occurred


    // @(posedge DUT.CPU.PC or negedge DUT.CPU.PC);  //  wait until step over; 
    if (DUT.CPU.DP.REGFILE.R1 !== 16'h000E) begin err = 1; 
    $display("FAILED: R1 should be 14."); end  // because MOV R1, R0, LSL #1 should have occurred

    // @(posedge DUT.CPU.PC or negedge DUT.CPU.PC);  //  wait until step over; 
    if (DUT.CPU.DP.REGFILE.R2 !== 16'h0011) begin err = 1; 
    $display("FAILED: R2 should be 11."); end // because ADD R2, R1, R0, LSL #1 

    // @(posedge DUT.CPU.PC or negedge DUT.CPU.PC);  //  wait until step over; 
    if (DUT.CPU.DP.Z !== 1'b1) begin err = 1; 
    $display("FAILED: Z should be 1."); end // because CMP R0, R1, LSR #1

    // @(posedge DUT.CPU.PC or negedge DUT.CPU.PC);  // wait for R3 to load WORD address; 
    // @(posedge DUT.CPU.PC or negedge DUT.CPU.PC);  //  wait for R3 to load WORD; 
    if (DUT.CPU.DP.REGFILE.R4 !== 16'b1001011110111100) begin err = 1; 
    $display("FAILED: R4 should be 4'h97BC.");  end // because LDR R3, [R4]
    
    // @(posedge DUT.CPU.PC or negedge DUT.CPU.PC);  // wait for R7 to load LEDR address; 
    // @(posedge DUT.CPU.PC or negedge DUT.CPU.PC);  //  wait for R7 to load LEDR_BASE;     
    // @(posedge DUT.CPU.PC or negedge DUT.CPU.PC);  //  wait until step over; 
    if (LEDR[7:0] !== 8'b10111100) begin err = 1;
    $display("FAILED LEDR[7:0] should be 2'hBC"); end // because STR R3, [R7]

    // @(posedge DUT.CPU.PC or negedge DUT.CPU.PC);  //  wait until step over; 
    if (DUT.CPU.DP.REGFILE.R5 !== ~16'b1001011110111100) begin err = 1; 
    $display("FAILED: R5 should be ~4'h97BC.");  end // because MVN R4, R3

    // @(posedge DUT.CPU.PC or negedge DUT.CPU.PC);  //  wait until step over; 
    if (DUT.CPU.DP.REGFILE.R6 !== 0) begin err = 1; 
    $display("FAILED: R6 should be 0.");   end // because R3 & R4 = 0

    // @(posedge DUT.CPU.PC or negedge DUT.CPU.PC);  // wait for R7 to load SW_BASE address; 
    // @(posedge DUT.CPU.PC or negedge DUT.CPU.PC);  // wait for R7 to load SW_BASE address;
    // @(posedge DUT.CPU.PC or negedge DUT.CPU.PC);  //  wait until step over; 
    if (DUT.CPU.DP.REGFILE.R7 !== SW[7:0]) begin err = 1; 
    $display("FAILED: R7 should be the val of SW.");  end // because LDR R6, [R7] 

    // @(posedge DUT.CPU.PC or negedge DUT.CPU.PC);
    if (DUT.CPU.con.present_state !== 8'b01110000) begin err = 1; 
    $display("Didnt go to halt state");   end // because HALT

    if (DUT.CPU.con.present_state !== 8'b01110000) begin err = 1; 
    $display("Didnt go to halt state");   end // because HALT
    #2;
    if (~err) begin $display("TEST 2 PASSED"); end

    #4;
    $stop; 

end

endmodule
