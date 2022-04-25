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

use IEEE.math_real.ceil;
use IEEE.math_real.log2;

entity game_of_life is
  generic (
    G_FRAME_WIDTH  : natural := 640;
    G_FRAME_HEIGHT : natural := 480;
    G_INIT_FILE    : string  := ""
    );
  port(
    clk : in std_logic;
    rst : in std_logic;

    i_en         : in  std_logic;
    o_cell_state : out std_logic
    );
end entity;

architecture rtl of game_of_life is
  constant C_FRAME_WIDTH_CLOG2  : natural := integer(ceil(log2(real(G_FRAME_WIDTH - 1 + 1))));
  constant C_FRAME_HEIGHT_CLOG2 : natural := integer(ceil(log2(real(G_FRAME_HEiGHT - 1 + 1))));

  --Function to count the number of bits set in a standard logic vecctor 
  function sum_slv(slv_in : std_logic_vector) return natural is
    variable v_sum : natural := 0;
  begin
    v_sum := 0;

    for i in 0 to slv_in'length - 1 loop
      if slv_in(i) = '1' then
        v_sum := v_sum + 1;
      end if;
    end loop;
    return v_sum;
  end;

  --Counter used to generate a pulse every four clock cycles for the VGA module
  --and for the shift registers
  signal line_buffer_0 : std_logic_vector(G_FRAME_WIDTH - 1 downto 0) := (others => '0');
  signal line_buffer_1 : std_logic_vector(G_FRAME_WIDTH - 1 downto 0) := (others => '0');
  signal sreg          : std_logic_vector(2 downto 0)                 := (others => '0');

  signal bram_sreg_out     : std_logic_vector(0 downto 0) := (others => '0');
  signal bram_sreg_out_vld : std_logic                    := '0';

  signal x_coor : unsigned(C_FRAME_WIDTH_CLOG2 - 1 downto 0)  := (others => '0');
  signal y_coor : unsigned(C_FRAME_HEIGHT_CLOG2 - 1 downto 0) := (others => '0');

  signal next_cell_state : std_logic := '0';

begin

  -- We need 3 shift registers in total, one big one storing the majority of
  -- the bottom lines, then 2 line buffers to buffer values for the sliding window.
  -- The big one will use block rams, while the smaller ones will use srl32s
  -- (LUT delay line) with 3 registers at the end to be able to tap the values
  -- from
  p_line_buff : process(clk)
  begin
    if rising_edge(clk) then
      if i_en = '1' then
        --bottom 3 values (index 0,1,2) will be in flops, rest shuld be in srl32
        line_buffer_0 <= line_buffer_1(0) & line_buffer_0(line_buffer_0'high downto 1);
        line_buffer_1 <= sreg(0) & line_buffer_1(line_buffer_1'high downto 1);

        -- We need 3 registers after the BRAM shift reg for the bottom 3 neighbour
        -- cells in the window
        sreg <= bram_sreg_out & sreg(sreg'high downto 1);
      end if;
    end if;
  end process;

  bram_shift_reg : entity work.bram_shift_reg
    generic map (
      G_DEPTH     => G_FRAME_WIDTH * (G_FRAME_HEIGHT - 1) - 3,
      G_WIDTH     => 1,
      G_INIT_FILE => "../scripts/bram_init.txt")  --TODO add file path
    port map (
      clk       => clk,
      i_wr_data => (0 => next_cell_state),        --convert to slv
      i_wr_en   => i_en,
      o_rd_data => bram_sreg_out,
      o_vld     => bram_sreg_out_vld);

  p_coord : process(clk)
  begin
    if rising_edge(clk) then
      if i_en = '1' then
        x_coor <= x_coor + 1;
        if x_coor = G_FRAME_WIDTH - 1 then
          x_coor <= (others => '0');
          y_coor <= y_coor + 1;
          if y_coor = G_FRAME_HEIGHT - 1 then
            y_coor <= (others => '0');
          end if;
        end if;
      end if;
    end if;
  end process;


-- Logic to determin the state of the cell for the next generation
  p_compute_state : process(clk)
    variable v_neighbour_cells : std_logic_vector(7 downto 0) := (others => '0');
  begin
    if rising_edge(clk) then
      -- Indexes are ordered like below :
      -- | 5 | 6 | 7 |
      -- | 3 | X | 4 |
      -- | 0 | 1 | 2 |

      v_neighbour_cells(7 downto 5) := line_buffer_0(2 downto 0);
      v_neighbour_cells(4 downto 3) := line_buffer_1(2) & line_buffer_1(0);
      v_neighbour_cells(2 downto 0) := sreg;

      -- Handle the border cases by zeroing out values outslde of the frame
      if y_coor = 0 then
        --Top line, zero out top neighbours
        v_neighbour_cells(7 downto 5) := (others => '0');
      end if;
      if y_coor = G_FRAME_HEIGHT - 1 then
        --Bottom line, zero out bottom neighbours
        v_neighbour_cells(2 downto 0) := (others => '0');
      end if;
      if x_coor = 0 then
        --left edge , zero out left neighbours
        v_neighbour_cells(5) := '0';
        v_neighbour_cells(3) := '0';
        v_neighbour_cells(0) := '0';

      end if;
      if x_coor = G_FRAME_WIDTH - 1 then
        -- Right edge, zero out right neighbours
        v_neighbour_cells(7) := '0';
        v_neighbour_cells(4) := '0';
        v_neighbour_cells(2) := '0';
      end if;

      --The cell is alive for the next generation if there are three alive
      --neighbouring cells, or there are 2 cells and itself is alive
      if sum_slv(v_neighbour_cells) = 3 or (sum_slv(v_neighbour_cells) = 2 and line_buffer_1(1) = '1') then
        next_cell_state <= '1';
      else
        next_cell_state <= '0';
      end if;

    end if;
  end process;

  o_cell_state <= line_buffer_1(1);

end architecture;
