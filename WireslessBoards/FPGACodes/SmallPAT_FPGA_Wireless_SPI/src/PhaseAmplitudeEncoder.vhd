library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity PhaseAmplitudeEncoder is
	generic(COUNTER_BITS: integer := 8);
	port ( 
		clk_10M	 : in  std_logic;
		phase		 : in  std_logic_vector(COUNTER_BITS - 1 downto 0);
		amplitude : in  std_logic_vector(COUNTER_BITS - 1 downto 0);
		counter	 : in  std_logic_vector(COUNTER_BITS - 1 downto 0);
		data_out  : out std_logic );
end PhaseAmplitudeEncoder;

architecture Behavioral of PhaseAmplitudeEncoder is

	signal data_out_s	   : std_logic := '0';

	signal phase_d 	   : std_logic_vector(COUNTER_BITS - 1 downto 0) := (others=>'0');
	signal amplitude_d   : std_logic_vector(COUNTER_BITS - 1 downto 0) := (others=>'0');
	signal phase_10M 	   : std_logic_vector(COUNTER_BITS - 1 downto 0) := (others=>'0');
	signal amplitude_10M : std_logic_vector(COUNTER_BITS - 1 downto 0) := (others=>'0');
	
	signal phase_s		   : std_logic_vector(COUNTER_BITS downto 0) := (others=>'0');
	signal counter_s	   : std_logic_vector(COUNTER_BITS downto 0) := (others=>'0');
	signal end_count	   : std_logic_vector(COUNTER_BITS downto 0) := (others=>'0');
	
begin

	data_out <= data_out_s;

	process (clk_10M) begin 
		if (rising_edge(clk_10M)) then
			phase_s <= '0' & phase_10M;
			counter_s <= '0' & counter;
			end_count <= ('0' & phase_10M) + ('0' & amplitude_10M);
			
			if(((counter_s >= phase_s) and (counter_s < end_count)) or ((end_count(COUNTER_BITS) = '1') and (counter_s(COUNTER_BITS - 1 downto 0) < end_count(COUNTER_BITS - 1 downto 0)))) then
				data_out_s <= '1';
			else
				data_out_s <= '0';
			end if;
						
			phase_d <= phase;
			amplitude_d <= amplitude;
			phase_10M <= phase_d;
			amplitude_10M <= amplitude_d;
		end if;
	end process;

end Behavioral;

