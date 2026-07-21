
---Questo codice codifica la trasmissione di dati serializzati in ingresso dalla fsm2 e li restituisce in output alla fifo con l'indirizzo corretto
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use WORK.performance_type_pkg.all;

entity fsm3 is
   port(
    clk : in STD_LOGIC;
    rst : in STD_LOGIC;

    data_in:    in STD_LOGIC;
    valid:      in STD_LOGIC;
    fifo_full1: in STD_LOGIC;
    fifo_full2: in STD_LOGIC;
    data_out:   out STD_LOGIC_VECTOR(c_data_width-1 downto 0);     fifo_wren1: out STD_LOGIC;
    fifo_wren2: out STD_LOGIC
    );
end entity fsm3;
architecture Behavioral of fsm3 is
    type STATE_MACHINE is (READ_HEADER, READ_PAYLOAD); 
  signal stato_corrente, prossimo_stato: STATE_MACHINE;
 
--Dichiarazione dei contatori
signal bit_counter_reg, bit_counter_next   : integer range 0 to c_data_width-1;

signal word_counter_reg, word_counter_next : integer range 0 to 255 := 0;

--registri per dato locale
signal header_reg, header_next : STD_LOGIC_VECTOR(c_data_width-1 downto 0);
signal payload_reg, payload_next: STD_LOGIC_VECTOR(c_data_width-1 downto 0);
--memoria indirizzo fifo
signal dest_fifo_reg, dest_fifo_next : STD_LOGIC_VECTOR(1 downto 0);

begin
    process(clk, rst)
  begin
    if rst = '0' then 
      stato_corrente   <= READ_HEADER;
      bit_counter_reg <= c_data_width - 1;
      word_counter_reg <= 0;
      dest_fifo_reg <= "00"; --stato non corrispondente a nessuna delle due fifo
      header_reg       <= (others => '0');
      payload_reg      <= (others => '0');

    elsif rising_edge(clk) then

      stato_corrente   <= prossimo_stato;
      bit_counter_reg  <= bit_counter_next;
      word_counter_reg <= word_counter_next;
      header_reg       <= header_next;
      payload_reg      <= payload_next;
      dest_fifo_reg    <= dest_fifo_next;
    end if;
  end process;

 process(stato_corrente, bit_counter_reg, word_counter_reg, header_reg, payload_reg, dest_fifo_reg, data_in, valid, fifo_full1, fifo_full2)
    variable v_lunghezza_payload : integer;
    variable v_header  : std_logic_vector(c_data_width-1 downto 0);
    variable v_payload : std_logic_vector(c_data_width-1 downto 0);
  begin
  --devo aggiungere delle variabili per poter trasmettere nello stesso stato di lettura
    v_header  := header_reg;
    v_payload := payload_reg;
   
    prossimo_stato    <= stato_corrente;
    word_counter_next <= word_counter_reg;
    bit_counter_next  <= bit_counter_reg;
    header_next       <= header_reg;
    payload_next      <= payload_reg;
    dest_fifo_next    <= dest_fifo_reg;

    -- Valori di default delle uscite
    data_out   <= (others => '0');
    fifo_wren1 <= '0';
    fifo_wren2 <= '0';

    --in questo stato ricostruisco il dato in ingresso, lo salvo e lo trasmetto, devo fare tutto in unico stato non avendo un segnale di ready verso la fsm2, altrimenti perderei dati
    case stato_corrente is
      when READ_HEADER =>
       
       if valid = '1' then
         v_header(bit_counter_reg) := data_in; --salvo il bit in ingresso
         header_next <= v_header; 
       
        
        --ho finito di leggere i bit:
        --al prossimo stato l'header sarà completo, ma ho bisogno del dato completo ora per poterlo trasmettere: uso il dato nella variabile v_header
          if bit_counter_reg = 0 then
             prossimo_stato <= READ_PAYLOAD;
             bit_counter_next <= c_data_width-1;
             v_lunghezza_payload := to_integer(unsigned(v_header(c_length_high downto c_length_low)));
             word_counter_next   <= v_lunghezza_payload;
            
        
            
           case v_header(c_hdr_dest_fifo_high downto c_hdr_dest_fifo_low ) is
                when "001" => 
                    dest_fifo_next <= "10"; --prima fifo
                    if fifo_full1 = '0' then 
                       fifo_wren1 <= '1'; 
                       data_out   <= v_header;
                    end if;
                    
                when "000" => 
                    dest_fifo_next <= "01"; --seconda fifo
                    if fifo_full2 = '0' then 
                      fifo_wren2 <= '1'; 
                      data_out   <= v_header;
                    end if;
                    
                when others =>
                    dest_fifo_next <= "00";
                end case;

          else
  
            bit_counter_next <= bit_counter_reg- 1;
          end if;
        end if;
           
                
       when READ_PAYLOAD =>
       if valid = '1' then
        
          v_payload(bit_counter_reg) := data_in;
          payload_next <= v_payload;
          if bit_counter_reg = 0 then
            bit_counter_next <= c_data_width-1;
            word_counter_next <= word_counter_reg - 1;

             
            if dest_fifo_reg = "10" then
              if fifo_full1 = '0' then 
                  fifo_wren1 <= '1';
                  data_out <= v_payload;
 
              end if;
            end if;
            if dest_fifo_reg= "01" then
              if fifo_full2 = '0' then 
                 fifo_wren2 <= '1'; 
                 data_out   <= v_payload;
              end if;
            end if;

           if word_counter_reg = 1 then
               prossimo_stato <= READ_HEADER;
               dest_fifo_next <= "00";
   
            else
               prossimo_stato <= READ_PAYLOAD;
            end if; 
         else
             
             bit_counter_next <= bit_counter_reg - 1;
          end if;
        end if;
        --if valid=1 viene saltato tutto il blocco precedente e le uscite mantengono i valori precedenti
          when others =>
        prossimo_stato <= READ_HEADER;
        end case;
      end process;
             

end architecture Behavioral;