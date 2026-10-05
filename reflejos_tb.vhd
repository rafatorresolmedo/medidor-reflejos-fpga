----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 13.11.2025 19:37:16
-- Design Name: 
-- Module Name: milisegundos_tb - Behavioral
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

entity reflejos_tb is
--  Port ( );
end reflejos_tb;

architecture behavior OF reflejos_tb IS 

    -- Declaración del componente (Debe ser la entidad 'reflejos')
    component reflejos
    port(
         Reset   : in  std_logic;
         Clk     : in  std_logic;
         Enable  : in  std_logic;
         seg     : out std_logic_vector(6 downto 0);
         an      : out std_logic_vector(3 downto 0)
        );
    end component;

    -- Señales para conectar al componente
    signal Reset   : std_logic := '0';
    signal Clk     : std_logic := '0';
    signal Enable  : std_logic := '0';

    -- Salidas observadas
    signal seg     : std_logic_vector(6 downto 0);
    signal an      : std_logic_vector(3 downto 0);

    -- Constante de periodo de reloj (100MHz -> 10ns)
    constant Clk_period : time := 10 ns;
 
begin

    -- Instanciación de la Unidad Bajo Prueba (UUT)
    uut: reflejos
        port map (
            Reset   => Reset,
            Clk     => Clk,
            Enable  => Enable,
            seg     => seg,
            an      => an
        );

    -- Proceso generador de Reloj
    Clk_process : process
    begin
        Clk <= '0';
        wait for Clk_period/2;
        Clk <= '1';
        wait for Clk_period/2;
    end process;

    -- Proceso de Estímulos (Simulación del juego)
    stim_proc: process
    begin        
        -- 1. Estado Inicial y Reset
        -- Mantenemos el Reset activo un momento para limpiar el sistema
        Reset  <= '1';
        Enable <= '0';
        wait for 100 ns;

        Reset  <= '0';
        wait for 100 ns;
        
        --simulamos que pulsamos el boton
        Enable <= '1';
        wait for 50 ns; 
        Enable <= '0'; -- lo dejamos de pulsar
        
        wait for 300 ms; --

        Enable <= '1';
        wait for 50 ns;
        Enable <= '0';

        wait for 100 us;

        wait;
    end process;

end behavior;


