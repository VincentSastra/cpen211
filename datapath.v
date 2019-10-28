module datapath (clk, 
                 //register operand fetch stage
                 readnum, vsel, loada, loadb, 
                 // computation stage
					  shift, asel, bsel, ALUop, loadc, loads, 
					  // set when writing back to register file
					  writenum, write,
					  //added for lab 6
					  mdata, PC, sximm8, sximm5,
					  // outputs
					  Z, N, V, datapath_out);
					  
  input [15:0] mdata, sximm8, sximm5; //datapath_in is disconneted, basically same as data_in
  output [15:0] datapath_out;
  input write, loada, loadb, asel, bsel, loadc, loads, clk;
  input [2:0] readnum, writenum;
  input [1:0] shift, ALUop;
  input [8:0] PC;
  input [3:0] vsel;
  wire [2:0] Z_out;
  wire [2:0] Zal;
  output Z, N, V;

  wire [15:0] data_in, data_out, Aload, Bload, sout, Ain, Bin, out, sximm5;
  
  mux4 mod9(datapath_out, {7'b0000000, PC}, sximm8, mdata, vsel, data_in); //largely unused - waiting to be connected in lab7/8
  
  regfile REGFILE(data_in, writenum, write, readnum, clk, data_out); //register file - does all the read/writing
  
  vDFFE #(16) mod3(clk, loada, data_out, Aload); //register for load a
  vDFFE #(16) mod4(clk, loadb, data_out, Bload); //register for load b
  
  mux2 mod6(Aload, 16'b0000_0000_0000_0000, asel, Ain); //decided weather to allow Ain through to cload
  mux2 mod7(sout, sximm5, bsel, Bin); //decides weather to sign extend
  
  shifter U1(Bload, shift, sout); //shifts if called for
  
  ALU U2(Ain,Bin,ALUop,out, Zal); //performs appropriate math operator
  
  vDFFE #(16) mod5(clk, loadc, out, datapath_out); //register for load c (output)
  vDFFE #(3) mod10(clk, loads, Zal, Z_out); //status register
  
endmodule




