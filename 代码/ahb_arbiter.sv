`include "ahb_pkg.sv"
module ahb_arbiter(ahb_if.arbiter arb);
                 
  wire [1:0]c_hgrant;
  logic [1:0]c_busreq;
  wire [1:0]c_hmaster;
  logic [3:0]burst_count;
  logic c_burst_cnt_end=0;
  logic grant_enb;
  logic master_enb;
  logic [1:0]c_hsel;
  logic [15:0]c_split_reg;
  logic [1:0]c_lock=0;
  logic c_ready;
  type_htrans c_trans;
  type_hresp c_resp;
  type_hburst c_burst;
  
  always@(arb.HLOCK)begin
      c_lock=arb.HLOCK;
  end
  
  always_comb begin
    if(!arb.HRESETN)
      c_split_reg<=16'b0;
    else if((c_resp==SPLIT)&&(c_ready==0))
      c_split_reg<=c_split_reg|{12'b0,arb.HMASTER};
    else if(c_split_reg==arb.HSPLIT)
      c_split_reg<=0;
  end
  
  //assign c_hbusreq=arb.HBUSREQ;
  always@(posedge arb.HCLK,negedge arb.HRESETN)begin
    if(!arb.HRESETN)begin
      c_busreq<=2'b0;
      c_ready<=1;
      c_resp<=OKAY;
      c_burst<=SINGLE;
      c_trans<=IDLE;
    end
    else begin
      c_busreq<=arb.HBUSREQ;
      c_resp<=arb.HRESP;
      c_ready<=arb.HREADY;
      c_burst<=arb.HBURST;
      c_trans<=arb.HTRANS;
    end
  end
  //arbiter U_arbiter(.hgrant(c_hgrant),.hmaster(c_hmaster),.hbusreq(c_hbusreq));
  arbiter_split U_arbiter(c_hgrant,c_hmaster,c_busreq,c_split_reg,arb.HSPLIT,c_lock);
  decoder U_decoder(arb.HADDR,arb.HSEL);
  
  //burst counter
  always @(posedge arb.HCLK, negedge arb.HRESETN)
    if((!arb.HRESETN)||(arb.HRESP==RETRY))
      burst_count <= 4'd0;
    else begin
      if((arb.HTRANS == NONSEQ) && (arb.HREADY == 1)&&(arb.HRESP == OKAY))
		    burst_count <= 4'd1;
	    else if((arb.HTRANS == SEQ) && (arb.HREADY == 1)&&(arb.HRESP == OKAY))
		    burst_count <= burst_count + 1;
	    else
		    burst_count <= burst_count;
	  end
	  
  always_comb begin
    if((arb.HTRANS == NONSEQ) && (arb.HBURST == SINGLE) )
		  c_burst_cnt_end = 1;
	  else if((burst_count == 3) && ((arb.HBURST == INCR4) || (arb.HBURST == WRAP4)) )
		  c_burst_cnt_end = 1;
	  else if((burst_count == 5) && ((arb.HBURST == INCR8) || (arb.HBURST == WRAP8)))
		  c_burst_cnt_end = 1;
	  else if((burst_count == 13) && ((arb.HBURST == INCR16) || (arb.HBURST == WRAP16)) )
		  c_burst_cnt_end = 1;
	  else 
		  c_burst_cnt_end = 0;
  end		
  
  //hgrant
  always_comb begin
    if(!arb.HRESETN)
      arb.HGRANT=2'b0;
    else if(grant_enb)
     arb.HGRANT=c_hgrant;
  end
  //hmaster
  always_comb begin
    if(!arb.HRESETN)
      arb.HMASTER=DEFAULT_MASTER;
    else if(master_enb)
      arb.HMASTER=arb.HGRANT;
  end

  //FSM
  enum logic [3:0] {ST_IDLE,ST_GRANT,ST_BUSY,ST_LAST} state,next_state;

  always_ff@(posedge arb.HCLK,negedge arb.HRESETN)begin
    if(!arb.HRESETN)
      state<=ST_IDLE;
    else
      state<=next_state;
  end
  
  always_comb begin
    next_state=ST_IDLE;
    unique case(state)
      ST_IDLE:begin
        if(c_hmaster!=DEFAULT_MASTER)
          next_state=ST_GRANT;
        end
      ST_GRANT:begin
        if(c_ready&&(c_hmaster!=DEFAULT_MASTER))
          next_state=ST_BUSY;
        else if(c_ready&&(c_hmaster==DEFAULT_MASTER))
          next_state=ST_IDLE;
        else
          next_state=ST_GRANT;
        end
      ST_BUSY:begin
        if((c_resp==ERROR)&&(c_ready!=1))//when HRESP=ERROR, stop transform
          next_state=ST_GRANT;
        else if((c_resp==SPLIT)&&(c_ready!=1))
          next_state=ST_GRANT;
        else if(((c_resp==RETRY)&&(c_ready!=1))&&(({2'b00,c_busreq}!=DEFAULT_MASTER)&&(({2'b00,c_busreq}-arb.HMASTER)<arb.HMASTER)))
          next_state=ST_GRANT;
        else if(c_ready==1&&((c_burst==SINGLE)||(c_burst_cnt_end)))
          next_state=ST_GRANT;
         // next_state=ST_GRANT;
        else if(c_trans==IDLE)
          next_state=ST_GRANT;
        else
          next_state=ST_BUSY;
        end
      ST_LAST:begin  //unused if no lock signal
        if(c_ready)begin
          if(c_hmaster==DEFAULT_MASTER)
            next_state=ST_IDLE;
          else
            next_state=ST_GRANT;
         end else
         next_state=ST_LAST;
       end
    endcase
  end
  
  always_comb begin
    grant_enb=1'b0;
    master_enb=1'b0;
    case(state)
      ST_IDLE:      grant_enb=1'b1;
      ST_GRANT:     master_enb=c_ready;
      ST_BUSY:
        begin
          grant_enb=(c_trans==IDLE)||(c_burst_cnt_end==1)||(c_resp==ERROR)||(c_resp==SPLIT)||((c_resp==RETRY)&&((c_busreq!=DEFAULT_MASTER)&&(({2'b00,c_busreq}-arb.HMASTER)<arb.HMASTER)));
        end
      ST_LAST:      master_enb=0;//unused if no lock signal
  endcase
end
    
endmodule