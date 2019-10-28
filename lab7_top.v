
//define mem_cmd
`define MWRITE 2'b10
`define MREAD 2'b01
`define MNONE 2'b00

/*module lab7_top(KEY,SW,LEDR,HEX0,HEX1,HEX2,HEX3,HEX4,HEX5);
	input[3:0] KEY;
	input[9:0] SW;
	output[9:0] LEDR;
	output[6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
*/

module lab7_top (
	input clk,    // Clock
	input reset  // Asynchronous reset active low
);

	wire [1:0] mem_cmd; // bit 0 is read. bit 1 is write
	wire [8:0] mem_addr;
	wire [15:0] read_data, write_data;
	
	
   	cpu U(clk, reset, read_data, mem_cmd, write_data, mem_addr);
	
	// Tri state inverter to read   	
	wire msel = (`MREAD == mem_cmd) && (mem_addr[8] == 1'b0);
   	read_data = msel ? dout : 15'bzzz_zzz_zzz_zzz_zzz;

   	wire write = (`MWRITE == mem_cmdm);
   	RAM MEM(clk,mem_addr[7:0],mem_addr[7:0],write, write_data,dout); // TODO idk how to connect write dout din


endmodule