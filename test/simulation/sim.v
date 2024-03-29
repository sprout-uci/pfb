//`include "../verilog/omsp430/openMSP430_defines.v"
`define NO_TIMEOUT
reg [32:0] total_cycles = 0;
initial
   begin
      $display(" ===============================================");
      $display("|                 START SIMULATION              |");
      $display(" ===============================================");
      repeat(5) @(posedge mclk);
      stimulus_done = 0;
      #10 $monitor("pc = %h, r1 = %h, r2 = %h, r3 = %h, r4 = %h, r5 = %h, r6 = %h, r14 = %h, srom_dout = %h, srom_cen = %h, pmem_cen = %h, ER_min = %h\n", dut.inst_pc, r1, r2, r3, r4, r5, r6, r14, dut.srom_dout, dut.srom_cen, dut.pmem_cen, dut.hdmod_0.VERSA_0.ER_min);
     
      @(r0==16'hfffe);
      $display("start");


     
      @(r0==16'he000);
      $display("In Flash");
      
      /*@(r0==16'he05c);
      num_cycles = 0;

      @(r0==16'ha000);
      num_non_tcb_cycles = num_cycles;
      
      @(r0==16'hdffe);
      //total_cycles = num_cycles;
      $display("Attestation take %d cycles", num_cycles-num_non_tcb_cycles);*/

      @(r0==16'hfffe);
      repeat(10) @(posedge mclk);
      $display("Total time %d cycles", $signed(num_cycles));
      $finish;


      @(r0==16'hfffe);
      $display("Total time %d cycles", $signed(num_cycles));
      $display("Final state:\n");
	$finish;

      $display("pc = %h, r1 = %h, r2 = %h, r3 = %h, r4 = %h, r5 = %h, srom_dout = %h, srom_cen = %h, pmem_cen = %h\n", r0, r1, r2, r3, r4, r5, dut.srom_dout, dut.srom_cen, dut.pmem_cen);

      stimulus_done = 1;
   end

reg [32:0] num_cycles = 0;
reg [32:0] num_non_tcb_cycles = 0;

always @(posedge mclk)
      num_cycles = num_cycles + 1;
