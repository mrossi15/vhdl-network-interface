library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library std;
use std.env.all;
entity tb_top_2 is
-- Un testbench non ha porte in ingresso o in uscita
end tb_top_2;

architecture Behavioral of tb_top_2 is

    -- Dichiarazione dei componenti
    COMPONENT top_2
    PORT(
         clk_p     : IN  std_logic;
         clk_n     : IN  std_logic;
         reset     : IN  std_logic;
         Test_ok_0 : OUT std_logic;
         Test_ok_1 : OUT std_logic
        );
    END COMPONENT;

    -- Segnali interni per collegarsi al top_2
    signal clk_p_sig     : std_logic := '0';
    signal clk_n_sig     : std_logic := '1';
    signal reset_sig     : std_logic := '0';
    
    -- Uscite dal top_2
    signal Test_ok_0_sig : std_logic;
    signal Test_ok_1_sig : std_logic;

    -- Definizione del periodo di clock (es. 10 ns per 100 MHz)
    constant clk_period : time := 10 ns;

begin

    -- Istanza del modulo principale 
    DUT: top_2 PORT MAP (
          clk_p     => clk_p_sig,
          clk_n     => clk_n_sig,
          reset     => reset_sig,
          Test_ok_0 => Test_ok_0_sig,
          Test_ok_1 => Test_ok_1_sig
        );

    -- Processo per la generazione del Clock Differenziale
    clk_process :process
    begin
        clk_p_sig <= '0';
        clk_n_sig <= '1';
        wait for clk_period/2;
        
        clk_p_sig <= '1';
        clk_n_sig <= '0';
        wait for clk_period/2;
    end process;

    -- Processo per lo Stimolo iniziale (Reset)
    stim_proc: process
    begin		
        -- Inizializza il sistema tenendo il reset a '0'
        reset_sig <= '0';
        
        -- Attendi qualche ciclo di clock
        wait for clk_period * 10;
        
        -- Rilascia il reset per far partire il packet_generator
        reset_sig <= '1';

        -- A questo punto il sistema viaggia da solo.
        -- Il simulatore continuerà a girare all'infinito o finché 
        -- non lo fermi manualmente.
        wait for 500 us;
           report "Simulazione completata con successo!";
          finish;
    end process;

end Behavioral;