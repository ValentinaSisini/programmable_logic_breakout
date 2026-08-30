library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Synchronizes a mechanical pushbutton, removes bounce, and emits
-- one clock-wide pulse on each new press.
entity button_onepulse is
    generic (
        DEBOUNCE_CYCLES : positive := 1_000_000  -- 10 ms at 100 MHz
    );
    port (
        clk     : in  std_logic;
        btn_in  : in  std_logic;
        pulse   : out std_logic
    );
end entity;

architecture rtl of button_onepulse is
    signal sync_ff1     : std_logic := '0';
    signal sync_ff2     : std_logic := '0';
    signal stable_state : std_logic := '0';
    signal count        : natural range 0 to DEBOUNCE_CYCLES - 1 := 0;
begin
    process(clk)
    begin
        if rising_edge(clk) then
            -- Two flip-flops reduce metastability risk for the asynchronous button.
            sync_ff1 <= btn_in;
            sync_ff2 <= sync_ff1;

            -- Default: no event this clock cycle.
            pulse <= '0';

            -- Debounce: accept a state change only after it has remained
            -- unchanged for DEBOUNCE_CYCLES clock cycles.
            if sync_ff2 = stable_state then
                count <= 0;
            else
                if count = DEBOUNCE_CYCLES - 1 then
                    stable_state <= sync_ff2;
                    count <= 0;

                    -- Generate one pulse only on the 0 -> 1 transition.
                    if sync_ff2 = '1' then
                        pulse <= '1';
                    end if;
                else
                    count <= count + 1;
                end if;
            end if;
        end if;
    end process;
end architecture;
