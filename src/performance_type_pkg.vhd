--****************************************************************************--
--
--  This file is part of the APELink firmware
--  Copyright (C) 2003, 2004, 2005  INFN, APE group
--
--  This program is free software; you can redistribute it and/or
--  modify it under the terms of the GNU General Public License
--  as published by the Free Software Foundation; either version 2
--  of the License, or (at your option) any later version.
--
--  This program is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU General Public License for more details.
--
--  You should have received a copy of the GNU General Public License
--  along with this core; if not, write to the Free Software
--  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
--
--
--****************************************************************************--

library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;

PACKAGE performance_type_pkg IS

-- Packet generator
--Il generatore invierà in totale 3 pacchetti durante il test. Quando la tua interfaccia avrà processato con successo tutti e 3 i pacchetti, la simulazione terminerà e il packet_checker accenderà il LED test_ok
constant c_number_of_packets            : integer :=  2;

constant c_constant_destination_enable  : std_logic := '0' ;    -- If '1' destination FIFO is always 0 else is 0,for c_number_of_packets, 1 for c_number_of_packets ...

--se constant destination enable è '1' allora il generatore invierà sempre pacchetti con destinazione 1, altrimenti invierà pacchetti con destinazione 0,1,0,1,... per c_number_of_packets pacchetti
constant c_constant_destination         : integer := 0 ;
--Definisce la lunghezza del Payload di ciascun pacchetto. In questo caso, ogni pacchetto sarà composto da 2 parole di dati (32 bit ciascuna), a cui si aggiungerà l'Header iniziale. Quindi, un pacchetto completo sarà lungo in tutto $1 (\text{Header}) + 2 (\text{Payload}) = 3 \text{ parole}$.
constant c_constant_length        : integer := 2 ;

constant c_wait_data  : integer := 3 ;

--Interface
constant c_data_width            : integer := 32; 
--numero massimo di destinazioni (FIFO) che il generatore utilizzerà per inviare i pacchetti. In questo caso, il generatore invierà pacchetti a un massimo di 2 destinazioni diverse (FIFO 0 e FIFO 1).
constant c_number_of_destination : integer := 2;

-- Header
constant c_hdr_dest_fifo_high  : integer:= 31;
constant c_hdr_dest_fifo_low   : integer:= 29;
constant c_length_low          : integer:= 0;
constant c_length_high         : integer:= 10;


function Log2( input:integer ) return integer;

end PACKAGE performance_type_pkg;


PACKAGE BODY performance_type_pkg is


function Log2( input:integer ) return integer is
   variable temp,log:integer;
  begin
    temp:=input;
    log:=0;
    while (temp /= 1) loop
     temp:=temp/2;
     log:=log+1;
     end loop;
     return log;
  end function log2;


end PACKAGE BODY performance_type_pkg;
