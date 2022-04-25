library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.ceil;
use IEEE.math_real.log2;

entity debouncer is
  generic (
    G_N_CLKS_MAX : natural := 5e6      --50ms with 100MHz clk
    );
  port (
    clk : in std_logic;
    rst : in std_logic;

    i_din  : in  std_logic;             --assume always asynchronous
    o_dout : out std_logic
    );
end;
architecture rtl of debouncer is
  signal din_meta : std_logic := '0';
  signal din_sync : std_logic := '0';   --only use this synchronised signal
  signal debounce_cnt : unsigned(integer(ceil(log2(real(G_N_CLKS_MAX)))) - 1 downto 0) := (others => '0');
  signal dout        : std_logic := '0';

  --Synthesis attributes for 2ff syncrhoniser
  attribute ASYNC_REG             : string;
  attribute ASYNC_REG of din_meta : signal is "TRUE";
  attribute ASYNC_REG of din_sync : signal is "TRUE";
begin

  -- Syncrhonise input asynchronous signal with 2ff
  p_sync_din : process(clk)
  begin
    if rising_edge(clk) then
      din_meta <= i_din;
      din_sync <= din_meta;
    end if;
  end process;
  
  p_debounce_input : process(clk)
  begin
    if rising_edge(clk) then
      --input is different to output, increment counter
      if din_sync /= dout then
        debounce_cnt <= debounce_cnt + 1;
        if debounce_cnt >= G_N_CLKS_MAX - 1 then
          debounce_cnt <= (others => '0');
          dout <= din_sync;
        end if;                  
      else
        debounce_cnt <= (others => '0');
      end if;
    end if;  
  end process;
  o_dout <= dout;
end architecture;
