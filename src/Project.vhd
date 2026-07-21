library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use WORK.performance_type_pkg.all;

entity project is 
    port (
           
    clk   : IN STD_LOGIC;
    reset : IN STD_LOGIC;
    
    Data_in : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    Valid_in : IN STD_LOGIC;
    ready : OUT STD_LOGIC;
    
    Read_0 : IN STD_LOGIC;
    Data_out_0 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    Valid_out_0 : OUT STD_LOGIC;
    
    Read_1 : IN STD_LOGIC;
    Data_out_1 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    Valid_out_1 : OUT STD_LOGIC 
        
    );
end entity project;

architecture Structural of project is
component tx_block is
    port(
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
    end component tx_block;
    component rx_block is
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
end component rx_block;
  --segnali interni 

   

    -- Interconnessioni: RX Block -> TX Block 
    signal serial_valid : std_logic;
    signal serial_data  : std_logic;

   -- Segnali interni per i flag empty
    signal empty_1_sig  : std_logic;
    signal empty_2_sig  : std_logic;

begin
tx_block_inst: tx_block
 port map(
    clk => clk,
    rst => reset,
    dt_valid => Valid_in,
    dt_ready => ready,
    data_in => data_in,
    valid_out => serial_valid,
    data_out => serial_data
);
rx_block_inst: rx_block

 port map(
    clk => clk,
    rst => reset,
    data_in => serial_data,
    valid => serial_valid,
    rd_en_1 => Read_0,
    rd_en_2 => Read_1,
    dout_1 => Data_out_0,
    dout_2 => Data_out_1,
    empty_1 => empty_1_sig,
    empty_2 => empty_2_sig
);
-- Logica per convertire Empty in Valid per il modulo a valle
    Valid_out_0 <= not empty_1_sig;
    Valid_out_1 <= not empty_2_sig;
end architecture;

