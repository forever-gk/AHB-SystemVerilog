module ahb_top;
  logic clk=0;
  logic reset=1;
  
  logic [3:0]hmaster;
  ahb_if ahb_bus(clk,reset);
  ahb_arbiter ahb_arbiter_module(ahb_bus); 
  ahb_master1 master1(ahb_bus);
  ahb_master2 master2(ahb_bus);
  ahb_slave1 slave1(ahb_bus);
  ahb_slave2 slave2(ahb_bus);
  
  
  //clock signal
  initial begin
    forever #2 clk=~clk;
  end
  //reset signal
  initial begin
    #1 reset=0;
    #3 reset=1; 
  end
endmodule
