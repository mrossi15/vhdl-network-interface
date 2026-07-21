--
library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;

use WORK.performance_type_pkg.all;


entity fsm1 is
  port (
    -- Clock e Reset di sistema
    clk       : in  std_logic;
    rst       : in  std_logic; -- attivo basso ('0' = reset)
    -- PACKET GENERATOR
    dt_valid  : in  std_logic; 
    dt_ready  : out std_logic; 
    data_in   : in  std_logic_vector(c_data_width-1 downto 0); 
    -- FIFO 
    fifo_full : in  std_logic; 
    fifo_wren : out std_logic; 
    data_out  : out std_logic_vector(c_data_width-1 downto 0)  
  );
end entity fsm1;

architecture Behavioral of fsm1 is

  type STATE_MACHINE is (IDLE, PAYLOAD); 
  signal stato_corrente, prossimo_stato: STATE_MACHINE;
  signal contatore_reg, contatore_next: integer range 0 to 2047;
begin

  -- Processo Sequenziale 
  process(clk, rst)
  begin
    if rst = '0' then 
      stato_corrente <= IDLE;
      contatore_reg  <= 0;
    elsif rising_edge(clk) then
      stato_corrente <= prossimo_stato;
      contatore_reg  <= contatore_next;
    end if;
  end process;

  -- Processo Combinatorio 
  process(stato_corrente, dt_valid, fifo_full, data_in, contatore_reg)
    variable v_lunghezza_payload : integer range 0 to 2047;
  begin
  
    --  VALORI DI DEFAULT 
    prossimo_stato <= stato_corrente;
    contatore_next <= contatore_reg;
    data_out       <= data_in; 
    dt_ready       <= '0';
    fifo_wren      <= '0'; 

   

    case stato_corrente is
        
      when IDLE =>
      
        if fifo_full = '0' then
          dt_ready <= '1'; 
 
          
          if dt_valid = '1' then
           
            fifo_wren <= '1'; -- Scriviamo l'header nella FIFO
            v_lunghezza_payload := to_integer(unsigned(data_in(c_length_high downto c_length_low)));
            -- Controllo se è presente una payload
            if v_lunghezza_payload = 0 then
              prossimo_stato <= IDLE;         
              contatore_next <= 0;
            else
              contatore_next <= v_lunghezza_payload; 
              prossimo_stato <= PAYLOAD;             
            end if;
          end if;
        end if;

      when PAYLOAD =>
        if fifo_full = '0' then
          dt_ready <= '1'; 
          
          if dt_valid = '1' then
            fifo_wren <= '1'; 
            
            if contatore_reg = 1 then
              contatore_next <= 0;
              prossimo_stato <= IDLE; 
            else
              contatore_next <= contatore_reg - 1;
            end if;
          end if;
        end if;

      when others =>
        prossimo_stato <= IDLE;
            
    end case;
  end process;

end architecture;