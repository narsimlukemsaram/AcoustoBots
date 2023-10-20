library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- this bolock generates final signals to send the transducers
entity SignalGenerator is
   generic (
		NUM_OUTPUT	 : integer := 256;
		COUNTER_BITS : integer := 8 );	
	port (
		clk	  : in  std_logic;
		clk_10M : in  std_logic;
		counter : in  std_logic_vector (COUNTER_BITS - 1 downto 0);
		enable  : in  std_logic;
		flag	  : in  std_logic;
		data	  : in  std_logic_vector (COUNTER_BITS-1 downto 0);
		address : in  std_logic_vector (7 downto 0);
		swap	  : in  std_logic;
		outputs : out std_logic_vector (NUM_OUTPUT-1 downto 0)
	);
end SignalGenerator;

architecture Behavioral of SignalGenerator is

component SerialToParallel is
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
		amplitudes : out std_logic_vector(COUNTER_BITS*NUM_OUTPUT- 1 downto 0) := (others => '0') );
end component;

component PhaseAmplitudeEncoder
   generic (
		COUNTER_BITS: integer := 8 );	
	port ( 
		clk_10M	 : in  std_logic;
		phase		 : in  std_logic_vector(COUNTER_BITS - 1 downto 0);
		amplitude : in  std_logic_vector(COUNTER_BITS - 1 downto 0);
		counter	 : in  std_logic_vector(COUNTER_BITS - 1 downto 0);
		data_out  : out std_logic );
end component;
		
	signal outputs_s	 : std_logic_vector (NUM_OUTPUT - 1 downto 0) := (others => '0');

	signal phases		 : std_logic_vector (COUNTER_BITS*NUM_OUTPUT- 1 downto 0) := (others => '0');
	signal amplitudes  : std_logic_vector (COUNTER_BITS*NUM_OUTPUT- 1 downto 0) := (others => '0');

begin
	
	outputs <= outputs_s;
		
	inst_SerialToParallel : SerialToParallel
	   generic map (
			NUM_OUTPUT	 => NUM_OUTPUT,
			COUNTER_BITS => COUNTER_BITS )
		port map (
			clk		  => clk,
			enable 	  => enable,
			flag	 	  => flag,
			data	 	  => data,
			address	  => address,
			swap	 	  => swap,
			phases	  => phases,
			amplitudes => amplitudes );
	
	PhaseAmplitudeEncoders : for i in 0 to (NUM_OUTPUT-1) generate
	begin
		inst_PhaseAmplitudeEncoder : PhaseAmplitudeEncoder
			generic map (
				COUNTER_BITS => COUNTER_BITS )
			port map (
				clk_10M 	 => clk_10M,
				phase	 	 => phases((NUM_OUTPUT-i)*COUNTER_BITS-1 downto (NUM_OUTPUT-i-1)*COUNTER_BITS),
				amplitude => amplitudes((NUM_OUTPUT-i)*COUNTER_BITS-1 downto (NUM_OUTPUT-i-1)*COUNTER_BITS),
				counter	 => counter,		   
				data_out  => outputs_s(i) );
	end generate PhaseAmplitudeEncoders;

end Behavioral;