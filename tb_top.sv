`timescale 1ns / 1ps

//`include "ahb_slave.sv"
//`include "ahb_if.sv"
`include "tb_classes.sv"

module tb_top;
  
  bit hclk;
  bit hresetn;
 
  always #5 hclk = ~hclk;
 
  ahb_if vif(hclk, hresetn);

  ahb_slave dut (
    
    .hclk(vif.hclk), .hresetn(vif.hresetn),
    .hsel(vif.hsel), .haddr(vif.haddr), .htrans(vif.htrans),
    .hwrite(vif.hwrite), .hsize(vif.hsize), .hburst(vif.hburst),
    .hwdata(vif.hwdata), .hrdata(vif.hrdata),
    .hready_out(vif.hready), .hresp(vif.hresp)
    
  );

    generator gen;
    driver drv;
    monitor mon;
    scoreboard sco;
    mailbox #(transaction) gen2drv, mon2sco;

    initial begin
      hclk = 0; hresetn = 0;

      //mb's
      gen2drv = new(1); // for handshaking
      mon2sco = new();

      // const
      gen = new(gen2drv);
      drv = new(gen2drv);
      mon = new(mon2sco);
      sco = new(mon2sco);

      //connections
      drv.vif = vif;
      mon.vif = vif;

      // Reset
      #10 hresetn = 1;



      fork 
        gen.run();
        drv.run();
        mon.run();
        sco.run();
      join_any


      wait(gen.done.triggered);
      #100; 
      $finish;
    end
    
    // Waveforms
    initial begin
      
      $dumpfile("ahb.vcd");
      $dumpvars;
      
    end
endmodule