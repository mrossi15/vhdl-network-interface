----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06/11/2025 11:45:24 AM
-- Design Name: 
-- Module Name: top - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use WORK.performance_type_pkg.all;

entity packet_checker is
PORT (
    clk:                in std_logic;
    rst:                in std_logic;
 
-- DATA FIFO interface
    read:            out std_logic;
	valid:           in std_logic;
    data:            in std_logic_vector(c_data_width-1 downto 0);
    
-- status
    test_ok:                  out std_logic
    );
end packet_checker;

architecture Behavioral of packet_checker is


COMPONENT flusher is	
  port (
-- clock & reset
    clk:                in std_logic;
    rst:                in std_logic;
 
-- DATA FIFO interface
    dt_rden:            out std_logic;
	dt_rdempty:         in std_logic;
    data:               in std_logic_vector(c_data_width-1 downto 0);
    
-- status
    All_data_received:        out std_logic;
    test_ok:                  out std_logic
	);
end COMPONENT;

signal empty : std_logic;

begin


empty <= not (valid);

fl_ins_0: flusher	
  port  map(
-- clock & reset
    clk => clk,
    rst => rst,
 
-- DATA FIFO interface
    dt_rden => read,
	dt_rdempty =>empty,
    data => data,
    
-- status
    All_data_received => open,
    test_ok => test_ok
	);

end Behavioral;
