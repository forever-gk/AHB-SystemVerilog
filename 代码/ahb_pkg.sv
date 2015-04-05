`ifndef AHB
  `define AHB
  package AHB;
  typedef enum logic [2:0]{BYTE,HALFFORD,WORD,BIT_64,FOUR_WORD,EIGHT_WORD,BIT_512,BIT_1024} type_hsize;
  typedef enum logic [2:0]{SINGLE,INCR,WRAP4,INCR4,WRAP8,INCR8,WRAP16,INCR16} type_hburst;
  typedef enum logic [1:0]{IDLE,BUSY,NONSEQ,SEQ} type_htrans;
  typedef enum logic [1:0]{OKAY,ERROR,RETRY,SPLIT} type_hresp;
  
  parameter logic [1:0] DEFAULT_MASTER=2'b00;
endpackage
  import AHB::*;
`endif
