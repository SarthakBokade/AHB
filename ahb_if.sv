
interface ahb_if (input logic hclk, input logic hresetn);
  
logic [31:0] haddr;
logic [31:0] hwdata;
logic [31:0] hrdata;
logic [1:0] htrans;
logic [2:0] hburst;
logic [2:0] hsize;
logic hwrite;
logic hsel;
logic hready; 
logic [1:0]  hresp;
  

// SVA
    
// checking stability
property p_stable_addr;
  @(posedge hclk) (hsel && !hready) |=> $stable(haddr);
endproperty
  
ASSERT_STABLE_ADDR: assert property (p_stable_addr) 
  else $error("AHB Violation: Address unstable during Wait State");

// checking signal validity
  
property p_valid_ctrl;
  @(posedge hclk) hsel |-> (!$isunknown(htrans) && !$isunknown(hwrite));
endproperty
  
ASSERT_VALID_CTRL: assert property (p_valid_ctrl);

  
endinterface