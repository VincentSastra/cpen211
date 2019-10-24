//some defitions for the FSM for each instruction
`define waitState 6'b000_000
`define instruct1 3'b001
`define instruct2 3'b010
`define instruct3 3'b011
`define instruct4 3'b100
`define instruct5 3'b011 //same as instruction 3
`define instruct6 3'b010 //same as instruction 2

//define some steps for the FSM
`define one 3'b000
`define two 3'b001
`define three 3'b010
`define four 3'b011
`define five 3'b100



module cpu(clk, reset, s, load, in, out, N, V, Z, w); //top level module
	input clk, reset, s, load;
	input [15:0] in;
	output [15:0] out;
	output N, V, Z, w;
	
	wire [15:0] instr, sximm8, sximm5;
	wire [3:0] vsel;
	wire [2:0] readnum, writenum, opcode, nsel;
	wire [1:0] ALUop, shift, op;
	wire loada, loadb, loadc, loads, write, asel, bsel;

	vDFFE #(16) instruction(clk, load, in, instr); //instruction register
	
	//OVERVIEW OF BEHAVIOR
	//if reset == 1 then FSM should go to reset state
			//after this FSM should not do anything until s == 1 & poseedge clk
	//out is dataout from datapath
	//N, V, Z, are from Z from status register
	//w gets one if FSM is reset == 1 & s ~== 1;
		//when the FSM is done, it should return here^

	instruct_decoder ID (instr, // from instrucion vDDF
				nsel, 
				ALUop, sximm5, sximm8, shift,
				readnum, writenum, op, opcode
				); //instruction decoder, depends on cpu inputs, instrution register, and FSM outputs

	datapath DP (clk, 
                 //register operand fetch stage
                 readnum, vsel, loada, loadb, 
                 // computation stage
					  shift, asel, bsel, ALUop, loadc, loads, 
					  // set when writing back to register file
					  writenum, write,
					  //added for lab 6
					  mdata, PC, sximm8, sximm5,
					  // outputs
					  Z, N, V, out); //accesses editted module from lab5 - does the mathematical operations and read/writes from registers
				 
	controllerFSM con(clk, s, reset, opcode, op, w, nsel, loada, loadb, loadc, vsel, write, asel, bsel, loads);
	//runs the finite state machine which will control the decoder and the datapath
endmodule //cpu



module instruct_decoder(Rd, nsel, ALUop, sximm5, sximm8, shift, readnum, writenum, op, opcode);
	input [15:0] Rd;
	input [2:0] nsel;
	output [15:0] sximm8, sximm5;
	output [2:0] readnum, writenum, opcode;
	output [1:0] ALUop, shift, op;	

	assign ALUop = Rd[12:11]; //parses ALU instruction from input

	assign sximm5 = {{11{Rd[4]}},Rd[4:0]}; //sign extension for 5 bit
	assign sximm8 = {{8{Rd[7]}},Rd[7:0]}; //sign extension for 8 bit

	assign shift = Rd[4:3]; //parse shift instruction

	wire [2:0] writeReadNum;
	mux3 #(3) muxR(Rd[2:0], Rd[7:5], Rd[10:8], nsel, writeReadNum);
	assign readnum = writeReadNum; //assign result of mux3 to readnum
	assign writenum = writeReadNum; //^ also to write num, because they are the same in lab6 and onward

	assign op = Rd[12:11]; //parse op
	assign opcode = Rd[15:13]; //parse opcode

endmodule

module mux3(a2, a1, a0, s, b);
	parameter n=3;
	input [n-1:0] a2, a1, a0;
	input [2:0] s;
	output [n-1:0] b;

	assign b = ({n{s[0]}} & a0) | //mux logic, chooses one of a0, a1, or a2
				  ({n{s[1]}} & a1) |
				  ({n{s[2]}} & a2);

endmodule


module controllerFSM(clk, s, reset, opcode, op, w, nsel, loada, loadb, loadc, vsel, write, asel, bsel, loads);
	input clk, s, reset;
	input [2:0] opcode;
	input [1:0] op;
	output reg loada, loadb, loadc, write, asel, bsel, loads;
	output reg [2:0] nsel;
	output reg [3:0] vsel;
	output w;
	
	reg [5:0] present_state;
	
	
	always @(posedge clk) begin //always block that runs the meat of the FSM (changes states), sensitivty is at rising edge of the clk
		if (reset) begin //check for reset
			present_state <= `waitState; //move to reset aka waitState if it is high
		end //if reset
	
	case(present_state)
		`waitState: if (s) begin //only leave waitState if start is 1
			case({opcode,op}) //case to move into the right instruction set
				5'b11010: present_state <= {`instruct1, `one}; //instruction one moves to regsiter Rd sign extend
				5'b11000: present_state <= {`instruct2, `one}; //instruction two moves to Rd and shift
				5'b10100: present_state <= {`instruct3, `one}; //instrution 3 Adds Rn to shifted Rm into Rd
				5'b10101: present_state <= {`instruct4, `one}; //instruction 4 status of Rn - shfited Rm
				5'b10110: present_state <= {`instruct5, `one}; //instruction 5 Rn anded with shifted Rm
				5'b10111: present_state <= {`instruct6, `one}; //instruction 6 Rd is shifted negation of Rn
				default: present_state <= 6'bxxx_xxx;
			endcase //waitstate
		end
		//default: present_state <= 6'bxxxxxx;		
	endcase


	case(present_state [5:3]) //the following case blocks check the steps within each instruction, as soon as one step is completed (clk is high) then the next step is ready to start. If a step is last for an instruction, it will connect back to waitState
		`instruct1: case(present_state[2:0])
							`one: present_state <= `waitState;
							default: present_state <= 6'bxxx_xxx;
						endcase //present_state step
		`instruct2: case(present_state [2:0]) //also instruction 6
							`one: present_state[2:0] <= `two;
							`two: present_state[2:0] <= `three;
							`three: present_state <= `waitState;
							default: present_state[2:0] <= 3'bxxx;
						endcase 
		`instruct3: case(present_state [2:0]) //also instruction 5
							`one: present_state[2:0] <= `two;
							`two: present_state[2:0] <= `three;
							`three: present_state[2:0] <= `four;
							`four: present_state <= `waitState;
							default: present_state[2:0] <= 3'bxxx;	
						endcase 
		`instruct4: case(present_state [2:0])
							`one: present_state[2:0] <= `two;
							`two: present_state[2:0] <= `three;
							`three: present_state <= `waitState;
							default: present_state[2:0] <= 3'bxxx;
						endcase 

		//default: present_state <= 6'bxxxxxx;
						
	endcase //present_state instruction
	
	end
	
	always @(*) begin //always block that sets the output for the states of the FSM, runs whenever something changes
	
	case(present_state) //last case statement that sets outputs
	`waitState: begin write <= 1'b0;
				nsel <= 3'b000;
				vsel <= 4'b0000;
				loada <= 1'b0;
				loadb <= 1'b0;
				loadc <= 1'b0;
				loads <= 1'b0;
				asel <= 1'b0;
				bsel <= 1'b0;
					 end
	{`instruct1, `one}: begin 
								nsel <= 3'b001;
								vsel <= 4'b0100;
								write <= 1'b1;
								loads <= 1'b0;
								
								loada <= 1'b0;
								loadb <= 1'b0;
								loadc <= 1'b0;
								asel <= 1'b0;
								bsel <= 1'b0;
								end
	{`instruct2, `one}: begin 
								nsel <= 3'b100;
								write <= 1'b0;
								asel <= 1'b1;
								bsel <= 1'b0;
								loadb <= 1'b1;
								loadc <= 1'b1;
								loads <= 1'b0;

								loada <= 1'b0;
								vsel <= 4'b0000;
								end
	{`instruct2, `two}: begin 
								nsel <= 3'b100;
								write <= 1'b0;
								asel <= 1'b1;
								bsel <= 1'b0;
								loadb <= 1'b1;
								loadc <= 1'b1;
								loads <= 1'b0;

								loada <= 1'b0;
								vsel <= 4'b0000;
								end
	{`instruct2, `three}: begin 
								nsel <= 3'b010;
								vsel <= 4'b0001;
								write <= 1'b1;
								loadc <= 1'b0;
								loads <= 1'b0;

								loada <= 1'b0;
								loadb <= 1'b1;
								asel <= 1'b1;
								bsel <= 1'b0;
								end
	{`instruct3, `one}: begin 
								nsel <= 3'b001;
								write <= 1'b0;
								loada<= 1'b1;
								loads <= 1'b0;

								loadb <= 1'b0;
								loadc <= 1'b0;
								vsel <= 4'b0000;
								asel <= 1'b0;
								bsel <= 1'b0;
								end
	{`instruct3, `two}: begin 
								nsel <= 3'b100;
								asel <= 1'b0;
								bsel <= 1'b0;
								loada <= 1'b0;
								loadb <= 1'b1;
								loadc <= 1'b1;
								loads <= 1'b0;
							
								vsel <= 4'b0000;
								write <= 1'b0;
								end
	{`instruct3, `three}: begin 
								nsel <= 3'b100;
								asel <= 1'b0;
								bsel <= 1'b0;
								loada <= 1'b0;
								loadb <= 1'b1;
								loadc <= 1'b1;
								loads <= 1'b0;
							
								write <= 1'b0;
								vsel <= 4'b0000;
								end
	{`instruct3, `four}: begin 
								nsel <= 3'b010;
								vsel <= 4'b0001;
								write <= 1'b1;
								loadc <= 1'b0;
								loads<=1'b0;

								asel <= 1'b0;
								bsel <= 1'b0;
								loada <= 1'b0;
								loadb <= 1'b0;
								loads <= 1'b0;
								end
	{`instruct4, `one}: begin 
								nsel <= 3'b001;
								write <= 1'b0;
								loada <= 1'b1;
								loads<=1'b0;

								loadb <= 1'b0;
								loadc <= 1'b0;
								asel <= 1'b0;
								bsel <= 1'b0;
								vsel <= 4'b0000;
								end
	{`instruct4, `two}: begin 
								nsel <= 3'b100;
								loadb <= 1'b1;
								loada <= 1'b0;
								loads <= 1'b1;
								asel <= 1'b0;
								bsel <= 1'b0;

								loadc <= 1'b0;
								write <= 1'b0;
								vsel <= 4'b0000;
								end
	{`instruct4, `three}: begin 
								nsel <= 3'b100;
								loadb <= 1'b1;
								loada <= 1'b0;
								loads <= 1'b1;
								asel <= 1'b0;
								bsel <= 1'b0;

								loadc <= 1'b0;
								write <= 1'b0;
								vsel <= 4'b0000;
								end
	default: begin
				nsel <= 3'bxxx;
				vsel <= 4'bxxxx;
				loada = 1'bx;
				loadb = 1'bx;
				loadc = 1'bx;
				loads = 1'bx;
				asel <= 1'bx;
				bsel <= 1'bx;
				write <= 1'bx;
			end

	
	endcase
	
	end
	
	assign w = ( present_state === `waitState ); //controls the wait variable... aka sets w to one whenever we are in the waitState
	
endmodule











