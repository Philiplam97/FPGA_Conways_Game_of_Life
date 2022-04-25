-------------------------------------------------------------------------------
-- Title      : Top level Conway's Game of Life
-- Project    : Conways GOL
-------------------------------------------------------------------------------
-- File       : game_of_life.vhd
-- Author     : Philip 
-- Created    : 15-04-2022
-------------------------------------------------------------------------------
-- Description: Top level of for conway's game of life, implemented on an ARTY
-- A7 FPGA with VGA output
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity arty_top is
  port(
    clk_100MHz : in std_logic;
    rst_btn_n  : in std_logic;

    --VGA signals
    o_red   : out unsigned(3 downto 0);
    o_green : out unsigned(3 downto 0);
    o_blue  : out unsigned(3 downto 0);

    o_h_sync : out std_logic;
    o_v_sync : out std_logic
    );
end entity;

architecture rtl of arty_top is

  constant C_FRAME_WIDTH  : natural := 640;
  constant C_FRAME_HEIGHT : natural := 480;
  constant C_PXL_TICK_DIV : natural := 4;  -- once every 4 clks

  signal rst : std_logic := '0';

  --Counter used to generate a pulse every four clock cycles for the VGA module
  --and for the shift registers
  signal pxl_tick_cnt : unsigned(1 downto 0) := (others => '0');
  signal pxl_tick     : std_logic            := '0';

  signal active_video : std_logic := '0';

  signal game_of_life_en : std_logic := '0';
  signal cell_state_out  : std_logic := '0';

  signal red   : unsigned(3 downto 0) := (others => '0');
  signal green : unsigned(3 downto 0) := (others => '0');
  signal blue  : unsigned(3 downto 0) := (others => '0');

  signal sof    : std_logic := '0';
  signal sav    : std_logic := '0';
  signal eav    : std_logic := '0';
  signal vblank : std_logic := '1';

begin
-- TODO sync reset button then debounce
  rst <= not rst_btn_n;

  -- We have a system clock 0f 100MHZ, and VGA SD needs approximately a 25MHZ
  -- clock. The VGA uses a clock enable instead, which we need to generate
  -- every 4 100MHz clock cycles. Run the whole datapath with this clock enable.
  p_pxl_tick : process(clk_100MHz)
  begin
    if rising_edge(clk_100MHz) then
      pxl_tick_cnt <= pxl_tick_cnt + 1;
      if pxl_tick_cnt = C_PXL_TICK_DIV - 1 then
        pxl_tick <= '1';
      else
        pxl_tick <= '0';
      end if;

      if rst = '1' then
        pxl_tick_cnt <= (others => '0');
      end if;
    end if;
  end process;

  p_active_vid : process(clk_100MHz)
  begin
    if rising_edge(clk_100MHz) then
      if sav = '1' and vblank = '0' then
        active_video <= '1';
      elsif eav = '1' then
        active_video <= '0';
      end if;
    end if;
  end process;

  -- Mask the enable with active video so that it only advances during the
  -- active video portion of the frame
  game_of_life_en <= pxl_tick and active_video;

  game_of_life_1 : entity work.game_of_life
    generic map (
      G_FRAME_WIDTH  => C_FRAME_WIDTH,
      G_FRAME_HEIGHT => C_FRAME_HEIGHT,
      G_INIT_FILE    => "../scripts/bram_init.txt")
    port map (
      clk          => clk_100MHz,
      rst          => rst,
      i_en         => game_of_life_en,
      o_cell_state => cell_state_out);


-- Set alive cells to all ones (white) and dead cells to all zeros (black)
  red   <= (others => cell_state_out);
  green <= (others => cell_state_out);
  blue  <= (others => cell_state_out);

-- 640x480 VGA
  VGA_1 : entity work.VGA
    port map (
      clk        => clk_100MHz,
      rst        => rst,
      i_pxl_tick => pxl_tick,
      i_red      => red,
      i_green    => green,
      i_blue     => blue,
      o_h_sync   => o_h_sync,
      o_v_sync   => o_v_sync,
      o_red      => o_red,
      o_green    => o_green,
      o_blue     => o_blue,
      o_sof      => sof,                -- Start of frame
      o_sav      => sav,                -- Start of active video line
      o_eav      => eav,                -- End of active video line
      o_vblank   => vblank              -- Vertical blanking
      );

end architecture;
