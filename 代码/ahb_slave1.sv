`include "ahb_pkg.sv"
module ahb_slave2(ahb_if sla);
  logic ready;
  type_hresp resp;
  always@(posedge sla.HCLK,negedge sla.HRESETN)begin
    if(!sla.HRESETN)begin
      sla.HREADY<=1;
      sla.HRESP<=OKAY;
    end
    else if(sla.HSEL==2'b10)begin
      sla.HREADY<=ready;
      sla.HRESP<=resp;
    end
  end
  
  initial begin
    ready=1;
    sla.HSPLIT<=0;
    resp=OKAY;
    #17 ready=0;
        resp=SPLIT;
    #4  ready=1;
       	resp=SPLIT;
    #4  resp=OKAY;
    end
endmodule
