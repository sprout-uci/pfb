`include "VERSA_atomicity.v"
`include "VERSA_irq_dma.v"
`include "VERSA_rp_gpio.v"
`include "VERSA_wp_ekey.v"

`ifdef OMSP_NO_INCLUDE
`else
`include "openMSP430_defines.v"
`endif

module VERSA (
    clk,
    pc,
    data_en,
    data_wr,
    data_addr,
    dma_addr,
    dma_en,
    ER_min,
    ER_max,
    puc,
    irq,
    
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
input           puc;
input           irq;

output          reset;


//////////// MACROS ///////////////////////////////////////////

parameter SMEM_BASE = 16'hA000;
parameter SMEM_SIZE = 16'h4000;

parameter AUTH_HANDLER = 16'hA0BE;

parameter META_MIN = 16'h0140;
parameter META_SIZE = 16'h0004;

parameter GPIO_BASE = 16'h0018;
parameter GPIO_SIZE = 16'h0020;

parameter EKEY_BASE = 16'h0230;
parameter EKEY_SIZE = 16'h001F;

parameter CTR_BASE = 16'h0250;
parameter CTR_SIZE = 16'h001F;

parameter RESET_HANDLER = 16'h0000;


//////////// DIGITAL LOGIC /////////////////////////////////////

wire    VERSA_atomicity;
VERSA_atomicity #(   
    .SMEM_BASE (SMEM_BASE),
    .SMEM_SIZE (SMEM_SIZE),
    .RESET_HANDLER (RESET_HANDLER)
) 
VERSA_atomicity_0 (
    .clk        (clk),
    .pc         (pc),
    .ER_min	(ER_min),
    .ER_max	(ER_max),
    .irq	(irq),
    
    .reset      (VERSA_atomicity)
);


wire   VERSA_irq_dma;
irq_dma #(
    .RESET_HANDLER (RESET_HANDLER)
) 
irq_dma_0 (
    .clk        (clk),
    .pc         (pc),
    .irq        (irq),
    .dma_en     (dma_en),
    .ER_min     (ER_min),
    .ER_max     (ER_max),

    .reset      (VERSA_irq_dma) 
);


wire   VERSA_rp_gpio;
VERSA_rp_gpio #(
    .SMEM_BASE (SMEM_BASE),
    .SMEM_SIZE (SMEM_SIZE),
    .AUTH_HANDLER (AUTH_HANDLER),
    .META_MIN (META_MIN),
    .META_SIZE (META_SIZE),
    .GPIO_BASE (GPIO_BASE),
    .GPIO_SIZE (GPIO_SIZE),
    .RESET_HANDLER (RESET_HANDLER)
) 
VERSA_rp_gpio_0 (
    .clk        (clk),
    .pc         (pc),
    .data_addr  (data_addr),
    .data_en    (data_en),
    .data_wr    (data_wr),
    .dma_addr   (dma_addr),
    .dma_en     (dma_en),
    .ER_min     (ER_min),
    .ER_max     (ER_max),

    .reset      (VERSA_rp_gpio) 
);

wire   VERSA_rp_ekey;
VERSA_rp_gpio #(
    .SMEM_BASE (SMEM_BASE),
    .SMEM_SIZE (SMEM_SIZE),
    .AUTH_HANDLER (AUTH_HANDLER),
    .META_MIN (META_MIN),
    .META_SIZE (META_SIZE),
    .GPIO_BASE (EKEY_BASE),
    .GPIO_SIZE (EKEY_SIZE),
    .RESET_HANDLER (RESET_HANDLER)
) 
VERSA_rp_gpio_1 (
    .clk        (clk),
    .pc         (pc),
    .data_addr  (data_addr),
    .data_en    (data_en),
    .data_wr    (data_wr),
    .dma_addr   (dma_addr),
    .dma_en     (dma_en),
    .ER_min     (ER_min),
    .ER_max     (ER_max),

    .reset      (VERSA_rp_ekey) 
);

wire   VERSA_wp_ekey;
VERSA_wp_ekey #(
    .SMEM_BASE (SMEM_BASE),
    .SMEM_SIZE (SMEM_SIZE),
    .EKEY_BASE (EKEY_BASE),
    .EKEY_SIZE (EKEY_SIZE),
    .RESET_HANDLER (RESET_HANDLER)
) 
VERSA_wp_ekey_0 (
    .clk        (clk),
    .pc         (pc),
    .data_addr  (data_addr),
    .data_en    (data_en),
    .data_wr    (data_wr),
    .dma_addr   (dma_addr),
    .dma_en     (dma_en),

    .reset      (VERSA_wp_ekey) 
);

wire   VERSA_wp_ctr;
VERSA_wp_ekey #(
    .SMEM_BASE (SMEM_BASE),
    .SMEM_SIZE (SMEM_SIZE),
    .EKEY_BASE (CTR_BASE),
    .EKEY_SIZE (CTR_SIZE),
    .RESET_HANDLER (RESET_HANDLER)
) 
VERSA_wp_ekey_1 (
    .clk        (clk),
    .pc         (pc),
    .data_addr  (data_addr),
    .data_en    (data_en),
    .data_wr    (data_wr),
    .dma_addr   (dma_addr),
    .dma_en     (dma_en),

    .reset      (VERSA_wp_ctr) 
);


assign reset = VERSA_atomicity | VERSA_irq_dma | VERSA_rp_ekey | VERSA_rp_gpio | VERSA_wp_ekey | VERSA_wp_ctr;
// assign reset = VERSA_irq_dma | VERSA_rp_gpio;

endmodule
