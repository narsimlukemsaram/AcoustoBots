library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity SPIReceiver is
	port (
		CLK     : in  STD_LOGIC;
		SCLK    : in  STD_LOGIC; -- SPI Clock
		SS      : in  STD_LOGIC; -- Slave Select (active low)
		MOSI    : in  STD_LOGIC; -- Master Out Slave In
		MISO    : out STD_LOGIC; -- Master In Slave Out
		Rx_en   : out STD_LOGIC;
		Rx_byte : out STD_LOGIC_VECTOR (7 downto 0);
		Debug	  : out STD_LOGIC_VECTOR (3 downto 0));
end SPIReceiver;

architecture Behavioral of SPIReceiver is
    type State_Type is (Idle, Receive, Update);
    signal state : State_Type := Idle;
    signal spi_counter : integer range 0 to 7 := 7;
    signal temp_Data : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
    signal enable_temp : STD_LOGIC := '0';
    signal received_data_temp : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');

    signal debug_s : STD_LOGIC_VECTOR (3 downto 0) := (others => '0');
    
    -- Synchronization flip-flops
    signal received_data_sync1, received_data_sync2 : STD_LOGIC_VECTOR (7 downto 0);
    signal enable_sync1, enable_sync2, enable_sync3 : STD_LOGIC := '0';


    signal rx_byte_s : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
    signal rx_en_s	: STD_LOGIC := '0';

		 
begin
	Rx_byte 	<= rx_byte_s;
	Rx_en 	<= rx_en_s;
	MISO 		<= 'Z';
	Debug		<= debug_s;
	
    -- Process for receiving data with SCLK
	process(SCLK) is
		begin
		if rising_edge(SCLK) then
			received_data_temp <= received_data_temp(6 downto 0) & MOSI;

			if SPI_Counter = 0 then
				SPI_Counter <= 7;
				enable_temp <= '1';
--				debug_s <= debug_s + '1';
			else
				SPI_Counter <= SPI_Counter - 1;
				enable_temp <= '0';
			end if;
		end if;
	end process;
 
	-- Process for syncing data with FPGA CLK
	process(CLK) is
		begin
			if rising_edge(CLK) then
				received_data_sync1 <= received_data_temp;
				enable_sync1 <= enable_temp;

				received_data_sync2 <= received_data_sync1;
				enable_sync2 <= enable_sync1;
				enable_sync3 <= enable_sync2;
				
				if(enable_sync2 = '1' and enable_sync3 = '0') then
					rx_byte_s <= received_data_sync2;
					rx_en_s <= '1';
				else
					rx_byte_s <= (others => '0');
					rx_en_s <= '0';
				end if;
				
				if(rx_en_s = '1') then
					debug_s <= received_data_sync2(3 downto 0);
				end if;
			end if;
	end process;

end Behavioral;
