module decoder(input logic[31:0]haddr,output logic[1:0]hsel);
  always@(haddr) begin
    hsel=2'b0;
    unique case(haddr[31])
      1'b0: hsel[0]=1'b1;
      1'b1: hsel[1]=1'b1;
    endcase
  end 
endmodule