module tb;
  reg clk, reset;
  wire done;
 
  top_module DUT(clk,reset,done);
  
  initial forever begin
      clk = 0; #5;
      clk = 1; #5;
  end

  wire [5:0] mem_value = DUT.MEM.mem[15];
  wire [3:0] pc = DUT.pc;
  wire [3:0] sp = DUT.sp;
  wire [5:0] tmp = DUT.tmp;

  initial begin
    reset = 1'b1;
    @(negedge clk);
    if (pc !== 0) begin
      $display("ERROR ** pc did not reset to zero. (pc=%h)", DUT.pc);
      $stop;
    end
    if (sp !== 4'b1111) begin
      $display("ERROR ** sp did not reset to 4'b1111. (sp=%h)", DUT.sp);
      $stop;
    end
    reset = 1'b0;
    @(posedge done);
    #5;
    $display("INTERFACE OK. WARNING: This message does NOT mean your solution will pass the autograder!");
    $stop; 
  end
endmodule
