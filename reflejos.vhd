----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10.12.2025 23:12:40
-- Design Name: 
-- Module Name: reflejos - Behavioral
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

entity reflejos is
    Port (
        Reset   : in  std_logic;
        Clk     : in  std_logic; 
        Enable  : in  std_logic; 
        seg     : out std_logic_vector(6 downto 0); -- Low level active
        an      : out std_logic_vector(3 downto 0)  -- Low level active
    );
end reflejos;

architecture Behavioral of reflejos is

--Declaracion del contador, lo vamos a hacer 4 veces y le hemos añadido el reset sincrono
    component contador is
        Port (
            Clk       : in  std_logic;
            Reset     : in  std_logic;
            Clear_s   : in  std_logic; --nuevo de contador para que sea sincrono tambien 
            Enable    : in  std_logic;
            Q         : out std_logic_vector(3 downto 0);
            Fin_count : out std_logic
        );
    end component;

--Señales para la maquina de estado (Tipo Moore)
    type t_estado is (Espera, Inicializa, Aleatorio, Cuenta);
    signal estado_actual, estado_siguiente : t_estado;

--Señales de control para la maquina de estados de moore
    signal reset_contadores     : std_logic; -- Poner contadores a 0
    signal habilitar_cuenta     : std_logic; -- Habilitar cuenta de tiempo
    signal cargar_t_aleatorio   : std_logic; -- Cargar tiempo aleatorio
    signal cuenta_atras_moore   : std_logic; -- Decrementar tiempo aleatorio en  la maquina de moore

--Señales para detectar cuando los flacos cambian 
    signal enable_anterior  : std_logic; --Valor del enable anterio para luego detectar el flanco
    signal flanco_detectado : std_logic; -- Pulso único cuando se aprieta el botón

-- 4. SEÑALES PARA GENERACIÓN DE TIEMPO ALEATORIO
    signal contador_aleatorio   : natural range 0 to 1000 := 0; -- COntador aleatorio va de 0 a 1000 porque no puede ser mas de 1s
    signal cuenta_atras         : natural range 0 to 1000 := 0; -- cuenta atras desde el numero aleatorio que como maximo es 1s hasta 0
    signal fin_cuenta_atras     : std_logic; -- Indica que el tiempo aleatorio terminó

--Señales para el generar pulsos -- Contador para el timer
    signal temp_count : natural range 0 to 99999; -- Contador para el timer (100.000)
    signal pulso_1ms  : std_logic; -- Pulso de 1ms
    signal temp_mux   : natural range 0 to 9; -- Contador para el multiplexor (10 es decri cada 10ms)
    signal pulso_10ms : std_logic; -- Pulso de 10ms

--Señales para los contadores
    signal unidades_milisegundos    : std_logic_vector(3 downto 0); -- milisegundos
    signal decenas_milisegundos     : std_logic_vector(3 downto 0); -- 10 milisegundos
    signal centenas_milisegundos    : std_logic_vector(3 downto 0); -- 100 milisegundos
    signal segundos                 : std_logic_vector(3 downto 0); -- Segundos

    signal fin_milisegundos          : std_logic;
    signal fin_decenas_milisegundos  : std_logic;
    signal fin_centenas_milisegundos : std_logic;

--Señales para el Multiplexor de Displays (Visulizacion)
    signal selector_mux : std_logic_vector(1 downto 0); -- selector del multiplexor
    signal valor_mux    : std_logic_vector(3 downto 0); -- valor que mostrara el display
    
-- Señal para habilitar el primer contador
    signal enable_unidades : std_logic; --Activador de unidades
    signal enable_decenas  : std_logic; --Activador de decenas
    signal enable_centenas : std_logic; --Activador de centenas
    signal enable_segundos : std_logic; --Activador de segundos
    

begin

-- Detecta la transición de 0 a 1 en el botón Enable
    process (Reset, Clk)
    begin
      if Reset ='1' then
        enable_anterior <= '0';
      elsif rising_edge(Clk) then
        enable_anterior <= Enable;
      end if;
    end process;
 -- El pulso se activa solo un ciclo cuando Enable está en 1 y antes estaba en 0 
    flanco_detectado <= '1' when (Enable = '1' and enable_anterior = '0') else '0'; -- Justo cuado cambia de 0 a 1

    
-- Generador de tiempo aleatrio, suma siempre cada 1ms desde 0ms hasta 1s y veulve a empezar
    process (Reset, Clk)
    begin
      if Reset = '1' then
         contador_aleatorio <= 0;
      elsif rising_edge(Clk) then            
         if pulso_1ms = '1' then
           if contador_aleatorio = 999 then 
              contador_aleatorio <= 0;
           else
             contador_aleatorio <= contador_aleatorio + 1;
           end if;
        end if;
      end if;
    end process;

-- Cuenta atras para medir los reflejos
    process (Reset, Clk)
    begin
      if Reset = '1' then
        cuenta_atras <= 0;
      elsif rising_edge(Clk) then
        if cargar_t_aleatorio = '1' then --Cuando cargar_t_aleatrio es 1 cuenta atras es contador_aleatorio lo cargamos ahi
          cuenta_atras <= contador_aleatorio; 
        elsif pulso_1ms = '1' AND cuenta_atras_moore = '1' then --Cuando cuenta_atras_moore y pasa un 1ms empieza la cuenta atras
                if cuenta_atras > 0 then
                    cuenta_atras <= cuenta_atras - 1;
                end if;
            end if;
        end if;
    end process;
    
    fin_cuenta_atras <= '1' when (cuenta_atras = 0) else '0';


--Maquina de estados Moore
    process (Clk, Reset)
    begin
        if Reset = '1' then
            estado_actual <= Espera;
        elsif rising_edge(Clk) then
            estado_actual <= estado_siguiente;
        end if;
    end process;


    process (estado_actual, flanco_detectado, fin_cuenta_atras)
    begin
        -- POnemos todo a cero paraa que no haya errores
        estado_siguiente    <= estado_actual;
        reset_contadores    <= '0';
        habilitar_cuenta    <= '0';
        cargar_t_aleatorio  <= '0';
        cuenta_atras_moore  <= '0';

        case estado_actual is
            
           
            when Espera =>  -- Espera: al empezar esta en 0000 y despues de una medida muestra el numero anterior
                if flanco_detectado = '1' then -- Si se pulsa el botón pasamos al siguiente estado
                    estado_siguiente <= Inicializa; --Estmaos siempre en espera hasta que detectamos un flaco (Pulsamos el boton)
                end if;

            
            when Inicializa => -- Inicializa: pone el display a 0000 y carga el tiempo aleatorio que vamos a esperar
                reset_contadores <= '1'; -- Pone a 0000 el display
                cargar_t_aleatorio     <= '1'; -- Cargamos el tiempo aleatorio que vamos a esperar
                estado_siguiente   <= Aleatorio; -- Cambia siempre

            
            when Aleatorio => -- Aleatorio: esperamos a que pase el tiempo aleatrio
                cuenta_atras_moore <= '1'; -- Habilitamos la cuenta atrás del delay
                if fin_cuenta_atras = '1' then
                    estado_siguiente <= Cuenta; -- Cuando se acaba el tiempo de espera pasamos a cuenta
                end if;

            
            when Cuenta => -- Cuenta: esperamos a que pulsemos el boton mientras avanza la cuenta 
                habilitar_cuenta <= '1'; -- empieza a contar el teimp que tardamos en reaccionar
                if flanco_detectado = '1' then --Cuando pulsamos se deja de contar y pasamos a espera 
                    estado_siguiente <= Espera; -- Volvemos a esperar y esta en el display el tiempo q hemos tardado en reaccionar
                end if;

        end case;
    end process;


-- Generador de tick de 1ms
    process (Clk, Reset)
    begin
        if Reset = '1' then
            temp_count <= 0;
        elsif rising_edge(Clk) then
            if temp_count = 99999 then -- 100MHz / 100,000 = 1kHz (1ms)
                temp_count <= 0;
            else
                temp_count <= temp_count + 1;
            end if;
        end if;
    end process;
    pulso_1ms <= '1' when temp_count = 99999 else '0';
    
-- Generador de tick de 10ms (para mostrar los digitos 100 veces por segundo, usando el generador de ticks de 1ms)
    process (Clk, Reset)
    begin
        if Reset = '1' then
            temp_mux <= 0;
        elsif rising_edge(Clk) then
            if pulso_1ms = '1' then -- Solo avanza con el tick de 1ms
                if temp_mux = 9 then 
                    temp_mux <= 0;
                else 
                    temp_mux <= temp_mux + 1;
                end if;
            end if;
        end if;
    end process;
    pulso_10ms <= '1' when (temp_mux = 9 and pulso_1ms = '1') else '0'; -- Genera el pulso de 10ms


    
 -- Contadores de tiempo, los mapeamos (Los habilita el fin del temporizador anterior)
    --count_avanza <= Enable and pulso_1ms; --Avanza el temporizador cuando esta pulsado el boton y haya un pulso, cuando paramos de pulsar -> nos da el numero del 0-9   
    --Ahora depende de que estemos en el estado cuenta
    
    enable_unidades <= habilitar_cuenta and pulso_1ms;
    enable_decenas  <= fin_milisegundos;       -- Cuando termina los milisegundos empeinzan las decenas
    enable_centenas <= fin_decenas_milisegundos; -- Cuando termina las decenas empeinzan las centenas
    enable_segundos <= fin_centenas_milisegundos; -- Cuando termina los centenas empeinzan los segundos

    TEMP_MILISEGUNDOS: contador
        port map (
            Clk       => Clk,
            Reset     => Reset,    -- Reset global asíncrono
            Clear_s   => reset_contadores, -- Puesta a cero controlada por FSM
            Enable    => enable_unidades,
            Q         => unidades_milisegundos,
            Fin_count => fin_milisegundos
        );

    TEMP_DECENAS_MILISEGUNDOS: contador
        port map (
            Clk       => Clk,
            Reset     => Reset,
            Clear_s   => reset_contadores,
            Enable    => enable_decenas,
            Q         => decenas_milisegundos,
            Fin_count => fin_decenas_milisegundos
        );

    TEMP_CENTENAS_MILISEGUNDOS: contador
        port map (
            Clk       => Clk,
            Reset     => Reset,
            Clear_s   => reset_contadores,
            Enable    => enable_centenas,
            Q         => centenas_milisegundos,
            Fin_count => fin_centenas_milisegundos
        );

    TEMP_SEGUNDOS: contador
        port map (
            Clk       => Clk,
            Reset     => Reset,
            Clear_s   => reset_contadores,
            Enable    => enable_segundos,
            Q         => segundos,
            Fin_count => open --no tiene fin
        );


--Secuencia de 00,01,10,11 con el pulso cada 10ms
    process (Clk, Reset)
    begin
        if Reset = '1' then
            selector_mux <= "00";
        elsif rising_edge(Clk) then
            if pulso_10ms = '1' then -- Cambia cada 10ms con el pulso que habiamos creado
                if selector_mux = "11" then --Si llegamos a la deercha del todo volvemos a la izquierda
                    selector_mux <= "00";
                else
                    selector_mux <= std_logic_vector(unsigned(selector_mux) + 1); --Le vamos sumando uno cada 10ms
                end if;
            end if;
        end if;
    end process;
    
   
--Multiplexor 
    process (selector_mux, unidades_milisegundos, decenas_milisegundos, centenas_milisegundos, segundos)
    begin
        case selector_mux is 
            when "00" => 
                valor_mux <= unidades_milisegundos; -- Colocamos en la dereecha los milisegundos
                an        <= "1110";
            when "01" => 
                valor_mux <= decenas_milisegundos; -- Colocamos en la dereecha las decenas de milisegundos
                an        <= "1101";
            when "10" => 
                valor_mux <= centenas_milisegundos; -- Colocamos en la dereecha las centenas de milisegundos
                an        <= "1011";
            when others => 
                valor_mux <= segundos; -- Colocamos en la izquierda los segundos
                an        <= "0111";
        end case;   
    end process;


-- Decodificador, segun el valor_mux se encendaran los segmentos haciendo el numero
    process (valor_mux)
    begin
        case valor_mux is       -- gfedcba  
            when "0000" => seg <= "0000001"; -- 0
            when "0001" => seg <= "1001111"; -- 1
            when "0010" => seg <= "0010010"; -- 2
            when "0011" => seg <= "0000110"; -- 3
            when "0100" => seg <= "1001100"; -- 4
            when "0101" => seg <= "0100100"; -- 5
            when "0110" => seg <= "0100000"; -- 6
            when "0111" => seg <= "0001111"; -- 7
            when "1000" => seg <= "0000000"; -- 8
            when "1001" => seg <= "0001100"; -- 9
            when others => seg <= "1111111"; -- Apagado
        end case;
    end process;
    
end Behavioral;


