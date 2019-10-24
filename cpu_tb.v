module cpu_tb ();

	reg [15:0] in;
	reg clk, reset, s, load, err;
	wire [15:0] out;
	wire N, V, Z, w;
	
	cpu DUT(clk, reset, s, load, in, out, N, V, Z, w);
	
  task outputcheck;
  input [15:0] outx;
    begin
	   if( out !== outx ) begin
	     err = 1'b1;
		  $display("Data error data out is %b, expected %b", out, outx);
		end
    end
  endtask
 
  task statuscheck;
  input Zx, Nx, Vx;
	 begin
	   if( Nx !== N ) begin
	     err = 1'b1;
		  $display("Status error N out is %b, expected %b", N, Nx);
		end
	   if( Vx !== V ) begin
	     err = 1'b1;
		  $display("Status error V out is %b, expected %b", V, Vx);
		end
	   if( Zx !== Z ) begin
	     err = 1'b1;
		  $display("Status error Z out is %b, expected %b", Z, Zx);
		end
	 end
  endtask
  
  task reg0check;
  input [15:0] regfile0;
    begin
	   if( cpu_tb.DUT.DP.REGFILE.R0 !== regfile0 ) begin
	     err = 1'b1;
		  $display("Regfile error R0 is %b, expected %b", cpu_tb.DUT.DP.REGFILE.R0, regfile0);
		end  
		end
  endtask
  
  task reg1check;
  input [15:0] regfile;
    begin
	   if( cpu_tb.DUT.DP.REGFILE.R1 !== regfile ) begin
	     err = 1'b1;
		  $display("Regfile error R1 is %b, expected %b", cpu_tb.DUT.DP.REGFILE.R1, regfile);
		end  
		end
  endtask
    
  task reg7check;
  input [15:0] regfile;
    begin
	   if( cpu_tb.DUT.DP.REGFILE.R7 !== regfile ) begin
	     err = 1'b1;
		  $display("Regfile error R7 is %b, expected %b", cpu_tb.DUT.DP.REGFILE.R7, regfile);
		end  
		end
  endtask
  
  initial forever begin
	   clk = 0; 
		#1
		clk = 1;
		#1;
    end
  
  initial begin
  
  reset = 1;
  err = 0;
  
   #10;
  
  reset = 0;
  //------Instruction 1----------//
  
  $display("-----Now testing instruction 1");
  $display("TEST 1");
  // Test 1 loading a random positive number in register 0
  // Expect that reg 0 contains the value of 0000 0000 0110 1001
  in = 16'b11010_000_0110_1001; // Load a random positive number in register 0
  load = 1;
  
   #10
  
  s = 1;
  
  @(posedge clk)
  s <= 0;
  
   
   #10;
  
  reg0check( {{8{1'b0}}, 8'b0110_1001} );
  
  
  // Test 2 loading a random negative number in register 0
  // Expect that reg 0 will contain 1111 1111 1100 1010
  $display("TEST 2");
  in = 16'b11010_000_1100_1010; // Load a random negative number in register 0
  load = 1;
    
   #10;
  
  s = 1;
  @(posedge clk)
  s <= 0;
  

   #10
  
  load = 0;
  in = 16'b11010_010_0000_1000; // Load 8 in register 2 for test 3
  
   #10
  
  reg0check( {{8{1'b1}}, 8'b1100_1010} );
  
  // Test 3 testing if there is a delay on load 
  // Expect that reg 2 will have the value 0000 0000 0000 1000
  $display("TEST 3");
  load = 1;
  s = 1;
  @(posedge clk)
  s <= 0;
  
   
   #10;
  //No need to change in because we have changed it before
  
  if (  cpu_tb.DUT.DP.REGFILE.R2 !== 16'b0000_0000_0000_1000 ) begin
    err = 1;
	 $display("Regfile error R2 is %b, expected %b", cpu_tb.DUT.DP.REGFILE.R2, 16'b0000_0000_0000_1000 );
  end
  
  //------Instruction 2----------//
  $display("-----Now testing instruction 2");
  $display("TEST 1");
  // Test 1 moving the value in reg 2 to reg 0
  // Expect reg 0 to contain 0000 0000 0000 1000
  in = 16'b11000_000_000_00_010; // Load reg 2 = 8 in reg 0
  
   #10;
  s = 1;
  @(posedge clk)
  s <= 0;
   
   #10;
  
  reg0check( {{8{1'b0}}, 8'b0000_1000} );
  
  // Test 2 moving the shifted value of reg 0 to reg 1
  // Expect reg 1 to contain 0000 0000 0000 0100
  $display("TEST 2");
  in = 16'b11000_011_001_10_000; // Load reg 0 shift left = 8 / 2 = 4 in reg 1
  
  
   #10;
  s = 1;
  @(posedge clk)
  s <= 0;
   
   #10;
  reg1check( {{8{1'b0}}, 8'b0000_0100} );
  
  // Test 3 moving the shifted value of reg 1 to reg 7
  // Expect reg 7 to contain 0000 0000 0000 0100
  $display("TEST 3");
  in = 16'b11000_011_111_01_001; // Load reg 1 shift right = 4 * 2 = 8 in reg 7
  
  
   #10;
  s = 1;
  @(posedge clk)
  s <= 0;
  
  
   #10;
  reg7check( {{8{1'b0}}, 8'b0000_1000} );
  
  //------Instruction 3----------//
  // Testing opcode 101 and op 00 for the next 3 test
  // This is addition and saving the outcome
  $display("-----Now testing instruction 3");
  $display("TEST 1");
  //Test 1 
  in = 16'b10100_010_001_00_001; // reg 2 + reg 1 = 8 + 4 = 12 in reg 1
  
   #10;
  s = 1;
  @(posedge clk)
  s <= 0;
   
   #10;
  
  reg1check( {{12{1'b0}}, 16'b1100} ); // expect 0000 0000 0000 1100 in reg 1
  
  //Test 2
  $display("TEST 2");
  in = 16'b10100_010_111_01_001; // reg 2 + reg 1 * 2 = 8 + 24 = 32 in reg 7
  
   #10;
  s = 1;
  @(posedge clk)
  s <= 0;
   
   #10;
  reg7check( {{8{1'b0}}, 8'b0010_0000} ); // expect 0000 0000 0010 0000 in reg 7
  
  //Test 3
  $display("TEST 3");
  in = 16'b10100_010_111_00_000; // reg 2 + reg 0 * 2 = 8 + 8 = 16 in reg 7   
  
   #10;
  s = 1;
  @(posedge clk)
  s <= 0;
  
   #10;
  reg7check( {{8{1'b0}}, 8'b0001_0000} ); // expect 0000 0000 0001 0000 in reg 7

  //------Instruction 4----------//
  // Testing opcode 101 and op 01 for the next 3 test
  // This is testing the status register for the outcome of subtraction
  $display("-----Now testing instruction 4");
  $display("TEST 1");
  //Test 1
  in = 16'b10101_010_001_01_111; // reg 2 - reg 7 * 2 = 8 - 32 = -24
  
   #10;
  s = 1;
  @(posedge clk)
  s <= 0;
   
   #10;
  
  statuscheck( 0, 1, 0 ); // Expecting a negative number that doesn't overflow
                          // So Z = 0, N = 1, V = 0
  
  //Test 2
  $display("TEST 2");
  in = 16'b10101_010_001_10_111; // reg 2 - reg 7 / 2 = 8 - 8 = 0 
  
  
   #10;
  s = 1;
  @(posedge clk)
  s <= 0;
   
   #10;
  statuscheck( 1, 0, 0 ); // Expecting a 0
                          // So Z = 1, N = 0, V = 0
  
  //Test 3

  $display("TEST 3");
  in = 16'b11010_100_1111_1111; // Load 1_111_1111 to reg 4 (-1)

  								 // This will turn to binary 1111_1111_1111_1111
   #10; s = 1; @(posedge clk) s <= 0;
   @(posedge w)
  in = 16'b11000_000_100_10_100; // reg 4 shift left and setting MSB = 0 to reg 4
  								 // This will turn to binary 0111_1111_1111_1111 (MAX_INTEGER)
   #10; s = 1; @(posedge clk) s <= 0;
   @(posedge w)
  in = 16'b11010_110_1111_0111; // Load -8 to reg 6 
   #10; s = 1; @(posedge clk) s <= 0;
   @(posedge w)

  in = 16'b10101_110_000_00_100; // reg 6 - reg 4 = -8 - MAX_INTEGER = 32760

  								 // 1111_1111_1111_0111 this is -8
  								 // 1000_0000_0000_0001 this is flipping the MAX_INTEGER
  								 // 0111_1111_1111_1000 resulting number is positve, MAX_INTEGER - 8
   #10;
  s = 1;
  @(posedge clk)
  s <= 0;
  
  
   #10;

  statuscheck( 0, 0, 1 ); // Expecting a large positive number 
                          // Since its a negative number - a positive number
                          // This is an overflow
                          // So Z = 0, N = 0, V = 1
  
  //------Instruction 5----------//
  // Testing opcode 101 and op 10 for the next 3 test
  // This is saving the outcome of ANDing two register values
  $display("-----Now testing instruction 5");
  
  //Test 1
  $display("TEST 1");
  in = 16'b10110_100_111_00_010; // reg 4 & reg 2 = 0111_1111_1111_1111 && 0000_0000_0000_0100
  								 // result is 8 to reg 7
  
   #10;
  s = 1;
  @(posedge clk)
  s <= 0;
   
   #10;
  
  reg7check( {{8{1'b0}}, 8'b0000_1000} ); // Expecting 0000 0000 0000 1000 in reg 7
  
  //Test 2
  $display("TEST 2");
  in = 16'b10110_010_111_10_010; // reg 2 & reg 2 shift left = 0 to reg 7
  
   #10;
  s = 1;
  @(posedge clk)
  s <= 0;
   
   #10;
  reg7check( {{8{1'b0}}, 8'b0000_0000} ); // Expecting 0000 0000 0000 0000 in reg 7
  
  //Test 3
  $display("TEST 3");
  in = 16'b10110_100_111_00_100; // Load reg 4 & reg 4 = reg 4 to reg 7
  
   #10;
  s = 1;
  @(posedge clk)
  s <= 0;
  
  
   #10;
  reg7check( { 1'b0, {15{1'b1}} } ); // Expecting 0111 1111 1111 1111 in reg 7
  

  //------Instruction 6----------//
  // Testing opcode 101 and op 11 for the next 3 test
  // This is saving the outcome of negating a reg value
  $display("-----Now testing instruction 6");
  
  //Test 1
  $display("TEST 1");
  in = 16'b10111_000_111_00_010; // Load ~reg 2 = 1111_1111_1111_0111 to reg 7
  
   #10;
  s = 1;
  @(posedge clk)
  s <= 0;
   
   #10;
  
  reg7check( {{8{1'b1}}, 8'b1111_0111} ); // Expecting 1111 1111 1111 0111 in reg 7
  
  //Test 2
  $display("TEST 2");
  in = 16'b10111_000_000_01_100; // ~(reg 4 shift left) = 0000_0000_0000_0001 to reg 0
  
   #10;
  s = 1;
  @(posedge clk)
  s <= 0;
   
   #10;
  reg0check( {{15{1'b0}}, 1'b1} ); // Expecting 0000 0000 0000 0001 in reg 0
  
  //Test 3
  $display("TEST 3");
  in = 16'b10111_000_001_11_000; // ~(reg 0 shift right MSB = 0) = all 1 to reg 1 
  
  
   #10;
  s = 1;
  @(posedge clk)
  s <= 0;
  
  
   #10;
  reg1check( {16{1'b1}} );


  //Test NOT and Status overflow
  $display("---Special tests");
  $display("TEST 1");
  in = 16'b10111_000_110_00_100; // ~reg 4 to reg 6
  								 // This is the MIN_INTEGER = 1000_0000_0000_0000
   #10; s = 1; @(posedge clk) s <= 0;
   @(posedge w)

  in = 16'b10101_110_000_00_100; // reg 6 - reg 4 = MIN_INTEGER - MAX_INTEGER 

  								 // 1000_0000_0000_0000 this is MIN_INTEGER
  								 // 0111_1111_1111_1111 this is MAX_INTEGER
  								 // 1000_0000_0000_0001 this is MAX_INTEGER flipped

  								 // 0000_0000_0000_0001 resulting in POSITIVE 1
   #10;
  s = 1;
  @(posedge clk)
  s <= 0;
  
  #10
  statuscheck( 0, 0, 1); // Expecting 1
                         // This is an overflow because Negative - Positive = Positive
                         // Z = 0, N = 0, V = 1


  //Test 2
  $display("TEST 2");

  in = 16'b10101_000_110_00_110; // reg 0 - reg 4 = 0 - MIN_INTEGER 

  								 // 1000_0000_0000_0000 this is MIN_INTEGER
  								 // 1000_0000_0000_0000 this is NEGATIVE of MIN_INTEGER
								   // 0 - MIN_INTEGER = 0 + MIN_INTEGER = MIN_INTEGER
  								 // 1000_0000_0000_0000 resulting in MIN_INTEGER
   #10;
  s = 1;
  @(posedge clk)
  s <= 0;
  
  #10;
  statuscheck( 0, 1, 1); // Expecting MIN_INTEGER
                         // This is an overflow because Positive - Negative = negative
                         // Z = 0, N = 1, V = 1
  #5;

  if(~err) begin
    $display("All test passed");
  end

  $stop;
  end
 
endmodule