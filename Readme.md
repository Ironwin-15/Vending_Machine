# Vending Machine using FSMDs

A cycle-accurate, hardware-validated **Finite State Machine (FSM)** modeling a smart vending machine. The architecture leverages sequential control paths in hardware while utilizing combinational shortcuts to achieve instant balance verification and zero-latency product delivery flags. 

The project includes HDL modules (**Verilog**), verification structures (**Testbenches**), an interactive dashboard (**Jupyter Notebook / Python**), and a dataset of various items in a vending machine from an external spreadsheet backend.

---
### Inventory Profile

The full 100 item inventory can be searched here:
 **[Click Here to Open complete inventory ledger (data/vending_items.xlsx)](data/vending_items.xlsx)**

A snippet from the inventory table is given below-
| Item Code | Category | Product Descriptor Name | Unit Price (Hardware Units) | Target Output Response |
| :---: |:--- | :--- | :---: | :--- |
| **1** | Drinks | Coca-Cola | 25 | Standard Release Flag |
| **2** | Drinks | Diet Coke | 25 | Standard Release Flag |
| **8** | Drinks | Monster Energy | 50 | Mid-Tier Validation |
| **16** | Chips | Classic Potato Chips | 50 | Mid-Tier Validation |
| **17** | Chips | Nacho Cheese Doritos | 50 | Mid-Tier Validation |
| **26** | Candy | Snickers Bar | 35 | Budget Tier Release |
| **27** | Candy | Twix Left & Right | 35 | Budget Tier Release |
| **41** | Healthy | Oats & Honey Granola Bar | 60 | High-Tier Validation |
| **51** | Drinks | Coca-Cola (Large Size) | 50 | Mid-Tier Validation |
| **76** | Candy | Snickers Bar (King Size) | 60 | High-Tier Validation |
| **100** | Healthy | Roasted Cashews (King Size) | 85 | Premium Tier Validation |

---

## System Architecture

1. **`The FSM Component (The Controller)`:** The system uses 4 states `(IDLE, ADD_MONEY, DISPENSE, REFUND)` to decide what to do next. 
2. **`The Datapath Component (The Calculator)`:** A pure FSM can only check binary inputs (like 1 or 0). Your code, however, stores, transfers, and calculates actual numbers:
   * **The Storage Register:** accumulated_balance acts as a data memory register.
   * **The Comparator:** The system performs dynamic lookups (target_price) and checks mathematical conditions (accumulated_balance > target_price).

### State Diagram of Controller
<img width="472" height="385" alt="image" src="https://github.com/user-attachments/assets/f02b5a0c-e5a4-4081-a0e1-7c9a7e2098f9" />


### Hardware Component Breakdown

1. **`IDLE` (State `00`)**: The machine starts here. It resets all values and clears the balance. On the very next clock edge, it automatically moves to the `ADD_MONEY` state.
2. **`ADD_MONEY` (State `01`)**: The machine checks how much money you put in and compares it directly to the item's price. 
   * **If you put in enough money**: It goes straight to the `DISPENSE` state to drop your item.
   * **If you did not put in enough money**: It goes straight to the `REFUND` state to give your money back.
3. **`DISPENSE` (State `10`)**: The machine immediately unlocks the tray and drops your selected item. It then moves automatically to the `REFUND` state.
4. **`REFUND` (State `11`)**: The machine checks your balaence one last time. If you overpaid, it drops your change. If you underpaid, it returns all your money. It then clears the balance to zero and goes back to `IDLE` for the next user.

---

## Hardware (Testbench Layout)

* **Test Case 1 (Underpayment)**: Selects a 50-unit item but deposits 30. Verifies the machine routes `ADD_MONEY -> REFUND`, keeping `dispense` locked at `0` while pulsing `return_change = 1`.
* **Test Case 2 (Exact Payment)**: Deposits precisely 25 units for a 25-unit item. Verifies `dispense` flips to `1` instantly inside the `DISPENSE` window and drops back to `0` cleanly during `REFUND` without leakage.
* **Test Case 3 (Overpayment)**: Deposits 100 units for a 75-unit item. Validates dual-pulse behaviors where `dispense` fires during state `10` and `return_change` fires during state `11`.

---


## Execution Instructions

```bash
import os
!git clone https://github.com/Ironwin-15/Vending_Machine.git
!cd Vending_Machine
!pip install -r Vending_Machine/requirements.txt
```

Open:

```text
simulation/Vending_Machine_Sim.ipynb
```

Run all notebook cells.
Ensure the notebook uses:

```python
excel_filename = "../data/vending_items.xlsx"
```

