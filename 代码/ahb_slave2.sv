`include "ahb_pkg.sv"
module ahb_slave1(ahb_if.slave sla); 
 logic [7:0]mem[0:50]={default:0};  
 logic [31:0]addr;
 bit flag_E;
 bit flag_R;
 bit flag_S;
 bit unready;
 bit h_retry;
 bit h_split;
 bit h_resume;
 int s_master;
 bit h_write;

//logic [1:0] trans;
 //type_htrans trans;
  always_ff@(posedge sla.HCLK,negedge sla.HRESETN)begin
    if (!sla.HRESETN) begin
      sla.HSPLIT<=0;
  end
    if ((!unready)&&(sla.HSEL == 2'b01))
      sla.HREADY <= 1;
    if((sla.HSEL == 2'b01 && sla.HREADY == 1)||flag_E==1||flag_R==1||flag_S==1)begin
      sla.HRESP<=OKAY;
      h_write<=sla.HWRITE;
      if(sla.HTRANS==NONSEQ||sla.HTRANS==SEQ)begin
        addr <= sla.HADDR;
       // trans<= sla.HTRANS;
      end
        //if(sla.HTRANS==NONSEQ||sla.HTRANS==SEQ||flag_E==1)begin

       if (flag_R==1) begin 
          sla.HRESP<=RETRY;
          flag_R<=0;
          sla.HREADY <= 1;
        end
      else if (flag_S==1) begin 
          sla.HRESP<=SPLIT;
          flag_S<=0;
          sla.HREADY <= 1;
        end 
      else if (flag_E==1) begin 
          sla.HRESP<=ERROR;
          flag_E<=0;
          sla.HREADY <= 1;
        end
       
      else begin

    
    if (h_write==1) begin
       //if(trans==NONSEQ||trans==SEQ)begin
         if(sla.HTRANS==NONSEQ||sla.HTRANS==SEQ)begin
         sla.HREADY <= 0;
      unique case(sla.HSIZE)
          3'b000:        
         mem[addr] = sla.HWDATA[7:0];
          3'b001:begin
         mem[addr] = sla.HWDATA[7:0];
         mem[addr+1] = sla.HWDATA[15:8];
       end
          3'b010:begin
         mem[addr] = sla.HWDATA[7:0];
         mem[addr+1] = sla.HWDATA[15:8];
         mem[addr+2] = sla.HWDATA[23:16];
         mem[addr+3] = sla.HWDATA[31:24];
       end
       endcase
       //mem[addr] <= sla.HWDATA;
       sla.HRESP<=OKAY; 
       if(!unready)
       sla.HREADY <= 1;
        end
      end
    
        if(sla.HWRITE==0&&(sla.HTRANS==NONSEQ||sla.HTRANS==SEQ)) begin
        unique case(sla.HSIZE)
          3'b000:
         sla.HRDATA <= {24'b0,mem[sla.HADDR]};        
     
          3'b001:
        sla.HRDATA <= {16'b0,mem[sla.HADDR+1],mem[sla.HADDR]};
          3'b010:begin
        sla.HRDATA <= {mem[sla.HADDR+3],mem[sla.HADDR+2],mem[sla.HADDR+1],mem[sla.HADDR]};
       end
       endcase
       // sla.HRDATA <= mem[addr];
        sla.HRESP<=OKAY; 
        sla.HREADY <= 1;
      end
            if(h_retry==1)begin
           sla.HRESP<=RETRY;
           flag_R<=1; 
           sla.HREADY <= 0;
         end
     
    if(h_split==1)begin
          sla.HRESP<=SPLIT;
          flag_S<=1;
          sla.HREADY <= 0;
          s_master<=sla.HMASTER;
        end
   if (h_resume==1)begin
       sla.HSPLIT[s_master-1]<=1;
     end
            if (sla.HADDR>39&&sla.HADDR<42)begin

           sla.HRESP<=ERROR;
           flag_E<=1;
           sla.HREADY <= 0;
      end
 end
  end 
end
    
    initial begin
       sla.HSPLIT=0;
      //#13 h_retry=1;
      //#2 h_retry=0;
      //#13 h_split=1;
      //#2 h_split=0;
     //  sla.HSPLIT=0;
      //#13 h_resume=1;
      // #21  unready=1;
       //#2 unready=0;
   /* #21 h_split=1;
      #2 h_split=0;
      #6 h_resume=1;
      #2 h_resume=0;*/
      
  end
 endmodule
 

 


    


 

 

