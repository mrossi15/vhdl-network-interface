-- In questo file sono uniti tutti i componenti del blocco di trasmissione (e serializzazione)
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use WORK.performance_type_pkg.all;

entity tx_block is
port (
    -- Clock e Reset di sistema
    clk       : in  std_logic;
    rst       : in  std_logic; -- attivo basso ('0' = reset)
    
    -- PACKET GENERATOR 
    dt_valid  : in  std_logic; 
    dt_ready  : out std_logic; 
    data_in   : in  std_logic_vector(c_data_width-1 downto 0); 
  
    -- Interfaccia uscita 
    valid_out : out std_logic;
    data_out  : out std_logic
);
end entity tx_block; 

architecture Structural of tx_block is

---componenti:

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
    end component fsm1;

  
    component fifo is
         generic (
    g_width : integer := 32; 
    g_depth : integer := 62  
  );
        port (
    clk   : in  std_logic;
    rst   : in  std_logic; 

    -- Lato Scrittura
    wr_en : in  std_logic;
    din   : in  std_logic_vector(g_width-1 downto 0);
    full  : out std_logic;

    -- Lato Lettura
    rd_en : in  std_logic;
    dout  : out std_logic_vector(g_width-1 downto 0);
    empty : out std_logic
  );

end component fifo;

component fsm2 is
        port (
        clk        : in  std_logic;
        rst        : in  std_logic; 
        fifo_dout  : in  std_logic_vector(c_data_width-1 downto 0);
        fifo_empty : in  std_logic;
        fifo_rd_en : out std_logic;
        valid_out  : out std_logic;
        data_out   : out std_logic
        );
end component fsm2;

   --segnali interni

    -- Connessioni FSM1 -> FIFO
    signal sig_fifo_wren : std_logic;
    signal sig_fifo_din  : std_logic_vector(c_data_width-1 downto 0);
    signal sig_fifo_full : std_logic;

    -- Connessioni FIFO -> FSM2
    signal sig_fifo_rd_en : std_logic;
    signal sig_fifo_dout  : std_logic_vector(c_data_width-1 downto 0);
    signal sig_fifo_empty : std_logic;

begin

    --Istanzia dei componenti
    
    -- Istanza della FSM1 
    U_FSM1: fsm1
        port map (
            clk       => clk,
            rst       => rst,
            dt_valid  => dt_valid,
            dt_ready  => dt_ready,
            data_in   => data_in,
            fifo_full => sig_fifo_full,  -- Collegato alla FIFO interna
            fifo_wren => sig_fifo_wren,  -- Collegato alla FIFO interna
            data_out  => sig_fifo_din    -- Collegato alla FIFO interna
        );

    -- Istanza della FIFO 
    U_FIFO_LOCAL: fifo
        port map (
            clk   => clk,
            rst   => rst,
            din   => sig_fifo_din,
            wr_en => sig_fifo_wren,
            rd_en => sig_fifo_rd_en,
            dout  => sig_fifo_dout,
            full  => sig_fifo_full,
            empty => sig_fifo_empty
        );

    -- Istanza della FSM2 
    U_FSM2: fsm2
        port map (
            clk        => clk,
            rst        => rst,
            fifo_dout  => sig_fifo_dout,
            fifo_empty => sig_fifo_empty,
            fifo_rd_en => sig_fifo_rd_en,
            valid_out  => valid_out,     
            data_out   => data_out       
        );

end architecture Structural;