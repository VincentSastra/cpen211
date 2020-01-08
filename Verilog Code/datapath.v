module datapath (clk, 
                 //register operand fetch stage
                 readnum, vsel, loada, loadb, 
                 // computation stage
            shift, asel, bsel, ALUop, loadc, loads, 
            // set when writing back to register file
            int_start, int_exit,
            // when starting interrupt loads the status register and PC
            writenum, write,
            //added for lab 6
            mdata, PC, sximm8, sximm5,
            // outputs
            Z, N, V, datapath_out, reg_out); //accesses editted module from lab5 - does the mathematical operations and read/writes from registers
         
  input [15:0] mdata, sximm8, sximm5; //datapath_in is disconneted, basically same as data_in
  output [15:0] datapath_out, reg_out;
  input write, loada, loadb, asel, bsel, loadc, loads, clk, int_exit, int_start;
  input [2:0] readnum, writenum;
  input [1:0] shift, ALUop;
  input [8:0] PC;
  input [3:0] vsel;
  wire [15:0] data_out, PC_backup;
  wire [2:0] Z_out;
  wire [2:0] Zal;
  wire [2:0] status_backup;
  output Z, N, V;
 
  assign Z = Z_out[0]; //added in lab6 - checks for all 0 answer from status register - all come from alu
  assign N = Z_out[1]; //checks for negative answer in status register
  assign V = Z_out[2]; //checks for overflow from status register
  
  wire [15:0] data_in, Aload, Bload, sout, Ain, Bin, out, sximm5;
  
  mux4 mod9(datapath_out, {7'b0000000, PC}, sximm8, mdata, vsel, data_in); //largely unused - waiting to be connected in lab7/8
  
  regfile REGFILE(data_in, writenum, write, readnum, clk, data_out); //register file - does all the read/writing
  
  vDFFE #(16) mod3(clk, loada, data_out, Aload); //register for load a
  vDFFE #(16) mod4(clk, loadb, data_out, Bload); //register for load b
  
  mux2 mod6(Aload, 16'b0000_0000_0000_0000, asel, Ain); //decided weather to allow Ain through to cload
  mux2 mod7(sout, sximm5, bsel, Bin); //decides weather to sign extend
  
  shifter U1(Bload, shift, sout); //shifts if called for
  
  ALU U2(Ain,Bin,ALUop,out, Zal); //performs appropriate math operator
  
  vDFFE #(16) mod5(clk, loadc, out, datapath_out); //register for load c (output)
  vDFFE #(3) mod10(clk, loads, (int_exit ? status_backup : Zal), Z_out); //status register
  
  vDFFE #(3) status_backupx(clk, int_start, Z_out, status_backup); //status register
  vDFFE #(16) PC_backupx(clk, int_start, {7'b0000000, PC}, PC_backup); //register for load a

  assign reg_out = int_exit ? PC_backup : data_out;

endmodule




