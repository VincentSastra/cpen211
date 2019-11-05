//some defitions for the FSM for each instruction
`define Reset 8'b0000_0000
`define IF1 8'b0000_0001// COULD BE MODIFIED AS THE FINAL BUFFER STEP FOR MOST STUFF
`define IF2 8'b0000_0010
`define UpdatePC 8'b0000_0011
`define instruct1 4'b0001
`define instruct2 4'b0010
`define instruct3 4'b0011
`define instruct4 4'b0100
`define instruct5 4'b0011 //same as instruction 3
`define instruct6 4'b0010 //same as instruction 2
`define instruct7 4'b0101 //LDR
`define instruct8 4'b0110 //STR
`define instruct9 4'b0111 //HALT
`define dcall 4'b1000 //Direct call 
`define icall 4'b1001 //Indirect call
`define branch 4'b1010 //Branch is set PC = PC + 1 + sx(im5)
`define intgo 4'b1011 // Go start interrupt
`define intstr 4'b1100 // Store Rn at e0 + offset (sximm5)
`define intldr 4'b1101 // Load Rn from e0 + offset (sximm5)
`define intlop 4'b1110 // Loop to PC e0 + offset (sximm5) if interrupt
`define intex 4'b1111 // Exit from interrupt setting PC to LR and status to status reg
//`define intgo 4'b1101 // Store status to R9

//define some steps for the FSM
`define one 4'b0000
`define two 4'b0001
`define three 4'b0010
`define four 4'b0011
`define five 4'b0100
`define six 4'b0101
`define seven 4'b0110
`define eight 4'b0111

//define mem_cmd
`define MWRITE 2'b10
`define MREAD 2'b01
`define MNONE 2'b00

module cpu(clk, reset, read_data, mem_cmd, datapath_out, mem_addr, halt, interrupt); //top level module
	input clk, reset, interrupt;//, load;
	input [15:0] read_data; // Instruction in
	output [15:0] datapath_out;
	output [8:0] mem_addr;
	output [1:0] mem_cmd;
	output halt;
	//output N, V, Z, w;
	
	wire [15:0] instr, sximm8, sximm5, reg_out; // instr = instruction that is being operated
	wire load_ir, load_pc, reset_pc, addr_sel, branch_link, int_start, int_exit, int_ls;

	wire [8:0] PC, DataAddressOut, next_pc;
	wire Z, N, V, branch_load, mask;
	
	// Instructions for datapath	
	wire [3:0] vsel;
	wire [2:0] readnum, writenum, opcode, nsel;
	wire [1:0] ALUop, shifts, shiftf, op;
	wire loada, loadb, loadc, loads, write, asel, bsel, load_addr;
	
	vDFFE #(16) instruction(clk, load_ir, read_data, instr); //instruction register
	
	assign shiftf = shifts & ~{2{int_ls}};
	assign next_pc = reset_pc ? 9'b00000_0000 : 
					((int_start & ~mask) ? 9'b01110_0000 :
					(branch_load ? (PC + sximm8) : 
					(branch_link ? (reg_out[8:0]) : (PC + 1'b1))));

	vDFFE #(9) PCvDFF(clk, load_pc, next_pc, PC); //Program counter register	
	vDFFE #(9) DataAddress(clk, load_addr, (int_ls ? datapath_out[8:0] + 9'b011100000 : datapath_out[8:0]), DataAddressOut); //data address register

	assign mem_addr = addr_sel ? PC : DataAddressOut;	//simple mux
	//OVERVIEW OF BEHAVIOR
	//if reset == 1 then FSM should go to reset state
			//after this FSM should not do anything until s == 1 & poseedge clk
	//out is dataout from datapath
	//N, V, Z, are from Z from status register
	//w gets one if FSM is reset == 1 & s ~== 1;
		//when the FSM is done, it should return here^

	instruct_decoder ID (instr, // from instrucion vDDF
				nsel, 
				ALUop, sximm5, sximm8, shifts,
				readnum, writenum, op, opcode
				); //instruction decoder, depends on cpu inputs, instrution register, and FSM outputs

	datapath DP (clk, 
                 //register operand fetch stage
                 readnum, vsel, loada, loadb, 
                 // computation stage
					  shiftf, asel, bsel, ALUop, loadc, loads, 
					  // set when writing back to register file
					  int_start, int_exit,
					  // when starting interrupt loads the status register and PC
					  writenum, write,
					  //added for lab 6
					  read_data, PC, sximm8, sximm5,
					  // outputs
					  Z, N, V, datapath_out, reg_out); //accesses editted module from lab5 - does the mathematical operations and read/writes from registers
				 
	controllerFSM FSM(clk, reset, opcode, op, 
							instr[10:8], Z, N, V, // input for Lab8 
							interrupt, 
							nsel, loada, loadb, loadc, vsel, write, asel, bsel, loads, // Outputs for datapath 
							load_ir, load_pc,
							reset_pc, addr_sel, mem_cmd, load_addr,
							branch_load, branch_link, halt,
							int_start, int_exit, int_ls, mask); // addition for Lab8
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

endmodule;

module controllerFSM(clk, reset, opcode, op, 
							cond, Z, N, V, // input for Lab8 
							interrupt, 
							nsel, loada, loadb, loadc, vsel, write, asel, bsel, loads, // Outputs for datapath 
							load_ir, load_pc,
							reset_pc, addr_sel, mem_cmd, load_addr,
							branch_load, branch_link, halt,
							int_start, int_exit, int_ls, mask); // addition for Lab8
	//runs the finite state machine which will control the decoder and the datapath

	input clk, reset, Z, N, V, interrupt;
	input [2:0] opcode, cond;
	input [1:0] op;
	output halt, int_start, int_exit, int_ls, mask;
	output reg loada, loadb, loadc, write, asel, bsel, loads, reset_pc, addr_sel, load_ir, load_pc, load_addr, branch_load, branch_link;
	output reg [1:0] mem_cmd;
	output reg [2:0] nsel;
	output reg [3:0] vsel;
	
	wire [19:0] p;

	assign p [15:0] = {16{1'b0}};
	assign p [19:17] = 3'b000;

	reg [7:0] present_state;
	assign p [16] = (present_state === `IF1);
	assign halt = (present_state == {`instruct9, `one});

	assign int_exit = (present_state == {`intex, `one});
	assign int_start = (present_state == {`intgo, `one});
	assign int_ls = (present_state[7:4] == `intldr) | (present_state[7:4] == `intstr);
	vDFFE #(1) MASK(clk, (int_exit | int_start | (present_state === `Reset) ), int_start, mask);

	always @(posedge clk) begin //always block that runs the meat of the FSM (changes states), sensitivty is at rising edge of the clk
		if (reset) begin //check for reset
			present_state <= `Reset; //move to reset aka waitState if it is high
		end else begin//if reset

		case(present_state [7:4]) //the following case blocks check the steps within each instruction, as soon as one step is completed (clk is high) then the next step is ready to start. If a step is last for an instruction, it will connect back to waitState
			4'b0000: case(present_state[3:0])
							`one: present_state <= `IF1; // if Reset go to IF1
							`two: present_state <= ((interrupt & ~mask) ? {`intgo, `one} : `IF2); // if IF1 go to IF2
							`three: present_state <= `UpdatePC; // if IF2 go to UpdatePC
							`four: begin
								casex({opcode,op}) //case to move into the right instruction set
									5'b11010: present_state <= {`instruct1, `one}; //instruction one moves to regsiter Rd sign extend
									5'b11000: present_state <= {`instruct2, `one}; //instruction two moves to Rd and shift
									5'b10100: present_state <= {`instruct3, `one}; //instrution 3 Adds Rn to shifted Rm into Rd
									5'b10101: present_state <= {`instruct4, `one}; //instruction 4 status of Rn - shfited Rm
									5'b10110: present_state <= {`instruct5, `one}; //instruction 5 Rn anded with shifted Rm
									5'b10111: present_state <= {`instruct6, `one}; //instruction 6 Rd is shifted negation of Rn
									5'b01100: present_state <= {`instruct7, `one}; //instruction 7 load
									5'b10000: present_state <= {`instruct8, `one}; //instruction 8 store
									5'b11100: present_state <= {`instruct9, `one}; //instruction 9 Inifinite halt loop - resets pc 
									5'b00100: present_state <= {`branch, `one}; //For branching out
									5'b01011: present_state <= {`dcall, `one}; // For direct call
									5'b01010: present_state <= {`icall, `one}; // For indirect call
									5'b01000: present_state <= {`icall, `two}; // Return back which is just icall step 2
									5'b00000: present_state <= {`intstr, `one};
									5'b00001: present_state <= {`intldr, `one};
									5'b00010: present_state <= {`intlop, `one};
									5'b00011: present_state <= {`intex, `one};
									default: present_state <= 8'bxxxx_xxxx;
								endcase //waitstate
								end
							default: present_state <= 8'bxxxx_xxxx;
						endcase
			`instruct1: case(present_state[3:0])
								`one: present_state <= `IF1;
								default: present_state <= 8'bxxxx_xxxx;
							endcase //present_state step

			`instruct2: case(present_state[3:0]) //also instruction 6
								`one: present_state[3:0] <= `two;
								`two: present_state[3:0] <= `three;
								`three: present_state <= `IF1;
								default: present_state[3:0] <= 4'bxxxx;
							endcase 

			`instruct3: case(present_state[3:0]) //also instruction 5
								`one: present_state[3:0] <= `two;
								`two: present_state[3:0] <= `three;
								`three: present_state[3:0] <= `four;
								`four: present_state <= `IF1;
								default: present_state[3:0] <= 4'bxxxx;	
							endcase 

			`instruct4: case(present_state[3:0])
								`one: present_state[3:0] <= `two;
								`two: present_state[3:0] <= `three;
								`three: present_state <= `IF1;
								default: present_state[3:0] <= 4'bxxxx;
							endcase 

			`instruct7: case (present_state[3:0])
								`one: present_state[3:0] <= `two;
								`two: present_state[3:0] <= `three;
								`three: present_state[3:0] <= `four;
								`four: present_state[3:0] <= `five;
								`five: present_state <= `IF1;
								default: present_state[3:0] <= 4'bxxxx;	
							endcase
			
			`instruct8: case (present_state[3:0])
								`one: present_state[3:0] <= `two;
								`two: present_state[3:0] <= `three;
								`three: present_state[3:0] <= `four;
								`four: present_state[3:0] <= `five;
								`five: present_state[3:0] <= `six;
								`six: present_state <= `IF1;
								default: present_state[3:0] <= 4'bxxxx;	
							endcase

			`instruct9: case (present_state[3:0])
								`one: present_state[3:0] <= `one;
								default: present_state[3:0] <= 4'bxxxx;
							endcase			

			`branch: case (present_state[3:0])
								`one: present_state <= `IF1;
								default: present_state[3:0] <= 4'bxxxx;
							endcase

			`dcall: case (present_state[3:0])
								`one: present_state <= `IF1;
								default: present_state[3:0] <= 4'bxxxx;
							endcase
			
			`icall: case (present_state[3:0])
								`one: present_state[3:0] <= `two;
								`two: present_state <= `IF1;
								default: present_state[3:0] <= 4'bxxxx;
							endcase

			`intstr: case (present_state[3:0])
								`one: present_state[3:0] <= `two;
								`two: present_state[3:0] <= `three;
								`three: present_state <= `IF1;
								default: present_state[3:0] <= 4'bxxxx;
							endcase		

			`intldr: case (present_state[3:0])
								`one: present_state[3:0] <= `two;
								`two: present_state[3:0] <= `three;
								`three: present_state[3:0] <= `four;
								`four: present_state <= `IF1;
								default: present_state[3:0] <= 4'bxxxx;
							endcase		

			`intlop: case (present_state[3:0])
								`one: present_state <= `IF1;
								default: present_state[3:0] <= 4'bxxxx;
							endcase

			`intgo: case (present_state[3:0])
								`one: present_state <= `IF1;
								default: present_state[3:0] <= 4'bxxxx;
							endcase

			`intex: case (present_state[3:0])
								`one: present_state <= `IF1;
								default: present_state[3:0] <= 4'bxxxx;
							endcase
													
						
			endcase //present_state instruction
		end
	end
	
	always @(*) begin //always block that sets the output for the states of the FSM, runs whenever something changes
	
	case(present_state) //last case statement that sets outputs. If an output is unspecified it should be set to 0 to avoid inferred latches
	`Reset: begin 
				branch_load = 0;
				reset_pc = 1;
				load_pc = 1;
				branch_link = 0;

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
				branch_load = 0;
				reset_pc = 0;
				load_pc = 0;
				branch_link = 0;

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
				branch_load = 0;
				reset_pc = 0;
				load_pc = 0;
				branch_link = 0;

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
				branch_load = 0;
				reset_pc = 0;
				load_pc = 1;
				branch_link = 0;

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
								branch_load = 0;
								reset_pc = 0;
								load_pc = 0;
								branch_link = 0;

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
								branch_load = 0;
								reset_pc = 0;
								load_pc = 0;
								branch_link = 0;

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
								branch_load = 0;
								reset_pc = 0;
								load_pc = 0;
								branch_link = 0;

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
								branch_load = 0;
								reset_pc = 0;
								load_pc = 0;
								branch_link = 0;

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
								branch_load = 0;
								reset_pc = 0;
								load_pc = 0;
								branch_link = 0;

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
								branch_load = 0;
								reset_pc = 0;
								load_pc = 0;
								branch_link = 0;

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
								branch_load = 0;
								reset_pc = 0;
								load_pc = 0;
								branch_link = 0;

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
								branch_load = 0;
								reset_pc = 0;
								load_pc = 0;
								branch_link = 0;

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
								branch_load = 0;
								reset_pc = 0;
								load_pc = 0;
								branch_link = 0;

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
								branch_load = 0;
								reset_pc = 0;
								load_pc = 0;
								branch_link = 0;

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
								branch_load = 0;
								reset_pc = 0;
								load_pc = 0;
								branch_link = 0;

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
								branch_load = 0;
								reset_pc = 0;
								load_pc = 0;
								branch_link = 0;

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
								branch_load = 0;
								reset_pc = 0;
								load_pc = 0;
								branch_link = 0;

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
								branch_load = 0;
								reset_pc = 0;
								load_pc = 0;
								branch_link = 0;

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
								branch_load = 0;
								reset_pc = 0;
								load_pc = 0;
								branch_link = 0;

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
								branch_load = 0;
								reset_pc = 0;
								load_pc = 0;
								branch_link = 0;

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
	{`instruct8, `one}: begin  
								branch_load = 0;
								reset_pc = 0;
								load_pc = 0;
								branch_link = 0;

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
								branch_load = 0;
								reset_pc = 0;
								load_pc = 0;
								branch_link = 0;

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
	{`instruct8, `three}: begin  
								branch_load = 0;
								reset_pc = 0;
								load_pc = 0;
								branch_link = 0;

								mem_cmd = `MREAD;
								addr_sel = 0;
								load_ir = 0;
								load_addr = 1'b1;
				
								nsel <= 3'b010;
								loadb <= 1'b1;
								loada <= 1'b0;
								loads <= 1'b0;
								asel <= 1'b0;
								bsel <= 1'b0;

								loadc <= 1'b0;
								write <= 1'b0;
								vsel <= 4'b0000;
								end
	{`instruct8, `four}: begin  
								branch_load = 0;
								reset_pc = 0;
								load_pc = 0;
								branch_link = 0;

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
	{`instruct8, `five}: begin  
								branch_load = 0;
								reset_pc = 0;
								load_pc = 0;
								branch_link = 0;

								mem_cmd = `MREAD;
								addr_sel = 0;
								load_ir = 0;
								load_addr = 1'b0;
				
								nsel <= 3'b001;
								write <= 1'b0;
								loada <= 1'b0;
								loads<=1'b0;

								loadb <= 1'b0;
								loadc <= 1'b1;
								asel <= 1'b1;
								bsel <= 1'b0;
								vsel <= 4'b0000;
								end
	{`instruct8, `six}: begin  
								branch_load = 0;
								reset_pc = 0;
								load_pc = 0;
								branch_link = 0;

								mem_cmd = `MWRITE;
								addr_sel = 0;
								load_ir = 0;
								load_addr = 1'b0;
				
								nsel <= 3'b001;
								write <= 1'b0;
								loada <= 1'b0;
								loads<=1'b0;

								loadb <= 1'b0;
								loadc <= 1'b1;
								asel <= 1'b1;
								bsel <= 1'b0;
								vsel <= 4'b0000;
								end								
	{`instruct9, `one}: begin  
								branch_load = 0;
								reset_pc = 1;
								load_pc = 1;
								branch_link = 0;

								mem_cmd = `MNONE;
								addr_sel = 0;
								load_ir = 0;
								load_addr = 1'b0;
				
								nsel <= 3'b001;
								write <= 1'b0;
								loada <= 1'b0;
								loads <= 1'b0;

								loadb <= 1'b0;
								loadc <= 1'b0;
								asel <= 1'b0;
								bsel <= 1'b0;
								vsel <= 4'b0000;
								end

	{`branch, `one}: 	begin
								reset_pc = 0;
								branch_link = 0;

								mem_cmd = `MNONE;
								addr_sel = 0;
								load_ir = 0;
								load_addr = 1'b0;
				
								nsel <= 3'b001;
								write <= 1'b0;
								loada <= 1'b0;
								loads <= 1'b0;

								loadb <= 1'b0;
								loadc <= 1'b0;
								asel <= 1'b0;
								bsel <= 1'b0;
								vsel <= 4'b0000;

								case(cond)
									3'b000: begin branch_load = 1'b1; 
												 	load_pc = 1'b1; end
									3'b001: begin branch_load = Z;
													load_pc = Z; end
									3'b010: begin branch_load = ~Z;
													load_pc = ~Z; end
									3'b011: begin branch_load = N ^ V;
													load_pc = N ^ V; end
									3'b100: begin branch_load = (N ^ V) | Z;
													load_pc = (N ^ V) | Z; end
									default: begin branch_load = 1'bx;
													load_pc = 1'bx; end
								endcase

							end

	{`dcall, `one}:		begin

								reset_pc = 0;
								load_pc = 1;
								branch_load = 1;
								branch_link = 0;

								mem_cmd = `MNONE;
								addr_sel = 0;
								load_ir = 0;
								load_addr = 1'b0;
				
								nsel <= 3'b001;
								write <= 1'b1;
								loada <= 1'b0;
								loads <= 1'b0;

								loadb <= 1'b0;
								loadc <= 1'b0;
								asel <= 1'b0;
								bsel <= 1'b0;
								vsel <= 4'b0010;
							end

	{`icall, `one}:		begin

								reset_pc = 0;
								load_pc = 0;
								branch_load = 0;
								branch_link = 0;

								mem_cmd = `MNONE;
								addr_sel = 0;
								load_ir = 0;
								load_addr = 1'b0;
				
								nsel <= 3'b001;
								write <= 1'b1;
								loada <= 1'b0;
								loads <= 1'b0;

								loadb <= 1'b0;
								loadc <= 1'b0;
								asel <= 1'b0;
								bsel <= 1'b0;
								vsel <= 4'b0010;

							end

	{`icall, `two}:		begin

								reset_pc = 0;
								load_pc = 1;
								branch_load = 0;
								branch_link = 1;

								mem_cmd = `MNONE;
								addr_sel = 0;
								load_ir = 0;
								load_addr = 1'b0;
				
								nsel <= 3'b010;
								write <= 1'b0;
								loada <= 1'b0;
								loads <= 1'b0;

								loadb <= 1'b0;
								loadc <= 1'b0;
								asel <= 1'b0;
								bsel <= 1'b0;
								vsel <= 4'b0000;

							end

	{`intstr, `one}:		begin

								reset_pc = 0;
								load_pc = 0;
								branch_load = 0;
								branch_link = 0;

								mem_cmd = `MNONE;
								addr_sel = 0;
								load_ir = 0;
								load_addr = 1'b1;
				
								nsel <= 3'b001;
								write <= 1'b0;
								loada <= 1'b0;
								loads <= 1'b0;

								loadb <= 1'b1;
								loadc <= 1'b1;
								asel <= 1'b1;
								bsel <= 1'b1;
								vsel <= 4'b0000;

							end	

	{`intstr, `two}:		begin

								reset_pc = 0;
								load_pc = 0;
								branch_load = 1;
								branch_link = 0;

								mem_cmd = `MNONE;
								addr_sel = 0;
								load_ir = 0;
								load_addr = 1'b1;
				
								nsel <= 3'b100;
								write <= 1'b0;
								loada <= 1'b0;
								loads <= 1'b0;

								loadb <= 1'b0;
								loadc <= 1'b1;
								asel <= 1'b1;
								bsel <= 1'b0;
								vsel <= 4'b0000;

							end	

	{`intstr, `three}:		begin

								reset_pc = 0;
								load_pc = 0;
								branch_load = 0;
								branch_link = 0;

								mem_cmd = `MWRITE;
								addr_sel = 0;
								load_ir = 0;
								load_addr = 1'b0;
				
								nsel <= 3'b100;
								write <= 1'b0;
								loada <= 1'b0;
								loads <= 1'b0;

								loadb <= 1'b0;
								loadc <= 1'b0;
								asel <= 1'b1;
								bsel <= 1'b1;
								vsel <= 4'b0000;

							end

	{`intldr, `one}:		begin

								reset_pc = 0;
								load_pc = 0;
								branch_load = 0;
								branch_link = 0;

								mem_cmd = `MNONE;
								addr_sel = 0;
								load_ir = 0;
								load_addr = 1'b1;
				
								nsel <= 3'b100;
								write <= 1'b0;
								loada <= 1'b0;
								loads <= 1'b0;

								loadb <= 1'b0;
								loadc <= 1'b1;
								asel <= 1'b1;
								bsel <= 1'b1;
								vsel <= 4'b0000;

							end	

	{`intldr, `two}:		begin

								reset_pc = 0;
								load_pc = 0;
								branch_load = 1;
								branch_link = 0;

								mem_cmd = `MREAD;
								addr_sel = 0;
								load_ir = 0;
								load_addr = 1'b1;
				
								nsel <= 3'b100;
								write <= 1'b0;
								loada <= 1'b0;
								loads <= 1'b0;

								loadb <= 1'b0;
								loadc <= 1'b1;
								asel <= 1'b1;
								bsel <= 1'b1;
								vsel <= 4'b0000;

							end	

	{`intldr, `three}:		begin

								reset_pc = 0;
								load_pc = 0;
								branch_load = 0;
								branch_link = 0;

								mem_cmd = `MREAD;
								addr_sel = 0;
								load_ir = 0;
								load_addr = 1'b0;
				
								nsel <= 3'b100;
								write <= 1'b0;
								loada <= 1'b0;
								loads <= 1'b0;

								loadb <= 1'b0;
								loadc <= 1'b0;
								asel <= 1'b1;
								bsel <= 1'b1;
								vsel <= 4'b0000;

							end	

	{`intldr, `four}:		begin

								reset_pc = 0;
								load_pc = 0;
								branch_load = 0;
								branch_link = 0;

								mem_cmd = `MREAD;
								addr_sel = 0;
								load_ir = 0;
								load_addr = 1'b0;
				
								nsel <= 3'b001;
								write <= 1'b1;
								loada <= 1'b0;
								loads <= 1'b0;

								loadb <= 1'b0;
								loadc <= 1'b0;
								asel <= 1'b1;
								bsel <= 1'b1;
								vsel <= 4'b1000;

							end	

	{`intlop, `one}: 	begin
								reset_pc = 0;
								branch_link = 0;

								mem_cmd = `MNONE;
								addr_sel = 0;
								load_ir = 0;
								load_addr = 1'b0;
				
								nsel <= 3'b001;
								write <= 1'b0;
								loada <= 1'b0;
								loads <= 1'b0;

								loadb <= 1'b0;
								loadc <= 1'b0;
								asel <= 1'b0;
								bsel <= 1'b0;
								vsel <= 4'b0000;

								branch_load <= interrupt;
								load_pc <= interrupt;

							end

	{`intex, `one}: 	begin

								reset_pc = 0;
								load_pc = 1;
								branch_load = 0;
								branch_link = 1;

								mem_cmd = `MNONE;
								addr_sel = 0;
								load_ir = 0;
								load_addr = 1'b0;
				
								nsel <= 3'b010;
								write <= 1'b0;
								loada <= 1'b0;
								loads <= 1'b0;

								loadb <= 1'b0;
								loadc <= 1'b0;
								asel <= 1'b0;
								bsel <= 1'b0;
								vsel <= 4'b0000;

							end


	{`intgo, `one}: 	begin

								reset_pc = 0;
								load_pc = 1;
								branch_load = 0;
								branch_link = 0;

								mem_cmd = `MNONE;
								addr_sel = 0;
								load_ir = 0;
								load_addr = 1'b0;
				
								nsel <= 3'b000;
								write <= 1'b0;
								loada <= 1'b0;
								loads <= 1'b0;

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
				branch_load = 1'bx;
			end

	
	endcase
	
	end
	
	//no more w needed assign w = ( present_state === `waitState ); //controls the wait variable... aka sets w to one whenever we are in the waitState
	
endmodule









