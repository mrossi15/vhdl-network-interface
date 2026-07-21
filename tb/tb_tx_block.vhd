library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;

use WORK.performance_type_pkg.all;

entity tb_tx_block is
-- I testbench non hanno porte esterne
end entity tb_tx_block;

architecture test of tb_tx_block is


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

  component tx_block is
    port (
    -- Clock e Reset di sistema
    clk       : in  std_logic;
    rst       : in  std_logic; -- attivo basso ('0' = reset)
    
    -- PACKET GENERATOR (Ingresso parallelo)
    dt_valid  : in  std_logic; 
    dt_ready  : out std_logic; 
    data_in   : in  std_logic_vector(c_data_width-1 downto 0); 
  
    -- Interfaccia uscita (Uscita seriale verso il canale o FSM3)
    valid_out : out std_logic;
    data_out  : out std_logic
);
  end component;

   signal clk_tb           : std_logic := '0';
   signal rst_tb           : std_logic := '0';
   signal connection_valid : std_logic;
   signal connection_ready : std_logic;
   signal connection_data  : std_logic_vector(c_data_width-1 downto 0);

  constant CLK_PERIOD     : time := 10 ns;

  begin
   --port map
    pck_gen_inst : packet_generator
    port map (
      clk      => clk_tb,
      rst      => rst_tb,           
      dt_valid => connection_valid, 
      dt_ready => connection_ready, 
      data     => connection_data   
    );
  rx_block_inst : tx_block
  port map(
    
    clk       => clk_tb,
    rst       => rst_tb,
    dt_valid  => connection_valid,
    dt_ready  => connection_ready,
    data_in   => connection_data
      
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
  
-- PROCESSO STIMOLI 
  stim_process : process
  begin
    rst_tb   <= '0'; 
    wait for CLK_PERIOD * 2;
    rst_tb   <= '1'; -- Rilasciamo il reset, il sistema parte!
    wait for 2500 ns;
    
   
    assert false report "Simulazione completata con successo!" severity note;
    
    std.env.finish; 
    
    wait;
  end process;
    end architecture test;