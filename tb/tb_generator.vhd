library IEEE;
  use IEEE.std_logic_1164.all;
library std;
use std.env.all;
use WORK.performance_type_pkg.all;

entity tb_generator is
end entity tb_generator;

architecture test of tb_generator is

  -- dichiarazione componente
  component packet_generator is
    port (
      clk      : in  std_logic;
      rst      : in  std_logic;
      dt_valid : out std_logic;
      dt_ready : in  std_logic;
      data     : out std_logic_vector(c_data_width-1 downto 0)
    );
  end component;

  --  segnali 
  signal clk      : std_logic := '0';
  signal rst      : std_logic := '0';
  signal dt_valid : std_logic;
  signal dt_ready : std_logic := '0'; -- Parte da 0
  signal data     : std_logic_vector(c_data_width-1 downto 0);

  -- Costante per il periodo del clock 
  constant clk_period : time := 10 ns;

begin

  --  Istanzio i componenti
  UUT : packet_generator
    port map (
      clk      => clk,
      rst      => rst,
      dt_valid => dt_valid,
      dt_ready => dt_ready,
      data     => data
    );

  --  Generatore di Clock automatico
  clk_process : process
  begin
    clk <= '0';
    wait for clk_period/2;
    clk <= '1';
    wait for clk_period/2;
  end process;

  -- stimolo
  stim_process : process
  begin
    rst <= '0';
    wait for 20 ns;
    rst <= '1'; 
    
    wait for 20 ns;
    dt_ready <= '1'; -- Forziamo a 1
    
   
    wait for 100 ns;
    dt_ready <='0'; 
    
    wait for 40 ns;
    dt_ready <= '1';
    wait for 300 ns;
    --assert false report "Simulazione completata con successo!" severity failure;
    report "Simulazione completata con successo!";
    finish;
  end process;
end architecture test;