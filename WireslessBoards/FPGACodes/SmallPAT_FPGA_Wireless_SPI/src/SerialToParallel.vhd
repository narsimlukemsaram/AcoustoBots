library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity SerialToParallel is
	generic(
		NUM_OUTPUT	 : integer := 256;
		COUNTER_BITS : integer := 8 );
	port (
		clk		  : in  std_logic;
		enable	  : in  std_logic;
		flag		  : in  std_logic;
		data		  : in  std_logic_vector(COUNTER_BITS-1 downto 0);
		address	  : in  std_logic_vector(7 downto 0);
		swap		  : in  std_logic;
		phases	  : out std_logic_vector(COUNTER_BITS*NUM_OUTPUT- 1 downto 0) := (others => '0');
		amplitudes : out std_logic_vector(COUNTER_BITS*NUM_OUTPUT- 1 downto 0) := (others => '0')
	 );
end SerialToParallel;

architecture Behavioral of SerialToParallel is
	
	signal init_flag	  : std_logic := '1';
	
	signal phases_s	  : std_logic_vector(COUNTER_BITS*NUM_OUTPUT- 1 downto 0) := (others => '0');
	signal amplitudes_s : std_logic_vector(COUNTER_BITS*NUM_OUTPUT- 1 downto 0) := (others => '0');

	signal shift_p		  : std_logic_vector(COUNTER_BITS*NUM_OUTPUT- 1 downto 0) := (others => '0');
	signal shift_a	  	  : std_logic_vector(COUNTER_BITS*NUM_OUTPUT- 1 downto 0) := (others => '0');

begin

	phases	  <= phases_s;
	amplitudes <= amplitudes_s;
	
	process (clk) begin
		if (rising_edge(clk)) then
			if(init_flag = '1') then
				init_flag <= '0';
				for i in 0 to NUM_OUTPUT-1 loop
					amplitudes_s(COUNTER_BITS*i + COUNTER_BITS-1) <= '1';
					shift_a(COUNTER_BITS*i + COUNTER_BITS-1) <= '1';
				end loop;
			else
				if(swap = '1') then
					phases_s <= shift_p;
					amplitudes_s <= shift_a;
				end if;
				
				if(enable = '1') then
					if(flag = '0') then
						shift_p(COUNTER_BITS-1 downto 0) <= data;
						for i in 1 to NUM_OUTPUT-1 loop
							shift_p((i+1)*COUNTER_BITS-1 downto i*COUNTER_BITS) <= shift_p(i*COUNTER_BITS-1 downto (i-1)*COUNTER_BITS) ;
						end loop;
					else
						shift_a(COUNTER_BITS-1 downto 0) <= data;
						for i in 1 to NUM_OUTPUT-1 loop
							shift_a((i+1)*COUNTER_BITS-1 downto i*COUNTER_BITS) <= shift_a(i*COUNTER_BITS-1 downto (i-1)*COUNTER_BITS) ;
						end loop;				
					end if;
				end if;
			end if;
		end if;
	end process;

end Behavioral;
