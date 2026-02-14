
class transaction;
  rand bit [31:0] haddr;
  rand bit [31:0] hwdata;
  rand bit hwrite;
  rand bit [2:0] hburst;
  rand bit [2:0] hsize;
  bit [31:0] hrdata;
    
  // constraints
  constraint c_align { haddr[1:0] == 0; } // Word Aligned
  constraint c_size  { hsize == 3'b010; } 
  constraint c_addr  { haddr < 1000; }    // mem boundry of 1kb 
  
  
endclass




class generator;
  
  transaction tr;
  mailbox #(transaction) mbx;
  event done;

  function new(mailbox #(transaction) mbx);
    this.mbx = mbx;
  endfunction

  task run();
    repeat(20) begin 
      tr = new();
      assert(tr.randomize());
      mbx.put(tr); //handshake with drv
    end
    
    ->done;
    
    endtask
  
endclass



class driver;
  
  virtual ahb_if vif;
  mailbox #(transaction) mbx;
  transaction tr;

  function new(mailbox #(transaction) mbx);
    this.mbx = mbx;
  endfunction

  task run();
  vif.hsel <= 0;
  vif.htrans <= 0; // IDLE
  vif.hwrite <= 0;
  vif.haddr <= 0;
  vif.hwdata <= 0;

  forever begin
    mbx.get(tr);
            
 /////////////////ADDRESS PHASE (Cycle N) ///////////////

  @(posedge vif.hclk);
  while(vif.hready == 0) @(posedge vif.hclk); // Wait for Ready

  vif.hsel    <= 1;
  vif.haddr   <= tr.haddr;
  vif.hwrite  <= tr.hwrite;
  vif.htrans  <= 2'b10; // NONSEQ
  vif.hsize   <= tr.hsize;
  vif.hburst  <= 0;     // single

 /////////////////DATA PHASE (Cycle N+1) ////////////////////////
    
  @(posedge vif.hclk);
  while(vif.hready == 0) @(posedge vif.hclk); // Waiting for ready

  // return to IDLE
  vif.htrans <= 0; 
  vif.hsel   <= 0; 

  // Drive Write Data when happend 
  if(tr.hwrite) vif.hwdata <= tr.hwdata;

    end
    
  endtask
  
  
endclass




class monitor;
  virtual ahb_if vif;
  mailbox #(transaction) mbx;
  transaction tr;

  // Pipeline logic (using queues)
  bit [31:0] addr_q[$]; 
  bit write_q[$];

  function new(mailbox #(transaction) mbx);
    this.mbx = mbx;
  endfunction

  task run();
    forever begin
      @(posedge vif.hclk);

      // addr phase capture
      if (vif.hready && vif.hsel && (vif.htrans[1])) begin
        addr_q.push_back(vif.haddr);
        write_q.push_back(vif.hwrite);
      end

      // data phase capture
      if (addr_q.size() > 0 && vif.hready) begin
        tr = new();
        tr.haddr  = addr_q.pop_front();
        tr.hwrite = write_q.pop_front();

        if (tr.hwrite) begin
          tr.hwdata = vif.hwdata; // sample Write data
          $display("[MON] WRITE Addr: %0h Data: %0h", tr.haddr, tr.hwdata);
        end else begin
          tr.hrdata = vif.hrdata; // sample read data
          $display("[MON] READ  Addr: %0h Data: %0h", tr.haddr, tr.hrdata);
        end

        mbx.put(tr); // to sco
      end
      
    end
    
  endtask
  
  
endclass


class scoreboard;
  
  mailbox #(transaction) mbx;
  transaction tr;
  bit [7:0] mem[int];//shadow memory

  function new(mailbox #(transaction) mbx);
    this.mbx = mbx;
  endfunction

  task run();
    forever begin
      mbx.get(tr);
      if (tr.hwrite) begin
        // setting shadow memory
        mem[tr.haddr] = tr.hwdata[7:0];
        mem[tr.haddr+1] = tr.hwdata[15:8];
        mem[tr.haddr+2] = tr.hwdata[23:16];
        mem[tr.haddr+3] = tr.hwdata[31:24];
        $display("[SCO] WRITE Success Addr: %0h", tr.haddr);
      end 
      
      else begin
        // reading logic
        bit [31:0] exp_data;
        exp_data[7:0] = mem.exists(tr.haddr) ? mem[tr.haddr] : 0;
        exp_data[15:8] = mem.exists(tr.haddr+1) ? mem[tr.haddr+1] : 0;
        exp_data[23:16] = mem.exists(tr.haddr+2) ? mem[tr.haddr+2] : 0;
        exp_data[31:24] = mem.exists(tr.haddr+3) ? mem[tr.haddr+3] : 0;

        if (exp_data !== tr.hrdata) 
          $error("[SCO] MISMATCH! Addr:%0h Exp:%0h Act:%0h", tr.haddr, exp_data, tr.hrdata);
        else
          $display("[SCO] READ MATCH  Addr:%0h Data:%0h", tr.haddr, tr.hrdata);
        
      end

    end

  endtask
  
  
endclass
