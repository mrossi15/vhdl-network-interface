library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;
library std;
use std.env.all;
use WORK.performance_type_pkg.all;

entity tb_fsm2 is
-- I testbench non hanno porte esterne
end entity tb_fsm2;

architecture test of tb_fsm2 is


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
 component fifo is 
     generic (
      g_width : integer := 32;
      g_depth : integer := 16
    );
    port(
    clk   : in  std_logic;
    rst   : in  std_logic; -- attivo basso ('0' = reset)

    -- Lato Scrittura (Gestito da FSM 1)
    wr_en : in  std_logic;
    din   : in  std_logic_vector(g_width-1 downto 0);
    full  : out std_logic;

    -- Lato Lettura (Gestito da FSM 2)
    rd_en : in  std_logic;
    dout  : out std_logic_vector(g_width-1 downto 0);
    empty : out std_logic
  );
    end component;
component fsm2 is
  port (
    -- Clock e Reset di sistema
    clk         : in  std_logic;
    rst         : in  std_logic; -- attivo basso ('0' = reset) come FSM1
    
    -- Interfaccia verso la FIFO 
    fifo_dout   : in  std_logic_vector(c_data_width-1 downto 0);
    fifo_empty  : in  std_logic;
    fifo_rd_en  : out std_logic;
    
    -- Interfaccia seriale in uscita
    valid_out   : out std_logic;
    data_out    : out std_logic
  );
end component;
  
  -- SEGNALI INTERNI DEL TESTBENCH 
  
  signal clk_tb           : std_logic := '0';
  signal rst_tb           : std_logic := '0'; -- reset globale attivo basso
    
  -- Canale tra Packet Generator e FSM1
  signal connection_valid : std_logic;
  signal connection_ready : std_logic;
  signal connection_data  : std_logic_vector(c_data_width-1 downto 0);
 --Canale tra FSM1 e FIFO
  signal fifo_full    : std_logic ; 
  signal fifo_wren     : std_logic;
  signal data_to_fifo     : std_logic_vector(c_data_width-1 downto 0);
--Canale tra FIFO e FSM2
  signal fifo_empty : std_logic;
  signal rd_enable: std_logic;
  signal data_to_fsm2 :  std_logic_vector(c_data_width-1 downto 0);
--Canale tra FSM2 e FSM3
 signal data_serialize: std_logic;
 signal valid_serialize: std_logic;
  -- Costante di tempo per il clock
  constant CLK_PERIOD     : time := 10 ns;

begin 

  
  -- PORT MAP
  
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
      fifo_full => fifo_full,    
      fifo_wren => fifo_wren,
      data_out  => data_to_fifo
    );
fifo_inst : fifo
    generic map (
      g_width => c_data_width,
      g_depth => 8
    )
    port map (
      clk   => clk_tb,
      rst   => rst_tb,
      wr_en => fifo_wren,
      din   => data_to_fifo,
      full  => fifo_full, 
      rd_en => rd_enable,
      dout  => data_to_fsm2,
      empty => fifo_empty
    );
 fsm2_inst : fsm2
  port map(
    
    clk       => clk_tb,
    rst       => rst_tb,
    fifo_dout    => data_to_fsm2,
    fifo_empty  => fifo_empty,
    fifo_rd_en => rd_enable,
    valid_out  =>valid_serialize,
    data_out   => data_serialize
  );

  
  -- GENERAZIONE DEL CLOCK
 
  clk_process : process
  begin
    clk_tb <= '0';
    wait for CLK_PERIOD/2;
    clk_tb <= '1';
    wait for CLK_PERIOD/2;
  end process clk_process;

  
  -- PROCESSO STIMOLI (GESTIONE RESET E FIFO)
  
  stim_process : process
  begin
    rst_tb   <= '0'; 
    
    wait for CLK_PERIOD * 2;
    
    rst_tb   <= '1'; -- Rilasciamo il reset, il sistema parte!
    wait for 2500 ns;
    --assert false report "Simulazione completata con successo!" severity failure;
    --wait;
    report "Simulazione completata con successo!";
        finish; -- Ferma la simulazione in modo pulito (Exit code 0)
    end process;

end architecture test; 