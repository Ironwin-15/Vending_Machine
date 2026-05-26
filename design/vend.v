module vend (
    input clk,
    input rst_n,
    input [1:0] item_code,     // 00=None, 01=Item A, 10=Item B, 11=Item C
    input [7:0] money_in,      // Numerical value of inserted cash/coin
    output reg dispense,       // 1 = Drop item, 0 = Lock (Combinational)
    output reg return_change   // Pulses 1 if change > 0 OR during an underpayment refund (Combinational)
);

    // FSM State Encodings
    parameter IDLE      = 2'b00,
              ADD_MONEY = 2'b01,
              DISPENSE  = 2'b10,
              REFUND    = 2'b11;

    reg [1:0] PS, NS;
    reg [7:0] accumulated_balance;
    
    // Combinational internal wires
    reg [7:0] target_price;
    wire is_enough_money;

    // 1. Combinational Circuit: Item Price Lookup Table
    always @(*) begin
        case (item_code)
            2'b01:   target_price = 8'd25;  // Item A costs 25 units
            2'b10:   target_price = 8'd50;  // Item B costs 50 units
            2'b11:   target_price = 8'd75;  // Item C costs 75 units
            default: target_price = 8'd255; // Default safety fallback
        endcase
    end

    // 2. Combinational Circuit: Look-Ahead Balance Checker
    // If currently in ADD_MONEY, it checks the money_in bus directly to make an instant state transition decision
    assign is_enough_money = (PS == ADD_MONEY) ? (money_in >= target_price) : (accumulated_balance >= target_price);

    // 3. FSM Sequential State Register
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n)
            PS <= IDLE;
        else
            PS <= NS;
    end

    // 4. Next State Logic (Your linear pipeline path preserved)
    always @(*) begin
        case (PS)
            IDLE: begin
                NS = ADD_MONEY; // Unconditional jump to ADD_MONEY
            end
            
            ADD_MONEY: begin
                if (money_in > 8'd0) begin
                    if (is_enough_money) 
                        NS = DISPENSE; // Sufficient funds -> Dispense -> Refund pipeline
                    else 
                        NS = REFUND;   // Insufficient funds -> Direct to Refund
                end else begin
                    NS = ADD_MONEY;    // Wait in ADD_MONEY state until cash drops
                end
            end
            
            DISPENSE: begin
                NS = REFUND; // Auto-advances to REFUND state on the next clock edge
            end

            REFUND: begin
                NS = IDLE;   // Auto-returns to IDLE to wait for the next transaction
            end
            
            default: NS = IDLE;
        endcase
    end

    // 5. Datapath Register: Balance Tracker
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            accumulated_balance <= 8'd0;
        end else begin
            case (PS)
                IDLE: begin
                    accumulated_balance <= 8'd0;
                end
                ADD_MONEY: begin
                    if (money_in > 8'd0)
                        accumulated_balance <= money_in; // Latch the money bus data
                end
                DISPENSE: begin
                    // Balance left alive so the combinational output circuit can calculate change
                end
                REFUND: begin
                    accumulated_balance <= 8'd0; // Flush register at the absolute end of pipeline
                end
            endcase
        end
    end

    // 6. Output Logic Generation (COMBINATIONAL - INSTANT OUTPUT)
    always @(*) begin
        case (PS)
            IDLE, ADD_MONEY: begin
                dispense      = 1'b0;
                return_change = 1'b0;
            end
            
            DISPENSE: begin
                dispense      = 1'b1; // Turns 1 instantly when entering DISPENSE state
                return_change = 1'b0;
            end

            REFUND: begin
                dispense = 1'b0; // Lock the dispenser tray back up
                
                // Return change if overpaid OR if the transaction was forced to a refund
                if ((accumulated_balance > target_price) || (~is_enough_money))
                    return_change = 1'b1; // Turns 1 instantly when entering REFUND state
                else
                    return_change = 1'b0;
            end
            
            default: begin
                dispense      = 1'b0;
                return_change = 1'b0;
            end
        endcase
    end

endmodule
