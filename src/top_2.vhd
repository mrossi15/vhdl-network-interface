

library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;

use WORK.performance_type_pkg.all;

entity top_2 is
PORT (
    clk_p : IN STD_LOGIC;
    clk_n : IN STD_LOGIC;
    reset : IN STD_LOGIC;
    Test_ok_0 :  out std_logic;
    Test_ok_1 :  out std_logic
    );
end top_2;

architecture Behavioral of top_2 is

COMPONENT project
  PORT (
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
END COMPONENT;

COMPONENT packet_generator
  port (
-- clock & reset
    clk:                 in std_logic;
    rst:                 in std_logic;

-- DATA FIFO interface
    dt_valid:            out std_logic;
	dt_ready:            in std_logic;
    data:                out std_logic_vector(c_data_width-1 downto 0)
	);
end COMPONENT;

COMPONENT packet_checker is
PORT (
    clk:                in std_logic;
    rst:                in std_logic;
 
-- DATA FIFO interface
    read:            out std_logic;
	valid:           in std_logic;
    data:            in std_logic_vector(c_data_width-1 downto 0);
    
-- status
    test_ok:          out std_logic
    );
end COMPONENT;

component clk_mng
  PORT (
   clk_out1: OUT STD_LOGIC;
   resetn : IN STD_LOGIC;
   locked: OUT STD_LOGIC;
   clk_in1_p: IN STD_LOGIC;
   clk_in1_n: IN STD_LOGIC
  );
END COMPONENT;

signal clk : STD_LOGIC;

signal din   : STD_LOGIC_VECTOR(31 DOWNTO 0);
signal wr_en : STD_LOGIC;

signal rd_en_0 : STD_LOGIC;
signal dout_0 :  STD_LOGIC_VECTOR(31 DOWNTO 0);
signal not_full :  STD_LOGIC;
signal not_empty_0:  STD_LOGIC; 

signal rd_en_1 : STD_LOGIC;
signal dout_1 :  STD_LOGIC_VECTOR(31 DOWNTO 0);
signal not_empty_1:  STD_LOGIC; 


begin

diff_clk: clk_mng
 PORT MAP (
   clk_out1 => clk,
   resetn => reset,
   locked=> open,
   clk_in1_p => clk_p,
   clk_in1_n => clk_n
  );


Project_inst : Project
  PORT MAP (
    clk => clk,
    reset => reset,
    
    Data_in  => din,
    Valid_in => wr_en,
    ready    => not_full,
    
    Read_0      => rd_en_0,
    Data_out_0  => dout_0,
    Valid_out_0 => not_empty_0,
    
    Read_1      => rd_en_1,
    Data_out_1  => dout_1,
    Valid_out_1 => not_empty_1
  );
  

pg_inst: packet_generator
  port map (
    clk    => clk,
    rst    => reset,

-- DATA FIFO interface : 
    dt_valid => wr_en,
	dt_ready => not_full,
    data     => din
	);

checker_0: packet_checker	
  port  map(
    clk   => clk,
    rst   => reset,
 
-- DATA FIFO interface
    read  => rd_en_0,
	valid => not_empty_0,
    data  => dout_0,
    
-- status
    test_ok => Test_ok_0
	);

checker_1: packet_checker	
  port  map(
    clk   => clk,
    rst   => reset,
 
-- DATA FIFO interface
    read  => rd_en_1,
	valid => not_empty_1,
    data  => dout_1,
    
-- status
    test_ok => Test_ok_1
	);


end Behavioral;
