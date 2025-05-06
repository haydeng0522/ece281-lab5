----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/18/2025 02:42:49 PM
-- Design Name: 
-- Module Name: controller_fsm - FSM
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity controller_fsm is
    Port ( i_reset : in STD_LOGIC;
           i_adv : in STD_LOGIC;
           o_cycle : out STD_LOGIC_VECTOR (3 downto 0));
end controller_fsm;

architecture FSM of controller_fsm is

	type sm_display is (blank, loadA, loadB, result);
	
	signal current_display, next_display: sm_display;

begin

    next_display <= current_display when i_adv = '0' else 
                    loadA when (current_display = blank) else
                    loadB when (current_display = loadA) else
                    result when (current_display = loadB) else
                    blank;                    

    with current_display select
    o_cycle <= x"1" when blank,
               x"2" when loadA,
               x"4" when loadB,
               x"8" when result,
               x"0" when others;
               
	state_register : process(i_reset)
	begin
	   if i_reset = '1' then
	       current_display <= blank;
	   else
            if i_adv = '1' then
                current_display <= next_display;
            end if;
      end if;
	end process state_register; 

end FSM;
