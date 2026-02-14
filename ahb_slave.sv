`timescale 1ns / 1ps

//////////////////////////// AHB Slave/////////////////////////////////////////

module ahb_slave (
  
input logic hclk,
input logic hresetn,
input logic hsel,
input logic [31:0] haddr,
input logic [1:0] htrans,
input logic hwrite,
input logic [2:0] hsize,
input logic [2:0] hburst,
input logic [31:0] hwdata,
    
output logic hready_out,
output logic [1:0] hresp,
output logic [31:0] hrdata
  
);


logic [7:0] mem [0:1023] = '{default:0};

// pipeline registers
  
logic [31:0] addr_reg;
logic [2:0] size_reg;
logic write_reg;
logic valid_phase_2; 

// transfer types supported
  
localparam NONSEQ = 2'b10;
localparam SEQ = 2'b11;

   
///////////address phase - Nth cycle/////////////
  
always_ff @(posedge hclk or negedge hresetn) begin
  if (!hresetn) begin
     addr_reg <= 0;
     size_reg <= 0;
     write_reg <= 0;
     valid_phase_2 <= 0;
  end else begin
   // sample when hready is high
  if (hready_out && hsel) begin
    if (htrans == NONSEQ || htrans == SEQ) begin
      addr_reg <= haddr;
      size_reg <= hsize;
      write_reg <= hwrite;
      valid_phase_2 <= 1; // Move to Data Phase next cycle
    end else begin
      valid_phase_2 <= 0; // IDLE
    end
    end else if (hready_out) begin
      valid_phase_2 <= 0; // not selected
    end
   
  end
 
end

   
//////////////////// data phase -  (N+1)th cycle /////////////////////
    
    
 // wr
always_ff @(posedge hclk) begin
  if (valid_phase_2 && write_reg && hready_out) begin
           
    mem[addr_reg] <= hwdata[7:0];
    mem[addr_reg+1] <= hwdata[15:8];
    mem[addr_reg+2] <= hwdata[23:16];
    mem[addr_reg+3] <= hwdata[31:24];
    
  end
end

// rd
always_comb begin
  hrdata = 32'b0;
  if (valid_phase_2 && !write_reg) begin
    hrdata[7:0] = mem[addr_reg];
    hrdata[15:8] = mem[addr_reg+1];
    hrdata[23:16] = mem[addr_reg+2];
    hrdata[31:24] = mem[addr_reg+3];
  end
end

    
///////////////// response logic ///////////////////////////
    
assign hresp = 2'b00; // Ok
assign hready_out = 1'b1;  // always ready zero wait state 

endmodule
