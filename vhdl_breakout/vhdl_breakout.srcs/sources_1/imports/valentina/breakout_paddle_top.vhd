library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Breakout paddle-position prototype for Digilent Basys 3.
--
-- SW3..SW0 : initial 4-bit position (0..15)
-- BTNC     : parallel LOAD of the switches into the counter
-- BTNR     : move one position to the right
-- BTNL     : move one position to the left
-- 7-seg    : shows position in hexadecimal (0..9, A..F) on digit AN0
--
-- The position saturates at the ends: 0 cannot decrement and F cannot increment.
entity breakout_paddle_top is
    port (
        clk  : in  std_logic;
        sw   : in  std_logic_vector(3 downto 0);
        btnC : in  std_logic;
        btnL : in  std_logic;
        btnR : in  std_logic;
        seg  : out std_logic_vector(6 downto 0);
        an   : out std_logic_vector(3 downto 0);
        dp   : out std_logic
    );
end entity;

architecture rtl of breakout_paddle_top is
    signal load_press  : std_logic;
    signal left_press  : std_logic;
    signal right_press : std_logic;

    signal up_enable   : std_logic;
    signal down_enable : std_logic;

    signal position    : std_logic_vector(3 downto 0);
begin
    -- Each physical press becomes one clean, one-clock pulse.
    load_button : entity work.button_onepulse
        generic map (DEBOUNCE_CYCLES => 1_000_000)
        port map (
            clk    => clk,
            btn_in => btnC,
            pulse  => load_press
        );

    left_button : entity work.button_onepulse
        generic map (DEBOUNCE_CYCLES => 1_000_000)
        port map (
            clk    => clk,
            btn_in => btnL,
            pulse  => left_press
        );

    right_button : entity work.button_onepulse
        generic map (DEBOUNCE_CYCLES => 1_000_000)
        port map (
            clk    => clk,
            btn_in => btnR,
            pulse  => right_press
        );

    -- External end-stop logic: keep the counter itself 74193-like,
    -- but prevent wraparound for the paddle position.
    up_enable   <= right_press when position /= "1111" else '0';
    down_enable <= left_press  when position /= "0000" else '0';

    paddle_counter : entity work.counter_74193_style
        port map (
            clk        => clk,
            load_pulse => load_press,
            up_pulse   => up_enable,
            down_pulse => down_enable,
            data_in    => sw,
            q          => position
        );

    display_decoder : entity work.sevenseg_hex
        port map (
            value => position,
            seg   => seg
        );

    -- Basys 3: anodes and segment cathodes are active low.
    -- Enable only AN0 (rightmost digit); disable the other three digits.
    an <= "1110";
    dp <= '1'; -- decimal point off
end architecture;
