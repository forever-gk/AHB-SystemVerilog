`include "ahb_pkg.sv"
module ahb_master2(ahb_if.master mas);
  int addr_count;
  int data_count;
  int prev_count;
  int prev_burst;
  int next_num;
  logic retry_split;
  logic addr_reg;
  logic [31:0]addr;
  type_hburst burst;
  type_htrans trans;
  logic write;
  logic busreq;
  logic bus_reg=0;
  logic [4:0]trans_num;
  logic [15:0][31:0]wdata={32'b010101010101,32'b10101,32'b0101,32'b1010,32'b1010,32'b0101,32'b011110,32'b0110101};
  parameter single=3'b1;
  always @(posedge mas.HCLK,negedge mas.HRESETN)begin
    if(!mas.HRESETN)begin
      mas.HBUSREQ = 0;
      mas.HLOCK = 0;
      mas.HWRITE = 0;
      mas.HTRANS = IDLE;
      mas.HADDR = 32'h00000000;
      mas.HWDATA = 32'h00000000;
      mas.HSIZE = BYTE;
      mas.HBURST = SINGLE;
      addr_count=0;
      data_count=0;
      bus_reg=0;
      addr_reg=0;
      prev_count=0;
      prev_burst=0;
      retry_split=0;
    end
  end
  
  always_comb begin 
     case(mas.HBURST)
      INCR:trans_num=0;
      SINGLE:trans_num=1;
      INCR4,WRAP4:trans_num=4;
      INCR8,WRAP8:trans_num=8;
      INCR16,WRAP16:trans_num=16;
    endcase
  end
  always @(busreq)begin      //Master sending the request signal to the arbiter
    if((!bus_reg)&&(mas.HGRANT!=2'b10))begin
      mas.HBUSREQ[1] = busreq;
      bus_reg=1;
    end
    else if(bus_reg&&(mas.HGRANT==2'b10))begin
      mas.HBUSREQ[1] = 1'b0;
      bus_reg = 0;
    end
  end

  
  //Master sending the address and the control signals once the bus is granted 
  always@(posedge mas.HCLK)begin 
    if(mas.HRESETN&&((mas.HGRANT==2'b10)||(addr_count!=0)))begin 
      if(mas.HREADY)begin
        if(!retry_split)begin
          if(!addr_reg)begin 
            mas.HADDR <= addr;
            mas.HWRITE <= write;
            mas.HSIZE <= WORD;
            mas.HBURST <= burst;//not INCR
            mas.HTRANS <= trans;
            addr_reg <= 1'b1;
            addr_count<=1;
          end
          else if(addr_reg && (addr_count!=trans_num))begin
        /*mas.HADDR=addr_calc(addr,addr_count,mas.HBURST);
          mas.HTRANS=SEQ;
          addr_count=addr_count+1;*/
            case(mas.HTRANS)
              NONSEQ:begin
                    mas.HADDR<=addr_calc(addr,addr_count,mas.HBURST);
                    addr_count<=addr_count+1;
                  end
              SEQ:begin
                  mas.HADDR<=addr_calc(addr,addr_count,mas.HBURST);
                  addr_count<=addr_count+1;
                  end
              IDLE:begin
                    mas.HADDR<=32'h00000000;
                    addr_count<=0;
                  end
              BUSY:begin
                    mas.HADDR<=addr_calc(addr,addr_count-1,mas.HBURST);
                  end
            endcase
            mas.HTRANS<=SEQ;//for testing htrans=busy
          end
          else if(addr_reg &&(addr_count == trans_num))begin
            if(mas.HGRANT==2'b10)begin
              mas.HADDR <= addr;
              mas.HWRITE <= write;
              mas.HSIZE <= WORD;
              mas.HBURST <= burst;//not INCR
              mas.HTRANS <= NONSEQ;
              addr_reg <= 1'b1;
              addr_count<=1;
            end
            else  begin
              addr_count<=0;
              addr_reg<=0;
            end
          end
        end
        else if(retry_split)begin
          if(!addr_reg)begin 
            mas.HADDR <= addr_calc(addr,prev_count,mas.HBURST);
            mas.HWRITE <= write;
            mas.HSIZE <= WORD;
            mas.HBURST <= INCR;
            mas.HTRANS <= NONSEQ;
            addr_reg <= 1'b1;
            addr_count<=addr_count+1;
          end
          else if(addr_reg && (addr_count!=prev_burst-prev_count))begin
            case(mas.HTRANS)
              NONSEQ:begin
                    mas.HADDR<=addr_calc(addr,addr_count+prev_count,mas.HBURST);
                    addr_count<=addr_count+1;
                  end
              SEQ:begin
                  mas.HADDR<=addr_calc(addr,addr_count+prev_count,mas.HBURST);
                  addr_count<=addr_count+1;
                  end
              IDLE:begin
                    mas.HADDR<=32'h00000000;
                    addr_count<=0;
                  end
              BUSY:begin
                    mas.HADDR<=addr_calc(addr,addr_count+prev_count-1,mas.HBURST);
                  end
            endcase
            mas.HTRANS<=SEQ;//for testing htrans=busy
          end
          else if(addr_reg &&(addr_count == prev_burst-prev_count))begin
            if(mas.HGRANT==2'b10)begin
              mas.HADDR <= addr;
              mas.HWRITE <= write;
              mas.HSIZE <= WORD;
              mas.HBURST <= burst;//not INCR
              mas.HTRANS <= NONSEQ;//
              addr_reg <= 1'b1;
              addr_count<=1;
              prev_count<=0;
              prev_burst<=0;
              retry_split<=0;
            end
           else  begin
              addr_count<=0;
              mas.HTRANS<=IDLE;
              addr_reg<=0;
              prev_count<=0;
              prev_burst<=0;
              retry_split<=0;
            end
            
          end
        end
      end
      else if((!mas.HREADY)&&((mas.HRESP==SPLIT)||(mas.HRESP==RETRY))&&((addr_count!=0)))begin
          mas.HTRANS<=IDLE;
          addr_reg<=0;
          addr_count<=0;
          busreq<=1;
          retry_split<=1;
          prev_count<=data_count-1;
          prev_burst<=trans_num;
          next_num<= trans_num-data_count+1;
          //data_count<=0;  
      end 
      
      else if((!mas.HREADY)&&(mas.HRESP==ERROR)&&((addr_count!=0)))begin
          addr_reg<=0;
          addr_count<=0;
          mas.HTRANS<=IDLE;
          busreq<=0;
          retry_split<=0;
          prev_burst<=0;
          prev_count<=0;
          //trans<=IDLE;
      end   
    end//reset
  end//always
  
  //trans data
  always@(posedge mas.HCLK)begin
    if(mas.HRESETN)begin 
      if(mas.HWRITE==1)begin
      if(((mas.HGRANT==2'b10)||(data_count!=0))&&addr_reg)begin
        if(!retry_split)begin
        if(mas.HREADY&&(data_count!=trans_num+1))begin
          case(mas.HTRANS)
            IDLE:begin
                  mas.HWDATA<=32'b0000;
                  data_count<=0;
                end
            NONSEQ:begin
                    mas.HWDATA<=wdata[0];
                    data_count=1;//data_count+1;      
                  end
            SEQ:begin
                    mas.HWDATA<=wdata[data_count];
                    data_count<=data_count+1;
                  end
            BUSY:mas.HWDATA<=wdata[data_count-1];
          endcase
        end
        else if(data_count == trans_num+1)begin
          data_count<=0;
        end 
      end
    else begin
      if(mas.HREADY&&(data_count!=next_num))begin
          case(mas.HTRANS)
            IDLE:begin
                  mas.HWDATA<=32'b0000;
                  data_count<=0;
                end
            NONSEQ:begin
                    mas.HWDATA<=wdata[prev_count];
                    data_count<=1;//data_count+1;      
                  end
            SEQ:begin
                    mas.HWDATA<=wdata[prev_count+data_count];
                    data_count<=data_count+1;
                  end
            BUSY:mas.HWDATA<=wdata[data_count-1];
          endcase
        end
        else if(data_count == next_num)begin
          data_count<=0;
        end 
    end
  end
      end
    end  
  end    

  function logic[31:0] addr_calc(input logic [31:0]addr, input logic [4:0]count,input logic [2:0]burst);
    unique case(burst)
      SINGLE:addr_calc=addr;
      INCR:addr_calc=addr+4*count;
      WRAP4:begin
            if(addr+4*count<{addr[31:4],4'b1111})
              addr_calc=addr+4*count ;
            else
              addr_calc=addr+4*count-4'b1111-1;
            end            
      INCR4:addr_calc=addr+4*count;
      WRAP8:begin
            if(addr+4*count<{addr[31:5],5'b11111})
              addr_calc=addr+4*count;
            else
              addr_calc=addr+4*count-5'b11111-1;
            end  
      INCR8:addr_calc=addr+4*count;
      WRAP16:begin
            if(addr+4*count<{addr[31:6],6'b111111})
              addr_calc=addr+4*count ;
            else
              addr_calc=addr+4*count-6'b111111-1;
            end  
      INCR16:addr_calc=addr+4*count;
    endcase
  endfunction
  
  initial begin
   //addr=32'b000000000000000000;
  addr=36;
    burst=INCR4;
    trans=NONSEQ;
    write=1;
    #5 busreq=1;
       //mas.HLOCK=2'b10;
    //#33 mas.HLOCK=2'b00;
    //#6 busreq=0;
    //#26 addr=32'b010000;
    //#12 busreq=0;
    //#10 trans=SEQ;
    //#13 trans=SEQ;
    //#5 trans=BUSY;
   //#4 trans=SEQ;
  end
endmodule