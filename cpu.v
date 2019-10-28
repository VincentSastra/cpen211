//some defitions for the FSM for each instruction
`define Reset 6'b000_000 // TODO
`define IF1 6'b000_001// TODO
`define IF2 6'b000_010// TODO
`define UpdatePC 6'b000_011// TODO
`define instruct1 3'b001
`define instruct2 3'b010
`define instruct3 3'b011
`define instruct4 3'b100
`define instruct5 3'b011 //same as instruction 3
`define instruct6 3'b010 //same as instruction 2
`define instruct7 3'b101 //LDR
`define instruct8 3'b110 //STR
`define instruct9 3'b111 //HALT

//define some steps for the FSM
`define one 3'b000
`define two 3'b001
`define three 3'b010
`define four 3'b011
`define five 3'b100
`define six 3'b101

//define mem_cmd
`define MWRITE 2'b10
`define MREAD 2'b01
`define MNONE 2'b00

module cpu(clk, reset, read_data, mem_cmd, write_data, mem_addr); //top level module
	input clk, reset;//, load;
	input [15:0] read_data; // Instruction in
	output [15:0] write_data;
	output [8:0] mem_addr;
	output [1:0] mem_cmd;
	//output N, V, Z, w;
	
	wire [15:0] instr, sximm8, sximm5; // instr = instruction that is being operated
	wire load_ir, load_pc, reset_pc, addr_sel;

	wire [8:0] PCout, DataAddressOut, next_pc;
	
	// Instructions for datapath	
	wire [3:0] vsel;
	wire [2:0] readnum, writenum, opcode, nsel;
	wire [1:0] ALUop, shift, op;
	wire loada, loadb, loadc, loads, write, asel, bsel, load_addr;
	
	vDFFE #(16) instruction(clk, load_ir, read_data, instr); //instruction register
	
	assign next_pc = reset_pc ? 9'b00000_0000 : PCout + 1'b1;
	vDFFE #(9) PCvDFF(clk, load_pc, next_pc, PCout);
	
	vDFFE #(9) DataAddress(clk, load_addr, write_data[8:0], DataAddressOut);

	assign mem_addr = addr_sel ? PCout : DataAddressOut;	
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
					  read_data, PCout, sximm8, sximm5,
					  // outputs
					  write_data); //accesses editted module from lab5 - does the mathematical operations and read/writes from registers
				 
	controllerFSM con(clk, reset, opcode, op, 
							nsel, loada, loadb, loadc, vsel, write, asel, bsel, loads, // Outputs for datapath 
							load_ir, load_pc,
							reset_pc, addr_sel, mem_cmd, load_addr);
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


module controllerFSM(clk, reset, opcode, op, nsel, loada, loadb, loadc, vsel, write, asel, bsel, loads, load_ir, load_pc, reset_pc, addr_sel, mem_cmd, load_addr);
	input clk, reset;
	input [2:0] opcode;
	input [1:0] op;
	output reg loada, loadb, loadc, write, asel, bsel, loads, reset_pc, addr_sel, load_ir, load_pc, load_addr;
	output reg [1:0] mem_cmd;
	output reg [2:0] nsel;
	output reg [3:0] vsel;
	
	reg [5:0] present_state;
	
	
	always @(posedge clk) begin //always block that runs the meat of the FSM (changes states), sensitivty is at rising edge of the clk
		if (reset) begin //check for reset
			present_state <= `Reset; //move to reset aka waitState if it is high
		end //if reset
	
	/*case(present_state)
		`UpdatePC: begin //only leave waitState if start is 1
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
*/

	case(present_state [5:3]) //the following case blocks check the steps within each instruction, as soon as one step is completed (clk is high) then the next step is ready to start. If a step is last for an instruction, it will connect back to waitState
		3'b000: case(present_state[2:0])
						`one: present_state <= `IF1; // if Reset go to IF1
						`two: present_state <= `IF2; // if IF1 go to IF2
						`three: present_state <= `UpdatePC; // if IF2 go to UpdatePC
						`four: begin
							case({opcode,op}) //case to move into the right instruction set
								5'b11010: present_state <= {`instruct1, `one}; //instruction one moves to regsiter Rd sign extend
								5'b11000: present_state <= {`instruct2, `one}; //instruction two moves to Rd and shift
								5'b10100: present_state <= {`instruct3, `one}; //instrution 3 Adds Rn to shifted Rm into Rd
								5'b10101: present_state <= {`instruct4, `one}; //instruction 4 status of Rn - shfited Rm
								5'b10110: present_state <= {`instruct5, `one}; //instruction 5 Rn anded with shifted Rm
								5'b10111: present_state <= {`instruct6, `one}; //instruction 6 Rd is shifted negation of Rn
								5'b01100: present_state <= {`instruct7, `one}; //instruction 6 Rd is shifted negation of Rn
								5'b10000: present_state <= {`instruct8, `one}; //instruction 6 Rd is shifted negation of Rn
								5'b11100: present_state <= {`instruct9, `one}; //instruction 6 Rd is shifted negation of Rn
								default: present_state <= 6'bxxx_xxx;
							endcase //waitstate
							end
						default: present_state <= 6'bxxx_xxx;
					endcase
		`instruct1: case(present_state[2:0])
							`one: present_state <= `IF1;
							default: present_state <= 6'bxxx_xxx;
						endcase //present_state step
		`instruct2: case(present_state [2:0]) //also instruction 6
							`one: present_state[2:0] <= `two;
							`two: present_state[2:0] <= `three;
							`three: present_state <= `IF1;
							default: present_state[2:0] <= 3'bxxx;
						endcase 
		`instruct3: case(present_state [2:0]) //also instruction 5
							`one: present_state[2:0] <= `two;
							`two: present_state[2:0] <= `three;
							`three: present_state[2:0] <= `four;
							`four: present_state <= `IF1;
							default: present_state[2:0] <= 3'bxxx;	
						endcase 
		`instruct4: case(present_state [2:0])
							`one: present_state[2:0] <= `two;
							`two: present_state[2:0] <= `three;
							`three: present_state <= `IF1;
							default: present_state[2:0] <= 3'bxxx;
						endcase 
		`instruct7: case (present_state [2:0])
							`one: present_state[2:0] <= `two;
							`two: present_state[2:0] <= `three;
							`three: present_state[2:0] <= `four;
							`four: present_state[2:0] <= `five;
							`five: present_state <= `IF1;
							default: present_state[2:0] <= 3'bxxx;	
						endcase
		
		`instruct8: case (present_state [2:0])
							`one: present_state[2:0] <= `two;
							`two: present_state[2:0] <= `three;
							`three: present_state[2:0] <= `four;
							`four: present_state[2:0] <= `five;
							`five: present_state[2:0] <= `six;
							`six: present_state <= `IF1;
							default: present_state[2:0] <= 3'bxxx;	
						endcase
		`instruct9: case (present_state[2:0])
							`one: present_state[2:0] <= `one;
							default: present_state[2:0] <= 3'bxxx;
						endcase

						
	endcase //present_state instruction
	
	end
	
	always @(*) begin //always block that sets the output for the states of the FSM, runs whenever something changes
	
	case(present_state) //last case statement that sets outputs
	`Reset: begin 
				reset_pc = 1;
				load_pc = 1;

				mem_cmd = 0;
				addr_sel = 0;
				load_ir = 0;
				load_addr = 1'b0;

				write <= 1'b0;
				nsel <= 3'b000;
				vsel <= 4'b0000;
				loada <= 1'b0;
				loadb <= 1'b0;
				loadc <= 1'b0;
				loads <= 1'b0;
				asel <= 1'b0;
				bsel <= 1'b0;
					 end
	`IF1: begin 
				reset_pc = 0;
				load_pc = 0;

				mem_cmd = `MREAD;
				addr_sel = 1;
				load_ir = 0;
				load_addr = 1'b0;
				
				write <= 1'b0;
				nsel <= 3'b000;
				vsel <= 4'b0000;
				loada <= 1'b0;
				loadb <= 1'b0;
				loadc <= 1'b0;
				loads <= 1'b0;
				asel <= 1'b0;
				bsel <= 1'b0;
					 end
	`IF2: begin 
				reset_pc = 0;
				load_pc = 0;

				mem_cmd = `MREAD;
				addr_sel = 1;
				load_ir = 1;
				load_addr = 1'b0;
				
				write <= 1'b0;
				nsel <= 3'b000;
				vsel <= 4'b0000;
				loada <= 1'b0;
				loadb <= 1'b0;
				loadc <= 1'b0;
				loads <= 1'b0;
				asel <= 1'b0;
				bsel <= 1'b0;
					 end
	`UpdatePC: begin 
				reset_pc = 0;
				load_pc = 1;

				mem_cmd = `MREAD;
				addr_sel = 0;
				load_ir = 0;
				
				load_addr = 1'b0;
				write <= 1'b0;
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
								reset_pc = 0;
								load_pc = 0;

								mem_cmd = `MNONE;
								addr_sel = 0;
								load_ir = 0;
								load_addr = 1'b0;
				
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
								reset_pc = 0;
								load_pc = 0;

								mem_cmd = `MNONE;
								addr_sel = 0;
								load_ir = 0;
								load_addr = 1'b0;
				
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
								reset_pc = 0;
								load_pc = 0;

								mem_cmd = `MNONE;
								addr_sel = 0;
								load_ir = 0;
								load_addr = 1'b0;
				 
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
								reset_pc = 0;
								load_pc = 0;

								mem_cmd = `MNONE;
								addr_sel = 0;
								load_ir = 0;
								load_addr = 1'b0;
				
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
								reset_pc = 0;
								load_pc = 0;

								mem_cmd = `MNONE;
								addr_sel = 0;
								load_ir = 0;
								load_addr = 1'b0;
				
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
								reset_pc = 0;
								load_pc = 0;

								mem_cmd = `MNONE;
								addr_sel = 0;
								load_ir = 0;
								load_addr = 1'b0;
				
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
								reset_pc = 0;
								load_pc = 0;

								mem_cmd = `MNONE;
								addr_sel = 0;
								load_ir = 0;
								load_addr = 1'b0;
				
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
								reset_pc = 0;
								load_pc = 0;

								mem_cmd = `MNONE;
								addr_sel = 0;
								load_ir = 0;
								load_addr = 1'b0;
				
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
								reset_pc = 0;
								load_pc = 0;

								mem_cmd = `MNONE;
								addr_sel = 0;
								load_ir = 0;
								load_addr = 1'b0;
				
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
								reset_pc = 0;
								load_pc = 0;

								mem_cmd = `MNONE;
								addr_sel = 0;
								load_ir = 0;
								load_addr = 1'b0;
				
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
								reset_pc = 0;
								load_pc = 0;

								mem_cmd = `MNONE;
								addr_sel = 0;
								load_ir = 0;
								load_addr = 1'b0;
				
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
	{`instruct7, `one}: begin  
								reset_pc = 0;
								load_pc = 0;

								mem_cmd = `MNONE;
								addr_sel = 0;
								load_ir = 0;
								load_addr = 1'b0;
				
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
	{`instruct7, `two}: begin  
								reset_pc = 0;
								load_pc = 0;

								mem_cmd = `MNONE;
								addr_sel = 0;
								load_ir = 0;
								load_addr = 1'b0;
				
								nsel <= 3'b100;
								loadb <= 1'b0;
								loada <= 1'b0;
								loads <= 1'b0;
								asel <= 1'b0;
								bsel <= 1'b1;

								loadc <= 1'b1;
								write <= 1'b0;
								vsel <= 4'b0000;
								end
	{`instruct7, `three}: begin  
								reset_pc = 0;
								load_pc = 0;

								mem_cmd = `MREAD;
								addr_sel = 0;
								load_ir = 0;
								load_addr = 1'b1;
				
								nsel <= 3'b100;
								loadb <= 1'b0;
								loada <= 1'b0;
								loads <= 1'b0;
								asel <= 1'b0;
								bsel <= 1'b0;

								loadc <= 1'b0;
								write <= 1'b0;
								vsel <= 4'b0000;
								end
	{`instruct7, `four}: begin //buffer state 
								reset_pc = 0;
								load_pc = 0;

								mem_cmd = `MREAD;
								addr_sel = 0;
								load_ir = 0;
								load_addr = 1'b1;
				
								nsel <= 3'b100;
								loadb <= 1'b0;
								loada <= 1'b0;
								loads <= 1'b0;
								asel <= 1'b0;
								bsel <= 1'b0;

								loadc <= 1'b0;
								write <= 1'b0;
								vsel <= 4'b0000;
								end
	{`instruct7, `five}: begin  
								reset_pc = 0;
								load_pc = 0;

								mem_cmd = `MREAD;
								addr_sel = 0;
								load_ir = 0;
								load_addr = 1'b1;
				
								nsel <= 3'b010;
								loadb <= 1'b0;
								loada <= 1'b0;
								loads <= 1'b0;
								asel <= 1'b0;
								bsel <= 1'b0;

								loadc <= 1'b0;
								write <= 1'b1;
								vsel <= 4'b1000;
								end
	{`instruct7, `six}: begin  
								reset_pc = 0;
								load_pc = 0;

								mem_cmd = `MNONE;
								addr_sel = 0;
								load_ir = 0;
								load_addr = 1'b0;
				
								nsel <= 3'b010;
								loadb <= 1'b0;
								loada <= 1'b0;
								loads <= 1'b0;
								asel <= 1'b0;
								bsel <= 1'b0;

								loadc <= 1'b0;
								write <= 1'b1;
								vsel <= 4'b1000;
								end								
	{`instruct8, `one}: begin  
								reset_pc = 0;
								load_pc = 0;

								mem_cmd = `MNONE;
								addr_sel = 0;
								load_ir = 0;
								load_addr = 1'b0;
				
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
	{`instruct8, `two}: begin  
								reset_pc = 0;
								load_pc = 0;

								mem_cmd = `MNONE;
								addr_sel = 0;
								load_ir = 0;
								load_addr = 1'b0;
				
								nsel <= 3'b100;
								loadb <= 1'b0;
								loada <= 1'b0;
								loads <= 1'b0;
								asel <= 1'b1;
								bsel <= 1'b0;

								loadc <= 1'b1;
								write <= 1'b0;
								vsel <= 4'b0000;
								end
	{`instruct8, `three}: begin  
								reset_pc = 0;
								load_pc = 0;

								mem_cmd = `MREAD;
								addr_sel = 1;
								load_ir = 0;
								load_addr = 1'b1;
				
								nsel <= 3'b100;
								loadb <= 1'b0;
								loada <= 1'b0;
								loads <= 1'b0;
								asel <= 1'b0;
								bsel <= 1'b0;

								loadc <= 1'b0;
								write <= 1'b0;
								vsel <= 4'b0000;
								end
	{`instruct8, `four}: begin  
								reset_pc = 0;
								load_pc = 0;

								mem_cmd = `MNONE;
								addr_sel = 0;
								load_ir = 0; 
								load_addr = 1'b0;
				
								nsel <= 3'b010;
								write <= 1'b0;
								loada <= 1'b0;
								loads<=1'b0;

								loadb <= 1'b1;
								loadc <= 1'b0;
								asel <= 1'b0;
								bsel <= 1'b0;
								vsel <= 4'b0000;
								end
	{`instruct8, `five}: begin  
								reset_pc = 0;
								load_pc = 0;

								mem_cmd = `MNONE;
								addr_sel = 0;
								load_ir = 0;
								load_addr = 1'b0;
				
								nsel <= 3'b001;
								write <= 1'b0;
								loada <= 1'b0;
								loads<=1'b0;

								loadb <= 1'b0;
								loadc <= 1'b1;
								asel <= 1'b0;
								bsel <= 1'b1;
								vsel <= 4'b0000;
								end
	{`instruct8, `six}: begin  
								reset_pc = 0;
								load_pc = 0;

								mem_cmd = `MWRITE;
								addr_sel = 0;
								load_ir = 0;
								load_addr = 1'b0;
				
								nsel <= 3'b001;
								write <= 1'b0;
								loada <= 1'b0;
								loads<=1'b0;

								loadb <= 1'b0;
								loadc <= 1'b0;
								asel <= 1'b0;
								bsel <= 1'b0;
								vsel <= 4'b0000;
								end
	{`instruct9, `one}: begin  
								reset_pc = 1;
								load_pc = 0;

								mem_cmd = `MNONE;
								addr_sel = 0;
								load_ir = 0;
								load_addr = 1'b0;
				
								nsel <= 3'b001;
								write <= 1'b0;
								loada <= 1'b0;
								loads<=1'b0;

								loadb <= 1'b0;
								loadc <= 1'b0;
								asel <= 1'b0;
								bsel <= 1'b0;
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
				load_addr = 1'bx;
				reset_pc = 1'bx;
				load_pc = 1'bx;
				mem_cmd = 2'bxx;
				addr_sel = 1'bx;
				load_ir = 1'bx;
			end

	
	endcase
	
	end
	
	//no more w needed assign w = ( present_state === `waitState ); //controls the wait variable... aka sets w to one whenever we are in the waitState
	
endmodule









