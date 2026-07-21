------------------------------------------------------------------------
------------------------------------------------------------------------
-- THIS FILE IS PART OF THE APElink (I/O interface) firmware      -----
-- VHDL MODEL - COPYRIGHT (C), 2007, 2008, INFN , APE GROUP      -----
--                                                                 -----
--  This program is free software; you can redistribute it and/or  -----
--  modify it under the terms of the GNU General Public License    -----
--  as published by the Free Software Foundation; either version 2 -----
--  of the License, or (at your option) any later version.         -----
--                                                                 -----
--  This program is distributed in the hope that it will be useful,-----
--  but WITHOUT ANY WARRANTY; without even the implied warranty of -----
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the  -----
--  GNU General Public License for more details.                   -----
--                                                                 -----
--  You should have received a copy of the GNU General Public      -----
--  License along with this core; if not, write to the Free        -----
--  Software Foundation, Inc., 59 Temple Place - Suite 330,        -----
--  Boston, MA  02111-1307, USA.                                   -----
------------------------------------------------------------------------
------------------------------------------------------------------------

library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;

use WORK.performance_type_pkg.all;

-- ONLY FOR TEST 
use std.textio.all;

entity packet_generator is
  port (
    -- clock & reset
    clk:                 in std_logic;
    rst:                 in std_logic;

    -- DATA FIFO interface
    dt_valid:            out std_logic;
    dt_ready:            in std_logic;
    data:                out std_logic_vector(c_data_width-1 downto 0)
  );
end packet_generator;
  
architecture RTL of packet_generator is

  type STATE_MACHINE is (OFF, IDLE, TX_HEADER, TX_PAYLOAD, WAIT_state_data);
  signal SM_STATE: STATE_MACHINE;

  signal header_reg : std_logic_vector(c_data_width-1 downto 0):= (others=>'0');

  signal destination_counter : integer range 0 to c_number_of_destination;
  signal destination_reg : std_logic_vector(c_hdr_dest_fifo_high downto c_hdr_dest_fifo_low);  

  signal length_counter : integer range 0 to c_number_of_destination;
  signal length_reg : std_logic_vector(c_length_high downto c_length_low);

  signal packet_end: std_logic;  

  signal len, data_int, pkt_cnt, number_of_destination : integer;
  signal w_hd_wren, w_dt_wren: std_logic;
  signal wire_data: std_logic_vector(c_data_width-1 downto 0);

  signal first : std_logic:= '1';
  constant c_sender_string  : string := " *** TEST: ";
  constant c_numb_string    : string := " *** TEST number of packet "; 
  constant c_len_string     : string := " *** TEST packet's len ( in words): ";
  constant c_dest_string    : string := " *** TEST destination FIFO: "; 

  signal wait_cnt : integer;
  signal end_transmission : STD_LOGIC;

begin

  -- FSM Process: Convertito il reset in completamente sincrono/asincrono solo su rst globale
  process(clk, rst)
  begin
    if rst = '0' then
      SM_STATE   <= OFF;
      packet_end <= '0';
      wait_cnt   <= 0; 
    elsif (clk'event and clk = '1') then 
      
      -- Gestione del reset software derivato da end_transmission in modo sincrono
      if c_constant_destination_enable = '0' and end_transmission = '1' then
        SM_STATE <= OFF;
      else
        case SM_STATE is
      
          when OFF => 
            SM_STATE <= IDLE;

          when IDLE =>
            packet_end <= '0';
            if pkt_cnt /= 0 then
              SM_STATE <= TX_HEADER;
            else      
              SM_STATE <= IDLE;
            end if;
       
          when TX_HEADER => 
            if w_hd_wren = '1' then
              if len = 0 then
                SM_STATE <= IDLE;
              else
                if c_wait_data = 0 then 
                  SM_STATE <= TX_PAYLOAD;
                else  
                  SM_STATE <= WAIT_state_data;
                end if;
              end if;
            else      
              SM_STATE <= TX_HEADER;
            end if;
       
          when WAIT_state_data =>
            if wait_cnt = c_wait_data-1 then 
              SM_STATE <= TX_PAYLOAD;
              wait_cnt <= 0;
            else
              wait_cnt <= wait_cnt + 1;
              SM_STATE <= WAIT_state_data;
            end if;          

          when TX_PAYLOAD =>  
            -- 1. Controlla PRIMA DI TUTTO se la FIFO ha accettato il dato corrente
           if w_dt_wren = '1' then
              --f dt_ready='1' then
              -- 2. Se ha accettato il dato, controlla se era l'ultimo
            if len = 1 then
                SM_STATE   <= IDLE;  
                packet_end <= '1';
            else
                -- 3. Se non era l'ultimo, decidi se fare una pausa o continuare
            if c_wait_data = 0 then  
                  SM_STATE <= TX_PAYLOAD;
            else 
                  SM_STATE <= WAIT_state_data;
              end if; 
              end if;

            else      
              -- Se la FIFO non era pronta (w_dt_wren = '0'), congela la FSM qui!
              SM_STATE <= TX_PAYLOAD;
            end if;
           
       
          when others =>
            SM_STATE <= IDLE;
        end case;
      end if;
    end if;
  end process;

  -- *****************************************************************************
  -- ********** HEADER GEN                         ********** -- **************************************************************************** 
  constant_destination_case: if c_constant_destination_enable='0' generate
      
      process(clk, rst)
      begin
        if rst='0' then
          destination_counter <= 0;
        elsif (clk'event and clk = '1') then
          if SM_STATE = OFF then
            if destination_counter < c_number_of_destination then
              destination_counter <= destination_counter + 1;
            else
              destination_counter <= 0;
            end if;
          end if;
        end if;
      end process;
          
      process(clk, rst)
      begin
        if rst='0' then
          pkt_cnt               <= 0;
          end_transmission      <= '0';
          number_of_destination <= 0;
        elsif (clk'event and clk = '1') then
          if number_of_destination < c_number_of_destination then
              if SM_STATE = OFF then
                pkt_cnt          <= c_number_of_packets - 1;
                end_transmission <= '0';
              elsif packet_end = '1' then 
                if pkt_cnt > 0 then
                  pkt_cnt          <= pkt_cnt - 1;
                  end_transmission <= '0';
                else
                  pkt_cnt          <= 0;
                  end_transmission <= '1';
                  number_of_destination <= number_of_destination + 1;
                end if;
              end if;
          else
              pkt_cnt               <= 0;
              end_transmission      <= '0';
              number_of_destination <= c_number_of_destination;
          end if;
        end if;
      end process;
  end generate;

  variable_destination_case: if c_constant_destination_enable='1' generate
      destination_counter <= c_constant_destination;
      end_transmission    <= '0';
      
      process(clk, rst)
      begin
        if rst='0' then
          pkt_cnt <= 0;       
        elsif (clk'event and clk = '1') then
          if SM_STATE = OFF then
            pkt_cnt <= c_number_of_packets - 1;
          elsif packet_end = '1' then 
            if pkt_cnt > 0 then
              pkt_cnt <= pkt_cnt - 1;
            else
              pkt_cnt <= 0;
            end if;
          end if;
        end if;
      end process;
  end generate;

  -- Corretto l'uso di to_unsigned al posto di to_signed
  destination_reg <= std_logic_vector(to_unsigned(destination_counter, destination_reg'length));
  length_counter  <= c_constant_length;
  length_reg      <= std_logic_vector(to_unsigned(length_counter, length_reg'length));

  process(clk, rst)
  begin
    if rst='0' then
      header_reg <= (others => '0');
    elsif (clk'event and clk = '1') then
      if SM_STATE = IDLE then
        header_reg(c_hdr_dest_fifo_high downto c_hdr_dest_fifo_low) <= destination_reg;
        header_reg(c_length_high downto c_length_low)               <= length_reg;
      end if;   
    end if;
  end process;

  w_hd_wren <= dt_ready when SM_STATE = TX_HEADER else '0'; 
        
  -- *****************************************************************************
  -- ********** PAYLOAD GEN                        ********** -- ***************************************************************************** 
  process(clk, rst)
  begin
    if rst='0' then
      len      <= 0;
      data_int <= 0;
    elsif (clk'event and clk = '1') then
      if SM_STATE = IDLE then
        len      <= length_counter;
        data_int <= 0;
      elsif w_dt_wren = '1' then 
        len      <= len - 1;
        data_int <= data_int + 1;
      end if;
    end if;
  end process;


  
 -- 1. Assegnazione diretta della parte alta del payload (data_int)
  wire_data(c_data_width-1 downto 4) <= std_logic_vector(to_signed(data_int, c_data_width-4));

  -- 2. Assegnazione diretta della parte bassa del payload (pkt_cnt)
  wire_data(3 downto 0)              <= std_logic_vector(to_signed(pkt_cnt, 32)(3 downto 0));
    
 ---------------------------------------------------------------------
  -- ASSEGNAZIONI COMBINATORIE FINALI (Uscite e Handshake)
  ---------------------------------------------------------------------

  -- 1. I segnali di abilitazione interna
  w_hd_wren <= dt_ready when SM_STATE = TX_HEADER else '0';
  w_dt_wren <= dt_ready when SM_STATE = TX_PAYLOAD else '0';

  -- 2. dt_valid stabile (non si abbassa se dt_ready va giù)
  dt_valid <= '1' when (SM_STATE = TX_HEADER or SM_STATE = TX_PAYLOAD) else '0';

  -- 3. Multiplexer del bus dati
  data     <= header_reg when SM_STATE = TX_HEADER else wire_data;

  -- DEBUG Process corretto per evitare loop infiniti di simulazione
  DEBUG: process(clk)
    variable var_ln : line;
  begin 
    if rising_edge(clk) then
      if (first = '1') then
         if (pkt_cnt = 0 and SM_STATE = IDLE) then
             first <= '0';
             write(var_ln, c_sender_string);
             writeline(output, var_ln);
             write(var_ln, c_numb_string);
             write(var_ln, c_number_of_packets);
             writeline(output, var_ln);
             write(var_ln, c_len_string);
             write(var_ln, to_integer(unsigned(length_reg)));
             writeline(output, var_ln);
             write(var_ln, c_dest_string);
             write(var_ln, to_integer(unsigned(destination_reg)));
             writeline(output, var_ln);
         end if;
      end if;
    end if;
  end process;  
  -- synthesis translate_on

end architecture;