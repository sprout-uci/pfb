`include "vrased.v"	
`include "VERSA.v"	

`ifdef OMSP_NO_INCLUDE
`else
`include "openMSP430_defines.v"
`endif

module hwmod (
    clk,
    pc,
    data_en,
    data_wr,
    data_addr,
    dma_addr,
    dma_en,
    ER_min,
    ER_max,
    irq,
    puc,
    
    reset
);


//////////// INPUTS AND OUTPUTS ////////////////////////////////

input           clk;
input   [15:0]  pc;
input           data_en;
input           data_wr;
input   [15:0]  data_addr;
input   [15:0]  dma_addr;
input           dma_en;
input   [15:0]  ER_min;
input   [15:0]  ER_max;
input           irq;
input           puc;

output          reset;


//////////// MACROS ///////////////////////////////////////////

// parameter ER_min = 16'hE1CC;
// parameter ER_max = ER_min + 16'h0500;

parameter SDATA_BASE = 16'h400;
parameter SDATA_SIZE = 16'hC00;

parameter SMEM_BASE = 16'hA000;
parameter SMEM_SIZE = 16'h4000;

parameter AUTH_HANDLER = 16'hA0AA;

parameter KMEM_BASE = 16'h6A00;
parameter KMEM_SIZE = 16'h0040;

parameter META_MIN = 16'h0140;
parameter META_SIZE = 16'h0004;

parameter GPIO_BASE = 16'h0018;
parameter GPIO_SIZE = 16'h0020;

parameter EKEY_BASE = 16'h0360;
parameter EKEY_SIZE = 16'h0020;

parameter CTR_BASE = 16'hFFC0;
parameter CTR_SIZE = 16'h0020;

parameter HMAC_BASE = EKEY_BASE;
parameter HMAC_SIZE = EKEY_SIZE;

parameter RESET_HANDLER = 16'h0000;


//////////// DIGITAL LOGIC /////////////////////////////////////

wire vrased_reset;

vrased #(
        .SMEM_BASE (SMEM_BASE),
        .SMEM_SIZE (SMEM_SIZE),
        .SDATA_BASE (SDATA_BASE),
        .SDATA_SIZE (SDATA_SIZE),
        .HMAC_BASE (HMAC_BASE),
        .HMAC_SIZE (HMAC_SIZE),
        .KMEM_BASE (KMEM_BASE),
        .KMEM_SIZE (KMEM_SIZE),
        .CTR_BASE  (CTR_BASE),
        .CTR_SIZE  (CTR_SIZE),
        .RESET_HANDLER (RESET_HANDLER)
) vrased_0 (
    .clk        (clk),
    .pc         (pc),
    .data_en    (data_en),
    .data_wr    (data_wr),
    .data_addr  (data_addr),
    .dma_addr   (dma_addr),
    .dma_en     (dma_en),
    .irq        (irq),
    
    .reset      (vrased_reset)
);



wire VERSA_reset;

VERSA #( .SMEM_BASE (SMEM_BASE),
        .SMEM_SIZE (SMEM_SIZE),
        .AUTH_HANDLER (AUTH_HANDLER),
        .META_MIN (META_MIN),
        .META_SIZE (META_SIZE),
        .GPIO_BASE (GPIO_BASE),
        .GPIO_SIZE (GPIO_SIZE),
        .EKEY_BASE (EKEY_BASE),
        .EKEY_SIZE (EKEY_SIZE),
        .CTR_BASE (CTR_BASE),
        .CTR_SIZE (CTR_SIZE),
        .RESET_HANDLER (RESET_HANDLER)
         ) VERSA_0 (
    .clk        (clk),
    .pc         (pc),
    .data_en    (data_en),
    .data_wr    (data_wr),
    .data_addr  (data_addr), 
    .dma_addr   (dma_addr),
    .dma_en     (dma_en),
    .ER_min     (ER_min),
    .ER_max     (ER_max),
    .irq        (irq),
    .puc        (puc),
    
    .reset      (VERSA_reset)
);


assign reset = vrased_reset | VERSA_reset;
// assign reset = vrased_reset;
// assign reset = 1'b0;

endmodule
