-------------------------------------------------------------------------------
-- Title      : Testbench for design "game_of_life"
-- Project    : Conways GOL
-------------------------------------------------------------------------------
-- File       : game_of_life_tb.vhd
-- Author     : Philip  <Little Lamb@DESKTOP-8H7PP4B>
-- Created    : 17-04-2022
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use STD.textio.all;
-------------------------------------------------------------------------------

entity game_of_life_tb is
  generic (G_BRAM_INIT_FILE_PATH : string := "");
end entity game_of_life_tb;

-------------------------------------------------------------------------------

architecture behav of game_of_life_tb is
  constant C_OUT_PATH     : string  := "sim_output.txt";
  constant C_NUM_FRAMES   : natural := 3;
  -- component generics
  constant C_FRAME_WIDTH  : natural := 640;
  constant C_FRAME_HEIGHT : natural := 480;
  constant C_PXL_TICK_DIV : natural := 4;  -- once every 4 clks

  signal pxl_tick_cnt : unsigned(1 downto 0) := (others => '0');
  signal pxl_tick     : std_logic            := '0';

-- component ports
  signal i_en       : std_logic := '0';
  signal cell_state : std_logic := '0';

  constant C_CLK_PERIOD : time      := 10 ns;
  signal clk            : std_logic := '1';
  signal rst            : std_logic := '0';

begin  -- architecture behav

  p_pxl_tick : process(clk)
  begin
    if rising_edge(clk) then
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

  -- component instantiation
  DUT : entity work.game_of_life
    generic map (
      G_FRAME_WIDTH  => C_FRAME_WIDTH,
      G_FRAME_HEIGHT => C_FRAME_HEIGHT,
      G_INIT_FILE    => G_BRAM_INIT_FILE_PATH)
    port map (
      clk          => clk,
      rst          => rst,
      i_en         => pxl_tick,
      o_cell_state => cell_state);

  clk_gen : process
  begin
    clk <= '0';
    wait for C_CLK_PERIOD/2;
    clk <= '1';
    wait for C_CLK_PERIOD/2;
  end process clk_gen;

  rst_gen : process
  begin
    rst <= '1';
    wait for 100 ns;
    rst <= '0';
    wait;
  end process rst_gen;

  p_write_output : process
    file fp         : text;
    variable v_line : line;
    variable v_data : bit;
  begin
    file_open(fp, C_OUT_PATH, write_mode);

    for i in 0 to C_NUM_FRAMES * (C_FRAME_WIDTH * C_FRAME_HEIGHT) - 1 loop
      wait until pxl_tick = '1';
      write(v_line, to_bit(cell_state));
      writeline(fp, v_line);
      wait until rising_edge(clk);
    end loop;
    assert false report "end of simulation" severity failure;
  end process;

end architecture behav;

