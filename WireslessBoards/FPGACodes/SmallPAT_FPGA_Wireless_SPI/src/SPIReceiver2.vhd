library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity SPIReceiver2 is
	port (
		CLK     : in  STD_LOGIC;
		SCLK    : in  STD_LOGIC; -- SPI Clock
		SS      : in  STD_LOGIC; -- Slave Select (active low)
		MOSI    : in  STD_LOGIC; -- Master Out Slave In
		MISO    : out STD_LOGIC; -- Master In Slave Out
		Rx_en   : out STD_LOGIC;
		Rx_byte : out STD_LOGIC_VECTOR (7 downto 0);
		Debug	  : out STD_LOGIC_VECTOR (3 downto 0));
end SPIReceiver2;

architecture RTL of SPIReceiver2 is


    signal sclk_meta	  : STD_LOGIC := '0';
    signal mosi_meta	  : STD_LOGIC := '0';
    signal sclk_reg	  : STD_LOGIC := '0';
    signal mosi_reg	  : STD_LOGIC := '0';

    signal spi_clk_reg : STD_LOGIC := '0';
    signal spi_clk_fedge_en : STD_LOGIC := '0';
    signal spi_clk_redge_en : STD_LOGIC := '0';

    signal bit_cnt_max	: STD_LOGIC := '0';
    signal bit_cnt		: STD_LOGIC_VECTOR (7 downto 0) := (others => '0');

    signal last_bit_en	: STD_LOGIC := '0';

    signal rx_data_vld	: STD_LOGIC := '0';
    signal data_shreg	: STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
	
    signal debug_s		: STD_LOGIC_VECTOR (3 downto 0) := (others => '0');
	 
    signal ready_n		: STD_LOGIC := '0';
    signal ready_cnt		: STD_LOGIC_VECTOR (25 downto 0) := (others => '0');
    signal reset_cnt		: STD_LOGIC_VECTOR (25 downto 0) := (others => '0');
    	
begin
	Rx_byte 	<= data_shreg;
	Rx_en 	<= rx_data_vld;
	MISO 		<= 'Z';
	Debug		<= debug_s;
	
	debug_p : process (CLK)
	begin
		if (rising_edge(CLK)) then
			if(rx_data_vld = '1') then
				debug_s <= data_shreg(3 downto 0);
			end if;
		end if;
	end process;
	
	
    -- Synchronization registers to eliminate possible metastability.
	sync_ffs_p : process(CLK)
	begin
		if rising_edge(CLK) then
			sclk_meta <= SCLK;
			mosi_meta <= MOSI;
			sclk_reg <= sclk_meta;
			mosi_reg <= mosi_meta;
		end if;
	end process;
 	
	-- The SPI clock register is necessary for clock edge detection.
	spi_clk_reg_p : process (CLK)
	begin
		if (rising_edge(CLK)) then
			spi_clk_reg <= sclk_reg;
		end if;
	end process;	
	
	-- Falling edge is detect when sclk_reg=0 and spi_clk_reg=1.
	spi_clk_fedge_en <= not sclk_reg and spi_clk_reg;
	-- Rising edge is detect when sclk_reg=1 and spi_clk_reg=0.
	spi_clk_redge_en <= sclk_reg and not spi_clk_reg;


	-- The counter counts received bits from the master. Counter is enabled when
	-- falling edge of SPI clock is detected and not asserted cs_n_reg.
	bit_cnt_p : process (CLK)
	begin
		if (rising_edge(CLK)) then
			if (spi_clk_fedge_en = '1' and ready_n = '0') then
				if (bit_cnt_max = '1') then
					bit_cnt <= (others => '0');
				else
					bit_cnt <= bit_cnt + 1;
				end if;
				reset_cnt <= (others => '0');
			else
				if (reset_cnt = "10111110101111000001111111") then
					bit_cnt <= (others => '0');
					reset_cnt <= (others => '0');
				else
					reset_cnt <= reset_cnt + '1';
				end if;
			end if;
		end if;
	end process;

	-- The flag of maximal value of the bit counter.
	bit_cnt_max <= '1' when (bit_cnt = 7) else '0';
	

	-- The flag of last bit of received byte is only registered the flag of
	-- maximal value of the bit counter.
	last_bit_en_p : process (CLK)
	begin
		if (rising_edge(CLK)) then
			last_bit_en <= bit_cnt_max;
		end if;
	end process;	
	
	-- Received data from master are valid when falling edge of SPI clock is
	-- detected and the last bit of received byte is detected.
	rx_data_vld <= spi_clk_fedge_en and last_bit_en;

	-- The shift register holds data for sending to master, capture and store
	-- incoming data from master.
	data_shreg_p : process (CLK)
	begin
		if (rising_edge(CLK)) then
			if (spi_clk_redge_en = '1' and ready_n = '0') then
				data_shreg <= data_shreg(6 downto 0) & mosi_reg;
			end if;
		end if;
	end process;
	
	-- Counting several sec to enable to read
	ready_counter_p : process (CLK)
	begin
		if (rising_edge(CLK)) then
			if (ready_cnt = "10111110101111000001111111") then
				ready_n <= '0';
			else
				ready_cnt <= ready_cnt + '1';
			end if;
		end if;
	end process;

end RTL;
