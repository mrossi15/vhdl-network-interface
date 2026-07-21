library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library std;
use std.env.all;
use WORK.performance_type_pkg.all;

entity tb_rx_tx is
end tb_rx_tx;

architecture Behavior of tb_rx_tx is

    -- Costante per il periodo di clock
    constant CLK_PERIOD : time := 10 ns;
    
    signal clk : std_logic := '0';
    signal rst : std_logic := '0'; -- attivo basso

    -- Interconnessioni: Packet Generator -> RX Block
    signal pg_dt_valid : std_logic;
    signal pg_dt_ready : std_logic;
    signal pg_data     : std_logic_vector(c_data_width-1 downto 0);

    -- Interconnessioni: RX Block -> TX Block 
    signal serial_valid : std_logic;
    signal serial_data  : std_logic;

    -- Uscite del rX Block verso l'esterno 
    signal tb_rd_en_1   : std_logic := '0';
    signal tb_rd_en_2   : std_logic := '0';
    signal tb_dout_1    : std_logic_vector(c_data_width-1 downto 0);
    signal tb_dout_2    : std_logic_vector(c_data_width-1 downto 0);
    signal tb_empty_1   : std_logic;
    signal tb_empty_2   : std_logic;

begin

    -- GENERAZIONE DEL CLOCK
    clk_process : process
    begin
        clk <= '0';
        wait for CLK_PERIOD / 2;
        clk <= '1';
        wait for CLK_PERIOD / 2;
    end process;


    -- ISTANZA DEL PACKET GENERATOR 
    U_PACKET_GEN: entity work.packet_generator
        port map (
            clk      => clk,
            rst      => rst,
            dt_valid => pg_dt_valid, -- Collegato a RX Block
            dt_ready => pg_dt_ready, -- Collegato a RX Block
            data     => pg_data      -- Collegato a RX Block
        );


    -- ISTANZA DEL RICEVITORE (
    U_TX_BLOCK: entity work.tx_block
        port map (
            clk       => clk,
            rst       => rst,
            dt_valid  => pg_dt_valid, -- Riceve da Packet Generator
            dt_ready  => pg_dt_ready, -- Invia a Packet Generator
            data_in   => pg_data,     -- Riceve da Packet Generator
            valid_out => serial_valid, -- Invia a TX Block
            data_out  => serial_data   -- Invia a TX Block
        );


    --ISTANZA DEL TRASMETTITORE 
    U_RX_BLOCK: entity work.rx_block
        generic map (
            g_width => c_data_width,
            g_depth => 62
        )
        port map (
            clk       => clk,
            rst       => rst,
            data_in   => serial_data,  -- Riceve da RX Block
            valid     => serial_valid, -- Riceve da RX Block
            rd_en_1   => tb_rd_en_1,   -- Pilotato dal processo di lettura del TB
            rd_en_2   => tb_rd_en_2,   -- Pilotato dal processo di lettura del TB
            dout_1    => tb_dout_1, --valori in uscita dalla FIFO1
            dout_2    => tb_dout_2, --valori in uscita dalla FIFO2
            empty_1   => tb_empty_1,
            empty_2   => tb_empty_2
        );

    tb_rd_en_1 <= not tb_empty_1;
    tb_rd_en_2 <= not tb_empty_2;
    -- 5. PROCESSO DI RESET
    stimulus_process: process
    begin
   
        -- Applica il reset iniziale
        rst <= '0';
        wait for 40 ns;
        tb_rd_en_1 <='1';
        tb_rd_en_2 <='1';
        rst <= '1';
        wait for 5000 ns; 
        
        -- Sostituisci l'assert con questo:
        report "Simulazione completata con successo!";
        finish; -- Ferma la simulazione in modo pulito (Exit code 0)
    end process;

-- Processo che simula un modulo a valle che legge i dati
    read_process: process(clk, rst)
    begin
        if rst = '0' then
            tb_rd_en_1 <= '0';
            tb_rd_en_2 <= '0';
        elsif rising_edge(clk) then
            -- Leggi dalla FIFO 1 solo se ci sono dati
            if tb_empty_1 = '0' then
                tb_rd_en_1 <= '1';
            else
                tb_rd_en_1 <= '0';
            end if;

            -- Leggi dalla FIFO 2 solo se ci sono dati
            if tb_empty_2 = '0' then
                tb_rd_en_2 <= '1';
            else
                tb_rd_en_2 <= '0';
            end if;
        end if;
    end process;


end architecture Behavior;
