
module  VERSA_wp_ekey (
    clk,
    pc,
    data_addr,
    data_en,
    data_wr,
    dma_addr,
    dma_en,

    reset
);

//////////// INPUTS AND OUTPUTS ////////////////////////////////

input		clk;
input   [15:0]  pc;
input   [15:0]  data_addr;
input           data_en;
input           data_wr;
input   [15:0]  dma_addr;
input           dma_en;
output          reset;


//////////// MACROS ///////////////////////////////////////////

parameter SMEM_BASE = 16'hA000;
parameter SMEM_SIZE = 16'h4000;

parameter EKEY_BASE = 16'h0230;
parameter EKEY_SIZE = 16'h001F;

parameter RESET_HANDLER = 16'h0000;


//////////// STATES ///////////////////////////////////////////

parameter RESET  = 1'b0, UNLOCK = 1'b1;


//////////// LOCAL VARIABLES //////////////////////////////////

reg             state;
reg             wp_res;


initial
    begin
        state = RESET;
        wp_res = 1'b1;
    end

wire is_wr_ekey_cpu = data_wr && (data_addr >= EKEY_BASE && data_addr <= EKEY_BASE + EKEY_SIZE - 1);
wire is_wr_ekey_dma = dma_en && (dma_addr >= EKEY_BASE && dma_addr <= EKEY_BASE + EKEY_SIZE - 1);
wire is_wr_ekey = is_wr_ekey_cpu || is_wr_ekey_dma;

wire pc_reset = pc == RESET_HANDLER;
wire pc_in_rom = (pc >= SMEM_BASE && pc <= SMEM_BASE + SMEM_SIZE - 2);


//////////// DIGITAL LOGIC /////////////////////////////////////


always @(posedge clk)
if( state == UNLOCK && !pc_in_rom && is_wr_ekey) 
    state <= RESET;
else if (state == RESET && pc_reset && !is_wr_ekey)
    state <= UNLOCK;
else state <= state;

always @(posedge clk)
if (state == UNLOCK && !pc_in_rom && is_wr_ekey)
    wp_res <= 1'b1;
else if (state == RESET && pc_reset && !is_wr_ekey)
    wp_res <= 1'b0;
else if (state == RESET)
    wp_res <= 1'b1;
else if (state == UNLOCK)
    wp_res <= 1'b0;
else wp_res <= 1'b0;


assign reset = wp_res;

endmodule
