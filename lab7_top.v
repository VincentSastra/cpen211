
//define mem_cmd
`define MWRITE 2'b10
`define MREAD 2'b01
`define MNONE 2'b00

//define IO address
`define SWADDR 9'b1_0100_0000
`define LEDADDR 9'b1_0000_0000

module lab7_top(KEY,SW,LEDR,HEX0,HEX1,HEX2,HEX3,HEX4,HEX5);
	input[3:0] KEY;
	input[9:0] SW;
	output[9:0] LEDR;
	output[6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;

	wire clk = ~KEY[0];
	wire reset = ~KEY[1];
	wire load_led, load_sw;
	wire [1:0] mem_cmd; // bit 0 is read. bit 1 is write
	wire [8:0] mem_addr;
	wire [15:0] read_data, write_data, dout;
	wire [5:0] present_state;
	
   	cpu CPU(clk, reset, read_data, mem_cmd, write_data, mem_addr); //initalizes the top level cpu module
	
		// Tri state driver to read   	
		wire msel = (`MREAD == mem_cmd) & (mem_addr[8] == 1'b0);
   	assign read_data = msel ? dout : 16'bzzzz_zzz_zzz_zzz_zzz; //tri-state driver

   	wire write = (`MWRITE == mem_cmd);
   	RAM MEM(clk,mem_addr[7:0],mem_addr[7:0],write, write_data, dout); // instaniates the RAM component, notice mem_addr[7:0] is both read address and write address

   	assign load_led = (mem_cmd == `MWRITE) & (mem_addr == `LEDADDR); //"your combinational logic circuit" block for leds
   	assign load_sw = (mem_cmd == `MREAD) & (mem_addr == `SWADDR); //"Your CL circuit" block for switches

   	assign read_data[15:8] = load_sw ? 8'b00000000 : 8'bzzzzzzzz; //tri state driver
   	assign read_data[7:0] = load_sw ? SW[7:0] : 8'bzzzzzzzz; //other tri - state driver. Similar design to mux but with high impedance output

   	vDFFE #(8) LED(clk, load_led, write_data[7:0], LEDR[7:0]); //try changing to load_led
		
		assign HEX0 = 7'b1111_111; //unused hex displays, just set to off for neatness sake
		assign HEX1 = 7'b1111_111;
		assign HEX2 = 7'b1111_111;
		assign HEX3 = 7'b1111_111;
		assign HEX4 = 7'b1111_111;
		assign HEX5 = 7'b1111_111;
		assign LEDR [9:8] = 2'b00;

endmodule
