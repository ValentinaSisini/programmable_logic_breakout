library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- FPGA-friendly functional equivalent of the part of a 74193 we need:
-- 4-bit parallel load plus UP and DOWN events.
--
-- Unlike the physical 74193, the FPGA uses one global clock.  The UP and
-- DOWN inputs below are one-clock enable pulses generated elsewhere.
entity counter_74193_style is
    port (
        clk        : in  std_logic;
        load_pulse : in  std_logic;
        up_pulse   : in  std_logic;
        down_pulse : in  std_logic;
        data_in    : in  std_logic_vector(3 downto 0);
        q          : out std_logic_vector(3 downto 0)
    );
end entity;

architecture rtl of counter_74193_style is
    signal count_reg : unsigned(3 downto 0) := (others => '0');
begin
    process(clk)
    begin
        if rising_edge(clk) then
            -- Parallel load has priority, as our explicit user command.
            if load_pulse = '1' then
                count_reg <= unsigned(data_in);

            -- If both directions are requested together, do nothing.
            elsif up_pulse = '1' and down_pulse = '0' then
                count_reg <= count_reg + to_unsigned(1, count_reg'length);

            elsif down_pulse = '1' and up_pulse = '0' then
                count_reg <= count_reg - to_unsigned(1, count_reg'length);
            end if;
        end if;
    end process;

    q <= std_logic_vector(count_reg);
end architecture;
