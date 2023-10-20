library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- this block generates 8bits counter based on 10.24MHz clock
entity Counter is
	generic(
		COUNTER_BITS: integer := 8);
	port (
		clk_10M	 : in  std_logic;
		sync_reset : in	 std_logic;
		counter	 : out std_logic_vector (COUNTER_BITS-1 downto 0)
	);
end Counter;

architecture Behavioral of Counter is

    signal prev_res	: std_logic := '0';
    signal counter_s : std_logic_vector (COUNTER_BITS-1 downto 0) := (others => '0');
	 
begin

	counter <= counter_s;

	pCounter: process (clk_10M) begin
		if rising_edge(clk_10M) then
			prev_res <= sync_reset;
			if (sync_reset = '1' and prev_res = '0') then
				counter_s <= (others => '0');
			else
				counter_s <= counter_s + '1';
			end if;
		end if;
	end process;
	 
end Behavioral;