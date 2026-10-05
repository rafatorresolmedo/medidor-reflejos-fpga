----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05.11.2025 13:26:40
-- Design Name: 
-- Module Name: contador - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity contador is
    Port (
        Clk     : in  std_logic;
        Reset   : in  std_logic;
        Clear_s : in  std_logic;  --Entrada para puesta a cero sincrono
        Enable  : in  std_logic;
        Q           : out std_logic_vector(3 downto 0);
        Fin_count   : out std_logic --Para cuando llegue a 9 saber que ha desbordado
    );
end contador;

architecture Behavioral of contador is

    signal count : unsigned (3 downto 0);
begin

    process (Clk, Reset)
    begin
        if Reset = '1' then --Reset Asincrono lo dejamos para poder emperzar en cero sin reloj
            count <= (others => '0');

        elsif rising_edge(Clk) then -- Cosas sincronas            
            if Clear_s = '1' then --puesta a cero sincrona
                count <= (others => '0');            
            elsif Enable = '1' then --si enable activo y clear_s no
                if count = 9 then
                    count <= (others => '0');
                else
                    count <= count + 1;
                end if;
            end if;
        end if;
    end process;

    Q <= std_logic_vector (count);
    Fin_count <= '1' 
        when (count = 9) and (Enable = '1') -- sin llegamos a 9 y enable 1 -> Es uno
        else '0'; -- Sino es 0

end Behavioral;
