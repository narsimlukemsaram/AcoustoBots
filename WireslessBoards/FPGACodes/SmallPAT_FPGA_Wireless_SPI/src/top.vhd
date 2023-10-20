library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity top is
	generic ( 
		NUM_OUTPUT	 : integer := 64;	-- number of transducers (maximum - 256)
		COUNTER_BITS : integer := 7;	-- resolution of the phase (0-255 when this value is maximum value, 8)
		CLKS_PER_BIT : integer := 25	-- determine the baudrate (baudrate = 50M / CLKS_PER_BIT)
	);
	port (
		CLK			 : in  STD_LOGIC; -- 50MHz clock input

		SCLK		 	 : in  STD_LOGIC; -- PIN_34
		MOSI		 	 : in  STD_LOGIC; -- PIN_32
		MISO		 	 : out STD_LOGIC; -- PIN_30
		
		
		MS_SELECT	 : in  STD_LOGIC; -- '0' when it's the Master ('1' when it's a Slave)
		SYNC_MAIN	 : inout STD_LOGIC;
		MISC_SYNC	 : inout STD_LOGIC;
		
		OUTPUTS		 : out STD_LOGIC_VECTOR (NUM_OUTPUT - 1 downto 0);
		LED			 : out STD_LOGIC_VECTOR (3 downto 0); -- Outputs to the onboard LEDs (PIN 3, 7, 10, 11)

		DEBUG_39		 : out STD_LOGIC;
		DEBUG_43		 : out STD_LOGIC
		--DS_NOT_USED	 : inout STD_LOGIC_VECTOR (1 downto 0)
	);
end top;

architecture Behavioral of top is

	component Masterclock is
		port (
			inclk0 : in  std_logic;
			c0 	 : out std_logic );	-- 40k * 128 = 5.12MHz 
	end component;

	component Counter is
		generic (
			COUNTER_BITS: integer := 8 );
		port (
			clk_10M 	  : in  std_logic;
			sync_reset : in  std_logic;
			counter	  : out std_logic_vector (COUNTER_BITS-1 downto 0) );
	end component;

	component SPIReceiver is
		port (
			CLK     : in  STD_LOGIC;
			SCLK    : in  STD_LOGIC; -- SPI Clock
			SS      : in  STD_LOGIC; -- Slave Select (active low)
			MOSI    : in  STD_LOGIC; -- Master Out Slave In
			MISO    : out STD_LOGIC; -- Master In Slave Out
			Rx_en   : out STD_LOGIC;
			Rx_byte : out STD_LOGIC_VECTOR (7 downto 0);
			Debug	  : out STD_LOGIC_VECTOR (3 downto 0));
	end component;

	component SPIReceiver2 is
		port (
			CLK     : in  STD_LOGIC;
			SCLK    : in  STD_LOGIC; -- SPI Clock
			SS      : in  STD_LOGIC; -- Slave Select (active low)
			MOSI    : in  STD_LOGIC; -- Master Out Slave In
			MISO    : out STD_LOGIC; -- Master In Slave Out
			Rx_en   : out STD_LOGIC;
			Rx_byte : out STD_LOGIC_VECTOR (7 downto 0);
			Debug	  : out STD_LOGIC_VECTOR (3 downto 0));
	end component;
	
	component DataDistributor is
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
	end component;
	
	component SignalGenerator is
		generic (
			NUM_OUTPUT	 : integer := 256;
			COUNTER_BITS : integer := 8 );	
		port (
			clk	  : in  std_logic;
			clk_10M : in  std_logic;
			counter : in  std_logic_vector (COUNTER_BITS-1 downto 0);
			enable  : in  std_logic;
			flag	  : in  std_logic;
			data	  : in  std_logic_vector (COUNTER_BITS-1 downto 0);
			address : in  std_logic_vector (7 downto 0);
			swap	  : in  std_logic;
			outputs : out std_logic_vector (NUM_OUTPUT-1 downto 0) );
	end component;

   signal outputs_s	 : std_logic_vector(NUM_OUTPUT - 1 downto 0) := (others => '0');
	signal led_s		 : std_logic_vector (3 downto 0) := (others => '0');

   signal clk_10M		 : std_logic := '0';
	signal sync_reset	 : std_logic := '0';
   signal counter_40k : std_logic_vector(COUNTER_BITS-1 downto 0) := (others => '0');
	
	signal rx_en		 : std_logic := '0';
   signal rx_byte		 : std_logic_vector(7 downto 0) := (others => '0');
	signal debug		 : std_logic_vector(3 downto 0) := (others => '0');

	signal enable		 : std_logic := '0';
	signal flag			 : std_logic := '0';
   signal data			 : std_logic_vector(COUNTER_BITS-1 downto 0) := (others => '0');
   signal address		 : std_logic_vector(7 downto 0) := (others => '0');
	signal swap			 : std_logic := '0';

	signal old_rx		 : std_logic := '0';
	
begin
	
	OUTPUTS <= outputs_s;
	
	SYNC_MAIN  <= counter_40k(COUNTER_BITS-1) when MS_SELECT = '0' else 'Z';
	MISC_SYNC  <= counter_40k(COUNTER_BITS-1) when MS_SELECT = '0' else 'Z';
	LED(3) <= 'Z';
	LED(2) <= 'Z';
	LED(1 downto 0) <= not debug(1 downto 0);
--	LED <= not debug;

	DEBUG_39 <= SCLK;
	DEBUG_43 <= MOSI;
	
	sync_reset <= '0' when MS_SELECT = '0' else SYNC_MAIN;
	inst_Masterclock : Masterclock 
		port map (
			inclk0 => clk,
			c0		 => clk_10M );

	inst_Counter : Counter 
	   generic map (
			COUNTER_BITS => COUNTER_BITS )
		port map (
			clk_10M	  => clk_10M,
			sync_reset => sync_reset,
			counter	  => counter_40k );

	inst_SPIReceiver : SPIReceiver2
		port map (
			Clk	  => CLk,
			SCLK	  => SCLK,
			SS		  => '0', -- active low
			MOSI 	  => MOSI,
			MISO	  => MISO,
			Rx_en	  => rx_en,
			Rx_byte => rx_byte,
			Debug	  => debug );

	inst_DataDistributor : DataDistributor 
	   generic map (
			NUM_OUTPUT	 => NUM_OUTPUT,
			COUNTER_BITS => COUNTER_BITS )
		port map (
			clk	  => clk,
			rx_en	  => rx_en,
			rx_byte => rx_byte,
			enable  => enable,
			flag	  => flag,
			data	  => data,
			address => address,
			swap	  => swap );
			
	inst_SignalGenerator : SignalGenerator
	   generic map (
			NUM_OUTPUT	 => NUM_OUTPUT,
			COUNTER_BITS => COUNTER_BITS )
		port map (
			clk	  => clk,
			clk_10M => clk_10M,
			counter => counter_40k,
			enable  => enable,
			flag	  => flag,
			data	  => data,
			address => address,
			swap	  => swap,
			outputs => outputs_s );

end Behavioral;