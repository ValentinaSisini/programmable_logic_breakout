library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Top level Breakout + VGA for Basys 3.
--
-- IMPORTANT:
-- The existing paddle-control files are NOT modified:
--   - button_onepulse.vhd
--   - counter_74193_style.vhd
--   - sevenseg_hex.vhd
--   - breakout_paddle_top.vhd
--
-- This is a NEW top level. It reuses the same paddle-control entities
-- and adds the VGA scan/render logic corresponding to the circuit
-- developed in Digital.
--
-- VGA timing implemented here:
--   X counter: 0 .. 799
--   Y counter: 0 .. 524
--   HSYNC low when 656 < X < 753
--   VSYNC low when 490 < Y < 493
--
-- Paddle rendering:
--   X_paddle_px = paddle_position * 40
--   X condition 1: X_scan > X_paddle_px
--   X condition 2: X_scan < X_paddle_px + 40
--   Y condition 1: Y_scan > 460
--   Y condition 2: Y_scan < 475
--   paddle_visible = X_condition_1 AND X_condition_2
--                    AND Y_condition_1 AND Y_condition_2
--
-- Final OR:
--   final_or = 0 OR paddle_visible
--
-- 4-bit VGA intensity:
--   final_or = 0 -> "0000"
--   final_or = 1 -> "1111" = 15
--
-- The paddle is currently drawn white, so the same 4-bit intensity
-- is sent to R, G and B.
entity breakout_vga_top is
    port (
        -- Basys 3 board clock and paddle controls
        clk      : in  std_logic;
        sw       : in  std_logic_vector(3 downto 0);
        btnC     : in  std_logic;
        btnL     : in  std_logic;
        btnR     : in  std_logic;

        -- Existing seven-segment paddle-position display
        seg      : out std_logic_vector(6 downto 0);
        an       : out std_logic_vector(3 downto 0);
        dp       : out std_logic;

        -- Basys 3 VGA outputs
        vgaRed   : out std_logic_vector(3 downto 0);
        vgaGreen : out std_logic_vector(3 downto 0);
        vgaBlue  : out std_logic_vector(3 downto 0);
        Hsync    : out std_logic;
        Vsync    : out std_logic
    );
end entity;

architecture rtl of breakout_vga_top is

    ----------------------------------------------------------------
    -- EXISTING PADDLE CONTROL
    -- Same logic already used in breakout_paddle_top.vhd.
    ----------------------------------------------------------------
    signal load_press  : std_logic;
    signal left_press  : std_logic;
    signal right_press : std_logic;

    signal up_enable   : std_logic;
    signal down_enable : std_logic;

    signal position    : std_logic_vector(3 downto 0);

    ----------------------------------------------------------------
    -- VGA SCAN
    ----------------------------------------------------------------
    -- 100 MHz / 4 = 25 MHz pixel clock enable.
    -- We keep the FPGA on the 100 MHz global clock and advance
    -- the pixel counters once every four system-clock cycles.
    signal pixel_div : unsigned(1 downto 0) := (others => '0');

    signal x_scan : unsigned(9 downto 0) := (others => '0');
    signal y_scan : unsigned(9 downto 0) := (others => '0');

    ----------------------------------------------------------------
    -- PADDLE PIXEL LOGIC
    ----------------------------------------------------------------
    signal paddle_x_px    : unsigned(9 downto 0);
    signal paddle_x_right : unsigned(9 downto 0);

    signal paddle_x_gt_left  : std_logic;
    signal paddle_x_lt_right : std_logic;
    signal paddle_x_visible  : std_logic;

    signal paddle_y_gt_460 : std_logic;
    signal paddle_y_lt_475 : std_logic;
    signal paddle_y_visible : std_logic;

    signal paddle_visible : std_logic;

    signal final_or_bit : std_logic;
    signal pixel_level  : std_logic_vector(3 downto 0);

begin

    ----------------------------------------------------------------
    -- PADDLE CONTROL: unchanged behavior
    ----------------------------------------------------------------
    load_button : entity work.button_onepulse
        generic map (
            DEBOUNCE_CYCLES => 1_000_000
        )
        port map (
            clk    => clk,
            btn_in => btnC,
            pulse  => load_press
        );

    left_button : entity work.button_onepulse
        generic map (
            DEBOUNCE_CYCLES => 1_000_000
        )
        port map (
            clk    => clk,
            btn_in => btnL,
            pulse  => left_press
        );

    right_button : entity work.button_onepulse
        generic map (
            DEBOUNCE_CYCLES => 1_000_000
        )
        port map (
            clk    => clk,
            btn_in => btnR,
            pulse  => right_press
        );

    -- Same saturation logic as the existing paddle top.
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

    an <= "1110";
    dp <= '1';

    ----------------------------------------------------------------
    -- VGA X/Y COUNTERS
    --
    -- Equivalent to the scan counters built in Digital:
    -- X = 0..799
    -- Y increments once when X wraps
    -- Y = 0..524
    ----------------------------------------------------------------
    scan_process : process(clk)
    begin
        if rising_edge(clk) then
            if pixel_div = "11" then
                pixel_div <= (others => '0');

                if x_scan = to_unsigned(799, x_scan'length) then
                    x_scan <= (others => '0');

                    if y_scan = to_unsigned(524, y_scan'length) then
                        y_scan <= (others => '0');
                    else
                        y_scan <= y_scan + 1;
                    end if;

                else
                    x_scan <= x_scan + 1;
                end if;

            else
                pixel_div <= pixel_div + 1;
            end if;
        end if;
    end process;

    ----------------------------------------------------------------
    -- HSYNC / VSYNC
    -- Exact inequalities used in the Digital circuit.
    ----------------------------------------------------------------
    Hsync <= '0'
        when (x_scan > to_unsigned(656, x_scan'length) and
              x_scan < to_unsigned(753, x_scan'length))
        else '1';

    Vsync <= '0'
        when (y_scan > to_unsigned(490, y_scan'length) and
              y_scan < to_unsigned(493, y_scan'length))
        else '1';

    ----------------------------------------------------------------
    -- X_PADDLE * 40
    --
    -- 40 = 32 + 8, therefore:
    -- X*40 = (X << 5) + (X << 3)
    --
    -- This corresponds directly to the shift/add circuit developed
    -- previously, without using a general multiplier.
    ----------------------------------------------------------------
    paddle_x_px <=
        shift_left(resize(unsigned(position), paddle_x_px'length), 5) +
        shift_left(resize(unsigned(position), paddle_x_px'length), 3);

    paddle_x_right <=
        paddle_x_px + to_unsigned(40, paddle_x_right'length);

    ----------------------------------------------------------------
    -- X CONDITIONS
    ----------------------------------------------------------------
    paddle_x_gt_left <= '1'
        when x_scan > paddle_x_px
        else '0';

    paddle_x_lt_right <= '1'
        when x_scan < paddle_x_right
        else '0';

    paddle_x_visible <=
        paddle_x_gt_left and paddle_x_lt_right;

    ----------------------------------------------------------------
    -- Y CONDITIONS
    ----------------------------------------------------------------
    paddle_y_gt_460 <= '1'
        when y_scan > to_unsigned(460, y_scan'length)
        else '0';

    paddle_y_lt_475 <= '1'
        when y_scan < to_unsigned(475, y_scan'length)
        else '0';

    paddle_y_visible <=
        paddle_y_gt_460 and paddle_y_lt_475;

    ----------------------------------------------------------------
    -- FINAL AND
    ----------------------------------------------------------------
    paddle_visible <=
        paddle_x_visible and paddle_y_visible;

    ----------------------------------------------------------------
    -- FINAL OR
    -- Kept explicitly because it mirrors the last stage of the
    -- circuit and leaves a natural point where other objects can
    -- later be ORed in.
    ----------------------------------------------------------------
    final_or_bit <= '0' or paddle_visible;

    ----------------------------------------------------------------
    -- 1 BIT -> 4 BIT INTENSITY
    --
    -- final_or_bit = 0 -> 0000
    -- final_or_bit = 1 -> 1111 = 15
    ----------------------------------------------------------------
    pixel_level <= (others => final_or_bit);

    ----------------------------------------------------------------
    -- RGB OUTPUT
    -- For now the paddle is white.
    ----------------------------------------------------------------
    vgaRed   <= pixel_level;
    vgaGreen <= pixel_level;
    vgaBlue  <= pixel_level;

end architecture;
