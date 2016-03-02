----------------------------------------------------------------------------------
-- Company: LNF - INFN
-- Authors: Albicocco Pietro
-- Contact: pietro.albicocco@lnf.infn.it
----------------------------------------------------------------------------------
-- File Name: auxbus.vhd
-- Target Devices: Xilinx - 7 Series
-- Tool Versions: VIVADO 2015.2
-- Description: AUXBUS Slave Implementation
-- 
-- Dependencies: 
--
----------------------------------------------------------------------------------
-- Revision History:
-- Revision 1.0 - Albicocco P. - First Version
----------------------------------------------------------------------------------
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity auxbus is
Generic (
    clock_period : integer := 10
    );
Port (
  -------- SYSTEM SIGNALS -------
  -- System clock
  clk : in STD_LOGIC;
  clk2x : in STD_LOGIC;
  -- System reset
  rst : in STD_LOGIC;
  -------- A FIFO Interface -------
  A_Wr_clk      : in STD_LOGIC;
  A_Din         : in STD_LOGIC_VECTOR(22-1 DOWNTO 0);
  A_Wr_en       : in STD_LOGIC;
  A_Full        : out STD_LOGIC;
  A_Almost_full : out STD_LOGIC;
  -------- B FIFO Interface -------
  B_Wr_clk      : in STD_LOGIC;
  B_Din         : in STD_LOGIC_VECTOR(22-1 DOWNTO 0);
  B_Wr_en       : in STD_LOGIC;
  B_Full        : out STD_LOGIC;
  B_Almost_full : out STD_LOGIC;
  -------- ROCK OUTPUT -------
  -- Trigger Bus, first valid trigger is 001
  xt : in STD_LOGIC_VECTOR (11 downto 0);
  -- Trigger Bus Data is valide, Active LOW
  xtrgv_n : in STD_LOGIC;
  -- Address Bus
  xa : in STD_LOGIC_VECTOR (3 downto 0);
  -- Address Bus is Valid
  xas_n : in STD_LOGIC;
  -- ROCK ready to read from slave, Active LOW
  -- ROCK finished to read from slave, Active HIGH
  xds : in STD_LOGIC;
  -- Master is initiating a synch check, Active LOW
  xsyncrd_n : in STD_LOGIC;
  -- ROCK send a system HALT due to Error,
  xsyshalt : in STD_LOGIC;
  -- ROCK produces a create level AUX reset
  xsysreset : in STD_LOGIC;
  -------- ROCK OPEN COLLECOTR INPUT -------
  -- Slave xsds bit is valid, Active HIGH
  xbk : out STD_LOGIC;
  -- Slave has an error, Active LOW
  xberr_n : out STD_LOGIC;
  -- Slave is full, Active LOW
  xbusy_n : out STD_LOGIC;
  -------- ROCK TRISTATE INPUT -------
  -- Slave data is valid, Active LOW
  -- Slave recognized Master finished cycle, Active HIGH
  xdk : out STD_LOGIC;
  -- Actual Slave Data Word is the last, Active LOW
  xeob_n : out STD_LOGIC;
  -- Slave Data
  xd : out STD_LOGIC_VECTOR (19 downto 0);
  -- Slave has data for a given Trigger Number
  -- Can be either tristate or always enabled
  xsds : out STD_LOGIC;
  -------- BACKPLANE HARDWIRED INPUT -------
  -- Slave Geographical Address
  sa : in STD_LOGIC_VECTOR (3 downto 0)
);
end auxbus;

architecture rtl of auxbus is
------------------------------------------------------------------
---- COMPONENTS DECLARATION----
------------------------------------------------------------------
--------------------
-- xFIFO
--------------------
-- 2 FIFO receiving data from AFE.
--------------------
component xfifo is
Port (
  Rst           : in STD_LOGIC;
  Rd_clk        : in STD_LOGIC;
  -------- A FIFO Interface -------
  A_Wr_clk      : in STD_LOGIC;
  A_Din         : in STD_LOGIC_VECTOR(22-1 DOWNTO 0);
  A_Wr_en       : in STD_LOGIC;
  A_Full        : out STD_LOGIC;
  A_Almost_full : out STD_LOGIC;
  A_Rd_en       : in STD_LOGIC;
  A_Dout        : out STD_LOGIC_VECTOR(22-1 DOWNTO 0);
  A_Empty       : out STD_LOGIC;
  A_Valid       : out STD_LOGIC;
  -------- B FIFO Interface -------
  B_Wr_clk      : in STD_LOGIC;
  B_Din         : in STD_LOGIC_VECTOR(22-1 DOWNTO 0);
  B_Wr_en       : in STD_LOGIC;
  B_Full        : out STD_LOGIC;
  B_Almost_full : out STD_LOGIC;
  B_Rd_en       : in STD_LOGIC;
  B_Dout        : out STD_LOGIC_VECTOR(22-1 DOWNTO 0);
  B_Empty       : out STD_LOGIC;
  B_Valid       : out STD_LOGIC
);
end component;
--------------------
-- xCTRL
--------------------
-- xCTRL provide data saved in FIFO to the auxbus when requested.
--------------------
component xctrl is
Port (
  clk      : in  STD_LOGIC;
  rst      : in  STD_LOGIC;
  -- A FIFO Side
  a_d      : in  STD_LOGIC_VECTOR(21 downto 0);
  a_dv     : in  STD_LOGIC;
  a_rd_en  : out STD_LOGIC;
  -- B FIFO Side
  b_d      : in  STD_LOGIC_VECTOR(21 downto 0);
  b_dv     : in  STD_LOGIC;
  b_rd_en  : out STD_LOGIC;
  -- AUXBUS Side
  -- Data, Data Valid, Last Event Data and New Event or Data Request
  x_d      : buffer STD_LOGIC_VECTOR(19 downto 0);
  x_dv     : out STD_LOGIC;
  x_last   : out STD_LOGIC;
  x_rd_en  : in  STD_LOGIC;
  -- Header Number and Header Number Valid (Valid is asserted when related data is ready)
  x_hdr_d  : buffer STD_LOGIC_VECTOR(19 downto 0);
  x_hdr_dv : out STD_LOGIC;
  -- Actual Header has no data 
  x_nodata : out STD_LOGIC;
  --Error: Header Number Mismatch between A and B FIFO
  x_mmatch : out STD_LOGIC
);
end component;
--------------------
-- xFRONT
--------------------
-- xFRONT manage the auxbus signals.
--------------------
component xfront is
Generic (
    clock_period : integer := 10
    );
Port (
  -------- SYSTEM SIGNALS -------
  -- System clock
  clk    : in STD_LOGIC;
  clk2x : in STD_LOGIC;
  -- System reset
  rst : in STD_LOGIC;
  -------- Control Interface -------
  -- Trigger Number
  i_t      : in  STD_LOGIC_VECTOR(11 downto 0);
  -- Trigger Number Data Valid
  i_tv     : in  STD_LOGIC;
  -- Trigger Number Request
  i_t_req  : out STD_LOGIC;
  -- Data, Data Valid, Last Event Data and New Event or Data Request
  i_d      : in  STD_LOGIC_VECTOR(19 downto 0);
  i_dv     : in  STD_LOGIC;
  i_last   : in  STD_LOGIC;
  i_rd_en  : out STD_LOGIC;
  -- Header Number and Header Number Valid (Valid is asserted when related data is ready)
  i_hdr_d  : in  STD_LOGIC_VECTOR(11 downto 0);
  i_hdr_dv : in  STD_LOGIC;
  -- Actual Header has no data 
  i_nodata : in  STD_LOGIC;
  --Error: Header Number Mismatch between A and B FIFO
  i_mmatch : in  STD_LOGIC;
  -- FIFO Full Flag, propagated and kept to xbusy
  i_full   : in  STD_LOGIC;
  -------- ROCK OUTPUT -------
  -- Trigger Bus, first valid trigger is 001
  xt : in STD_LOGIC_VECTOR (11 downto 0);
  -- Trigger Bus Data is valide, Active LOW
  xtrgv_n : in STD_LOGIC;
  -- Address Bus
  xa : in STD_LOGIC_VECTOR (3 downto 0);
  -- Address Bus is Valid
  xas_n : in STD_LOGIC;
  -- ROCK ready to read from slave, Active LOW
  -- ROCK finished to read from slave, Active HIGH
  xds : in STD_LOGIC;
  -- Master is initiating a synch check, Active LOW
  xsyncrd_n : in STD_LOGIC;
  -- ROCK send a system HALT due to Error,
  xsyshalt : in STD_LOGIC;
  -- ROCK produces a create level AUX reset
  xsysreset : in STD_LOGIC;
  -------- ROCK OPEN COLLECOTR INPUT -------
  -- Slave xsds bit is valid, Active HIGH
  xbk : out STD_LOGIC;
  -- Slave has an error, Active LOW
  xberr_n : out STD_LOGIC;
  -- Slave is full, Active LOW
  xbusy_n : out STD_LOGIC;
  -------- ROCK TRISTATE INPUT -------
  -- Slave data is valid, Active LOW
  -- Slave recognized Master finished cycle, Active HIGH
  xdk : out STD_LOGIC;
  -- Actual Slave Data Word is the last, Active LOW
  xeob_n : out STD_LOGIC;
  -- Slave Data
  xd : out STD_LOGIC_VECTOR (19 downto 0);
  -- Slave has data for a given Trigger Number
  -- Can be either tristate or always enabled
  xsds : out STD_LOGIC;
  -------- BACKPLANE HARDWIRED INPUT -------
  -- Slave Geographical Address
  sa : in STD_LOGIC_VECTOR (3 downto 0)
);
end component;
------------------------------------------------------------------
---- SIGNALS DECLARATION ----
------------------------------------------------------------------
--------------------
-- xFIFO
--------------------
-- FIFOs' reset
signal xfifo_reset : std_logic;
-- A FIFO Side
signal a_d      :  STD_LOGIC_VECTOR(21 downto 0);
signal a_dv     :  STD_LOGIC;
signal a_rd_en  :  STD_LOGIC;
signal afull    :  STD_LOGIC;
signal aafull    :  STD_LOGIC;
-- B FIFO Side
signal b_d      :  STD_LOGIC_VECTOR(21 downto 0);
signal b_dv     :  STD_LOGIC;
signal b_rd_en  :  STD_LOGIC;
signal bfull    :  STD_LOGIC;
signal bafull    :  STD_LOGIC;
--------------------
-- xCTRL
--------------------
-- xCTRL reset
signal xctrl_reset : std_logic;
-------- Control Interface -------
-- Data, Data Valid, Last Event Data and New Event or Data Request
signal d      :  STD_LOGIC_VECTOR(19 downto 0);
signal dv     :  STD_LOGIC;
signal last   :  STD_LOGIC;
signal rd_en  :  STD_LOGIC;
-- Header Number and Header Number Valid (Valid is asserted when related data is ready)
signal hdr_d  :  STD_LOGIC_VECTOR(19 downto 0);
signal hdr_dv :  STD_LOGIC;
-- Actual Header has no data 
signal nodata :  STD_LOGIC;
--Error: Header Number Mismatch between A and B FIFO
signal mmatch :  STD_LOGIC;
-- FIFO Full Flag, propagated and kept to xbusy
signal full    :  STD_LOGIC;
--------------------
-- xFRONT
--------------------
-- xFRONT' reset
signal xfront_reset : std_logic;

begin
--------------------
-- xFIFO
--------------------
xfifo_reset   <= '0';
A_Full        <= afull;
B_Full        <= bfull;
A_Almost_full <= aafull;
B_Almost_full <= bafull;
xfifo_inst: xfifo
Port Map(
  Rst           => xfifo_reset,
  Rd_clk        => clk,
  -------- A FIFO Interface -------
  A_Wr_clk      => A_Wr_clk,
  A_Din         => A_Din,
  A_Wr_en       => A_Wr_en,
  A_Full        => afull,
  A_Almost_full => aafull,
  A_Rd_en       => a_rd_en,
  A_Dout        => a_d,
  A_Empty       => open,
  A_Valid       => a_dv,
  -------- B FIFO Interface -------
  B_Wr_clk      => B_Wr_clk,
  B_Din         => B_Din,
  B_Wr_en       => B_Wr_en,
  B_Full        => bfull,
  B_Almost_full => bafull,
  B_Rd_en       => b_rd_en,
  B_Dout        => b_d,
  B_Empty       => open,
  B_Valid       => b_dv
);
--------------------
-- xCTRL
--------------------
xctrl_reset <= '0';
xctrl_inst: xctrl
Port Map(
  clk           => clk,
  rst           => rst,
  -- A FIFO Side
  a_d           => a_d,
  a_dv          => a_dv,
  a_rd_en       => a_rd_en,
  -- B FIFO Side
  b_d           => b_d,
  b_dv          => b_dv,
  b_rd_en       => b_rd_en,
  -- AUXBUS Side
  -- Data, Data Valid, Last Event Data and New Event or Data Request
  x_d           => d,
  x_dv          => dv,
  x_last        => last,
  x_rd_en       => rd_en,
  -- Header Number and Header Number Valid (Valid is asserted when related data is ready)
  x_hdr_d       => hdr_d,
  x_hdr_dv      => hdr_dv,
  -- Actual Header has no data 
  x_nodata      => nodata,
  --Error: Header Number Mismatch between A and B FIFO
  x_mmatch      => mmatch
);
--------------------
-- xFRONT
--------------------
xfront_reset <= '0';
full         <= aafull or bafull;
xfront_inst: xfront
Generic Map(
  clock_period  => clock_period
  )
Port Map(
  -------- SYSTEM SIGNALS -------
  -- System clock
  clk           => clk,
  clk2x        => clk2x,
  -- System reset
  rst           => xfront_reset,
  -------- Control Interface -------
  -- Trigger Number
  i_t           => x"AAA", --(others =>'0'),
  -- Trigger Number Data Valid
  i_tv          => '1',
  -- Trigger Number Request
  i_t_req       => open,
  -- Data, Data Valid, Last Event Data and New Event or Data Request
  i_d           => d,
  i_dv          => dv,
  i_last        => last,
  i_rd_en       => rd_en,
  -- Header Number and Header Number Valid (Valid is asserted when related data is ready)
  i_hdr_d       => hdr_d(11 downto 0),
  i_hdr_dv      => hdr_dv,
  -- Actual Header has no data 
  i_nodata      => nodata,
  --Error: Header Number Mismatch between A and B FIFO; propagated to xberr
  i_mmatch      => mmatch,
  -- FIFO Full Flag, propagated and kept to xbusy
  i_full        => full,
  -------- ROCK OUTPUT -------
  -- Trigger Bus, first valid trigger is 001
  xt            => xt,
  -- Trigger Bus Data is valide, Active LOW
  xtrgv_n       => xtrgv_n,
  -- Address Bus
  xa            => xa,
  -- Address Bus is Valid
  xas_n         => xas_n,
  -- ROCK ready to read from slave, Active LOW
  -- ROCK finished to read from slave, Active HIGH
  xds           => xds,
  -- Master is initiating a synch check, Active LOW
  xsyncrd_n     => xsyncrd_n,
  -- ROCK send a system HALT due to Error,
  xsyshalt      => xsyshalt,
  -- ROCK produces a create level AUX reset
  xsysreset     => xsysreset,
  -------- ROCK OPEN COLLECOTR INPUT -------
  -- Slave xsds bit is valid, Active HIGH
  xbk           => xbk,
  -- Slave has an error, Active LOW
  xberr_n       => xberr_n,
  -- Slave is full, Active LOW
  xbusy_n       => xbusy_n,
  -------- ROCK TRISTATE INPUT -------
  -- Slave data is valid, Active LOW
  -- Slave recognized Master finished cycle, Active HIGH
  xdk           => xdk,
  -- Actual Slave Data Word is the last, Active LOW
  xeob_n        => xeob_n,
  -- Slave Data
  xd            => xd,
  -- Slave has data for a given Trigger Number
  -- Can be either tristate or always enabled
  xsds          => xsds,
  -------- BACKPLANE HARDWIRED INPUT -------
  -- Slave Geographical Address
  sa            => sa
);
end rtl;
----------------------------------------------------------------------------------
-- Company: LNF - INFN
-- Authors: Albicocco Pietro
-- Contact: pietro.albicocco@lnf.infn.it
----------------------------------------------------------------------------------
-- File Name: xfifo.vhd
-- Target Devices: Xilinx - 7 Series
-- Tool Versions: VIVADO 2015.2
-- Description: 2 FIFO receiving data from AFE.
-- 
-- Dependencies: 
--
----------------------------------------------------------------------------------
-- Revision History:
-- Revision 1.0 - Albicocco P. - First Version
----------------------------------------------------------------------------------
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity xfifo is
Port (
	Rst           : in STD_LOGIC;
	Rd_clk        : in STD_LOGIC;
  -------- A FIFO Interface -------
  A_Wr_clk      : in STD_LOGIC;
  A_Din         : in STD_LOGIC_VECTOR(22-1 DOWNTO 0);
  A_Wr_en       : in STD_LOGIC;
  A_Full        : out STD_LOGIC;
  A_Almost_full : out STD_LOGIC;
  A_Rd_en       : in STD_LOGIC;
  A_Dout        : out STD_LOGIC_VECTOR(22-1 DOWNTO 0);
  A_Empty       : out STD_LOGIC;
  A_Valid       : out STD_LOGIC;
  -------- B FIFO Interface -------
  B_Wr_clk      : in STD_LOGIC;
  B_Din         : in STD_LOGIC_VECTOR(22-1 DOWNTO 0);
  B_Wr_en       : in STD_LOGIC;
  B_Full        : out STD_LOGIC;
  B_Almost_full : out STD_LOGIC;
  B_Rd_en       : in STD_LOGIC;
  B_Dout        : out STD_LOGIC_VECTOR(22-1 DOWNTO 0);
  B_Empty       : out STD_LOGIC;
  B_Valid       : out STD_LOGIC
);
end xfifo;

architecture rtl of xfifo is
------------------------------------------------------------------
---- COMPONENTS DECLARATION ----
------------------------------------------------------------------
component xINFIFO
port (
  Rst         : in STD_LOGIC;
  Wr_clk      : in STD_LOGIC;
  Rd_clk      : in STD_LOGIC;
  Din         : in STD_LOGIC_VECTOR(22-1 DOWNTO 0);
  Wr_en       : in STD_LOGIC;
  Rd_en       : in STD_LOGIC;
  Dout        : out STD_LOGIC_VECTOR(22-1 DOWNTO 0);
  Full        : out STD_LOGIC;
  prog_full   : out STD_LOGIC;
  Empty       : out STD_LOGIC;
  Valid       : out STD_LOGIC
  );
end component;

begin

--------------------
-- AFIFO
--------------------
AFIFO: xINFIFO
port map(
  Rst         => Rst,
  Wr_clk      => A_Wr_clk,
  Rd_clk      => Rd_clk,
  Din         => A_Din,
  Wr_en       => A_Wr_en,
  Rd_en       => A_Rd_en,
  Dout        => A_Dout,
  Full        => A_Full,
  prog_full   => A_Almost_full,
  Empty       => A_Empty,
  Valid       => A_Valid
);
--------------------
-- BFIFO
--------------------
BFIFO: xINFIFO
port map(
  Rst         => Rst,
  Wr_clk      => B_Wr_clk,
  Rd_clk      => Rd_clk,
  Din         => B_Din,
  Wr_en       => B_Wr_en,
  Rd_en       => B_Rd_en,
  Dout        => B_Dout,
  Full        => B_Full,
  prog_full   => B_Almost_full,
  Empty       => B_Empty,
  Valid       => B_Valid
);

end rtl;

----------------------------------------------------------------------------------
-- Company: LNF - INFN
-- Authors: Albicocco Pietro
-- Contact: pietro.albicocco@lnf.infn.it
----------------------------------------------------------------------------------
-- File Name: xctrl.vhd
-- Target Devices: Xilinx - 7 Series
-- Tool Versions: VIVADO 2015.2
-- Description: 
-- xCTRL provide data saved in FIFO to the auxbus when requested.
-- 
-- Dependencies: 
--
----------------------------------------------------------------------------------
-- Revision History:
-- Revision 1.0 - Albicocco P. - First Version
----------------------------------------------------------------------------------
-- Additional Comments:
-- Data from FIFO:
--    a_d/b_d: 22 bit data
--      00&DATA| is data  , not last  , DATA
--      01&DATA| is data  , is  last  , DATA
--      10&EV_N| is header, data exist, EVENT NUMBER
--      11&EV_N| is header, no data   , EVENT NUMBER
--    a_dv/b_dv: data valid
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity xctrl is
Port (
	clk      : in  STD_LOGIC;
	rst      : in  STD_LOGIC;
	-- A FIFO Side
	a_d      : in  STD_LOGIC_VECTOR(21 downto 0);
	a_dv     : in  STD_LOGIC;
	a_rd_en  : out STD_LOGIC;
	-- B FIFO Side
  b_d      : in  STD_LOGIC_VECTOR(21 downto 0);
  b_dv     : in  STD_LOGIC;
  b_rd_en  : out STD_LOGIC;
	-- AUXBUS Side
	-- Data, Data Valid, Last Event Data and New Event or Data Request
	x_d      : buffer STD_LOGIC_VECTOR(19 downto 0);
	x_dv     : out STD_LOGIC;
	x_last   : out STD_LOGIC;
	x_rd_en  : in  STD_LOGIC;
	-- Header Number and Header Number Valid (Valid is asserted when related data is ready)
	x_hdr_d  : buffer STD_LOGIC_VECTOR(19 downto 0);
	x_hdr_dv : out STD_LOGIC;
	-- Actual Header has no data 
	x_nodata : out STD_LOGIC;
	--Error: Header Number Mismatch between A and B FIFO
	x_mmatch : out STD_LOGIC
);
end xctrl;

architecture rtl of xctrl is
------------------------------------------------------------------
---- CONSTANTS ----
------------------------------------------------------------------
constant RESET_STATE        : std_logic_vector (2 downto 0) := "000";
constant WAITAHEADER        : std_logic_vector (2 downto 0) := "001";
constant WAITBHEADER        : std_logic_vector (2 downto 0) := "010";
constant SEND_A_DATA        : std_logic_vector (2 downto 0) := "011";
constant SEND_B_DATA        : std_logic_vector (2 downto 0) := "100";
constant SEND_ABDATA        : std_logic_vector (2 downto 0) := "101";
constant NOFOUNDDATA        : std_logic_vector (2 downto 0) := "110";
constant HEADER_MISM        : std_logic_vector (2 downto 0) := "111";
------------------------------------------------------------------
---- FUNCTIONS ----
------------------------------------------------------------------
--------------------
-- is_header
--------------------
function is_header(data: std_logic_vector; data_valid: std_logic) return boolean is
  variable r : boolean := FALSE;
begin
  if data_valid='1' and data(data'high)='1' then
    r := TRUE;
  end if;
  return r;
end is_header;
--------------------
-- dataexist
--------------------
function dataexist(data: std_logic_vector; data_valid: std_logic) return boolean is
  variable r : boolean := FALSE;
begin
  if data_valid='1' and data(data'high downto data'high-1)="10" then
    r := TRUE;
  end if;
  return r;
end dataexist;
--------------------
-- get_header
--------------------
function get_header(data: std_logic_vector; data_valid: std_logic) return std_logic_vector is
  variable r : std_logic_vector(data'high-2 downto data'low-0) := (others => 'X');
begin
  if data_valid='1' and data(data'high)='1' then
    r := data(data'high-2 downto data'low-0);
  end if;
  return r;
end get_header;
--------------------
-- is_last
--------------------
function is_last(data: std_logic_vector; data_valid: std_logic) return boolean is
  variable r : boolean := FALSE;
begin
  if data_valid='1' and data(data'high downto data'high-1)="01" then
    r := TRUE;
  end if;
  return r;
end is_last;

------------------------------------------------------------------
---- SIGNALS ----
------------------------------------------------------------------
-- State machine signals
signal pstate               : std_logic_vector (2 downto 0) := RESET_STATE;
signal nstate               : std_logic_vector (2 downto 0);
signal x_d_r                : std_logic_vector(19 downto 0);
signal x_hdr_d_r            : std_logic_vector(19 downto 0);
signal b_header             : std_logic_vector(19 downto 0);
signal a_header             : std_logic_vector(19 downto 0);
signal b_header_r           : std_logic_vector(19 downto 0);
signal a_header_r           : std_logic_vector(19 downto 0);

begin
  
seq_fsm: process(clk, rst) is
begin
  if rst = '1' then
    a_header_r <= (others => '0');
    b_header_r <= (others => '0');
    x_hdr_d_r  <= (others => '0');
    x_d_r      <= (others => '0');
    pstate <= RESET_STATE;
  elsif clk='1' and clk'event then
    a_header_r <= a_header;
    b_header_r <= b_header;
    x_hdr_d_r  <= x_hdr_d;
    x_d_r      <= x_d;
    pstate <= nstate;
  end if;
end process;  

cmb_fsm: process (pstate, a_d, a_dv, b_d, b_dv, a_header_r, x_rd_en, x_hdr_d_r, b_header_r, x_d_r) is
begin
  -- Default Values
  a_header <= a_header_r;
  a_rd_en  <= a_dv;
  b_header <= b_header_r;
  b_rd_en  <= b_dv;
  x_d      <= x_d_r;
  x_dv     <= '0';
  x_last   <= '0';
  x_nodata  <= '0';
  x_hdr_d    <= x_hdr_d_r;
  x_hdr_dv   <= '0';
  x_mmatch <= '0';
  case pstate is
  when RESET_STATE =>
  -- Reset
    nstate   <= WAITAHEADER;
    a_rd_en  <= '0';
    b_rd_en  <= '0';
  when WAITAHEADER =>
  -- Wait for the First Header and look forward for second header
    nstate   <= WAITAHEADER;
    -- Check A Header  
    if is_header(a_d, a_dv) then
      a_header <= get_header(a_d, a_dv);
      x_hdr_d    <= get_header(a_d, a_dv);
      if is_header(b_d, b_dv) then
      -- Both Headers found: request the new data to be sent
        b_header  <= get_header(b_d, b_dv);
        x_hdr_dv   <= '1';
        if dataexist(a_d, a_dv) and dataexist(b_d, b_dv) then
        -- Disable B, Request A
          nstate   <= SEND_ABDATA;
          b_rd_en  <= '0';
        elsif dataexist(a_d, a_dv) then
        -- Disable B, Request A
          nstate   <= SEND_A_DATA;
          b_rd_en   <= '0';
        elsif dataexist(b_d, b_dv) then
        -- Disable A, Request B
          nstate   <= SEND_B_DATA;
          a_rd_en  <= '0';
        else
        -- Disable A,B
          nstate   <= NOFOUNDDATA;
          x_nodata  <= '1';
        end if;
      else
      -- B header not found. Disable A, req new B data and go in WAITBHEADER
        a_rd_en  <= '0';
        nstate   <= WAITBHEADER;
      end if;
    -- Check B Header
    elsif is_header(b_d, b_dv) then
    -- B found: disable B, request new A data and wait for A header
      b_header  <= get_header(b_d, b_dv);
      b_rd_en   <= '0';
    end if;
  when WAITBHEADER =>
    if is_header(b_d, b_dv) then
    -- Both Headers found: go in send state and request new data 
      b_header  <= get_header(b_d, b_dv);
      x_hdr_dv   <= '1';
      if dataexist(a_d, a_dv) and dataexist(b_d, b_dv) then
        nstate   <= SEND_ABDATA;
        b_rd_en  <= '0';
      elsif dataexist(a_d, a_dv) then
        nstate   <= SEND_A_DATA;
        b_rd_en  <= '0';
      elsif dataexist(b_d, b_dv) then
        nstate   <= SEND_B_DATA;
      else
        nstate   <= NOFOUNDDATA;
        x_nodata  <= '1';
      end if;
    else
    -- B header not found. disable A, request new B data and wait for B header
      a_rd_en  <= '0';
      nstate   <= WAITBHEADER;
    end if;
  when SEND_A_DATA =>
    x_hdr_dv   <= '1';
    a_rd_en  <= x_rd_en  and a_dv;
    b_rd_en  <= '0';
    x_dv     <= a_dv;
    x_d      <= a_d(19 downto 0);
    nstate   <= SEND_A_DATA;
    -- Check for last data
    if is_last(a_d, a_dv) then
    -- Last data sent.
    -- x_rd_en requests a new header: req. new data for both A and B and wait for headers.
      b_rd_en  <= x_rd_en and a_dv;
      if x_rd_en = '1' then
        nstate   <= WAITAHEADER;
      end if;
      x_last   <= '1';
    end if;
  when SEND_ABDATA =>
    x_hdr_dv   <= '1';
    a_rd_en  <= x_rd_en;
    b_rd_en  <= '0';
    x_dv     <= a_dv;
    x_d      <= a_d(19 downto 0);
    nstate   <= SEND_ABDATA;
    -- Check for last data
    if is_last(a_d, a_dv) then
    -- Last A data sent.
    -- x_rd_en requests a new B data: disable A and req. new B data.
      b_rd_en  <= x_rd_en;
      a_rd_en  <= '0'; -- New header for A is requested in state SEND_B_DATA.
      if x_rd_en = '1' then
        nstate   <= SEND_B_DATA;
      end if;
    end if;
  when SEND_B_DATA =>
    x_hdr_dv   <= '1';
    b_rd_en  <= x_rd_en;
    a_rd_en  <= '0';
    x_dv     <= b_dv;
    x_d      <= b_d(19 downto 0)+std_logic_vector(to_unsigned(48) & 0 & x"000",7);
    nstate   <= SEND_B_DATA;
    -- Check for last data
    if is_last(b_d, b_dv) then
    -- Last data sent.
    -- x_rd_en requests a new header: req. new data for both A and B and wait for headers.
    a_rd_en  <= x_rd_en;
      if x_rd_en = '1' then
        nstate   <= WAITAHEADER;
      end if;
      x_last   <= '1';
    end if;
  when NOFOUNDDATA => 
    x_hdr_dv   <= '1';
    x_nodata  <= '1';
    nstate <= NOFOUNDDATA;
    if x_rd_en = '1' then
    -- End of Cycle
      nstate <= WAITAHEADER;
    end if;
    -- New data already requested. Check for headers.
    -- Check A Header
    if is_header(a_d, a_dv) then
      a_header <= get_header(a_d, a_dv);
      a_rd_en  <= '0';
    end if;
    -- Check B Header
    if is_header(b_d, b_dv) then
      b_header <= get_header(b_d, b_dv);
      b_rd_en  <= '0';
    end if;
  when HEADER_MISM => 
    -- Header Mismatch
    -- Should never go in this state.
    -- Can be solved by using TrigNum from ROCK if A abd B are synchronous.
    x_mmatch <= '1';
    nstate   <= HEADER_MISM;
    a_rd_en  <= '0';
    b_rd_en  <= '0';
  when others =>
    nstate   <= "XXX";
    a_rd_en  <= '0';
    b_rd_en  <= '0';
  end case;
end process;

end rtl;


----------------------------------------------------------------------------------
-- Company: LNF - INFN
-- Authors: Albicocco Pietro
-- Contact: pietro.albicocco@lnf.infn.it
----------------------------------------------------------------------------------
-- File Name: xfront.vhd
-- Target Devices: Xilinx - 7 Series
-- Tool Versions: VIVADO 2015.2
-- Description: xFRONT manage the auxbus signals.
-- 
-- Dependencies: 
--
----------------------------------------------------------------------------------
-- Revision History:
-- Revision 1.0 - Albicocco P. - First Version
----------------------------------------------------------------------------------
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity xfront is
Generic (
    clock_period : integer := 10
    );
Port (
  -------- SYSTEM SIGNALS -------
  -- System clock
  clk    : in STD_LOGIC;
  clk2x : in STD_LOGIC;
  -- System reset
  rst : in STD_LOGIC;
  -------- Control Interface -------
  -- Trigger Number
  i_t      : in  STD_LOGIC_VECTOR(11 downto 0);
  -- Trigger Number Data Valid
  i_tv     : in  STD_LOGIC;
  -- Trigger Number Request
  i_t_req  : out STD_LOGIC;
  -- Data, Data Valid, Last Event Data and New Event or Data Request
  i_d      : in  STD_LOGIC_VECTOR(19 downto 0);
  i_dv     : in  STD_LOGIC;
  i_last   : in  STD_LOGIC;
  i_rd_en  : out STD_LOGIC;
  -- Header Number and Header Number Valid (Valid is asserted when related data is ready)
  i_hdr_d  : in  STD_LOGIC_VECTOR(11 downto 0);
  i_hdr_dv : in  STD_LOGIC;
  -- Actual Header has no data 
  i_nodata : in  STD_LOGIC;
  --Error: Header Number Mismatch between A and B FIFO
  i_mmatch : in  STD_LOGIC;
  -- FIFO Full Flag, propagated and kept to xbusy
  i_full   : in  STD_LOGIC;
  -------- ROCK OUTPUT -------
  -- Trigger Bus, first valid trigger is 001
  xt : in STD_LOGIC_VECTOR (11 downto 0);
  -- Trigger Bus Data is valide, Active LOW
  xtrgv_n : in STD_LOGIC;
  -- Address Bus
  xa : in STD_LOGIC_VECTOR (3 downto 0);
  -- Address Bus is Valid
  xas_n : in STD_LOGIC;
  -- ROCK ready to read from slave, Active LOW
  -- ROCK finished to read from slave, Active HIGH
  xds : in STD_LOGIC;
  -- Master is initiating a synch check, Active LOW
  xsyncrd_n : in STD_LOGIC;
  -- ROCK send a system HALT due to Error,
  xsyshalt : in STD_LOGIC;
  -- ROCK produces a create level AUX reset
  xsysreset : in STD_LOGIC;
  -------- ROCK OPEN COLLECOTR INPUT -------
  -- Slave xsds bit is valid, Active HIGH
  xbk : out STD_LOGIC;
  -- Slave has an error, Active LOW
  xberr_n : out STD_LOGIC;
  -- Slave is full, Active LOW
  xbusy_n : out STD_LOGIC;
  -------- ROCK TRISTATE INPUT -------
  -- Slave data is valid, Active LOW
  -- Slave recognized Master finished cycle, Active HIGH
  xdk : out STD_LOGIC;
  -- Actual Slave Data Word is the last, Active LOW
  xeob_n : out STD_LOGIC;
  -- Slave Data
  xd : out STD_LOGIC_VECTOR (19 downto 0);
  -- Slave has data for a given Trigger Number
  -- Can be either tristate or always enabled
  xsds : out STD_LOGIC;
  -------- BACKPLANE HARDWIRED INPUT -------
  -- Slave Geographical Address
  sa : in STD_LOGIC_VECTOR (3 downto 0)
);
end xfront;

architecture rtl of xfront is
------------------------------------------------------------------
---- FUNCTIONS ----
------------------------------------------------------------------
--------------------
-- and_reduce
--------------------
function and_reduce(x : std_logic_vector) return std_logic is
  variable r : std_logic := '1';
begin
  for i in x'range loop
    r := r and x(i);
  end loop;
  return r;
end and_reduce;
--------------------
-- log2
--------------------
function log2( i : integer) return integer is
  variable t    : integer := i;
  variable r : integer := 0; 
begin         
  while t > 1 loop
    r := r + 1;
    t := t / 2;     
  end loop;
  return r;
end function;
------------------------------------------------------------------
---- COMPONENTS ----
------------------------------------------------------------------
--------------------
-- IBUFV
--------------------
component IBUFV is
generic (
  WIDTH        : integer; 
  IBUF_LOW_PWR : BOOLEAN;
  IOSTANDARD   : STRING);
port (
  O            : out STD_LOGIC_VECTOR (WIDTH-1 downto 0);
  I            : in  STD_LOGIC_VECTOR (WIDTH-1 downto 0)
);
end component IBUFV;
--------------------
-- OBUFTV
--------------------
component OBUFTV is
generic (
  WIDTH        : integer; 
  DRIVE        : integer;
  IOSTANDARD   : STRING;
  SLEW         : STRING);
port (
  O            : out STD_LOGIC_VECTOR (WIDTH-1 downto 0);
  I            : in  STD_LOGIC_VECTOR (WIDTH-1 downto 0);
  T            : in  STD_LOGIC
);
end component OBUFTV;
------------------------------------------------------------------
---- CONSTANTS ----
------------------------------------------------------------------
-- input to output
--constant thold35             : integer := (35-clock_period/2)/clock_period;
--constant thold15             : integer := (15-clock_period/2)/clock_period;
-- internal to output
constant thold35             : integer := (1000*(35+clock_period)-1)/1000/clock_period-1;
constant thold15             : integer := (1000*(15+clock_period)-1)/1000/clock_period-1;
--------------------
-- Counter
--------------------
constant Ncnt				        : integer := 1+log2(thold35);
------------------------------------------------------------------
---- SIGNALS ----
------------------------------------------------------------------
-- Slave Address Selection
signal ssel                 : std_logic;
-- State machine signals
signal done                 : std_logic;
type xstate is (idle, sync, trig, readout);
signal pstate               : xstate := idle;
signal nstate               : xstate;
-- Registerd Signals
signal full_r               : std_logic;
signal full                 : std_logic;
-- Counter signals
signal cvalue 				      : std_logic_vector(Ncnt-1 downto 0);
signal ccnt    				      : std_logic_vector(Ncnt-1 downto 0);
signal cvalid               : std_logic;
signal read_data            : std_logic;
signal read_data_r          : std_logic;
signal first_word_flag      : std_logic;
signal first_word_flag_r    : std_logic;
-- Counter State Machine
type cstate is (idle, reset, start, run, freerun);
  -- PS
signal cps					        : cstate := reset;
signal ccntr                : std_logic_vector(Ncnt-1 downto 0) := (others => '0');
  --  NS
signal cns					        : cstate;
-- AUXBUS INPUT SYNCRONIZATION
attribute async_reg : STRING;
-- Trigger Bus, first valid trigger is 001
signal bt         : STD_LOGIC_VECTOR (11 downto 0);
signal it         : STD_LOGIC_VECTOR (11 downto 0);
signal mt         : STD_LOGIC_VECTOR (11 downto 0);
attribute async_reg of it : signal is "TRUE";
attribute async_reg of mt : signal is "TRUE";
-- Trigger Bus Data is valide, Active LOW
signal btrgv_n    : STD_LOGIC;
signal itrgv_n    : STD_LOGIC;
signal mtrgv_n    : STD_LOGIC;
attribute async_reg of itrgv_n : signal is "TRUE";
attribute async_reg of mtrgv_n : signal is "TRUE";
-- Address Bus
signal ba         : STD_LOGIC_VECTOR (3 downto 0);
signal ia         : STD_LOGIC_VECTOR (3 downto 0);
signal ma         : STD_LOGIC_VECTOR (3 downto 0);
attribute async_reg of ia : signal is "TRUE";
attribute async_reg of ma : signal is "TRUE";
-- Address Bus is Valid
signal bas_n      : STD_LOGIC;
signal ias_n      : STD_LOGIC;
signal mas_n      : STD_LOGIC;
attribute async_reg of ias_n : signal is "TRUE";
attribute async_reg of mas_n : signal is "TRUE";
-- ROCK ready to read from slave, Active LOW
-- ROCK finished to read from slave, Active HIGH
signal bds        : STD_LOGIC;
signal ids        : STD_LOGIC;
signal mds        : STD_LOGIC;
attribute async_reg of ids : signal is "TRUE";
attribute async_reg of mds : signal is "TRUE";
-- Master is initiating a synch check, Active LOW
signal bsyncrd_n  : STD_LOGIC;
signal isyncrd_n  : STD_LOGIC;
signal msyncrd_n  : STD_LOGIC;
attribute async_reg of isyncrd_n : signal is "TRUE";
attribute async_reg of msyncrd_n : signal is "TRUE";
-- ROCK send a system HALT due to Error,
signal bsyshalt   : STD_LOGIC;
signal isyshalt   : STD_LOGIC;
signal msyshalt   : STD_LOGIC;
attribute async_reg of isyshalt : signal is "TRUE";
attribute async_reg of msyshalt : signal is "TRUE";
-- ROCK produces a create level AUX reset
signal bsysreset  : STD_LOGIC;
signal isysreset  : STD_LOGIC;
signal msysreset  : STD_LOGIC;
attribute async_reg of isysreset : signal is "TRUE";
attribute async_reg of msysreset : signal is "TRUE";
-------- BACKPLANE HARDWIRED INPUT -------
-- Slave Geographical Address
signal bsa         : STD_LOGIC_VECTOR (3 downto 0);
signal isa         : STD_LOGIC_VECTOR (3 downto 0);
signal msa         : STD_LOGIC_VECTOR (3 downto 0);
attribute async_reg of isa : signal is "TRUE";
attribute async_reg of msa : signal is "TRUE";
  
-- Example Tristate Output Enable
signal tris_en              : std_logic;
signal tris_out             : std_logic; 
-------- ROCK OPEN COLLECOTR INPUT -------
-- Slave xsds bit is valid, Active HIGH
signal obk                  : std_logic;
-- Slave has an error, Active LOW
signal oberr_n              : std_logic;
-- Slave is full, Active LOW
signal obusy_n              : std_logic;
-------- TRISTATE OUTPUT AND ENABLE SIGNALS -------
-- Slave data is valid, Active LOW
-- Slave recognized Master finished cycle, Active HIGH
signal odk                  : std_logic;
signal odk_en               : std_logic;
-- Actual Slave Data Word is the last, Active LOW
signal oeob_n               : std_logic;
signal oeob_en              : std_logic;
-- Slave Data (19 downto 0)
signal od                   : std_logic_vector(xd'range);
signal od_en                : std_logic;
-- Slave has data for a given Trigger Number
-- Can be either tristate or always enabled
signal osds                 : std_logic;
signal osds_en              : std_logic;

begin

-------- INPUT -------
-- Input Buffers
ibuf_xt: IBUFV
generic map (
   WIDTH => xt'high+1,
   IBUF_LOW_PWR => TRUE, -- Low power (TRUE) vs. performance (FALSE) setting for referenced I/O standards
   IOSTANDARD => "DEFAULT")
port map (
   O => bt,
   I => xt
);
ibuf_btrgv_n: IBUF
generic map (
   IBUF_LOW_PWR => TRUE, -- Low power (TRUE) vs. performance (FALSE) setting for referenced I/O standards
   IOSTANDARD => "DEFAULT")
port map (
   O => btrgv_n,
   I => xtrgv_n
);
ibuf_ba: IBUFV
generic map (
   WIDTH => xa'high+1,
   IBUF_LOW_PWR => TRUE, -- Low power (TRUE) vs. performance (FALSE) setting for referenced I/O standards
   IOSTANDARD => "DEFAULT")
port map (
   O => ba,
   I => xa
);
ibuf_bas_n: IBUF
generic map (
   IBUF_LOW_PWR => TRUE, -- Low power (TRUE) vs. performance (FALSE) setting for referenced I/O standards
   IOSTANDARD => "DEFAULT")
port map (
   O => bas_n,
   I => xas_n
);
ibuf_bds: IBUF
generic map (
   IBUF_LOW_PWR => TRUE, -- Low power (TRUE) vs. performance (FALSE) setting for referenced I/O standards
   IOSTANDARD => "DEFAULT")
port map (
   O => bds,
   I => xds
);
ibuf_bsyncrd_n: IBUF
generic map (
   IBUF_LOW_PWR => TRUE, -- Low power (TRUE) vs. performance (FALSE) setting for referenced I/O standards
   IOSTANDARD => "DEFAULT")
port map (
   O => bsyncrd_n,
   I => xsyncrd_n
);
ibuf_bsyshalt: IBUF
generic map (
   IBUF_LOW_PWR => TRUE, -- Low power (TRUE) vs. performance (FALSE) setting for referenced I/O standards
   IOSTANDARD => "DEFAULT")
port map (
   O => bsyshalt,
   I => xsyshalt
);
ibuf_bsysreset: IBUF
generic map (
   IBUF_LOW_PWR => TRUE, -- Low power (TRUE) vs. performance (FALSE) setting for referenced I/O standards
   IOSTANDARD => "DEFAULT")
port map (
   O => bsysreset,
   I => xsysreset
);
ibuf_bsa: IBUFV
generic map (
   WIDTH => sa'high+1,
   IBUF_LOW_PWR => TRUE, -- Low power (TRUE) vs. performance (FALSE) setting for referenced I/O standards
   IOSTANDARD => "DEFAULT")
port map (
   O => bsa,
   I => sa
);
-- Input Synchronisation
insync_pr: process (rst, clk, clk2x) is
begin
  if rst='1' then
    mt         <= (others => '0');
    it         <= (others => '0');
      -- Trigger Bus Data is valide, Active LOW
    mtrgv_n    <= '0';
    itrgv_n    <= '0';
    -- Address Bus
    ma         <= (others => '0');
    ia         <= (others => '0');
    -- Address Bus is Valid
    mas_n      <= '0';
    ias_n      <= '0';
    -- ROCK ready to read from slave, Active LOW
    -- ROCK finished to read from slave, Active HIGH
    mds        <= '0';
    ids        <= '0';
    -- Master is initiating a synch check, Active LOW
    msyncrd_n  <= '0';
    isyncrd_n  <= '0';
    -- ROCK send a system HALT due to Error,
    msyshalt   <= '0';
    isyshalt   <= '0';
    -- ROCK produces a create level AUX reset
    msysreset  <= '0';
    isysreset  <= '0';
    -------- BACKPLANE HARDWIRED INPUT -------
    -- Slave Geographical Address
    msa        <= (others => '0');
    isa        <= (others => '0');
  else
    if clk2x'event and clk2x='1' then
      -- Trigger Bus, first valid trigger is 001
      mt         <= bt;
      -- Trigger Bus Data is valide, Active LOW
      mtrgv_n    <= btrgv_n;
      -- Address Bus
      ma         <= ba;
      -- Address Bus is Valid
      mas_n      <= bas_n;
      -- ROCK ready to read from slave, Active LOW
      -- ROCK finished to read from slave, Active HIGH
      mds        <= bds;
      -- Master is initiating a synch check, Active LOW
      msyncrd_n  <= bsyncrd_n;
      -- ROCK send a system HALT due to Error,
      msyshalt   <= bsyshalt;
      -- ROCK produces a create level AUX reset
      msysreset  <= bsysreset;
      -------- BACKPLANE HARDWIRED INPUT -------
      -- Slave Geographical Address
      msa        <= bsa;
      -- Trigger Bus, first valid trigger is 001
      it         <= mt;
      -- Trigger Bus Data is valide, Active LOW
      itrgv_n    <= mtrgv_n;
      -- Address Bus
      ia         <= ma;
      -- Address Bus is Valid
      ias_n      <= mas_n;
      -- ROCK ready to read from slave, Active LOW
      -- ROCK finished to read from slave, Active HIGH
      ids        <= mds;
      -- Master is initiating a synch check, Active LOW
      isyncrd_n  <= msyncrd_n;
      -- ROCK send a system HALT due to Error,
      isyshalt   <= msyshalt;
      -- ROCK produces a create level AUX reset
      isysreset  <= msysreset;
      -------- BACKPLANE HARDWIRED INPUT -------
      -- Slave Geographical Address
      isa        <= msa;
    end if;
  end if;
end process;

-- Slave Address Selection
ssel <= and_reduce (ia xnor isa);

--Signal registering
sig_reg_p: process(clk, rst) is
begin
  if rst='1' then
    full_r <= '0';
  elsif clk'event and clk='1' then
    full_r <= full;
  end if;
end process;
full    <= i_full or full_r;
-- Slave has an error, Active LOW
oberr_n <= not i_mmatch;
-- Slave is full, Active LOW
obusy_n <= not full;

-------- COUNTER -------
-- Counter Seq. Network
cseq_pr: process(clk, rst) is
begin
  if rst = '1' then
    cps <= reset;
    ccntr <= (others => '0');
  elsif clk='1' and clk'event then
    cps <= cns;
    if cps = start then
      ccntr <= (0 => '1', others => '0');
    else
      ccntr <= ccnt;
    end if;
  end if;
end process;
-- Counter Output Network
ccomb_pr: process(cps, ccnt, ccntr, cvalue) is
begin
  case cps is
  when reset =>
  -- Reset
  	ccnt <= (others => '0');
  	cvalid <= '0';
  when idle =>
  -- Idle
    ccnt <= ccntr;
    if ccntr=cvalue then
      cvalid <= '1';
    else
      cvalid <= '0';
    end if;
  when start =>
  -- Start
    ccnt <= (ccnt'low => '1', others => '0');
    cvalid <= '0';
  when run =>
  -- Run
    if ccntr=cvalue then
      ccnt <= ccntr;
      cvalid <= '1';
    else
      ccnt <= ccntr + 1;
      cvalid <= '0';
    end if;
  when freerun =>
  -- Free Run
    ccnt <= ccntr + 1;
    --if and_reduce(ccnt) = '1' then
    if ccnt=cvalue then
      cvalid <= '1';
    else
      cvalid <= '0';
    end if;
  when others =>
  -- Idle
    ccnt <= ccntr;
    if ccnt=cvalue then
      cvalid <= '1';
    else
      cvalid <= '0';
    end if;
  end case;
end process;

-------- PROTOCOL -------
-- Sequential network
xseq_pr: process(clk, rst) is
begin
  if rst = '1' then
    read_data_r <= '0';
    first_word_flag_r <= '0';
    pstate <= idle;
  elsif clk='1' and clk'event then
    read_data_r <= read_data;
    first_word_flag_r <= first_word_flag;
    pstate <= nstate;
  end if;
end process;

-- State Transition Process
-- missing error and reset
xcomb_pr: process(pstate, itrgv_n, isyncrd_n, done, i_nodata) is
begin
  -- Trigger Value Request
  i_t_req <= '0';
  case pstate is
  when idle =>
  -- Wait for a Trigger Cycle or a Sync Cycle
    if (itrgv_n = '0') and (isyncrd_n = '0') then
      nstate <= trig;--sync;       -- Sync Cycle
    elsif (itrgv_n = '0') then
      nstate <= trig;       -- Trigger Cycle
--      if (i_hdr_d/=xt_s) then
--        nstate <= send_error;
--      end if;
    else
      nstate <= idle;       -- Wait for an event
    end if;
  when trig =>
  -- Trigger Cycle
    if (isyncrd_n = '0') and done = '1' then
      nstate <= sync;
    elsif (itrgv_n = '1') and done = '1' and i_nodata='1' then
      nstate <= idle;       -- No data
    elsif (itrgv_n = '1') and done = '1' then
      nstate <= readout;    -- Readout Procedure
    else 
      nstate <= trig;       -- Wait for an event
    end if;
  when readout =>
  -- Performe the Readout Procedure
    if (done = '0') then
      nstate <= readout;    -- Sending data
    else 
      nstate <= idle;       -- End of Frame
    end if;
  when sync =>
  -- Synchronisation Cycle
    if ( isyncrd_n = '1') or (done = '1') then
      nstate <= idle;       -- End of Synchronisation Cycle
      i_t_req <= '1';
    else 
      nstate <= sync;       -- Performing Synchronisation
    end if;
--  when others =>
--    pstate <= idle;           -- Wait for an event; or return Error? Halt?
  end case;
end process;

-- Output Transition Functions
ocomb_pr: process(pstate,ids, cvalid, ssel, i_last, ias_n, i_d, first_word_flag_r, i_nodata, i_dv, i_t, i_tv, i_hdr_d, i_mmatch, i_hdr_dv, it) is
begin
  read_data       <= '0';
  first_word_flag <= '0';
  case pstate is
  when idle =>
    -- Timing
    cvalue <= (others => '0');
    done <= '0';
    cns <= reset;
    -------- ROCK OPEN COLLECOTR INPUT -------
    -- Slave xsds bit is valid, Active HIGH
    obk <= '0';
    -- Slave has an error, Active LOW
    oberr_n <= '1';
    -- Slave is full, Active LOW
    obusy_n <= '1';
    -------- ROCK TRISTATE INPUT -------
    -- Slave data is valid, Active LOW
    -- Slave recognized Master finished cycle, Active HIGH
    odk <= '1';
    odk_en <= '1';
    -- Actual Slave Data Word is the last, Active LOW
    oeob_n <= '1';
    oeob_en <= '1';
    -- Slave Data (19 downto 0)
    od <= (others => '0');
    od_en <= '1';
    -- Slave has data for a given Trigger Number
    -- Can be either tristate or always enabled
    osds <= '0';
    osds_en <= '1';
  when trig =>
    -- Timing
    cvalue <= std_logic_vector(to_unsigned(thold35, Ncnt));
    done <= '0';
    if (i_hdr_dv='1') and (i_hdr_d=it) and (i_mmatch = '0') then
      -- Count 35 ns after data is ready for requested trigger number
      cns <= run;
    elsif (i_tv='1') and (isyncrd_n = '0') then
      cns <= run;
    else 
      -- Waiting data for requested trigger number
      cns <= reset;
    end if;
    -- Slave has data for a given Trigger Number
    -- Can be either tristate or always enabled
    osds <= i_nodata and isyncrd_n;
    osds_en <= '0';
    -- Slave xsds bit is valid, Active HIGH
    obk <= '0';   
    if cvalid ='1' then
      -- Wait for the end of the trigger cycle (i.e. xtrgv = '1')
      obk <= '1';
      done <= '1';
      read_data <= i_nodata;
    end if;
    -------- ROCK OPEN COLLECOTR INPUT -------
    -- Slave has an error, Active LOW
    oberr_n <= '1';
    -- Slave is full, Active LOW
    obusy_n <= '1';
    -------- ROCK TRISTATE INPUT -------
    -- Slave data is valid, Active LOW
    -- Slave recognized Master finished cycle, Active HIGH
    odk <= '1';
    odk_en <= '1';
    -- Actual Slave Data Word is the last, Active LOW
    oeob_n <= '1';
    oeob_en <= '1';
    -- Slave Data (19 downto 0)
    od <= (others => '0');
    od_en <= '1';
  when readout =>
    -- Timing
    cvalue <= (others => '0');
    done <= '0';
    cns <= reset;
    -------- ROCK OPEN COLLECOTR INPUT -------
    -- Slave xsds bit is valid, Active HIGH
    obk <= '0';
    -- Slave has an error, Active LOW
    oberr_n <= '1';
    -- Slave is full, Active LOW
    obusy_n <= '1';
    -------- ROCK TRISTATE INPUT -------
    -- Slave data is valid, Active LOW
    -- Slave recognized Master finished cycle, Active HIGH
    odk <= '1';
    odk_en <= '1';
    -- Actual Slave Data Word is the last, Active LOW
    oeob_n <= '1';
    oeob_en <= '1';
    -- Slave Data (19 downto 0)
    od <= (others => '0');
    od_en <= '1';
    -- Slave has data for a given Trigger Number
    -- Can be either tristate or always enabled
    osds <= '0';
    osds_en <= '1';
    -------- START DATA READOUT -------
    first_word_flag <= first_word_flag_r;
    if (ssel = '1') and ias_n = '0' then
      od_en <= '0';
      odk_en <= '0';
      oeob_en <= '0';
      if (ids = '0') or (i_last = '1') then
        first_word_flag <= first_word_flag_r or '1';
        -- Set valid data in xd
        -- Slave Data (19 downto 0)
        od <= i_d;
            -- Actual Slave Data Word is the last, Active LOW
        oeob_n <= not i_last;
        -- Wait for 15ns after data valid
        cvalue <= std_logic_vector(to_unsigned(thold15, Ncnt));
        if i_dv = '1' then
          cns <= run;
        end if;
        if cvalid = '1' then
        -- After 15 ns assert xdk and xeob
          -- Slave data is valid, Active LOW
          -- Slave recognized Master finished cycle, Active HIGH
          odk <= '0';
        end if;
      else
        -- Request new data
        read_data <= '1' and first_word_flag_r;
      end if;
    elsif first_word_flag_r = '1' then
      done <= '1';
      read_data <= '1';
    end if;
    -------- END DATA READOUT -------
    when sync =>
    -- Timing
    cvalue <= (others => '0');
    done <= '0';
    cns <= reset;
    -------- ROCK OPEN COLLECOTR INPUT -------
    -- Slave xsds bit is valid, Active HIGH
    obk <= '0';
    -- Slave has an error, Active LOW
    oberr_n <= '1';
    -- Slave is full, Active LOW
    obusy_n <= '1';
    -------- ROCK TRISTATE INPUT -------
    -- Slave data is valid, Active LOW
    -- Slave recognized Master finished cycle, Active HIGH
    odk <= '1';
    odk_en <= '1';
    -- Actual Slave Data Word is the last, Active LOW
    oeob_n <= '1';
    oeob_en <= '1';
    -- Slave Data (19 downto 0)
    od <= (others => '0');
    od_en <= '1';
    -- Slave has data for a given Trigger Number
    -- Can be either tristate or always enabled
    osds <= '0';
    osds_en <= '1';
    -------- START SYNC READOUT -------
    first_word_flag <= first_word_flag_r;
    if (ssel = '1') and ias_n = '0' then
      od_en <= '0';
      odk_en <= '0';
      oeob_en <= '0';
      first_word_flag <= first_word_flag_r or '1';
      -- Set valid data in xd
      -- Slave Data (19 downto 0)
      od <= X"00" & i_t;
          -- Actual Slave Data Word is the last, Active LOW
      oeob_n <= '0';
      -- Wait for 15ns after data valid
      cvalue <= std_logic_vector(to_unsigned(thold15, Ncnt));
      if i_tv = '1' then
        cns <= run;
      end if;
      if cvalid = '1' then
      -- After 15 ns assert xdk and xeob
        -- Slave data is valid, Active LOW
        -- Slave recognized Master finished cycle, Active HIGH
        odk <= '0';
      end if;
    elsif first_word_flag_r = '1' then
      done <= '1';
    end if;
    -------- END SYNC READOUT -------
  end case;
end process;
-- New Data Request
newdata_req: process(clk, rst) is
begin
  if rst = '1' then
    i_rd_en <= '0';
  elsif clk'event and clk='1' then
    if read_data='1' and read_data_r='0' then
      i_rd_en <= '1';
    else
      i_rd_en <= '0';
    end if; 
  end if;
end process;

-- Tristate Output Enable
ts_enable_pr: process(ias_n, tris_en, ssel) is
begin
  if (ias_n = '0') and (ssel = '1') then
    -- Output depends on the protocol
    tris_out <= tris_en;
  else
    -- Output is disabled
    tris_out <= '0';
  end if;
end process;

--Output Buffers
-------- ROCK OPEN COLLECOTR INPUT -------
OBUFT_xbk : OBUFT
generic map (
   DRIVE => 12,
   IOSTANDARD => "DEFAULT",
   SLEW => "SLOW")
port map (
   O => xbk,
   I => '0',
   T => obk
);
OBUFT_xberr_n : OBUFT
generic map (
   DRIVE => 12,
   IOSTANDARD => "DEFAULT",
   SLEW => "SLOW")
port map (
   O => xberr_n,
   I => '0',
   T => oberr_n
);
OBUFT_xbusy_n : OBUFT
generic map (
   DRIVE => 12,
   IOSTANDARD => "DEFAULT",
   SLEW => "SLOW")
port map (
   O => xbusy_n,
   I => '0',
   T => obusy_n
);
-------- ROCK TRISTATE INPUT -------
OBUFT_xdk : OBUFT
generic map (
   DRIVE => 12,
   IOSTANDARD => "DEFAULT",
   SLEW => "SLOW")
port map (
   O => xdk,
   I => odk,
   T => odk_en
);
OBUFT_xeob_n : OBUFT
generic map (
   DRIVE => 12,
   IOSTANDARD => "DEFAULT",
   SLEW => "SLOW")
port map (
   O => xeob_n,
   I => oeob_n,
   T => oeob_en
);
OBUFT_xd : OBUFTV
generic map (
   WIDTH => xd'high+1,
   DRIVE => 12,
   IOSTANDARD => "DEFAULT",
   SLEW => "SLOW")
port map (
   O => xd,
   I => od,
   T => od_en
);
OBUFT_xsds : OBUFT
generic map (
   DRIVE => 12,
   IOSTANDARD => "DEFAULT",
   SLEW => "SLOW")
port map (
   O => xsds,
   I => osds,
   T => osds_en
);

end rtl;


----------------------------------------------------------------------------------
-- Company: LNF - INFN
-- Authors: Albicocco Pietro
-- Contact: pietro.albicocco@lnf.infn.it
----------------------------------------------------------------------------------
-- File Name: IBUFV.vhd
-- Target Devices: Xilinx - 7 Series
-- Tool Versions: VIVADO 2015.2
-- Description: IBUFV extents the IBUF primitive to std_logic_vectors.
-- 
-- Dependencies: 
--
----------------------------------------------------------------------------------
-- Revision History:
-- Revision 1.0 - Albicocco P. - First Version
----------------------------------------------------------------------------------
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity IBUFV is
generic (
  WIDTH        : integer; 
  IBUF_LOW_PWR : BOOLEAN;
  IOSTANDARD   : STRING);
port (
  O            : out STD_LOGIC_VECTOR (WIDTH-1 downto 0);
  I            : in  STD_LOGIC_VECTOR (WIDTH-1 downto 0)
);
end IBUFV;

architecture rtl of IBUFV is
begin
gen: for index in I'range generate
ibuf_i: IBUF
generic map (
  IBUF_LOW_PWR => IBUF_LOW_PWR,
  IOSTANDARD => IOSTANDARD)
port map (
  O => O(index),
  I => I(index)
);
end generate;
end rtl;


----------------------------------------------------------------------------------
-- Company: LNF - INFN
-- Authors: Albicocco Pietro
-- Contact: pietro.albicocco@lnf.infn.it
----------------------------------------------------------------------------------
-- File Name: OBUFTV.vhd
-- Target Devices: Xilinx - 7 Series
-- Tool Versions: VIVADO 2015.2
-- Description: OBUFTV extents the OBUFTV primitive to std_logic_vectors.
-- 
-- Dependencies: 
--
----------------------------------------------------------------------------------
-- Revision History:
-- Revision 1.0 - Albicocco P. - First Version
----------------------------------------------------------------------------------
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity OBUFTV is
generic (
  WIDTH        : integer; 
  DRIVE        : integer;
  IOSTANDARD   : STRING;
  SLEW         : STRING);
port (
  O            : out STD_LOGIC_VECTOR (WIDTH-1 downto 0);
  I            : in  STD_LOGIC_VECTOR (WIDTH-1 downto 0);
  T            : in  STD_LOGIC
);
end OBUFTV;

architecture rtl of OBUFTV is
begin
gen: for index in I'range generate
ibuf_i: OBUFT
generic map (
  DRIVE       => DRIVE,
  IOSTANDARD  => IOSTANDARD,
  SLEW        => SLEW)
port map (
  O => O(index),
  I => I(index),
  T => T
);
end generate;
end rtl;