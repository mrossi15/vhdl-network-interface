-- In questo file sono uniti tutti i componenti del blocco di ricezione (e serializzazione)
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use WORK.performance_type_pkg.all;

entity rx_block is
          generic (
    g_width : integer := 32; 
    g_depth : integer := 62  
  );
port (

    -- Clock e Reset di sistema
    clk       : in  std_logic;
    rst       : in  std_logic; -- attivo basso ('0' = reset)
    --fsm3
    data_in:    in STD_LOGIC;
    valid:      in STD_LOGIC;
    
    --fifo verso esterno
    -- Lato Lettura
    rd_en_1 : in  std_logic;
    rd_en_2 : in  std_logic;
    dout_1  : out std_logic_vector(g_width-1 downto 0);
    dout_2  : out std_logic_vector(g_width-1 downto 0);

    empty_1 : out std_logic;
    empty_2 : out std_logic
);
end entity rx_block; 

architecture Structural of rx_block is

---componenti:

    component fsm3 is
      port(
    clk : in STD_LOGIC;
    rst : in STD_LOGIC;

    data_in:    in STD_LOGIC;
    valid:      in STD_LOGIC;
    fifo_full1: in STD_LOGIC;
    fifo_full2: in STD_LOGIC;
    data_out:   out STD_LOGIC_VECTOR(c_data_width-1 downto 0);     
    fifo_wren1: out STD_LOGIC;
    fifo_wren2: out STD_LOGIC
    );
    end component fsm3;

  
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


   --segnali interni

    -- Connessioni FSM3 -> FIFO
    signal sig_fifo_wren_1 : std_logic;
    signal sig_fifo_wren_2 : std_logic;

    signal sig_fifo_din  : std_logic_vector(c_data_width-1 downto 0);
    signal sig_fifo_full_1 : std_logic;
    signal sig_fifo_full_2 : std_logic;



begin

    --Istanzia dei componenti
    
    -- Istanza della FSM3
    U_FSM3: fsm3
        port map (
            clk       => clk,
            rst       => rst,
            data_in   => data_in,
            valid     =>  valid,
            fifo_full1 => sig_fifo_full_1,
            fifo_full2 => sig_fifo_full_2,
            data_out =>  sig_fifo_din,    
            fifo_wren1 => sig_fifo_wren_1,
            fifo_wren2 => sig_fifo_wren_2
        );

    -- Istanza della FIFO1
    U_FIFO_LOCAL_1: fifo
        port map (
            clk   => clk,
            rst   => rst,
            din   => sig_fifo_din,
            wr_en => sig_fifo_wren_1,
            rd_en => rd_en_1,
            dout  => dout_1,
            full  => sig_fifo_full_1,
            empty => empty_1
        );
 U_FIFO_LOCAL_2: fifo
  
     port map (
            clk   => clk,
            rst   => rst,
            din   => sig_fifo_din,
            wr_en => sig_fifo_wren_2,
            rd_en => rd_en_2,
            dout  => dout_2,
            full  => sig_fifo_full_2,
            empty => empty_2
     );
end architecture Structural;