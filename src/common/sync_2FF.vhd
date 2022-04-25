library IEEE;
use IEEE.std_logic_1164.all;

-- Single bit 2 flip flop syncroniser for crossing clock domains 
entity sync_2FF is
  port (
    clk   : in  std_logic;
    i_bit : in  std_logic;
    o_bit : out std_logic
    );
end entity;

architecture rtl of sync_2FF is
  -- Synchronisation flip flops 
  signal sync_ff_1 : std_logic := '0';
  signal sync_ff_2 : std_logic := '0';

  attribute ASYNC_REG              : string;
  attribute ASYNC_REG of sync_ff_1 : signal is "TRUE";
  attribute ASYNC_REG of sync_ff_2 : signal is "TRUE";
begin
  -- Synchronise input by double registering the signal
  p_sync : process (clk)
  begin
    if rising_edge(clk) then
      sync_ff_1 <= i_bit;
      sync_ff_2 <= sync_ff_1;
    end if;
  end process;
  o_bit <= sync_ff_2;
end;
