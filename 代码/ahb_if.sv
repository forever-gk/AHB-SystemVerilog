`include "ahb_pkg.sv"
interface ahb_if(input logic HCLK,input logic HRESETN);
  logic[1:0]   HBUSREQ;//arbiter
  logic[1:0]   HLOCK;
  logic[31:0]  HADDR;
  type_htrans  HTRANS;
  type_hburst  HBURST;
  type_hsize   HSIZE;
  logic[3:0]   HPROT;
  logic        HWRITE;
  logic[31:0]  HWDATA;
  logic[1:0]   HGRANT;
  logic        HREADY;
  type_hresp   HRESP;
  logic[31:0]  HRDATA;
  logic[1:0]   HSEL; //decoder    
  logic[3:0]   HMASTER;
  logic        HMASTLOCK;
  logic[15:0]  HSPLIT;
  
  modport master(input    HCLK,
                 input    HRESETN,
                 input    HGRANT,
                 input    HRESP,
                 input    HREADY,
                 input    HRDATA,
                 output   HBURST,
                 output   HLOCK,
                 output   HWRITE,
                 output   HBUSREQ,
                 output   HADDR,
                 output   HSIZE,
                 output   HTRANS,
                 output   HWDATA,
                 output   HPROT);
                
  modport slave(input    HCLK,
                input    HRESETN,
                input    HSEL,
                input    HADDR,
                input    HWRITE,
                input    HTRANS,
                input    HSIZE,                
                input    HBURST,           
                input    HWDATA,
                input    HMASTER,
                input    HMASTLOCK,
                output   HREADY,
                output   HSPLIT,
                output   HRDATA,
                output   HRESP);
                
  modport arbiter(input    HCLK,
                  input    HRESETN,
                  input    HBUSREQ,
                  input    HLOCK,
                  input    HADDR,
                  input    HSPLIT,
                  input    HTRANS,                
                  input    HBURST,
                  input    HRESP,
                  input    HREADY,           
                  output   HMASTER,
                  output   HMASTLOCK,
                  output   HGRANT,
                  output   HSEL);
endinterface
