`include "ahb_pkg.sv"
module arbiter_split (output logic [1:0]hgrant,
                      output logic [1:0]hmaster,
                      input logic [1:0]hbusreq,
                      input logic [15:0]hsplit_reg,
                      input logic [15:0]split,
					             input logic [1:0]hlock);
  wire [15:0]request_pending;
  assign request_pending=(((~hsplit_reg)|split)&{14'b0,hbusreq});           
  // Priority selector(fixed priority)
   always_comb begin 
   if (hlock&hsplit_reg)begin
	   hgrant=DEFAULT_MASTER;
	   hmaster=DEFAULT_MASTER;
   end
   else if(hlock)begin
	   hgrant=hlock;
	   hmaster=hlock;
	 end
   else begin
     casex (request_pending)
       16'b???????????????1: begin
                              hgrant = 2'b01;
                              hmaster=2'b01;
                            end 
       16'b??????????????10: begin
                              hgrant = 2'b10;
                              hmaster=2'b10;
                            end 
       default: begin
              hgrant = DEFAULT_MASTER;
              hmaster=2'b00;
            end
     endcase
   end
   end
endmodule
module arbiter (output logic [1:0]hgrant,
                output logic [3:0]hmaster,
                input logic [1:0]hbusreq);
  wire [15:0]request_pending;
  assign request_pending={14'b0,hbusreq};   
           
  // Priority selector(fixed priority)
   always_comb begin 
     casex (request_pending)
       16'b???????????????1: begin
                              hgrant = 2'b01;
                              hmaster=4'b0001;
                            end 
       16'b??????????????10: begin
                              hgrant = 2'b10;
                              hmaster=4'b0010;
                            end 
       default: begin
              hgrant = DEFAULT_MASTER;
              hmaster=4'b0000;
            end
     endcase
   end
endmodule

