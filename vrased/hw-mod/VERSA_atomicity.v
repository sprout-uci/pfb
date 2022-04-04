
module  VERSA_atomicity (
    clk,    
    pc,     
    ER_min,
    ER_max,
    irq,

    reset
);

input		    clk;
input   [15:0]  pc;
input   [15:0]  ER_min;
input   [15:0]  ER_max;
input		    irq;
output          reset;

////// FSM States ////////////////////////////////////////////////////
parameter notER  = 3'b000;
parameter fstER = 3'b001;
parameter lstER = 3'b010;
parameter midER = 3'b011;
parameter kill = 3'b100;

////// MACROS ////////////////////////////////////////////////////////
parameter SMEM_BASE = 16'hA000;
parameter SMEM_SIZE = 16'h4000;
parameter SMEM_MAX = SMEM_BASE + SMEM_SIZE;
parameter RESET_HANDLER = 16'h0000;

//////////////////////////////////////////////////////////////////////

wire [15:0] ER_BASE = ER_min;
wire [15:0] LAST_ER_ADDR = ER_max;

reg     [2:0]   pc_state; // 3 bits for 5 states
reg             atomicity_reset;

initial
begin
        pc_state = kill;
        atomicity_reset = 1'b1;
end
	

wire not_valid_ER =        (ER_min >= ER_max) 
                        || (ER_min <= SMEM_MAX && SMEM_BASE <= ER_max)
                        || (ER_min == RESET_HANDLER || ER_max == RESET_HANDLER);

wire is_mid_ER = pc > ER_BASE && pc < LAST_ER_ADDR;
wire is_fst_ER = pc == ER_BASE;
wire is_lst_ER = pc == LAST_ER_ADDR;
wire is_not_ER = pc < ER_BASE | pc > LAST_ER_ADDR;
wire is_reset = pc == RESET_HANDLER;


always @(posedge clk)
begin
    if(not_valid_ER)
        pc_state <= kill;
    else
        begin
        case (pc_state)
            notER:
                if (is_not_ER)
                    pc_state <= notER;
                else if (is_fst_ER)
                    pc_state <= fstER;
                else if (is_mid_ER || is_lst_ER)
                    pc_state <= kill;
                else 
                    pc_state <= pc_state;
            
            midER:
                if (is_mid_ER)
                    pc_state <= midER;
                else if (is_lst_ER)
                    pc_state <= lstER;
                else if (is_not_ER || is_fst_ER)
                    pc_state <= kill; 
                else
                    pc_state <= pc_state;
                    
            fstER:
                if (is_mid_ER) 
                    pc_state <= midER;
                else if (is_fst_ER) 
                    pc_state = fstER;
                else if (is_not_ER  || is_lst_ER) 
                    pc_state <= kill;
                else 
                    pc_state <= pc_state;
                
            lstER:
                if (is_not_ER)
                    pc_state <= notER;
                else if (is_lst_ER) 
                    pc_state = lstER;
                else if (is_fst_ER || is_mid_ER)
                  pc_state <= kill;
                else pc_state <= pc_state;
                    
            kill:
                // if (is_fst_ER)
                //     pc_state <= fstER;
                // else if (is_reset || is_not_ER)
                //     pc_state <= notER;
                // if (is_reset && is_fst_ER)
                //     pc_state <= fstER;
                // else if (is_reset)
                //     pc_state <= notER;
                if (is_reset)
                     pc_state <= notER;
                else
                    pc_state <= pc_state;
                    
        endcase
        end
end

////////////// OUTPUT LOGIC //////////////////////////////////////
always @(posedge clk)
if (not_valid_ER)
    atomicity_reset <= 1'b1;
else if (
            (pc_state == kill && !is_reset) ||
            (pc_state == fstER && (is_not_ER || is_lst_ER)) ||
            (pc_state == lstER && (is_mid_ER || is_fst_ER)) ||
            (pc_state == midER && (is_not_ER || is_fst_ER)) ||
            (pc_state == notER && (is_mid_ER || is_lst_ER))
        )
    atomicity_reset <= 1'b1;
else
    atomicity_reset <= 1'b0;


assign reset = atomicity_reset;

endmodule
