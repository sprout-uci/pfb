
module  VERSA_rp_gpio (
    clk,
    pc,
    data_addr,
    data_en,
    data_wr,
    dma_addr,
    dma_en,
    ER_min,
    ER_max,

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
input   [15:0]  ER_min;
input   [15:0]  ER_max;
output          reset;


//////////// MACROS ///////////////////////////////////////////
parameter SMEM_BASE = 16'hA000;
parameter SMEM_SIZE = 16'h4000;
parameter SMEM_MAX = SMEM_BASE + SMEM_SIZE;
parameter AUTH_HANDLER = 16'hA0BE;

parameter META_MIN = 16'h0140;
parameter META_SIZE = 16'h0004;

parameter GPIO_BASE = 16'h0018;
parameter GPIO_SIZE = 16'h0020;

parameter RESET_HANDLER = 16'h0000;


//////////// STATES ///////////////////////////////////////////

parameter LOCK  = 2'b00, UNLOCK = 2'b01, RESET = 2'b10;


//////////// LOCAL VARIABLES //////////////////////////////////

reg[2:0]        state;
reg             rp_res;


initial
    begin
        state = RESET;
        rp_res = 1'b1;
    end

wire is_rd_gpio_cpu = data_en && (data_addr >= GPIO_BASE && data_addr <= GPIO_BASE + GPIO_SIZE - 1);
wire is_rd_gpio_dma = dma_en && (dma_addr >= GPIO_BASE && dma_addr <= GPIO_BASE + GPIO_SIZE - 1);
wire is_rd_gpio = is_rd_gpio_cpu || is_rd_gpio_dma;

wire is_wr_meta_cpu = data_wr && (data_addr >= META_MIN && data_addr <= META_MIN + META_SIZE - 2);
wire is_wr_meta_dma = dma_en && (dma_addr >= META_MIN && dma_addr <= META_MIN + META_SIZE - 2);
wire is_wr_er_cpu = data_wr && (data_addr >= ER_min && data_addr <= ER_max);
wire is_wr_er_dma = dma_en && (dma_addr >= ER_min && dma_addr <= ER_max);
wire is_wr_meta_er = is_wr_meta_cpu || is_wr_meta_dma || is_wr_er_cpu || is_wr_er_dma;

wire is_reset = (pc == RESET_HANDLER);
wire is_auth_pass = pc == AUTH_HANDLER;
wire is_fst_ER = pc == ER_min;
wire is_lst_ER = pc == ER_max;
wire pc_in_ER = (pc >= ER_min && pc <= ER_max - 1) && (ER_min < ER_max);

wire not_valid_ER =        (ER_min >= ER_max) 
                        || (ER_min <= SMEM_MAX && SMEM_BASE <= ER_max)
                        || (ER_min == RESET_HANDLER || ER_max == RESET_HANDLER);



//////////// DIGITAL LOGIC /////////////////////////////////////

always @(posedge clk)
if (not_valid_ER || (is_auth_pass && is_wr_meta_er))
    state <= RESET;
else if( state == RESET && is_rd_gpio) 
    state <= RESET;
else if( state == RESET && is_reset && !is_rd_gpio)
    state <= LOCK;
else if( state == LOCK && is_rd_gpio) 
    state <= RESET;
else if( state == LOCK && is_auth_pass && !is_wr_meta_er && !is_rd_gpio) 
    state <= UNLOCK;
else if( state == UNLOCK && is_reset)
    state <= RESET;
else if( state == UNLOCK && is_rd_gpio && !pc_in_ER) 
    state <= RESET;
else if( state == UNLOCK && is_wr_meta_er && is_rd_gpio) 
    state <= RESET;
else if( state == UNLOCK && (is_lst_ER || is_wr_meta_er) && !is_rd_gpio) 
    state <= LOCK;
else state <= state;

always @(posedge clk)
if (not_valid_ER || (is_auth_pass && is_wr_meta_er)) 
    rp_res <= 1'b1;
else if( state == RESET && is_rd_gpio) 
    rp_res <= 1'b1;
else if( state == RESET && is_reset && !is_rd_gpio)
    rp_res <= 1'b0;
else if( state == LOCK && is_rd_gpio) 
    rp_res <= 1'b1;
else if( state == LOCK && is_auth_pass && !is_wr_meta_er && !is_rd_gpio) 
    rp_res <= 1'b0;
else if( state == UNLOCK && is_reset)
    rp_res <= 1'b1;
else if( state == UNLOCK && is_rd_gpio && !pc_in_ER) 
    rp_res <= 1'b1;
else if( state == UNLOCK && is_wr_meta_er && is_rd_gpio) 
    rp_res <= 1'b1;
else if( state == UNLOCK && (is_lst_ER || is_wr_meta_er) && !is_rd_gpio) 
    rp_res <= 1'b0;
else if (state == RESET)
    rp_res <= 1'b1;
else if (state == LOCK)
    rp_res <= 1'b0;
else if (state == UNLOCK)
    rp_res <= 1'b0;
else rp_res <= 1'b0;


assign reset = rp_res;

endmodule
