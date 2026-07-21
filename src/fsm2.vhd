library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use WORK.performance_type_pkg.all;

entity fsm2 is 
  port (
    clk         : in  std_logic;
    rst         : in  std_logic; -- attivo basso ('0' = reset)
    
    -- Interfaccia FIFO 
    fifo_dout   : in  std_logic_vector(c_data_width-1 downto 0);
    fifo_empty  : in  std_logic;
    fifo_rd_en  : out std_logic;
    
    -- Interfaccia  uscita
    valid_out   : out std_logic;
    data_out    : out std_logic
   
  );
end entity fsm2;

architecture Behavioral of fsm2 is

  type STATE_MACHINE is (READ_HEADER, SERIALIZE_HEADER, READ_PAYLOAD, SERIALIZE_PAYLOAD); 
  signal stato_corrente, prossimo_stato: STATE_MACHINE;
  
  signal header_reg, header_next       : std_logic_vector(c_data_width-1 downto 0);
  signal payload_reg, payload_next     : std_logic_vector(c_data_width-1 downto 0);
  
  signal bit_counter_reg, bit_counter_next   : integer range 0 to 31;
  signal word_counter_reg, word_counter_next : integer range 0 to 2047;

begin
--clk e reset
  process(clk, rst)
  begin
    if rst = '0' then 
      stato_corrente   <= READ_HEADER;
      bit_counter_reg  <= 0;
      word_counter_reg <= 0;
      header_reg       <= (others => '0'); --impongo a zero tutti i valori del registro
      payload_reg      <= (others => '0'); 
    elsif rising_edge(clk) then
      stato_corrente   <= prossimo_stato;
      header_reg       <= header_next;
      payload_reg      <= payload_next;
      bit_counter_reg  <= bit_counter_next;
      word_counter_reg <= word_counter_next;
    end if;
  end process;

  process(stato_corrente, fifo_empty, fifo_dout, header_reg, payload_reg, bit_counter_reg, word_counter_reg)
    variable v_lunghezza : integer range 0 to 2047;
  begin
  
    -- VALORI DI DEFAULT 
    prossimo_stato    <= stato_corrente;
    header_next       <= header_reg;
    payload_next      <= payload_reg;
    bit_counter_next  <= bit_counter_reg;
    word_counter_next <= word_counter_reg;
    
    fifo_rd_en        <= '0';
    valid_out         <= '0';
    data_out          <= '0';
    
---dentro gli stati di lettura aziono rd_enable e mi permette di leggere i dati provenienti dalla fifo che rimangono congelati fino a che sono nello stato di serializzazione
    case stato_corrente is
        
      --Lettura Header
     
      when READ_HEADER =>
        if fifo_empty = '0' then
          fifo_rd_en       <= '1';         -- Consuma l'header (la FIFO cambierà dato al prossimo clock)
          header_next      <= fifo_dout;   
          bit_counter_next <= c_data_width-1;
          prossimo_stato   <= SERIALIZE_HEADER;
        end if;

      
      --  Serializzazione Header
       when SERIALIZE_HEADER =>
        valid_out <= '1';
        data_out  <= header_reg(bit_counter_reg); 
        --alla fine della serializzazione memorizzo la lunghezza della payload e se è maggiore di uno passo nello stato di payload
        if bit_counter_reg = 0 then
          v_lunghezza := to_integer(unsigned(header_reg(c_length_high downto c_length_low)));
          word_counter_next <= v_lunghezza;
          
          if v_lunghezza = 0 then
            prossimo_stato <= READ_HEADER; -- Nessun payload, torna a cercare un header
          else
            prossimo_stato <= READ_PAYLOAD;
          end if;
        else
          bit_counter_next <= bit_counter_reg - 1;
        end if;

     
      -- STATO 3: Lettura Payload 
      
      when READ_PAYLOAD =>
  
        if word_counter_reg = 0 then
          prossimo_stato <= READ_HEADER; -- se ho finito le payload devo tornare nell'header
        else
          if fifo_empty = '0' then
            fifo_rd_en        <= '1';        -- Consuma la parola attuale
            payload_next      <= fifo_dout;  
            word_counter_next <= word_counter_reg - 1;
            bit_counter_next  <= c_data_width-1;         
            prossimo_stato    <= SERIALIZE_PAYLOAD;
            
          end if;
        end if;

      
      -- STATO 4: Serializzazione Payload

      when SERIALIZE_PAYLOAD =>
        valid_out <= '1';
        data_out  <= payload_reg(bit_counter_reg); 

        if bit_counter_reg = 0 then
          if word_counter_reg = 0 then
            prossimo_stato <= READ_HEADER;  -- Pacchetto finito
          else
            prossimo_stato <= READ_PAYLOAD; -- Altre parole da leggere
          end if;
        else
          bit_counter_next <= bit_counter_reg - 1;
        end if;

      when others =>
        prossimo_stato <= READ_HEADER;
            
    end case;
  end process;

end architecture Behavioral;

