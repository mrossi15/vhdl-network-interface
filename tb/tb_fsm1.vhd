library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;
library std;
use std.env.all;
use WORK.performance_type_pkg.all;

entity tb_fsm1 is
-- I testbench non hanno porte esterne
end entity tb_fsm1;

architecture test of tb_fsm1 is

  
  -- DICHIARAZIONE DEI COMPONENTI
  
  component packet_generator is 
    port (
      clk      : in  std_logic;
      rst      : in  std_logic;
      dt_valid : out std_logic;
      dt_ready : in  std_logic;
      data     : out std_logic_vector(c_data_width-1 downto 0)
    );
  end component;

  component fsm1 is
    port (
      clk       : in  std_logic;
      rst       : in  std_logic;
      dt_valid  : in  std_logic;
      dt_ready  : out std_logic;
      data_in   : in  std_logic_vector(c_data_width-1 downto 0);
      fifo_full : in  std_logic;
      fifo_wren : out std_logic;
      data_out  : out std_logic_vector(c_data_width-1 downto 0)
    );
  end component;

  
  -- SEGNALI INTERNI DEL TESTBENCH 
  signal clk_tb           : std_logic := '0';
  signal rst_tb           : std_logic := '0'; -- reset globale attivo basso
    
  -- Canale tra Packet Generator e FSM1
  signal connection_valid : std_logic;
  signal connection_ready : std_logic;
  signal connection_data  : std_logic_vector(c_data_width-1 downto 0);
    
  -- Uscite della FSM1 verso la FIFO 
  signal fifo_full_tb     : std_logic := '0'; 
  signal fifo_wren_tb     : std_logic;
  signal data_to_fifo     : std_logic_vector(c_data_width-1 downto 0);

  -- Costante di tempo per il clock
  constant CLK_PERIOD     : time := 10 ns;

begin 

  
  -- ISTANZIAZIONE E COLLEGAMENTO DEI BLOCCHI (PORT MAP)
  
  pck_gen_inst : packet_generator
    port map (
      clk      => clk_tb,
      rst      => rst_tb,           
      dt_valid => connection_valid, 
      dt_ready => connection_ready, 
      data     => connection_data   
    );

  fsm1_inst : fsm1                 
    port map (
      clk       => clk_tb,
      rst       => rst_tb,          
      dt_valid  => connection_valid,
      dt_ready  => connection_ready,
      data_in   => connection_data,
      fifo_full => fifo_full_tb,    
      fifo_wren => fifo_wren_tb,
      data_out  => data_to_fifo
    );

  
  -- GENERAZIONE DEL CLOCK
  
  clk_process : process
  begin
    clk_tb <= '0';
    wait for CLK_PERIOD/2;
    clk_tb <= '1';
    wait for CLK_PERIOD/2;
  end process clk_process;

  
  -- PROCESSO STIMOLI 
  
  stim_process : process
  begin
   
    rst_tb <= '1'; 
    
    wait for 100 ns;
    fifo_full_tb <= '1'; -- Forziamo a 1
    
    wait for 100 ns;
    fifo_full_tb<='0'; 
    
    wait for 40 ns;
    fifo_full_tb <= '1';
    wait for 300 ns;
    --assert false report "Simulazione completata con successo!" severity failure;
     report "Simulazione completata con successo!";
    finish;
  end process;


end architecture test; 