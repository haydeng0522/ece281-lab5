----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/18/2025 02:50:18 PM
-- Design Name: 
-- Module Name: ALU - Behavioral
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
use ieee.NUMERIC_STD.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ALU is
    Port ( i_A : in STD_LOGIC_VECTOR (7 downto 0);
           i_B : in STD_LOGIC_VECTOR (7 downto 0);
           i_op : in STD_LOGIC_VECTOR (2 downto 0);
           o_result : out STD_LOGIC_VECTOR (7 downto 0);
           o_flags : out STD_LOGIC_VECTOR (3 downto 0));
end ALU;

architecture Behavioral of ALU is

signal result : std_logic_vector(7 downto 0);
signal carry_result : std_logic_vector(8 downto 0); -- one bit greater to check for carry flag

begin
    
     process(i_A, i_B, i_op)
    begin
        case(i_op) is
        when "000" => result <= std_logic_vector(signed(i_A) + signed(i_B));
        when "001" => result <= std_logic_vector(signed(i_A) - signed(i_B));
        when "010" => result <= i_A and i_B;
        when others => result <= i_A or i_B;
        end case;
     end process;
  
    
    with i_op select
    carry_result <= std_logic_vector(('0' & signed(i_A)) + ('0' & signed(i_B))) when "000",
                    std_logic_vector(('0' & unsigned(i_A)) + ('0' & (not(unsigned(i_B)) + 1))) when others; 
    
    
    o_result <= result;
    o_flags(0) <= '0' when i_A(7) = result(7) else
                  '1' when i_op = "000" and i_A(7) = i_B(7) else
                  '1' when i_op = "001" and i_A(7) = not(i_B(7)) else
                  '0'; 
    o_flags(1) <= carry_result(8) when (i_op = "000" or i_op = "001") else
                  '0';
    o_flags(2) <= '1' when result = "00000000" else
                  '0';
    o_flags(3) <= result(7);
    
end Behavioral;
