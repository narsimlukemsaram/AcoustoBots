library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity DataDistributor is
	generic(
		NUM_OUTPUT	 : integer := 256;
		COUNTER_BITS : integer := 8 );
	port (
		clk	  : in  std_logic;
		rx_en	  : in  std_logic;
		rx_byte : in  std_logic_vector (7 downto 0);
		enable  : out std_logic;
		flag	  : out std_logic;
		data	  : out std_logic_vector (COUNTER_BITS-1 downto 0);
		address : out std_logic_vector (7 downto 0);
		swap	  : out std_logic
	 );
end DataDistributor;

architecture Behavioral of DataDistributor is
	
	type CommandState is (Idle, ReadPhases, ReadAmplitudes, Swapping);
	signal state : CommandState := Idle;

	signal prev_en   : std_logic := '0';	
	signal byteCount : std_logic_vector (7 downto 0) := (others => '0');
		
	signal enable_s  : std_logic := '0';
	signal flag_s	  : std_logic := '0';
	signal data_s	  : std_logic_vector (COUNTER_BITS-1 downto 0) := (others => '0');
	signal address_s : std_logic_vector (7 downto 0) := (others => '0');
	signal swap_s	  : std_logic := '0';

	signal reset	  : std_logic := '0';
	signal rstCount  : std_logic_vector (25 downto 0) := (others => '0');

begin

	enable  <= enable_s;
	flag	  <= flag_s;
	data	  <= data_s;
	address <= address_s;
	swap	  <= swap_s;

	process (clk) begin
		if (rising_edge(clk)) then
			if(reset = '1') then
				state <= Idle;
				byteCount <= (others => '0');
				enable_s <= '0';
				data_s <= (others => '0');
				address_s <= (others => '0');				
				flag_s <= '0';
				swap_s <= '0';	
			else
				case state is
					when Idle =>
						if (rx_en = '1' and rx_byte(7) = '1') then
							state <= ReadPhases;
							byteCount <= byteCount + '1';
							enable_s <= '1';
							data_s <= rx_byte(6 downto 0);
						else
							state <= Idle;
							byteCount <= (others => '0');
							enable_s <= '0';
							data_s <= (others => '0');
						end if;
						flag_s <= '0';
						address_s <= (others => '0');
						swap_s <= '0';								
					
					when ReadPhases =>
						if (rx_en = '1') then
							if (byteCount = NUM_OUTPUT - 1) then
								state <= ReadAmplitudes;
								byteCount <= (others => '0');
							else
								state <= ReadPhases;
								byteCount <= byteCount + '1';
							end if;
							enable_s <= '1';
							data_s <= rx_byte(6 downto 0);
							address_s <= byteCount;
						else
							enable_s <= '0';
							data_s <= (others => '0');
							address_s <= (others => '0');				
						end if;
						flag_s <= '0';
						swap_s <= '0';
					
					when ReadAmplitudes =>
						if (rx_en = '1') then
							if (byteCount = NUM_OUTPUT - 1) then
								state <= Swapping;
								byteCount <= (others => '0');
							else
								state <= ReadAmplitudes;
								byteCount <= byteCount + '1';
							end if;
							enable_s <= '1';
							data_s <= rx_byte(6 downto 0);
							address_s <= byteCount;
						else
							enable_s <= '0';
							data_s <= (others => '0');
							address_s <= (others => '0');				
						end if;
						flag_s <= '1';
						swap_s <= '0';					
					
					when Swapping =>
						state <= Idle;
						byteCount <= (others => '0');
						enable_s <= '0';
						data_s <= (others => '0');
						address_s <= (others => '0');				
						flag_s <= '0';
						swap_s <= '1';		
						
					when others =>
						state <= Idle;
				end case;
			end if;
							
			if(state = Idle) then
				rstCount <= (others => '0');
				reset <= '0';
			else
				if(rstCount = "10111110101111000001111111") then
					reset <= '1';
				else
					rstCount <= rstCount + '1';
				end if;
			end if;			
		end if;
	end process;

--	process (clk) begin
--		if (rising_edge(clk)) then	
--			prev_en <= rx_en;
--			case state is
--				when Idle => 
--					if (rx_en = '1' and prev_en = '0') then
--						if(rx_byte = "11111111") then			-- 255 is start reading phases
--							state <= ReadTransducers;
--							flag_s <= '0';
--							byteCount <= (others => '0');
--						elsif(rx_byte = "11111110") then		-- 254 is start reading amplitudes
--							state <= ReadTransducers;
--							flag_s <= '1';
--							byteCount <= (others => '0');
--						elsif(rx_byte = "11111101") then		-- 253 is swap transducers
--							state <= Idle;
--							swap_s <= '1';
--						else	-- other number tells us the number of frames
--							state <= Idle;
--						end if;
--					else
--						swap_s <= '0';
--					end if;
--					enable_s <= '0';
--					data_s <= (others => '0');
--					address_s <= (others => '0');					
--				
--				when ReadTransducers =>
--					if (rx_en = '1' and prev_en = '0') then
--						if (byteCount = NUM_OUTPUT - 1) then
--							state <= Idle;
--							byteCount <= (others => '0');
--						else
--							byteCount <= byteCount + '1';
--						end if;
--						enable_s <= '1';
--						data_s <= rx_byte(COUNTER_BITS-1 downto 0);
--						address_s <= byteCount;				
--					else
--						enable_s <= '0';
--						data_s <= (others => '0');
--						address_s <= (others => '0');
--					end if;
--					
--				when others =>
--				
--			end case;
--		end if;
--	end process;

end Behavioral;
