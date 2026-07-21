library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;

use WORK.performance_type_pkg.all;

entity tb_fifo is
-- I testbench non hanno porte esterne
end entity tb_fifo;

architecture test of tb_fifo is

  
  --DICHIARAZIONE DEI COMPONENTI

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
    port (
      clk   : in  std_logic;
      rst   : in  std_logic;
      wr_en : in  std_logic;
      din   : in  std_logic_vector(g_width-1 downto 0);
      full  : out std_logic;
      rd_en : in  std_logic;
      dout  : out std_logic_vector(g_width-1 downto 0);
      empty : out std_logic
    );
  end component;

  
  -- SEGNALI INTERNI DEL TESTBENCH 
  
  signal clk_tb           : std_logic := '0';
  signal rst_tb           : std_logic := '0'; 
  -- Canale tra Packet Generator e FSM1
  signal connection_valid : std_logic;
  signal connection_ready : std_logic;
  signal connection_data  : std_logic_vector(c_data_width-1 downto 0);
    
  -- Uscite della FSM1 verso la FIFO reale
  signal fifo_full_tb     : std_logic; -- Ora è pilotato dall'uscita "full" della FIFO
  signal fifo_wren_tb     : std_logic;
  signal data_to_fifo     : std_logic_vector(c_data_width-1 downto 0);

  -- Segnali per il lato lettura della FIFO (Interfaccia FSM2 fittizia)
  signal rd_en_tb         : std_logic := '0'; -- Lo controlliamo noi nel processo stimoli
  signal data_from_fifo   : std_logic_vector(c_data_width-1 downto 0);
  signal fifo_empty_tb    : std_logic;

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
      fifo_full => fifo_full_tb,    -- Collegato al "full" della FIFO reale
      fifo_wren => fifo_wren_tb,    -- Collegato al "wr_en" della FIFO reale
      data_out  => data_to_fifo     -- Collegato al "din" della FIFO reale
    );

  fifo_inst : fifo
    generic map (
      g_width => c_data_width,
      g_depth => 8
    )
    port map (
      clk   => clk_tb,
      rst   => rst_tb,
      wr_en => fifo_wren_tb,
      din   => data_to_fifo,
      full  => fifo_full_tb, 
      rd_en => rd_en_tb,
      dout  => data_from_fifo,
      empty => fifo_empty_tb
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
    -- 1. FASE DI RESET 
    rst_tb   <= '0'; 
    rd_en_tb <= '0';
    wait for CLK_PERIOD * 2;
    
    rst_tb   <= '1'; -- Rilasciamo il reset, il sistema parte!
    wait for CLK_PERIOD;

    --  LASCIAMO RIEMPIRE LA FIFO
    -- Il Packet Generator inizierà a sparare pacchetti. 
    -- Dato che rd_en_tb = '0', nessuno sta leggendo dalla FIFO.
    -- Prima o poi la FIFO si riempirà, fifo_full_tb andrà a '1' e la FSM1 bloccherà il generatore.
    
    report "In attesa che la FIFO si riempia da sola...";
    wait until rising_edge(clk_tb) and fifo_full_tb = '1';
    report "La FIFO e' PIENA! La FSM1 dovrebbe aver congelato il flusso (dt_ready='0').";
    
    -- Lasciamo il sistema congelato per qualche ciclo per verificare la stabilità
    wait for CLK_PERIOD * 5;

    -- SVUOTIAMO LA FIFO 
    report "Inizio svuotamento della FIFO...";
    while fifo_empty_tb = '0' loop
      wait until falling_edge(clk_tb);
      rd_en_tb <= '1'; -- Chiediamo un dato alla FIFO
    end loop;
    
    -- Quando la FIFO torna vuota, spegniamo il segnale di lettura
    wait until falling_edge(clk_tb);
    rd_en_tb <= '0';
    report "La FIFO e' di nuovo vuota.";

  
    wait for CLK_PERIOD * 10;

    assert false report "Simulazione integrata completata con successo!" severity failure;
    wait;
  end process;

end architecture test;