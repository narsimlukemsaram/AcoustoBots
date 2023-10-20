-- Testbench File for MAX(R) 10 FPGA Evaluation Kit or Intel(R) Cyclone(R) 10 LP FPGA Evaluation Kit ##

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library modelsim_lib;
use modelsim_lib.util.all;

entity holo_tb is
	generic ( 
		NUM_OUTPUT : integer := 37;	-- number of transducers (maximum - 256)
		COUNTER_BITS : integer := 7;	-- resolution of the phase (0-255 when this value is maximum value, 8)
		CLKS_PER_BIT : integer := 4	-- determine the baudrate (baudrate = 50M / CLKS_PER_BIT)
	);
end holo_tb;

architecture rtl of holo_tb is
	component Masterclock is
		port (
			inclk0 : in  std_logic;
			c0 	 : out std_logic );	-- 40k * 256 = 10.24MHz 
	end component;

	component Counter is
		generic (
			COUNTER_BITS: integer := 8 );
		port (
			clk_10M 	  : in  std_logic;
			sync_reset : in  std_logic;
			counter	  : out std_logic_vector (COUNTER_BITS-1 downto 0) );
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
   signal counter_256 : std_logic_vector(COUNTER_BITS-1 downto 0) := (others => '0');
	
	signal rx_en		 : std_logic := '0';
   signal rx_byte		 : std_logic_vector(7 downto 0) := (others => '0');
	
	signal enable		 : std_logic := '0';
	signal flag			 : std_logic := '0';
   signal data			 : std_logic_vector(COUNTER_BITS-1 downto 0) := (others => '0');
   signal address		 : std_logic_vector(7 downto 0) := (others => '0');
	signal swap			 : std_logic := '0';


	signal CLK	: std_logic := '0';
	signal LED	: std_logic_vector (3 downto 0);
	signal OUTPUTS	: std_logic_vector (NUM_OUTPUT - 1 downto 0);
	signal REF	: std_logic := '0';

   signal q				 : std_logic_vector(7 downto 0) := (others => '0');
   signal offset		 : std_logic_vector(7 downto 0) := (others => '0');

   -- Clock period definitions
   constant CLK_period : time := 20 ns;

begin

	-- Instantiate the Unit Under Test (UUT) 
	OUTPUTS <= outputs_s;
	REF  <= counter_256(COUNTER_BITS-1);
	
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
			counter	  => counter_256 );

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
			counter => counter_256,
			enable  => enable,
			flag	  => flag,
			data	  => data,
			address => address,
			swap	  => swap,
			outputs => outputs_s );

			
	-- Clock process definitions
   CLK_process :process
   begin
		clk <= '0';
		wait for CLK_period/2;
		clk <= '1';
		wait for CLK_period/2;
   end process;
 
   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	

				wait for CLK_period*16;
		rx_byte <= "11111111";
		rx_en <= '1';
		wait for CLK_period;
		rx_byte <= (others => '0');
		rx_en <= '0';
		offset <= "00000000";
		wait for CLK_period*4;
		for i in 0 to NUM_OUTPUT-1 loop
			rx_byte <= q - offset;
			rx_en <= '1';
			wait for CLK_period;
			rx_byte <= (others => '0');
			rx_en <= '0';
			q <= q + '1';
			wait for CLK_period*4;
		end loop;
		wait for CLK_period*12;
		rx_byte <= "11111101";
		rx_en <= '1';
		wait for CLK_period;
		rx_byte <= (others => '0');
		rx_en <= '0';
		
			
		--wait for 74480 ns;
		wait for 5000 ns;
		rx_byte <= "11111111";
		rx_en <= '1';
		wait for CLK_period;
		rx_byte <= (others => '0');
		rx_en <= '0';
		offset <= "00000100";
		wait for CLK_period*4;
		for i in 0 to NUM_OUTPUT-1 loop
			rx_byte <= q - offset;
			rx_en <= '1';
			wait for CLK_period;
			rx_byte <= (others => '0');
			rx_en <= '0';
			q <= q + '1';
			wait for CLK_period*4;
		end loop;
		wait for CLK_period*12;
		rx_byte <= "11111101";
		rx_en <= '1';
		wait for CLK_period;
		rx_byte <= (others => '0');
		rx_en <= '0';
		
			
		wait for 74480 ns;
		rx_byte <= "11111111";
		rx_en <= '1';
		wait for CLK_period;
		rx_byte <= (others => '0');
		rx_en <= '0';
		offset <= "00001000";
		wait for CLK_period*4;
		for i in 0 to NUM_OUTPUT-1 loop
			rx_byte <= q - offset;
			rx_en <= '1';
			wait for CLK_period;
			rx_byte <= (others => '0');
			rx_en <= '0';
			q <= q + '1';
			wait for CLK_period*4;
		end loop;
		wait for CLK_period*12;
		rx_byte <= "11111101";
		rx_en <= '1';
		wait for CLK_period;
		rx_byte <= (others => '0');
		rx_en <= '0';		
		
			
		wait for 74480 ns;
		rx_byte <= "11111111";
		rx_en <= '1';
		wait for CLK_period;
		rx_byte <= (others => '0');
		rx_en <= '0';
		offset <= "00001100";
		wait for CLK_period*4;
		for i in 0 to NUM_OUTPUT-1 loop
			rx_byte <= q - offset;
			rx_en <= '1';
			wait for CLK_period;
			rx_byte <= (others => '0');
			rx_en <= '0';
			q <= q + '1';
			wait for CLK_period*4;
		end loop;
		wait for CLK_period*12;
		rx_byte <= "11111101";
		rx_en <= '1';
		wait for CLK_period;
		rx_byte <= (others => '0');
		rx_en <= '0';			
		
			
		wait for 74480 ns;
		rx_byte <= "11111111";
		rx_en <= '1';
		wait for CLK_period;
		rx_byte <= (others => '0');
		rx_en <= '0';
		offset <= "00010000";
		wait for CLK_period*4;
		for i in 0 to NUM_OUTPUT-1 loop
			rx_byte <= q - offset;
			rx_en <= '1';
			wait for CLK_period;
			rx_byte <= (others => '0');
			rx_en <= '0';
			q <= q + '1';
			wait for CLK_period*4;
		end loop;
		wait for CLK_period*12;
		rx_byte <= "11111101";
		rx_en <= '1';
		wait for CLK_period;
		rx_byte <= (others => '0');
		rx_en <= '0';
		
			
		wait for 74480 ns;
		rx_byte <= "11111111";
		rx_en <= '1';
		wait for CLK_period;
		rx_byte <= (others => '0');
		rx_en <= '0';
		offset <= "00010100";
		wait for CLK_period*4;
		for i in 0 to NUM_OUTPUT-1 loop
			rx_byte <= q + offset;
			rx_en <= '1';
			wait for CLK_period;
			rx_byte <= (others => '0');
			rx_en <= '0';
			q <= q + '1';
			wait for CLK_period*4;
		end loop;
		wait for CLK_period*12;
		rx_byte <= "11111101";
		rx_en <= '1';
		wait for CLK_period;
		rx_byte <= (others => '0');
		rx_en <= '0';
		
			
		wait for 74480 ns;
		rx_byte <= "11111111";
		rx_en <= '1';
		wait for CLK_period;
		rx_byte <= (others => '0');
		rx_en <= '0';
		offset <= "00011000";
		wait for CLK_period*4;
		for i in 0 to NUM_OUTPUT-1 loop
			rx_byte <= q + offset;
			rx_en <= '1';
			wait for CLK_period;
			rx_byte <= (others => '0');
			rx_en <= '0';
			q <= q + '1';
			wait for CLK_period*4;
		end loop;
		wait for CLK_period*12;
		rx_byte <= "11111101";
		rx_en <= '1';
		wait for CLK_period;
		rx_byte <= (others => '0');
		rx_en <= '0';
		
			
		wait for 74480 ns;
		rx_byte <= "11111111";
		rx_en <= '1';
		wait for CLK_period;
		rx_byte <= (others => '0');
		rx_en <= '0';
		offset <= "00011100";
		wait for CLK_period*4;
		for i in 0 to NUM_OUTPUT-1 loop
			rx_byte <= q + offset;
			rx_en <= '1';
			wait for CLK_period;
			rx_byte <= (others => '0');
			rx_en <= '0';
			q <= q + '1';
			wait for CLK_period*4;
		end loop;
		wait for CLK_period*12;
		rx_byte <= "11111101";
		rx_en <= '1';
		wait for CLK_period;
		rx_byte <= (others => '0');
		rx_en <= '0';
		
      wait;
   end process;
	
end rtl;