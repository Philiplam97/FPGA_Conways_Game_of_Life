-------------------------------------------------------------------------------
-- Title      : Block RAM shift register
-- Project    : Conways GOL
-------------------------------------------------------------------------------
-- File       : bram_shift_reg.vhd
-- Author     : Philip
-- Created    : 15-04-2022
-------------------------------------------------------------------------------
-- Description: A shift register implemented in BRAM using the
-- read-before-write mode. 
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;

use IEEE.math_real.ceil;
use IEEE.math_real.log2;

entity bram_shift_reg is
  generic (
    G_DEPTH     : natural := 640*479-3;                  --640x480
    G_WIDTH     : natural := 1;
    G_INIT_FILE : string  := "../scripts/bram_init.txt"  -- path to memory init file
    );
  port (
    clk : in std_logic;

    i_wr_data : in std_logic_vector(G_WIDTH - 1 downto 0);
    i_wr_en   : in std_logic;

    o_rd_data : out std_logic_vector(G_WIDTH - 1 downto 0)
    );
end entity;

architecture rtl of bram_shift_reg is

  type t_ram is array (natural range<>) of std_logic_vector(G_WIDTH - 1 downto 0);
  constant C_ADDR_WIDTH : natural := integer(ceil(log2(real(G_DEPTH))));

  impure function init_ram_from_file(path : string) return t_ram is
    file fp         : text;
    variable v_line : line;
    variable v_data : bit_vector(3 downto 0);
    variable v_ram  : t_ram(0 to G_DEPTH-1) := (others => (others => '0'));
  begin
    if path = "" then
      return v_ram;
    end if;
    assert (G_WIDTH <= 4)
      report "init_ram_from_file function currently hardcoded to read 1 hex value."
      & "Change v_data width for larger data widths!!!"
      severity failure;

    file_open(fp, path, read_mode);

    for i in 0 to v_ram'high loop
      readline(fp, v_line);
      hread(v_line, v_data);  -- Vivado doesn't seem to support read with integers, so read in hex data instead
      v_ram(i) := to_std_logic_vector(v_data(G_WIDTH - 1 downto 0));
    end loop;
    file_close(fp);
    return v_ram;
  end;

  constant C_RAM_INIT : t_ram(0 to G_DEPTH-1) := init_ram_from_file(G_INIT_FILE);
  
  signal ram         : t_ram(0 to G_DEPTH-2)               := C_RAM_INIT(1 to G_DEPTH-1);
  signal rd_data     : std_logic_vector(o_rd_data'range)   := C_RAM_INIT(0);
  signal rd_data_out : std_logic_vector(o_rd_data'range)   := (others => '0');
  signal rd_data_d1  : std_logic_vector(o_rd_data'range)   := (others => '0');
  signal addr        : unsigned(C_ADDR_WIDTH - 1 downto 0) := (others => '0');

begin

  process(clk)
  begin
    if rising_edge(clk) then
      if i_wr_en = '1' then
        -- Minus 2 because we use the output register of the blockram
        if addr = G_DEPTH - 2 then
          addr <= (others => '0');
        else
          addr <= addr + 1;
        end if;
        ram(to_integer(addr)) <= i_wr_data;

        rd_data     <= ram(to_integer(addr));
        rd_data_out <= rd_data;
      end if;
    end if;
  end process;

  o_rd_data <= rd_data_out;

end architecture;
