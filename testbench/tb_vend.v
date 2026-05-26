`timescale 1ns / 1ps

module tb_custom_vending_machine;

    // Inputs to the Unit Under Test (UUT)
    reg clk;
    reg rst_n;
    reg [1:0] item_code;
    reg [7:0] money_in;

    // Outputs from the UUT
    wire dispense;
    wire return_change;

    // Instantiate the Unit Under Test (UUT)
    vend uut (
        .clk(clk),
        .rst_n(rst_n),
        .item_code(item_code),
        .money_in(money_in),
        .dispense(dispense),
        .return_change(return_change)
    );

    // Clock generation: 100MHz (10ns period)
    always #5 clk = ~clk;

    initial begin
        // Setup text monitoring output so you can watch execution logs in Colab/Vivado console
        $monitor("Time=%0d ns | Item=%d Money=%d | State=%b | Dispense=%b Return_Change=%b", 
                 $time, item_code, money_in, uut.PS, dispense, return_change);

        // --- Step 1: Initialize System Signals ---
        clk = 0;
        rst_n = 0;
        item_code = 2'b00;
        money_in = 8'd0;

        // Hold reset active for 2 clock cycles, then release
        #20;
        rst_n = 1;
        #10; // Allow FSM to stabilize onto its unconditional transition path

        // =================================================================
        // TEST CASE 1: Underpayment Scenario
        // Item B selected (Price: 50). Insufficient money (30) inserted.
        // Expected Path: IDLE -> ADD_MONEY -> REFUND -> IDLE
        // Expected Outputs: dispense = 0, return_change = 1 (Refunded)
        // =================================================================
        $display("\n[TIME %0t] >>> Starting Test Case 1: Underpayment (Item B, Price 50, Paid 30) <<<", $time);
        item_code = 2'b10;   // Select Item B
        money_in = 8'd30;    // Insert insufficient cash
        #20;                 // HOLD FOR 2 CYCLES: Allows FSM to transition and sample balance cleanly
        
        money_in = 8'd0;     // Clear input bus 
        #20;                 // Pipeline passes automatically through REFUND back to IDLE
        item_code = 2'b00;   // Reset control panel switches
        #10;                 

        // =================================================================
        // TEST CASE 2: Exact Payment Scenario
        // Item A selected (Price: 25). Exact money (25) inserted.
        // Expected Path: IDLE -> ADD_MONEY -> DISPENSE -> REFUND -> IDLE
        // Expected Outputs: dispense = 1, then return_change = 0 (No change)
        // =================================================================
        $display("\n[TIME %0t] >>> Starting Test Case 2: Exact Payment (Item A, Price 25, Paid 25) <<<", $time);
        item_code = 2'b01;   // Select Item A
        money_in = 8'd25;    // Insert exact cash
        #20;                 // Hold for 2 clock cycles
        
        money_in = 8'd0;     // Clear input bus
        #30;                 // Pipeline flows through DISPENSE -> REFUND -> IDLE automatically
        item_code = 2'b00;   
        #10;

        // =================================================================
        // TEST CASE 3: Overpayment Scenario
        // Item C selected (Price: 75). Excess money (100) inserted.
        // Expected Path: IDLE -> ADD_MONEY -> DISPENSE -> REFUND -> IDLE
        // Expected Outputs: dispense = 1, then return_change = 1 (Dispensed + Change given)
        // =================================================================
        $display("\n[TIME %0t] >>> Starting Test Case 3: Overpayment (Item C, Price 75, Paid 100) <<<", $time);
        item_code = 2'b11;   // Select Item C
        money_in = 8'd100;   // Insert excess cash
        #20;                 // Hold for 2 clock cycles
        
        money_in = 8'd0;     // Clear input bus
        #30;                 // Pipeline flows through DISPENSE -> REFUND -> IDLE automatically
        item_code = 2'b00;   
        #10;

        $display("\n[TIME %0t] Simulation Completed Successfully.", $time);
        $finish;
    end

endmodule
