----------------------------------------------------------------------------------
-- Company: LNF - INFN
-- Authors: Albicocco Pietro
-- Contact: pietro.albicocco@lnf.infn.it
----------------------------------------------------------------------------------
-- File Name: xpack.vhd
-- Target Devices: Xilinx - 7 Series
-- Tool Versions: VIVADO 2015.4
-- Description: AUXBUS Slave Implementation
-- 
-- Dependencies: 
--
----------------------------------------------------------------------------------
-- Revision History:
-- Revision 1.0 - 03/2016 - Albicocco P. - First Version
-- Revision 2.0 - 03/2016 - Albicocco P. - Integrated Test Strategy 
----------------------------------------------------------------------------------
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;

package xpack is
------------------------------------------------------------------
---- RECORDS ----
-----------------------------------------------------------------
--------------------
-- ro_reg
--------------------
type ro_reg_type is
record
  -------- TRIGGER -------
  -- A FIFO Trigger Number (Test Mode)
  atest_Ntrig      : std_logic_vector (11 downto 0);
  -- B FIFO Trigger Number (Test Mode)
  btest_Ntrig      : std_logic_vector (11 downto 0);
  -- Voted Trigger Number Valid
  Ntrig_voter_v    : std_logic;
  -- Voted Trigger Number
  Ntrig_voter      : std_logic_vector (11 downto 0);
  -- Local Trigger Number
  Ntrig_local      : std_logic_vector (11 downto 0);
  -- FPGA A Trigger Number
  Ntrig_devA       : std_logic_vector (11 downto 0);
  -- FPGA B Trigger Number
  Ntrig_devB       : std_logic_vector (11 downto 0);
  -------- XFIFO -------
  -- A FIFO Full
  AFIFO_isfull     : std_logic;
  -- A FIFO Almost Full
  AFIFO_isafull    : std_logic;
  -- A FIFO Prog Full
  AFIFO_ispfull    : std_logic;
  -- A FIFO Empty
  AFIFO_isempty    : std_logic;
  -- B FIFO Full
  BFIFO_isfull     : std_logic;
  -- B FIFO Almost Full
  BFIFO_isafull    : std_logic;
  -- B FIFO Prog Full
  BFIFO_ispfull    : std_logic;
  -- B FIFO Empty
  BFIFO_isempty    : std_logic;
  -------- AXI FIFO Regs and Signals -------
  -- A read data (Reg?)
  A_read_data      : std_logic_vector (21 DOWNTO 0);
  -- A FIFO empty (not valid) (Sig)
  A_empty          : std_logic;
  -- A Almost Full (Sig)
  A_afull          : std_logic;
  -- B read data (Reg?)
  B_read_data      : std_logic_vector (21 DOWNTO 0);
  -- B FIFO empty (not valid) (Sig)
  B_empty          : std_logic;
  -- B Almost Full (Sig)
  B_afull          : std_logic;
end record;
--------------------
-- rw_reg
--------------------
type rw_reg_type is
record
  -------- RESET -------
  -- Reset Aux Bus
  reset            : std_logic;
  -- Reset FIFOs
  fiforeset        : std_logic;
  -- Trigger Counters Reset (A+B+Local)
  triggerreset     : std_logic;
  -------- TEST -------
  -- Enable Test Mode: 0 Disable, 1 Enable.
  test_mode        : std_logic;
  -- Trigger Test Mode : '0' : count real trigger, '1' : Count trigger only in Local FPGA --use value in rw_reg.test_Ntrig
  test_trig_mode   : std_logic;
  -- Test Trigger Number -- Unused
  test_Ntrig       : std_logic_vector (11 DOWNTO 0);
  -- A Busy flag in test mode
  A_is_busy        : std_logic;
  -- B Busy flag in test mode
  B_is_busy        : std_logic;
  -------- AXI FIFO Regs and Signals -------
  -- Enable Read from A FIFO (Reg)
  A_FIFO_read_en   : std_logic;
  -- A Read Enable (Sig)
  A_read_en        : std_logic;
  -- Enable Write to A FIFO (Sig)
  A_FIFO_write_en  : std_logic;
  -- A write data (Reg?)
  A_write_data     : std_logic_vector (31 DOWNTO 0);
  -- A Write Enable (Sig)
  A_write_en       : std_logic;
  -- Enable Read from B FIFO (Reg)
  B_FIFO_read_en   : std_logic;
  -- B read enable (Sig)
  B_read_en        : std_logic;
  -- Enable Write to B FIFO (Sig)
  B_FIFO_write_en  : std_logic;
  -- B write data (Reg?)
  B_write_data     : std_logic_vector (31 DOWNTO 0);
  -- B Write Enable (Sig)
  B_write_en      : std_logic;
end record;
------------------------------------------------------------------
---- CONSTANTS ----
------------------------------------------------------------------
constant rw_defaults : rw_reg_type := (
  -------- RESET -------
  '0',               -- Reset Aux Bus
  '0',               -- Reset FIFOs
  '0',               -- Trigger Counters Reset (A+B+Local)
  -------- TEST -------
  '0',               -- test_mode - Enable Test Mode: 0 Disable, 1 Enable.
  '1',               -- Trigger Test Mode : '0' : count real trigger, '1' : Count trigger only in Local FPGA.
  x"555",            -- Test Trigger Number
  '0',               -- A Busy flag in test mode
  '0',               -- B Busy flag in test mode
  -------- AXI FIFO -------
  '0',               -- Enable Read from A FIFO
  '0',               -- A Read Enable
  '0',               -- Enable Write to A FIFO
  (others => '0'),   -- A write data
  '0',               -- A Write Enable
  '0',               -- Enable Read from B FIFO
  '0',               -- B read enable
  '0',               -- Enable Write to B FIFO
  (others => '0'),   -- B write data
  '0'                -- B Write Enable
);
------------------------------------------------------------------
---- FUNCTIONS ----
------------------------------------------------------------------
--------------------
-- or_reduce
--------------------
function or_reduce(x: std_logic_vector) return std_logic;  
--------------------
-- and_reduce
--------------------
function and_reduce(x : std_logic_vector) return std_logic;
--------------------
-- log2
--------------------
function log2( i : integer) return integer;

end xpack;

package body xpack is
------------------------------------------------------------------
---- FUNCTIONS ----
------------------------------------------------------------------
--------------------
-- or_reduce
--------------------
function or_reduce(x : std_logic_vector) return std_logic is
  variable r : std_logic := '0';
begin
  for i in x'range loop
    r := r or x(i);
  end loop;
  return r;
end or_reduce;
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

end xpack;
----------------------------------------------------------------------------------
-- Company: LNF - INFN
-- Authors: Albicocco Pietro
-- Contact: pietro.albicocco@lnf.infn.it
----------------------------------------------------------------------------------
-- File Name: auxbus.vhd
-- Target Devices: Xilinx - 7 Series
-- Tool Versions: VIVADO 2015.4
-- Description: AUXBUS Slave Implementation
-- 
-- Dependencies: 
--
----------------------------------------------------------------------------------
-- Revision History:
-- Revision 1.0 - 02/2016 - Albicocco P. - First Version
-- Revision 2.0 - 03/2016 - Albicocco P. - Integrated Test Strategy 
----------------------------------------------------------------------------------
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.xpack.all;

entity auxbus is
Generic (
    -------- CLK  PERIOD -------
    clock_period : integer := 10;
    -------- AXI-4  LITE -------
    C_S_AXI_DATA_WIDTH  : integer := 32;
    C_S_AXI_ADDR_WIDTH  : integer := 9
    );
Port (
  --------  SYSTEM  PORTS  -------
  -- System clock
  clk           : in STD_LOGIC;
  clk2x         : in STD_LOGIC;
  -- System reset
  rst           : in STD_LOGIC;
  --------  Trigger PORTS  -------
  -- Local Input Trigger
  trig_in       : in  STD_LOGIC;
  -- A Input Trigger
  atrig_det     : in  STD_LOGIC;
  -- B Input Trigger
  btrig_det     : in  STD_LOGIC;
  -------- A FIFO Interface -------
  A_Wr_clk      : in  STD_LOGIC;
  A_Din         : in  STD_LOGIC_VECTOR(22-1 DOWNTO 0);
  A_Wr_en       : in  STD_LOGIC;
  A_Full        : out STD_LOGIC;
  A_Almost_full : out STD_LOGIC;
  A_Prog_full   : out STD_LOGIC;
  -------- B FIFO Interface -------
  B_Wr_clk      : in  STD_LOGIC;
  B_Din         : in  STD_LOGIC_VECTOR(22-1 DOWNTO 0);
  B_Wr_en       : in  STD_LOGIC;
  B_Full        : out STD_LOGIC;
  B_Almost_full : out STD_LOGIC;
  B_Prog_full   : out STD_LOGIC;
  -------- AXI-4  LITE -------
  S_AXI_ACLK    : in  std_logic;
  S_AXI_ARESETN : in  std_logic;
  S_AXI_AWADDR  : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
  S_AXI_AWPROT  : in  std_logic_vector(2 downto 0);
  S_AXI_AWVALID : in  std_logic;
  S_AXI_AWREADY : out std_logic;
  S_AXI_WDATA   : in  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  S_AXI_WSTRB   : in  std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
  S_AXI_WVALID  : in  std_logic;
  S_AXI_WREADY  : out std_logic;
  S_AXI_BRESP   : out std_logic_vector(1 downto 0);
  S_AXI_BVALID  : out std_logic;
  S_AXI_BREADY  : in  std_logic;
  S_AXI_ARADDR  : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
  S_AXI_ARPROT  : in  std_logic_vector(2 downto 0);
  S_AXI_ARVALID : in  std_logic;
  S_AXI_ARREADY : out std_logic;
  S_AXI_RDATA   : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  S_AXI_RRESP   : out std_logic_vector(1 downto 0);
  S_AXI_RVALID  : out std_logic;
  S_AXI_RREADY  : in  std_logic;
  -------- ROCK OUTPUT -------
  -- Trigger Bus, first valid trigger is 001
  xt            : in STD_LOGIC_VECTOR (11 downto 0);
  -- Trigger Bus Data is valide, Active LOW
  xtrgv_n       : in STD_LOGIC;
  -- Address Bus
  xa            : in STD_LOGIC_VECTOR (3 downto 0);
  -- Address Bus is Valid
  xas_n         : in STD_LOGIC;
  -- ROCK ready to read from slave, Active LOW
  -- ROCK finished to read from slave, Active HIGH
  xds           : in STD_LOGIC;
  -- Master is initiating a synch check, Active LOW
  xsyncrd_n     : in STD_LOGIC;
  -- ROCK send a system HALT due to Error,
  xsyshalt      : in STD_LOGIC;
  -- ROCK produces a create level AUX reset
  xsysreset     : in STD_LOGIC;
  -------- ROCK OPEN COLLECOTR INPUT -------
  -- Slave xsds bit is valid, Active HIGH
  xbk           : out STD_LOGIC;
  -- Slave has an error, Active LOW
  xberr_n       : out STD_LOGIC;
  -- Slave is full, Active LOW
  xbusy_n       : out STD_LOGIC;
  -------- ROCK TRISTATE INPUT -------
  -- Slave data is valid, Active LOW
  -- Slave recognized Master finished cycle, Active HIGH
  xdk           : out STD_LOGIC;
  -- Actual Slave Data Word is the last, Active LOW
  xeob_n        : out STD_LOGIC;
  -- Slave Data
  xd            : out STD_LOGIC_VECTOR (19 downto 0);
  -- Slave has data for a given Trigger Number
  -- Can be either tristate or always enabled
  xsds          : out STD_LOGIC;
  -------- BACKPLANE HARDWIRED INPUT -------
  -- Slave Geographical Address
  sa            : in STD_LOGIC_VECTOR (3 downto 0)
);
end auxbus;

architecture rtl of auxbus is
------------------------------------------------------------------
---- COMPONENTS DECLARATION----
------------------------------------------------------------------
--------------------
-- xTRIG
--------------------
-- Trigger Counters and Voter.
--------------------
component xtrig is
Port (
  --------  System Signals  -------
  clk           : in  STD_LOGIC;
  rst           : in  STD_LOGIC;
  -------- Status Registers -------
  ro_reg        : out ro_reg_type;
  --------  Ctrl Registers  -------
  rw_reg        : in  rw_reg_type;
  -------- Trigger  Signals -------
  -- Local Input Trigger
  trig_in       : in  STD_LOGIC;
  -- A Input Trigger
  atrig_det     : in  STD_LOGIC;
  -- B Input Trigger
  btrig_det     : in  STD_LOGIC;
  -- Output Trigger
  trigger       : out STD_LOGIC_VECTOR(11 DOWNTO 0);
  -- Output Trigger Valid
  trigger_v     : out STD_LOGIC
);
end component xtrig;
--------------------
-- xTEST
--------------------
-- Protocol Test Environment.
--------------------
component xtest is
Port (
  clk           : in  STD_LOGIC;
  rst           : in  STD_LOGIC;
  -------- Status Registers -------
  ro_reg        : out ro_reg_type;
  --------  Ctrl Registers  -------
  rw_reg        : in  rw_reg_type;
  -------- Test Control Bit -------
  test_mode     : out  STD_LOGIC;
  -------- A FIFO Interface -------
  A_Wr_clk      : in  STD_LOGIC;
  A_Din         : out STD_LOGIC_VECTOR(22-1 DOWNTO 0);
  A_Wr_en       : out STD_LOGIC;
  A_Full        : in  STD_LOGIC;
  A_Almost_full : in  STD_LOGIC;
  A_Prog_full   : in  STD_LOGIC;
  A_busy        : out STD_LOGIC;
  -------- B FIFO Interface -------
  B_Wr_clk      : in  STD_LOGIC;
  B_Din         : out STD_LOGIC_VECTOR(22-1 DOWNTO 0);
  B_Wr_en       : out STD_LOGIC;
  B_Full        : in  STD_LOGIC;
  B_Almost_full : in  STD_LOGIC;
  B_Prog_full   : in  STD_LOGIC;
  B_busy        : out STD_LOGIC
);
end component xtest;
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
  A_Prog_full   : out STD_LOGIC;
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
  B_Prog_full   : out STD_LOGIC;
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
--------------------
-- xAXI
--------------------
-- AXI-4 LITE Control and Status Registers.
--------------------
component xaxi is
  generic (
    -- Width of S_AXI data bus
    C_S_AXI_DATA_WIDTH  : integer := 32;
    -- Width of S_AXI address bus
    C_S_AXI_ADDR_WIDTH  : integer := 9
  );
  port (
    -------- Status Registers -------
    ro_reg        : in  ro_reg_type;
    --------  Ctrl Registers  -------
    rw_reg        : out rw_reg_type;
    --------   AXI-4  PORTS   -------
    -- Global Clock Signal
    S_AXI_ACLK    : in  std_logic;
    -- Global Reset Signal. This Signal is Active LOW
    S_AXI_ARESETN : in std_logic;
    -- Write address (i ssued by master, acceped by Slave)
    S_AXI_AWADDR  : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    -- Write channel Protection type. This signal indicates the
        -- privilege and security level of the transaction, and whether
        -- the transaction is a data access or an instruction access.
    S_AXI_AWPROT  : in std_logic_vector(2 downto 0);
    -- Write address valid. This signal indicates that the master signaling
        -- valid write address and control information.
    S_AXI_AWVALID : in std_logic;
    -- Write address ready. This signal indicates that the slave is ready
        -- to accept an address and associated control signals.
    S_AXI_AWREADY : out std_logic;
    -- Write data (issued by master, acceped by Slave) 
    S_AXI_WDATA   : in  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    -- Write strobes. This signal indicates which byte lanes hold
        -- valid data. There is one write strobe bit for each eight
        -- bits of the write data bus.    
    S_AXI_WSTRB   : in  std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
    -- Write valid. This signal indicates that valid write
        -- data and strobes are available.
    S_AXI_WVALID  : in  std_logic;
    -- Write ready. This signal indicates that the slave
        -- can accept the write data.
    S_AXI_WREADY  : out std_logic;
    -- Write response. This signal indicates the status
        -- of the write transaction.
    S_AXI_BRESP   : out std_logic_vector(1 downto 0);
    -- Write response valid. This signal indicates that the channel
        -- is signaling a valid write response.
    S_AXI_BVALID  : out std_logic;
    -- Response ready. This signal indicates that the master
        -- can accept a write response.
    S_AXI_BREADY  : in  std_logic;
    -- Read address (issued by master, acceped by Slave)
    S_AXI_ARADDR  : in  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    -- Protection type. This signal indicates the privilege
        -- and security level of the transaction, and whether the
        -- transaction is a data access or an instruction access.
    S_AXI_ARPROT  : in  std_logic_vector(2 downto 0);
    -- Read address valid. This signal indicates that the channel
        -- is signaling valid read address and control information.
    S_AXI_ARVALID : in  std_logic;
    -- Read address ready. This signal indicates that the slave is
        -- ready to accept an address and associated control signals.
    S_AXI_ARREADY : out std_logic;
    -- Read data (issued by slave)
    S_AXI_RDATA   : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    -- Read response. This signal indicates the status of the
        -- read transfer.
    S_AXI_RRESP   : out std_logic_vector(1 downto 0);
    -- Read valid. This signal indicates that the channel is
        -- signaling the required read data.
    S_AXI_RVALID  : out std_logic;
    -- Read ready. This signal indicates that the master can
        -- accept the read data and response information.
    S_AXI_RREADY  : in  std_logic
  );
end component xaxi;
------------------------------------------------------------------
---- SIGNALS DECLARATION ----
------------------------------------------------------------------
-------- Status Registers -------
signal ro_reg      :  ro_reg_type;
signal ro_reg_xtest:  ro_reg_type;
signal ro_reg_xtrig:  ro_reg_type;
--------  Ctrl Registers  -------
signal rw_reg      :  rw_reg_type;
--------------------
-- xTRIG
--------------------
-- Trigger Counters and Voter.
--------------------
signal xtrig_reset : STD_LOGIC;
signal trigger     : STD_LOGIC_VECTOR(11 DOWNTO 0);
signal trigger_v   : STD_LOGIC;
--------------------
-- xTEST
--------------------
-- xtest Reset
signal xtest_reset : STD_LOGIC;
-- Test Control Bit
signal test_mode   : STD_LOGIC;
-- A FIFO Side
signal A_Din_t     : STD_LOGIC_VECTOR(21 downto 0);
signal A_Wr_en_t   : STD_LOGIC;
signal A_busy_t    : STD_LOGIC;
-- B FIFO Side
signal B_Din_t     : STD_LOGIC_VECTOR(21 downto 0);
signal B_Wr_en_t   : STD_LOGIC;
signal B_busy_t    : STD_LOGIC;
-- FIFOs Common 
signal busy_t      : STD_LOGIC;
--------------------
-- xFIFO
--------------------
-- FIFOs' reset
signal xfifo_reset : std_logic;
-- A FIFO Side
signal A_Din_i     : STD_LOGIC_VECTOR(21 downto 0);  
signal A_Wr_en_i   : STD_LOGIC;  
signal a_d         : STD_LOGIC_VECTOR(21 downto 0);
signal a_dv        : STD_LOGIC;
signal a_rd_en     : STD_LOGIC;
signal afull       : STD_LOGIC;
signal aafull      : STD_LOGIC;
signal apfull      : STD_LOGIC;
-- B FIFO Side
signal B_Din_i     : STD_LOGIC_VECTOR(21 downto 0);  
signal B_Wr_en_i   : STD_LOGIC;  
signal b_d         : STD_LOGIC_VECTOR(21 downto 0);
signal b_dv        : STD_LOGIC;
signal b_rd_en     : STD_LOGIC;
signal bfull       : STD_LOGIC;
signal bafull      : STD_LOGIC;
signal bpfull      : STD_LOGIC;
-- FIFOs Common 
signal full_i      : STD_LOGIC;
--------------------
-- xCTRL
--------------------
-- xCTRL reset
signal xctrl_reset : std_logic;
-------- FIFO Interface -------
signal a_dv_xctrl  : std_logic;
signal b_dv_xctrl  : std_logic;
signal a_rd_en_xctrl : std_logic;
signal b_rd_en_xctrl : std_logic;
-------- Control Interface -------
-- Data, Data Valid, Last Event Data and New Event or Data Request
signal d           : STD_LOGIC_VECTOR(19 downto 0);
signal dv          : STD_LOGIC;
signal last        : STD_LOGIC;
signal rd_en       : STD_LOGIC;
-- Header Number and Header Number Valid (Valid is asserted when related data is ready)
signal hdr_d       : STD_LOGIC_VECTOR(19 downto 0);
signal hdr_dv      : STD_LOGIC;
-- Actual Header has no data 
signal nodata      : STD_LOGIC;
--Error: Header Number Mismatch between A and B FIFO
signal mmatch      : STD_LOGIC;
-- FIFO Full Flag, propagated and kept to xbusy
signal full        : STD_LOGIC;
--------------------
-- xFRONT
--------------------
-- xFRONT reset
signal xfront_reset: STD_LOGIC;

begin
--------------------
-- xTRIG
--------------------
-- Trigger Counters and Voter.
--------------------
xtrig_reset   <= rst or rw_reg.reset or rw_reg.triggerreset;
xtrig_inst: xtrig
Port Map(
  --------  System Signals  -------
  clk           => clk,
  rst           => xtrig_reset,
  -------- Status Registers -------
  ro_reg        => ro_reg_xtrig,
  --------  Ctrl Registers  -------
  rw_reg        => rw_reg,
  -------- Trigger  Signals -------
  -- Local Input Trigger
  trig_in       => trig_in,
  -- A Input Trigger
  atrig_det     => atrig_det,
  -- B Input Trigger
  btrig_det     => btrig_det,
  -- Output Trigger
  trigger       => trigger,
  -- Output Trigger Valid
  trigger_v     => trigger_v
);
-- Voted Trigger Number Valid
ro_reg.Ntrig_voter_v <= ro_reg_xtrig.Ntrig_voter_v;
-- Voted Trigger Number
ro_reg.Ntrig_voter   <= ro_reg_xtrig.Ntrig_voter;
-- Local Trigger Number
ro_reg.Ntrig_local   <= ro_reg_xtrig.Ntrig_local;
-- FPGA A Trigger Number
ro_reg.Ntrig_devA    <= ro_reg_xtrig.Ntrig_devA;
-- FPGA B Trigger Number
ro_reg.Ntrig_devB    <= ro_reg_xtrig.Ntrig_devB;
--------------------
-- xTEST
--------------------
-- Protocol Test Environment.
--------------------
xtest_reset   <= rst or rw_reg.reset;
xtest_int: xtest
Port Map (
  clk           => clk,
  rst           => xtest_reset,
  -------- Status Registers -------
  ro_reg        => ro_reg_xtest,
  --------  Ctrl Registers  -------
  rw_reg        => rw_reg,
  -------- Test Control Bit -------
  test_mode     => test_mode,
  -------- A FIFO Interface -------
  A_Wr_clk      => A_Wr_clk,
  A_Din         => A_Din_t,
  A_Wr_en       => A_Wr_en_t,
  A_Full        => afull,
  A_Almost_full => aafull,
  A_Prog_full   => apfull,
  A_busy        => A_busy_t,
  -------- B FIFO Interface -------
  B_Wr_clk      => B_Wr_clk,
  B_Din         => B_Din_t,
  B_Wr_en       => B_Wr_en_t,
  B_Almost_full => bafull,
  B_Full        => bfull,
  B_Prog_full   => bpfull,
  B_busy        => B_busy_t
);
-------- XTEST Status Register -------
ro_reg.atest_Ntrig    <= ro_reg_xtest.atest_Ntrig;
ro_reg.btest_Ntrig    <= ro_reg_xtest.btest_Ntrig;
--------------------
-- xFIFO
--------------------
xfifo_reset   <= rst or rw_reg.fiforeset or rw_reg.reset;
A_Full        <= afull;
B_Full        <= bfull;
A_Prog_full   <= apfull;
B_Prog_full   <= bpfull;
xfifo_inst: xfifo
Port Map(
  Rst           => xfifo_reset,
  Rd_clk        => clk,
  -------- A FIFO Interface -------
  A_Wr_clk      => A_Wr_clk,
  A_Din         => A_Din_i,
  A_Wr_en       => A_Wr_en_i,
  A_Full        => afull,
  A_Almost_full => aafull,
  A_Prog_full   => apfull,
  A_Rd_en       => a_rd_en,
  A_Dout        => a_d,
  A_Empty       => open,
  A_Valid       => a_dv,
  -------- B FIFO Interface -------
  B_Wr_clk      => B_Wr_clk,
  B_Din         => B_Din_i,
  B_Wr_en       => B_Wr_en_i,
  B_Full        => bfull,
  B_Almost_full => bafull,
  B_Prog_full   => bpfull,
  B_Rd_en       => b_rd_en,
  B_Dout        => b_d,
  B_Empty       => open,
  B_Valid       => b_dv
);
-------- XFIFO Status Register -------
  -- A FIFO Full
  ro_reg.AFIFO_isfull  <= afull;
  -- A FIFO Almost Full
  ro_reg.AFIFO_isafull <= aafull;
  -- A FIFO Prog Full
  ro_reg.AFIFO_ispfull <= apfull;
  -- A FIFO Empty
  ro_reg.AFIFO_isempty <= not a_dv;
  -- B FIFO Full
  ro_reg.BFIFO_isfull  <= bfull;
  -- B FIFO Almost Full
  ro_reg.BFIFO_isafull <= bafull;
  -- B FIFO Prog Full
  ro_reg.BFIFO_ispfull <= bpfull;
  -- B FIFO Empty
  ro_reg.BFIFO_isempty <= not b_dv;
-------- FIFO AXI/Test/Normal Mode -------
-- Data Read to XAXI
ro_reg.A_read_data <= a_d  when rw_reg.A_FIFO_read_en = '1' else
                      (others => '0');
ro_reg.B_read_data <= b_d  when rw_reg.B_FIFO_read_en = '1' else
                      (others => '0');
-- Empty to XAXI
ro_reg.A_empty<= not a_dv  when rw_reg.A_FIFO_read_en = '1' else
                 '0';
ro_reg.B_empty<= not b_dv  when rw_reg.B_FIFO_read_en = '1' else
                 '0';
-- Full to XAXI
ro_reg.A_afull<= aafull    when rw_reg.A_FIFO_write_en = '1' else
                 '0';
ro_reg.B_afull<= bafull    when rw_reg.B_FIFO_write_en = '1' else
                 '0';
-- Data Read to XCTRL
  -- Directly connected
-- Data Valid to XCTRL
a_dv_xctrl    <= '0'       when rw_reg.A_FIFO_read_en = '1' or rw_reg.B_FIFO_read_en = '1'   else
                 a_dv;
b_dv_xctrl    <= '0'       when rw_reg.A_FIFO_read_en = '1' or rw_reg.B_FIFO_read_en = '1'   else
                 b_dv;
-- Full to XFRONT
full_i        <= '1'       when rw_reg.A_FIFO_write_en = '1' or rw_reg.B_FIFO_write_en = '1' else
                 busy_t    when test_mode = '1'                                              else
                 full;
busy_t        <= A_busy_t  or B_busy_t;
-- Data Read Enable to XFIFO
a_rd_en       <= rw_reg.A_read_en    when rw_reg.A_FIFO_read_en = '1'  else
                 '0'                 when rw_reg.B_FIFO_read_en = '1'  else
                 a_rd_en_xctrl;
b_rd_en       <= rw_reg.B_read_en    when rw_reg.B_FIFO_read_en = '1'  else
                 '0'                 when rw_reg.A_FIFO_read_en = '1'  else
                 b_rd_en_xctrl;
-- Data Write to XFIFO
A_Din_i       <= rw_reg.A_write_data (21 DOWNTO 0) 
                                     when rw_reg.A_FIFO_write_en = '1' else
                 (others => '0')     when rw_reg.B_FIFO_write_en = '1' else
                 A_Din_t             when test_mode = '1'              else
                 A_Din;
B_Din_i       <= rw_reg.B_write_data (21 DOWNTO 0) 
                                     when rw_reg.B_FIFO_write_en = '1' else
                 (others => '0')     when rw_reg.A_FIFO_write_en = '1' else
                 B_Din_t             when test_mode = '1'              else
                 B_Din;
-- Write Enable to XFIFO
A_Wr_en_i     <= rw_reg.A_write_en   when rw_reg.A_FIFO_write_en = '1' else
                 '0'                 when rw_reg.B_FIFO_write_en = '1' else
                 A_Wr_en_t           when test_mode = '1'              else
                 A_Wr_en;
B_Wr_en_i     <= rw_reg.B_write_en   when rw_reg.B_FIFO_write_en = '1' else
                 '0'                 when rw_reg.A_FIFO_write_en = '1' else
                 B_Wr_en_t           when test_mode = '1'              else
                 B_Wr_en;
--------------------
-- xCTRL
--------------------
xctrl_reset <= rst or rw_reg.reset;
xctrl_inst: xctrl
Port Map(
  clk           => clk,
  rst           => xctrl_reset,
  -- A FIFO Side
  a_d           => a_d,
  a_dv          => a_dv_xctrl,
  a_rd_en       => a_rd_en_xctrl,
  -- B FIFO Side
  b_d           => b_d,
  b_dv          => b_dv_xctrl,
  b_rd_en       => b_rd_en_xctrl,
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
xfront_reset <= rst or rw_reg.reset;
full         <= apfull or bpfull;
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
  i_t           => trigger,
  -- Trigger Number Data Valid
  i_tv          => trigger_v,
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
  i_full        => full_i,
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
--------------------
-- xAXI
--------------------
xaxi_inst: xaxi
Generic Map(
    -------- AXI-4  LITE -------
    C_S_AXI_DATA_WIDTH  => C_S_AXI_DATA_WIDTH,
    C_S_AXI_ADDR_WIDTH  => C_S_AXI_ADDR_WIDTH
)
Port Map(
    -------- Status Registers -------
    ro_reg        => ro_reg,
    --------  Ctrl Registers  -------
    rw_reg        => rw_reg,
    --------   AXI-4  PORTS   -------
    S_AXI_ACLK    => S_AXI_ACLK   ,
    S_AXI_ARESETN => S_AXI_ARESETN,
    S_AXI_AWADDR  => S_AXI_AWADDR ,
    S_AXI_AWPROT  => S_AXI_AWPROT ,
    S_AXI_AWVALID => S_AXI_AWVALID,
    S_AXI_AWREADY => S_AXI_AWREADY,
    S_AXI_WDATA   => S_AXI_WDATA  ,
    S_AXI_WSTRB   => S_AXI_WSTRB  ,
    S_AXI_WVALID  => S_AXI_WVALID ,
    S_AXI_WREADY  => S_AXI_WREADY ,
    S_AXI_BRESP   => S_AXI_BRESP  ,
    S_AXI_BVALID  => S_AXI_BVALID ,
    S_AXI_BREADY  => S_AXI_BREADY ,
    S_AXI_ARADDR  => S_AXI_ARADDR ,
    S_AXI_ARPROT  => S_AXI_ARPROT ,
    S_AXI_ARVALID => S_AXI_ARVALID,
    S_AXI_ARREADY => S_AXI_ARREADY,
    S_AXI_RDATA   => S_AXI_RDATA  ,
    S_AXI_RRESP   => S_AXI_RRESP  ,
    S_AXI_RVALID  => S_AXI_RVALID ,
    S_AXI_RREADY  => S_AXI_RREADY
);
end rtl;
----------------------------------------------------------------------------------
-- Company: LNF - INFN
-- Authors: Albicocco Pietro
-- Contact: pietro.albicocco@lnf.infn.it
----------------------------------------------------------------------------------
-- File Name: xtrig.vhd
-- Target Devices: Xilinx - 7 Series
-- Tool Versions: VIVADO 2015.4
-- Description: Trigger Front End, Counters and Voter.
-- 
-- Dependencies: 
--
----------------------------------------------------------------------------------
-- Revision History:
-- Revision 2.0 - 03/2016 - Albicocco P. - Integrated Test Strategy
----------------------------------------------------------------------------------
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_unsigned.ALL;

library work;
use work.xpack.all;

entity xtrig is
Port (
  --------  System Signals  -------
  clk           : in  STD_LOGIC;
  rst           : in  STD_LOGIC;
  -------- Status Registers -------
  ro_reg        : out ro_reg_type;
  --------  Ctrl Registers  -------
  rw_reg        : in  rw_reg_type;
  -------- Trigger  Signals -------
  -- Local Input Trigger
  trig_in       : in  STD_LOGIC;
  -- A Input Trigger
  atrig_det     : in  STD_LOGIC;
  -- B Input Trigger
  btrig_det     : in  STD_LOGIC;
  -- Output Trigger
  trigger       : out STD_LOGIC_VECTOR(11 DOWNTO 0);
  -- Output Trigger Valid
  trigger_v     : out STD_LOGIC
);
end xtrig;

architecture rtl of xtrig is
------------------------------------------------------------------
---- SIGNALS DECLARATION ----
------------------------------------------------------------------
--------------------
-- Trigger Detector
--------------------
-- Trigger detection Register
signal trig_det_reg       : std_logic_vector (6 downto 0);
-- Async Reg
attribute ASYNC_REG : STRING;
--attribute ASYNC_REG of trig_det_reg(1 downto 0) : signal is "TRUE"; -- Modify to set as async
--------------------
-- Trigger Synchronization
--------------------
signal trig_sync_reg      : std_logic_vector (1 downto 0);
-- Async Reg
attribute ASYNC_REG of trig_sync_reg : signal is "TRUE";
--------------------
-- Trigger Counter
--------------------
signal trig_counter       : std_logic_vector (11 downto 0);
--------------------
-- A Trigger Synchronization
--------------------
signal atrig_sync_reg      : std_logic_vector (1 downto 0);
-- Async Reg
attribute ASYNC_REG of atrig_sync_reg : signal is "TRUE";
--------------------
-- A Trigger Counter
--------------------
signal atrig_counter       : std_logic_vector (11 downto 0);
--------------------
-- B Trigger Synchronization
--------------------
signal btrig_sync_reg      : std_logic_vector (1 downto 0);
-- Async Reg
attribute ASYNC_REG of btrig_sync_reg : signal is "TRUE";
--------------------
-- B Trigger Counter
--------------------
signal btrig_counter       : std_logic_vector (11 downto 0);
--------------------
-- Trigger Timeout
--------------------
signal timeout_done        : std_logic;
signal start_timeout_counter : std_logic;
signal timeout_counter     : std_logic_vector (1 downto 0);
constant timeout           : std_logic_vector (1 downto 0) := "10";
--------------------
-- RX Trigger
--------------------
signal trig_rec            : std_logic_vector (2 downto 0);
--------------------
-- Trigger Voter
--------------------
signal trigger_i           : std_logic_vector (11 downto 0);
signal trigger_v_i         : std_logic;

begin
--------------------
-- Trigger Detector
--------------------
trig_det_pr: process(rst, trig_det_reg(trig_det_reg'high), trig_in)
begin
  if rst = '1' or trig_det_reg(trig_det_reg'high) = '1' then
    trig_det_reg(0)    <= '0';
  elsif trig_in'event and trig_in='1' then
    trig_det_reg(0)    <= '1';
  end if;
end process;
trig_shift_pr: process(rst, trig_det_reg(trig_det_reg'high), clk)
begin
  if rst = '1' or (trig_det_reg(trig_det_reg'high)='1') then
    trig_det_reg(trig_det_reg'high-1 DOWNTO 1)    <= (others => '0');
  elsif clk'event and clk='1' then
    trig_det_reg(trig_det_reg'high-1 DOWNTO 1)    <= trig_det_reg(trig_det_reg'high-2 DOWNTO 0);
  end if;
end process;
trig_reset_pr: process(rst, clk)
begin
  if rst = '1' then
    trig_det_reg(trig_det_reg'high)    <= '0';
  elsif clk'event and clk='1' then
    trig_det_reg(trig_det_reg'high)    <= trig_det_reg(trig_det_reg'high-1);
  end if;
end process;
--------------------
-- Trigger Synchronization
--------------------
trig_sync_pr: process(rst, clk)
begin
  if rst = '1' then
    trig_sync_reg     <= "00";
  elsif clk'event and clk='1' then
    trig_sync_reg(0)  <= trig_det_reg(0);
    trig_sync_reg(1)  <= trig_sync_reg(0);
  end if;
end process;
--------------------
-- Trigger Counter
--------------------
trig_counter_pr: process(rst, clk)
begin
  if rst = '1' then
    trig_counter                       <= (others => '0');
  elsif clk'event and clk='1' then
    if trig_sync_reg = "10" then
      trig_counter <= trig_counter + 1;
    else
      trig_counter <= trig_counter;
    end if;
  end if;
end process;
--------------------
-- A Trigger Synchronization
--------------------
atrig_sync_pr: process(rst, clk)
begin
  if rst = '1' then
    atrig_sync_reg     <= "00";
  elsif clk'event and clk='1' then
    atrig_sync_reg(0)  <= atrig_det;
    atrig_sync_reg(1)  <= atrig_sync_reg(0);
  end if;
end process;
--------------------
-- A Trigger Counter
--------------------
atrig_counter_pr: process(rst, clk)
begin
  if rst = '1' then
    atrig_counter                       <= (others => '0');
  elsif clk'event and clk='1' then
    if atrig_sync_reg = "10" then
      atrig_counter <= atrig_counter + 1;
    else
      atrig_counter <= atrig_counter;
    end if;
  end if;
end process;
--------------------
-- B Trigger Synchronization
--------------------
btrig_sync_pr: process(rst, clk)
begin
  if rst = '1' then
    btrig_sync_reg     <= "00";
  elsif clk'event and clk='1' then
    btrig_sync_reg(0)  <= btrig_det;
    btrig_sync_reg(1)  <= btrig_sync_reg(0);
  end if;
end process;
--------------------
-- B Trigger Counter
--------------------
btrig_counter_pr: process(rst, clk)
begin
  if rst = '1' then
    btrig_counter <= (others => '0');
  elsif clk'event and clk='1' then
    if btrig_sync_reg = "10" then
      btrig_counter <= btrig_counter + 1;
    else
      btrig_counter <= btrig_counter;
    end if;
  end if;
end process;
--------------------
-- Trigger Timeout
--------------------
trig_timeout_pr: process(rst, clk)
begin
  if rst = '1' then
    timeout_counter <= (others => '0');
    timeout_done    <= '1';
  elsif clk'event and clk='1' then
    if timeout_counter = timeout then
      timeout_done <= '1';
    elsif start_timeout_counter='1' then
      timeout_done <= '0';
    else
      timeout_done <= timeout_done;
    end if;
    if timeout_done = '0' then
      timeout_counter <= timeout_counter + 1;
    else
      timeout_counter <= (others => '0');
    end if;
  end if;
end process;
--------------------
-- RX Trigger
--------------------
trig_rx_pr: process(rst, clk)
begin
  if rst = '1' then
    start_timeout_counter <= '0';
    trig_rec              <= "000";
  elsif clk'event and clk='1' then
    if (timeout_done = '1') and ((trig_sync_reg = "10") or (atrig_sync_reg = "10") or (btrig_sync_reg = "10")) then
      -- Start Timout Counter and Set RX Triggers
      start_timeout_counter <= '1';
      if trig_sync_reg = "10" then
        trig_rec(0)           <= '1';
      else
        trig_rec(0)           <= '0';
      end if;
      if atrig_sync_reg = "10" then
        trig_rec(1)           <= '1';
      else
        trig_rec(1)           <= '0';
      end if;
      if btrig_sync_reg = "10" then
        trig_rec(2)           <= '1';
      else
        trig_rec(2)           <= '0';
      end if;
    else
      start_timeout_counter <= '0';
      if timeout_done = '0' then
        -- Wait for triggers
        if trig_sync_reg = "10" then
          trig_rec(0)           <= '1';
        else
          trig_rec(0)           <= trig_rec(0);
        end if;
        if atrig_sync_reg = "10" then
          trig_rec(1)           <= '1';
        else
          trig_rec(1)           <= trig_rec(1);
        end if;
        if btrig_sync_reg = "10" then
          trig_rec(2)           <= '1';
        else
          trig_rec(2)           <= trig_rec(2);
        end if;
      else
        -- Timeout Reached
        trig_rec              <= trig_rec;
      end if;
    end if;
  end if;
end process;
--------------------
-- Trigger Voter
--------------------
trig_voter_pr: process(rst, clk)
begin
  if rst = '1' then
    trigger_i    <= (others => '0');
    trigger_v_i  <= '0';
  elsif clk'event and clk='1' then
    if (trig_rec = "111") or (timeout_done='1') then
      -- all triggers received or timeout
      if atrig_counter = btrig_counter then
        -- Send A and B Trigger Number, local trigger number is not checked
        trigger_i    <= atrig_counter;
        trigger_v_i  <= '1';
      elsif atrig_counter = trig_counter then
        -- Send the Least Likely Trigger Number, but is not validated
        trigger_i    <= btrig_counter;
        trigger_v_i  <= '0';
      else
        -- Send the Least Likely Trigger Number, but is not validated
        trigger_i    <= atrig_counter;
        trigger_v_i  <= '0';
      end if;
    else
      -- waiting for trigger or timeout
      trigger_i    <= trigger_i;
      trigger_v_i  <= trigger_v_i;
    end if;
  end if;
end process;
trigger    <= trigger_i   when rw_reg.test_mode='1' and rw_reg.test_trig_mode='0' else trig_counter; --else rw_reg.test_Ntrig;
trigger_v  <= trigger_v_i when rw_reg.test_mode='1' and rw_reg.test_trig_mode='0' else '1';
--------------------
-- Status Register
--------------------
-- Voted Trigger Number Valid
ro_reg.Ntrig_voter_v <= trigger_v_i;
-- Voted Trigger Number
ro_reg.Ntrig_voter   <= trigger_i;
-- Local Trigger Number
ro_reg.Ntrig_local   <= trig_counter;
-- FPGA A Trigger Number
ro_reg.Ntrig_devA    <= atrig_counter;
-- FPGA B Trigger Number
ro_reg.Ntrig_devB    <= btrig_counter;

end rtl;
----------------------------------------------------------------------------------
-- Company: LNF - INFN
-- Authors: Albicocco Pietro
-- Contact: pietro.albicocco@lnf.infn.it
----------------------------------------------------------------------------------
-- File Name: xtest.vhd
-- Target Devices: Xilinx - 7 Series
-- Tool Versions: VIVADO 2015.4
-- Description: Protocol Test Environment.
-- 
-- Dependencies: 
--
----------------------------------------------------------------------------------
-- Revision History:
-- Revision 2.0 - 03/2016 - Albicocco P. - Integrated Test Strategy 
----------------------------------------------------------------------------------
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_unsigned.ALL;

library work;
use work.xpack.all;

entity xtest is
Port (
  clk           : in  STD_LOGIC;
  rst           : in  STD_LOGIC;
  -------- Status Registers -------
  ro_reg        : out ro_reg_type;
  --------  Ctrl Registers  -------
  rw_reg        : in  rw_reg_type;
  -------- Test Control Bit -------
  test_mode     : out STD_LOGIC;
  -------- A FIFO Interface -------
  A_Wr_clk      : in  STD_LOGIC;
  A_Din         : out STD_LOGIC_VECTOR(22-1 DOWNTO 0);
  A_Wr_en       : out STD_LOGIC;
  A_Full        : in  STD_LOGIC;
  A_Almost_full : in  STD_LOGIC;
  A_Prog_full   : in  STD_LOGIC;
  A_busy        : out STD_LOGIC;
  -------- B FIFO Interface -------
  B_Wr_clk      : in  STD_LOGIC;
  B_Din         : out STD_LOGIC_VECTOR(22-1 DOWNTO 0);
  B_Wr_en       : out STD_LOGIC;
  B_Full        : in  STD_LOGIC;
  B_Almost_full : in  STD_LOGIC;
  B_Prog_full   : in  STD_LOGIC;
  B_busy        : out STD_LOGIC
);
end xtest;

architecture rtl of xtest is
------------------------------------------------------------------
---- COMPONENTS DECLARATION ----
------------------------------------------------------------------
--------------------
-- PRBS_ANY
--------------------
component PRBS_ANY 
generic (      
  -- out alp:
  --CHK_MODE: boolean := false; 
  INV_PATTERN     : boolean := false;
  POLY_LENGHT     : natural range 0 to 63  := 31;
  POLY_TAP        : natural range 0 to 63  := 3;
  NBITS           : natural range 0 to 512 := 22
);
port (
  -- in alp:
  CHK_MODE        : in  std_logic;
  RST             : in  std_logic;                            -- sync reset active high
  CLK             : in  std_logic;                            -- system clock
  DATA_IN         : in  std_logic_vector(NBITS - 1 downto 0); -- inject error/data to be checked
  EN              : in  std_logic;                            -- enable/pause pattern generation
  DATA_OUT        : out std_logic_vector(NBITS - 1 downto 0)  -- generated prbs pattern/errors found
);
end component;
------------------------------------------------------------------
---- CONSTANTS  DECLARATION ----
------------------------------------------------------------------
--------------------
-- PRBS_ANY
--------------------
-- PRBS-15 Settings
constant A_INV_PATTERN : boolean := true;
constant B_INV_PATTERN : boolean := false;
constant POLY_LENGHT   : natural range 0 to 63  := 15;
constant POLY_TAP      : natural range 0 to 63  := 14;
------------------------------------------------------------------
---- SIGNALS    DECLARATION ----
------------------------------------------------------------------
-- test mode: 0 Disable, 1 Enable.
SIGNAL test             : STD_LOGIC;
--------------------
-- PRBS_ANY: A DATA GENERATION
--------------------
SIGNAL a_inj            : STD_LOGIC_VECTOR(11 downto 0);
SIGNAL a_req            : STD_LOGIC;
SIGNAL areq             : STD_LOGIC;
SIGNAL a_data           : STD_LOGIC_VECTOR(11 downto 0);
--------------------
-- PRBS_ANY: A EVENT GENERATION
--------------------
SIGNAL an               : STD_LOGIC_VECTOR(5 DOWNTO 0);
SIGNAL an_10bit         : STD_LOGIC_VECTOR(9 DOWNTO 0);
SIGNAL aev_req          : STD_LOGIC;
--------------------
-- A FIFO WRITE
--------------------
SIGNAL adone            : STD_LOGIC;
SIGNAL acnt             : STD_LOGIC_VECTOR(6 downto 0);
SIGNAL achannel         : STD_LOGIC_VECTOR(6 downto 0);
--------------------
-- A FIFO STIMULI
--------------------
SIGNAL aw               : STD_LOGIC;
SIGNAL ad               : STD_LOGIC_VECTOR(21 downto 0);
SIGNAL A_Din_i          : STD_LOGIC_VECTOR(21 downto 0);
SIGNAL ainc             : STD_LOGIC_VECTOR(11 downto 0);
SIGNAL adone_reg        : STD_LOGIC;
--------------------
-- PRBS_ANY: B DATA GENERATION
--------------------
SIGNAL b_inj            : STD_LOGIC_VECTOR(11 downto 0);
SIGNAL b_req            : STD_LOGIC;
SIGNAL breq             : STD_LOGIC;
SIGNAL b_data           : STD_LOGIC_VECTOR(11 downto 0);
--------------------
-- PRBS_ANY: B EVENT GENERATION
--------------------
SIGNAL bn               : STD_LOGIC_VECTOR(5 DOWNTO 0);
SIGNAL bn_10bit         : STD_LOGIC_VECTOR(9 DOWNTO 0);
SIGNAL bev_req          : STD_LOGIC;
--------------------
-- B FIFO WRITE
--------------------
SIGNAL bdone            : STD_LOGIC;
SIGNAL bcnt             : STD_LOGIC_VECTOR(6 downto 0);
SIGNAL bchannel         : STD_LOGIC_VECTOR(6 downto 0);
--------------------
-- B FIFO STIMULI
--------------------
SIGNAL bw               : STD_LOGIC;
SIGNAL bd               : STD_LOGIC_VECTOR(21 downto 0);
SIGNAL B_Din_i          : STD_LOGIC_VECTOR(21 downto 0);
SIGNAL binc             : STD_LOGIC_VECTOR(11 downto 0);
SIGNAL bdone_reg        : STD_LOGIC;

begin

--------------------
-- rw_reg assignments
--------------------
test              <= rw_reg.test_mode;
test_mode         <= rw_reg.test_mode;
A_busy            <= rw_reg.A_is_busy;
B_busy            <= rw_reg.B_is_busy;
--------------------
-- ro_reg assignments
--------------------
ro_reg.atest_Ntrig    <= ainc;
ro_reg.btest_Ntrig    <= binc;

--------------------
-- PRBS_ANY: A DATA GENERATION
--------------------
areq <= a_req and not A_Almost_full;
a_inj <= (others => '0');
a_data_gen: PRBS_ANY 
 GENERIC MAP(
    INV_PATTERN => A_INV_PATTERN,
    POLY_LENGHT => POLY_LENGHT,              
    POLY_TAP    => POLY_TAP,
    NBITS       => a_data'high+1
 )
 PORT MAP(
  CHK_MODE      => '0',
  RST           => rst,
  CLK           => A_Wr_clk,
  DATA_IN       => a_inj,
  EN            => areq,
  DATA_OUT      => a_data
);
--------------------
-- PRBS_ANY: B DATA GENERATION
--------------------
breq <= b_req and not B_Almost_full;
b_inj <= (others => '0');
b_data_gen: PRBS_ANY 
 GENERIC MAP(
    INV_PATTERN => B_INV_PATTERN,
    POLY_LENGHT => POLY_LENGHT,              
    POLY_TAP    => POLY_TAP,
    NBITS       => b_data'high+1
 )
 PORT MAP(
  CHK_MODE      => '0',
  RST           => rst,
  CLK           => B_Wr_clk,
  DATA_IN       => b_inj,
  EN            => breq,
  DATA_OUT      => b_data
);
--------------------
-- PRBS_ANY: A EVENT GENERATION
--------------------
aevent_gen: PRBS_ANY 
 GENERIC MAP(
    INV_PATTERN => A_INV_PATTERN,
    POLY_LENGHT => POLY_LENGHT,              
    POLY_TAP    => POLY_TAP,
    NBITS       => 10
 )
 PORT MAP(
  CHK_MODE      => '0',
  RST           => rst,
  CLK           => A_Wr_clk,
  DATA_IN       => (others=>'0'),
  EN            => aev_req,
  DATA_OUT      => an_10bit
);
an <= std_logic_vector( unsigned('0' & an_10bit(9 downto 5)) + unsigned(an_10bit(4 downto 1)) + unsigned(an_10bit(0 downto 0)) );
--------------------
-- PRBS_ANY: B EVENT GENERATION
--------------------
bevent_gen: PRBS_ANY 
 GENERIC MAP(
    INV_PATTERN => B_INV_PATTERN,
    POLY_LENGHT => POLY_LENGHT,              
    POLY_TAP    => POLY_TAP,
    NBITS       => 10
 )
 PORT MAP(
  CHK_MODE      => '0',
  RST           => rst,
  CLK           => B_Wr_clk,
  DATA_IN       => (others=>'0'),
  EN            => bev_req,
  DATA_OUT      => bn_10bit
);
bn <= std_logic_vector( unsigned('0' & bn_10bit(9 downto 5)) + unsigned(bn_10bit(4 downto 1)) + unsigned(bn_10bit(0 downto 0)) );
--------------------
-- A FIFO STIMULI
--------------------
-- Data from FIFO:
--    a_d/b_d: 22 bit data
--      00&DATA| is data  , not last  , DATA
--      01&DATA| is data  , is  last  , DATA
--      10&EV_N| is header, data exist, EVENT NUMBER
--      11&EV_N| is header, no data   , EVENT NUMBER
--    a_dv/b_dv: data valid
astim_pr: process(rst, A_Wr_clk)
variable a_dataexist  : std_logic := '0';
variable a_dataislast : std_logic := '0';
begin
  if rst = '1' then
    ainc         <= (others => '0');
    aw           <= '0';
    a_dataexist  := '0';
    a_dataislast := '0';
    adone_reg    <= '0';
    ad           <= (others => '0');
  elsif A_Wr_clk'event and A_Wr_clk='1' then
    adone_reg    <= adone;
    ainc         <= ainc;
    aw           <= '0';
    if adone = '1' then
      -- Start a new write process
      aw           <= '1';
      if adone_reg = '0' then
        -- Increment trigger number
        ainc          <= std_logic_vector( unsigned(ainc) + 1);
      end if;
    else
      -- Provide words to be written (Header or Data)
      if acnt = std_logic_vector(to_unsigned(0, acnt'high)) then
        -- Heaader
        if an/=std_logic_vector(to_unsigned(0, acnt'high)) then
          a_dataexist := '0';
        else 
          a_dataexist := '1';
        end if;
        ad <= '1' & a_dataexist & X"00" & ainc;
      else
        -- Data
        if acnt=an then
          a_dataislast := '1';
        else 
          a_dataislast := '0';
        end if;
        ad <= '0' & a_dataislast & achannel & '0' & a_data;
      end if;
    end if;
    if A_Almost_full='1' then
      -- Wait until A_Almost_full='0'
      ad <= ad;
    end if;
    if test = '0' then
      -- Test mode is disabled
      ainc         <= (others => '0');
      aw           <= '0';
      a_dataexist  := '0';
      a_dataislast := '0';
      adone_reg    <= '0';
    end if;
  end if;
end process;
--------------------
-- B FIFO STIMULI
--------------------
-- Data from FIFO:
--    a_d/b_d: 22 bit data
--      00&DATA| is data  , not last  , DATA
--      01&DATA| is data  , is  last  , DATA
--      10&EV_N| is header, data exist, EVENT NUMBER
--      11&EV_N| is header, no data   , EVENT NUMBER
--    a_dv/b_dv: data valid
bstim_pr: process(rst, B_Wr_clk)
variable b_dataexist  : std_logic := '0';
variable b_dataislast : std_logic := '0';
begin
  if rst = '1' then
    binc         <= (others => '0');
    bw           <= '0';
    b_dataexist  := '0';
    b_dataislast := '0';
    bdone_reg    <= '0';
    bd           <= (others => '0');
  elsif B_Wr_clk'event and B_Wr_clk='1' then
    bdone_reg    <= bdone;
    binc         <= binc;
    bw           <= '0';
    if bdone = '1' then
      -- Start a new write process
      bw           <= '1';
      if bdone_reg = '0' then
        -- Increment trigger number
        binc          <= std_logic_vector( unsigned(binc) + 1 );
      end if;
    else
      -- Provide words to be written (Header or Data)
      if bcnt = std_logic_vector(to_unsigned(0, bcnt'high)) then
        -- Heaader
        if bn/=std_logic_vector(to_unsigned(0, bcnt'high)) then
          b_dataexist := '0';
        else 
          b_dataexist :=  '1';
        end if;
        bd <= '1' & b_dataexist & X"00" & binc;
      else
        -- Data
        if bcnt=bn then
          b_dataislast := '1';
        else 
          b_dataislast :=  '0';
        end if;
        bd <= '0' & b_dataislast & bchannel & '0' & b_data;
      end if;
    end if;
    if B_Almost_full='1' then
      -- Wait until B_Almost_full='0'
      bd <= bd;
    end if;
    if test = '0' then
      -- Test mode is disabled
      binc         <= (others => '0');
      bw           <= '0';
      b_dataexist  := '0';
      b_dataislast := '0';
      bdone_reg    <= '0';
    end if;
  end if;
end process;
--------------------
-- A FIFO WRITE
--------------------
A_Din <= A_Din_i;
aw_pr: process(rst, A_Wr_clk)
begin
  if rst = '1' then
    acnt    <= (others => '0');
    achannel<= (others => '0');
    adone   <= '1';
    A_Din_i <= (others => '0');
    A_Wr_en <= '0';
    a_req   <= '1';
    aev_req <= '0';
  elsif A_Wr_clk'event and A_Wr_clk='1' then
    acnt    <= (others => '0');
    achannel<= (others => '0');
    adone   <= '1';
    A_Din_i <= (others => '0');
    A_Wr_en <= '0';
    a_req   <= a_req;
    aev_req <= '0';
    if aw = '1' or adone = '0' then
    -- Start FIFO Write
      adone   <= '0';
      if acnt <= std_logic_vector( unsigned(an)+1) then
      -- Write all requested data (1 header + an data)
        A_Din_i <= ad;
        A_Wr_en <= not aw;
        if adone='0' then
          acnt    <= std_logic_vector(unsigned(acnt) + 1);
        else
          acnt    <= acnt;
        end if;
        achannel<= acnt;
        if (acnt = an) or (acnt = std_logic_vector( unsigned(an)+1)) then
          -- Do not request new data
          a_req   <= '0';
        elsif acnt = std_logic_vector(to_unsigned(0,acnt'high)) then
          -- Request new data
          a_req   <= not adone;
        else
          -- Request next data
          a_req   <= '1';
        end if;
        if A_Almost_full='1' then
          -- Wait until A_Almost_full='0'
          A_Wr_en <= '0';
          A_Din_i <= A_Din_i;
          acnt    <= acnt;
          achannel<= achannel;
          a_req   <= a_req;
        end if;
      else
        -- Done
        adone   <= '1';
        -- Request new event
        aev_req <= '1';
      end if;
    end if;
    if test = '0' then
      -- Test mode is disabled
      acnt    <= (others => '0');
      achannel<= (others => '0');
      adone   <= '1';
      A_Din_i <= (others => '0');
      A_Wr_en <= '0';
      a_req   <= '0';
      aev_req <= '0';
    end if;
  end if;
end process;
--------------------
-- B FIFO WRITE
--------------------
B_Din <= B_Din_i;
bw_pr: process(rst, B_Wr_clk)
begin
  if rst = '1' then
    bcnt    <= (others => '0');
    bchannel<= (others => '0');
    bdone   <= '1';
    B_Din_i <= (others => '0');
    B_Wr_en <= '0';
    b_req   <= '1';
    bev_req <= '0';
  elsif B_Wr_clk'event and B_Wr_clk='1' then
    bcnt    <= (others => '0');
    bchannel<= (others => '0');
    bdone   <= '1';
    B_Din_i <= (others => '0');
    B_Wr_en <= '0';
    b_req   <= b_req;
    bev_req <= '0';
    if bw = '1' or bdone = '0' then
    -- Start FIFO Write
      bdone   <= '0';
      if bcnt <= std_logic_vector( unsigned(bn)+1) then
      -- Write all requested data (1 header + an data)
        B_Din_i <= bd;
        B_Wr_en <= not bw;
        if bdone='0' then
          -- Write Header
          bcnt    <= std_logic_vector(unsigned(bcnt) + 1);
        else
          -- Write Data
          bcnt    <= bcnt;
        end if;
        bchannel<= bcnt;
        if (bcnt = bn) or (bcnt = std_logic_vector( unsigned(bn)+1)) then
          -- Do not request new data
          b_req   <= '0';
        elsif bcnt = std_logic_vector( to_unsigned(0,bcnt'high) ) then
          -- Request new data
          b_req   <= not bdone;
        else
          -- Request next data
          b_req   <= '1';
        end if;
        if B_Almost_full='1' then
          -- Wait until B_Almost_full='0'
          B_Wr_en <= '0';
          B_Din_i <= B_Din_i;
          bcnt    <= bcnt;
          bchannel<= bchannel;
          b_req   <= b_req;
        end if;
      else
        -- Done
        bdone   <= '1';
        -- Request new event
        bev_req <= '1';
      end if;
    end if;
    if test = '0' then
      -- Test mode is disabled
      bcnt    <= (others => '0');
      bchannel<= (others => '0');
      bdone   <= '1';
      B_Din_i <= (others => '0');
      B_Wr_en <= '0';
      b_req   <= '0';
      bev_req <= '0';
    end if;
  end if;
end process;

end rtl;
----------------------------------------------------------------------------------
-- Company: LNF - INFN
-- Authors: Albicocco Pietro
-- Contact: pietro.albicocco@lnf.infn.it
----------------------------------------------------------------------------------
-- File Name: xfifo.vhd
-- Target Devices: Xilinx - 7 Series
-- Tool Versions: VIVADO 2015.4
-- Description: 2 FIFO receiving data from AFE.
-- 
-- Dependencies: 
--
----------------------------------------------------------------------------------
-- Revision History:
-- Revision 1.0 - 02/2016 - Albicocco P. - First Version
-- Revision 2.0 - 03/2016 - Albicocco P. - Integrated Test Strategy 
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
  A_Prog_full   : out STD_LOGIC;
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
  B_Prog_full   : out STD_LOGIC;
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
  Almost_full : out STD_LOGIC;
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
  Almost_full => A_Almost_full,
  prog_full   => A_Prog_full,
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
  Almost_full => B_Almost_full,
  prog_full   => B_Prog_full,
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
-- Tool Versions: VIVADO 2015.4
-- Description: 
-- xCTRL provide data saved in FIFO to the auxbus when requested.
-- 
-- Dependencies: 
--
----------------------------------------------------------------------------------
-- Revision History:
-- Revision 1.0 - 02/2016 - Albicocco P. - First Version
-- Revision 2.0 - 03/2016 - Albicocco P. - Integrated Test Strategy 
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
        -- Request new A and B Header
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
    -- Both Headers found: go in send state and request new data to be sent
      b_header  <= get_header(b_d, b_dv);
      x_hdr_dv   <= '1';
      if dataexist(a_d, a_dv) and dataexist(b_d, b_dv) then
      -- Disable B, Request A
        nstate   <= SEND_ABDATA;
        b_rd_en  <= '0';
      elsif dataexist(a_d, a_dv) then
      -- Disable B, Request A
        nstate   <= SEND_A_DATA;
        b_rd_en  <= '0';
      elsif dataexist(b_d, b_dv) then
      -- Disable A, Request B
        nstate   <= SEND_B_DATA;
        a_rd_en  <= '0';
      else
      -- Request new A and B Header
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
    x_d      <= std_logic_vector(unsigned(b_d(19 downto 0))+unsigned((std_logic_vector(to_unsigned(48,7)) & '0' & x"000")));
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
-- Tool Versions: VIVADO 2015.4
-- Description: xFRONT manage the auxbus signals.
-- 
-- Dependencies: 
--
----------------------------------------------------------------------------------
-- Revision History:
-- Revision 1.0 - 02/2016 - Albicocco P. - First Version
-- Revision 2.0 - 03/2016 - Albicocco P. - Integrated Test Strategy 
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

library work;
use work.xpack.all;

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
constant thold15             : integer := (1000*(15+clock_period)-1)/1000/clock_period;
--------------------
-- Counter
--------------------
constant Ncnt				        : integer := 1+log2(thold15);
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
--obusy_n <= not full;

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
ocomb_pr: process(pstate,ids, cvalid, ssel, i_last, ias_n, i_d, isyncrd_n, first_word_flag_r, i_nodata, i_dv, i_t, i_tv, i_hdr_d, i_mmatch, i_hdr_dv, it) is
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
    obusy_n <= not full;
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
      read_data <= i_nodata and isyncrd_n;
    end if;
    -------- ROCK OPEN COLLECOTR INPUT -------
    -- Slave has an error, Active LOW
    oberr_n <= '1';
    -- Slave is full, Active LOW
    obusy_n <= not full;
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
    obusy_n <= not full;
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
    obusy_n <= not full;
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
-- Tool Versions: VIVADO 2015.4
-- Description: IBUFV extents the IBUF primitive to std_logic_vectors.
-- 
-- Dependencies: 
--
----------------------------------------------------------------------------------
-- Revision History:
-- Revision 1.0 - 02/2016 - Albicocco P. - First Version
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
-- Tool Versions: VIVADO 2015.4
-- Description: OBUFTV extents the OBUFTV primitive to std_logic_vectors.
-- 
-- Dependencies: 
--
----------------------------------------------------------------------------------
-- Revision History:
-- Revision 1.0 - 02/2016 - Albicocco P. - First Version
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
----------------------------------------------------------------------------------
-- Company: LNF - INFN
-- Authors: Albicocco Pietro
-- Contact: pietro.albicocco@lnf.infn.it
----------------------------------------------------------------------------------
-- File Name: xaxi.vhd
-- Target Devices: Xilinx - 7 Series
-- Tool Versions: VIVADO 2015.4
-- Description: Protocol Test Environment.
-- 
-- Dependencies: 
--
----------------------------------------------------------------------------------
-- Revision History:
-- Revision 2.0 - 03/2016 - Albicocco P. - Integrated Test Strategy 
----------------------------------------------------------------------------------
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.xpack.all;

entity xaxi is
  generic (
    -- Width of S_AXI data bus
    C_S_AXI_DATA_WIDTH  : integer := 32;
    -- Width of S_AXI address bus
    C_S_AXI_ADDR_WIDTH  : integer := 9
  );
  port (
    -------- Status Registers -------
    ro_reg        : in  ro_reg_type;
    --------  Ctrl Registers  -------
    rw_reg        : out rw_reg_type;
    --------   AXI-4  PORTS   -------
    -- Global Clock Signal
    S_AXI_ACLK  : in std_logic;
    -- Global Reset Signal. This Signal is Active LOW
    S_AXI_ARESETN : in std_logic;
    -- Write address (issued by master, acceped by Slave)
    S_AXI_AWADDR  : in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    -- Write channel Protection type. This signal indicates the
        -- privilege and security level of the transaction, and whether
        -- the transaction is a data access or an instruction access.
    S_AXI_AWPROT  : in std_logic_vector(2 downto 0);
    -- Write address valid. This signal indicates that the master signaling
        -- valid write address and control information.
    S_AXI_AWVALID : in std_logic;
    -- Write address ready. This signal indicates that the slave is ready
        -- to accept an address and associated control signals.
    S_AXI_AWREADY : out std_logic;
    -- Write data (issued by master, acceped by Slave) 
    S_AXI_WDATA : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    -- Write strobes. This signal indicates which byte lanes hold
        -- valid data. There is one write strobe bit for each eight
        -- bits of the write data bus.    
    S_AXI_WSTRB : in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
    -- Write valid. This signal indicates that valid write
        -- data and strobes are available.
    S_AXI_WVALID  : in std_logic;
    -- Write ready. This signal indicates that the slave
        -- can accept the write data.
    S_AXI_WREADY  : out std_logic;
    -- Write response. This signal indicates the status
        -- of the write transaction.
    S_AXI_BRESP : out std_logic_vector(1 downto 0);
    -- Write response valid. This signal indicates that the channel
        -- is signaling a valid write response.
    S_AXI_BVALID  : out std_logic;
    -- Response ready. This signal indicates that the master
        -- can accept a write response.
    S_AXI_BREADY  : in std_logic;
    -- Read address (issued by master, acceped by Slave)
    S_AXI_ARADDR  : in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    -- Protection type. This signal indicates the privilege
        -- and security level of the transaction, and whether the
        -- transaction is a data access or an instruction access.
    S_AXI_ARPROT  : in std_logic_vector(2 downto 0);
    -- Read address valid. This signal indicates that the channel
        -- is signaling valid read address and control information.
    S_AXI_ARVALID : in std_logic;
    -- Read address ready. This signal indicates that the slave is
        -- ready to accept an address and associated control signals.
    S_AXI_ARREADY : out std_logic;
    -- Read data (issued by slave)
    S_AXI_RDATA : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    -- Read response. This signal indicates the status of the
        -- read transfer.
    S_AXI_RRESP : out std_logic_vector(1 downto 0);
    -- Read valid. This signal indicates that the channel is
        -- signaling the required read data.
    S_AXI_RVALID  : out std_logic;
    -- Read ready. This signal indicates that the master can
        -- accept the read data and response information.
    S_AXI_RREADY  : in std_logic
  );
end xaxi;

architecture arch_imp of xaxi is

  -- Read Only Registers
  type ro_reg_mat_type is array (69 DOWNTO 0) of std_logic_vector (31 DOWNTO 0);
  signal ro_reg_mat : ro_reg_mat_type := (others => (others =>'0'));
  -- AXI4LITE signals
  signal axi_awaddr : std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
  signal axi_awready: std_logic;
  signal axi_wready : std_logic;
  signal axi_bresp  : std_logic_vector(1 downto 0);
  signal axi_bvalid : std_logic;
  signal axi_araddr : std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
  signal axi_arready: std_logic;
  signal axi_rdata  : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal axi_rresp  : std_logic_vector(1 downto 0);
  signal axi_rvalid : std_logic;
  -- FIFO Signals
  signal A_req       : std_logic := '0';
  signal A_req_r     : std_logic := '0';
  signal B_req       : std_logic := '0';
  signal B_req_r     : std_logic := '0';

  -- Example-specific design signals
  -- local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
  -- ADDR_LSB is used for addressing 32/64 bit registers/memories
  -- ADDR_LSB = 2 for 32 bits (n downto 2)
  -- ADDR_LSB = 3 for 64 bits (n downto 3)
  constant ADDR_LSB  : integer := (C_S_AXI_DATA_WIDTH/32)+ 1;
  constant OPT_MEM_ADDR_BITS : integer := 6;
  ------------------------------------------------
  ---- Signals for user logic register space example
  --------------------------------------------------
  ---- Number of Slave Registers 128
  -- Reset Register
  signal slv_reg0   :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0) := ( x"0000000" & '0' &             -- 31 DOWNTO 3
                                                                          rw_defaults.triggerreset &     -- 2: Trigger Counters Reset (A+B+Local)
                                                                          rw_defaults.fiforeset &        -- 1: Reset FIFOs
                                                                          rw_defaults.reset );           -- 0: Reset Aux Bus
  -- Test Register
  signal slv_reg1   :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0) := ( x"0000" &                      -- 31 DOWNTO 16
                                                                          rw_defaults.test_Ntrig &       -- 15 DOWNTO 4: Unused
                                                                          rw_defaults.B_is_busy &        -- 3: B Busy flag in test mode
                                                                          rw_defaults.A_is_busy &        -- 2: A Busy flag in test mode
                                                                          rw_defaults.test_trig_mode &   -- 1: Trigger Test Mode : '0' : count real trigger, '1' : Count trigger only in Local FPGA
                                                                          rw_defaults.test_mode );       -- 0: Enable Test Mode: 0 Disable, 1 Enable.
  -- FIFO Control Register
  signal slv_reg2   :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0) := ( x"0000_00" & b"00" &           -- 31 DOWNTO 6
                                                                          rw_defaults.B_FIFO_write_en &  -- 5: Enable Write from B FIFO
                                                                          rw_defaults.A_FIFO_write_en &  -- 4: Enable Write from A FIFO
                                                                          b"00" &                        -- 3 DOWNTO 2
                                                                          rw_defaults.B_FIFO_read_en &   -- 1: Enable Read from B FIFO
                                                                          rw_defaults.A_FIFO_read_en );  -- 0: Enable Read from A FIFO
  -- A FIFO Write Data
  signal slv_reg3   :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);-- := ( rw_defaults.A_write_data );    -- 22 DOWNTO 0
  -- B FIFO Write DATA
  signal slv_reg4   :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);-- := ( rw_defaults.B_write_data );    -- 22 DOWNTO 0
  signal slv_reg5   :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg6   :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg7   :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg8   :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg9   :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg10  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg11  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg12  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg13  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg14  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg15  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg16  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg17  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg18  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg19  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg20  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg21  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg22  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg23  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg24  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg25  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg26  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg27  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg28  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg29  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg30  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg31  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg32  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg33  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg34  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg35  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg36  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg37  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg38  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg39  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg40  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg41  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg42  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg43  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg44  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg45  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg46  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg47  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg48  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg49  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg50  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg51  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg52  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg53  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg54  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg55  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg56  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg57  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg58  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg59  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg60  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg61  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg62  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg63  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg64  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg65  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg66  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg67  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg68  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg69  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg70  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg71  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg72  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg73  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg74  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg75  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg76  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg77  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg78  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg79  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg80  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg81  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg82  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg83  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg84  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg85  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg86  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg87  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg88  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg89  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg90  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg91  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg92  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg93  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg94  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg95  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg96  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg97  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg98  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg99  :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg100 :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg101 :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg102 :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg103 :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg104 :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg105 :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg106 :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg107 :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg108 :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg109 :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg110 :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg111 :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg112 :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg113 :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg114 :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg115 :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg116 :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg117 :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg118 :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg119 :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg120 :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg121 :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg122 :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg123 :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg124 :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg125 :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg126 :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg127 :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal slv_reg_rden : std_logic;
  signal slv_reg_wren : std_logic;
  signal reg_data_out :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal byte_index : integer;

begin

--areset <= not S_AXI_ARESETN;
  -- I/O Connections assignments

  S_AXI_AWREADY <= axi_awready;
  S_AXI_WREADY  <= axi_wready;
  S_AXI_BRESP <= axi_bresp;
  S_AXI_BVALID  <= axi_bvalid;
  S_AXI_ARREADY <= axi_arready;
  S_AXI_RDATA <= axi_rdata;
  S_AXI_RRESP <= axi_rresp;
  S_AXI_RVALID  <= axi_rvalid;
  -- Implement axi_awready generation
  -- axi_awready is asserted for one S_AXI_ACLK clock cycle when both
  -- S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
  -- de-asserted when reset is low.

  process (S_AXI_ACLK)
  begin
    if rising_edge(S_AXI_ACLK) then 
      if S_AXI_ARESETN = '0' then
        axi_awready <= '0';
      else
        if (axi_awready = '0' and S_AXI_AWVALID = '1' and S_AXI_WVALID = '1') then
          -- slave is ready to accept write address when
          -- there is a valid write address and write data
          -- on the write address and data bus. This design 
          -- expects no outstanding transactions.
          if S_AXI_AWADDR = b"0000011" & "00" then
            axi_awready <= not ro_reg.A_afull;
          elsif S_AXI_AWADDR = b"0000100" & "00" then
            axi_awready <= not ro_reg.B_afull;
          else
            axi_awready <= '1';
          end if; 
        else
          axi_awready <= '0';
        end if;
      end if;
    end if;
  end process;

  -- Implement axi_awaddr latching
  -- This process is used to latch the address when both 
  -- S_AXI_AWVALID and S_AXI_WVALID are valid. 

  process (S_AXI_ACLK)
  begin
    if rising_edge(S_AXI_ACLK) then 
      if S_AXI_ARESETN = '0' then
        axi_awaddr <= (others => '0');
      else
        if (axi_awready = '0' and S_AXI_AWVALID = '1' and S_AXI_WVALID = '1') then
          -- Write Address latching
          axi_awaddr <= S_AXI_AWADDR;
        end if;
      end if;
    end if;                   
  end process; 

  -- Implement axi_wready generation
  -- axi_wready is asserted for one S_AXI_ACLK clock cycle when both
  -- S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is 
  -- de-asserted when reset is low. 

  process (S_AXI_ACLK)
  begin
    if rising_edge(S_AXI_ACLK) then 
      if S_AXI_ARESETN = '0' then
        axi_wready <= '0';
      else
        if (axi_wready = '0' and S_AXI_WVALID = '1' and S_AXI_AWVALID = '1') then
            -- slave is ready to accept write data when 
            -- there is a valid write address and write data
            -- on the write address and data bus. This design 
            -- expects no outstanding transactions.           
            if S_AXI_AWADDR = b"0000011" & "00" then
              axi_wready <= not ro_reg.A_afull;
            elsif S_AXI_AWADDR = b"0000100" & "00" then
              axi_wready <= not ro_reg.B_afull;
            else
              axi_wready <= '1';
            end if; 
        else
          axi_wready <= '0';
        end if;
      end if;
    end if;
  end process; 

  -- Implement memory mapped register select and write logic generation
  -- The write data is accepted and written to memory mapped registers when
  -- axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
  -- select byte enables of slave registers while writing.
  -- These registers are cleared when reset (active low) is applied.
  -- Slave register write enable is asserted when valid address and data are available
  -- and the slave is ready to accept the write address and write data.
  slv_reg_wren <= axi_wready and S_AXI_WVALID and axi_awready and S_AXI_AWVALID ;

  process (S_AXI_ACLK)
  variable loc_addr :std_logic_vector(OPT_MEM_ADDR_BITS downto 0); 
  begin
    if rising_edge(S_AXI_ACLK) then 
      rw_reg.A_write_data <= (others => '0');
      rw_reg.A_write_en   <= '0';
      rw_reg.B_write_data <= (others => '0');
      rw_reg.B_write_en   <= '0';
      if S_AXI_ARESETN = '0' then
        -- Reset Register
  -- Reset Register
        slv_reg0    <= ( x"0000000" & '0' &             -- 31 DOWNTO 3 
                         rw_defaults.triggerreset &     -- 2           
                         rw_defaults.fiforeset &        -- 1           
                         rw_defaults.reset );           -- 0            
        -- Test Register
        slv_reg1    <= ( x"0000" &                      -- 31 DOWNTO 16
                         rw_defaults.test_Ntrig &       -- 15 DOWNTO 4 
                         rw_defaults.B_is_busy &        -- 3           
                         rw_defaults.A_is_busy &        -- 2           
                         rw_defaults.test_trig_mode &   -- 1           
                         rw_defaults.test_mode );       -- 0           
        slv_reg2    <= ( x"0000_00" & b"00" &           -- 31 DOWNTO 2
                         rw_defaults.B_FIFO_write_en &  -- 5: Enable Read from B FIFO
                         rw_defaults.A_FIFO_write_en &  -- 4: Enable Read from A FIFO
                         b"00" &                        -- 3 DOWNTO 2
                         rw_defaults.B_FIFO_read_en &   -- 1: Enable Read from B FIFO
                         rw_defaults.A_FIFO_read_en );  -- 0: Enable Read from A FIFO
        -- A Write Data (reg 3): rw_reg.A_write_data
        slv_reg3    <= (others => '0');
        -- B Write Data (reg 4): rw_reg.B_write_data
        slv_reg4    <= (others => '0');
        --
        slv_reg5    <= (others => '0');
        slv_reg6    <= (others => '0');
        slv_reg7    <= (others => '0'); 
        slv_reg8    <= (others => '0');
        slv_reg9    <= (others => '0');
        slv_reg10   <= (others => '0');
        slv_reg11   <= (others => '0');
        slv_reg12   <= (others => '0');
        slv_reg13   <= (others => '0');
        slv_reg14   <= (others => '0');
        slv_reg15   <= (others => '0');
        slv_reg16   <= (others => '0');
        slv_reg17   <= (others => '0');
        slv_reg18   <= (others => '0');
        slv_reg19   <= (others => '0');
        slv_reg20   <= (others => '0');
        slv_reg21   <= (others => '0');
        slv_reg22   <= (others => '0');
        slv_reg23   <= (others => '0');
        slv_reg24   <= (others => '0');
        slv_reg25   <= (others => '0');
        slv_reg26   <= (others => '0');
        slv_reg27   <= (others => '0');
        slv_reg28   <= (others => '0');
        slv_reg29   <= (others => '0');
        slv_reg30   <= (others => '0');
        slv_reg31   <= (others => '0');
        slv_reg32   <= (others => '0');
        slv_reg33   <= (others => '0');
        slv_reg34   <= (others => '0');
        slv_reg35   <= (others => '0');
        slv_reg36   <= (others => '0');
        slv_reg37   <= (others => '0');
        slv_reg38   <= (others => '0');
        slv_reg39   <= (others => '0');
        slv_reg40   <= (others => '0');
        slv_reg41   <= (others => '0');
        slv_reg42   <= (others => '0');
        slv_reg43   <= (others => '0');
        slv_reg44   <= (others => '0');
        slv_reg45   <= (others => '0');
        slv_reg46   <= (others => '0');
        slv_reg47   <= (others => '0');
        slv_reg48   <= (others => '0');
        slv_reg49   <= (others => '0');
        slv_reg50   <= (others => '0');
        slv_reg51   <= (others => '0');
        slv_reg52   <= (others => '0');
        slv_reg53   <= (others => '0');
        slv_reg54   <= (others => '0');
        slv_reg55   <= (others => '0');
        slv_reg56   <= (others => '0');
        slv_reg57   <= (others => '0');
        slv_reg58   <= (others => '0');
        slv_reg59   <= (others => '0');
        slv_reg60   <= (others => '0');
        slv_reg61   <= (others => '0');
        slv_reg62   <= (others => '0');
        slv_reg63   <= (others => '0');
        slv_reg64   <= (others => '0');
        slv_reg65   <= (others => '0');
        slv_reg66   <= (others => '0');
        slv_reg67   <= (others => '0');
        slv_reg68   <= (others => '0');
        slv_reg69   <= (others => '0');
        slv_reg70   <= (others => '0');
        slv_reg71   <= (others => '0');
        slv_reg72   <= (others => '0');
        slv_reg73   <= (others => '0');
        slv_reg74   <= (others => '0');
        slv_reg75   <= (others => '0');
        slv_reg76   <= (others => '0');
        slv_reg77   <= (others => '0');
        slv_reg78   <= (others => '0');
        slv_reg79   <= (others => '0');
        slv_reg80   <= (others => '0');
        slv_reg81   <= (others => '0');
        slv_reg82   <= (others => '0');
        slv_reg83   <= (others => '0');
        slv_reg84   <= (others => '0');
        slv_reg85   <= (others => '0');
        slv_reg86   <= (others => '0');
        slv_reg87   <= (others => '0');
        slv_reg88   <= (others => '0');
        slv_reg89   <= (others => '0');
        slv_reg90   <= (others => '0');
        slv_reg91   <= (others => '0');
        slv_reg92   <= (others => '0');
        slv_reg93   <= (others => '0');
        slv_reg94   <= (others => '0');
        slv_reg95   <= (others => '0');
        slv_reg96   <= (others => '0');
        slv_reg97   <= (others => '0');
        slv_reg98   <= (others => '0');
        slv_reg99   <= (others => '0');
        slv_reg100  <= (others => '0');
        slv_reg101  <= (others => '0');
        slv_reg102  <= (others => '0');
        slv_reg103  <= (others => '0');
        slv_reg104  <= (others => '0');
        slv_reg105  <= (others => '0');
        slv_reg106  <= (others => '0');
        slv_reg107  <= (others => '0');
        slv_reg108  <= (others => '0');
        slv_reg109  <= (others => '0');
        slv_reg110  <= (others => '0');
        slv_reg111  <= (others => '0');
        slv_reg112  <= (others => '0');
        slv_reg113  <= (others => '0');
        slv_reg114  <= (others => '0');
        slv_reg115  <= (others => '0');
        slv_reg116  <= (others => '0');
        slv_reg117  <= (others => '0');
        slv_reg118  <= (others => '0');
        slv_reg119  <= (others => '0');
        slv_reg120  <= (others => '0');
        slv_reg121  <= (others => '0');
        slv_reg122  <= (others => '0');
        slv_reg123  <= (others => '0');
        slv_reg124  <= (others => '0');
        slv_reg125  <= (others => '0');
        slv_reg126  <= (others => '0');
        slv_reg127  <= (others => '0');
      else
        --------------------- Read Only Registers ---------------------
        slv_reg32   <= ro_reg_mat(0);
        slv_reg33   <= ro_reg_mat(1);
        slv_reg34   <= ro_reg_mat(2);
        -- Used for A FIFO DATA Read
        slv_reg35   <= ro_reg_mat(3);
        -- Used for B FIFO DATA Read
        slv_reg36   <= ro_reg_mat(4);
        slv_reg37   <= ro_reg_mat(5);
        slv_reg38   <= ro_reg_mat(6);
        slv_reg39   <= ro_reg_mat(7);
        slv_reg40   <= ro_reg_mat(8);
        slv_reg41   <= ro_reg_mat(9);
        slv_reg42   <= ro_reg_mat(10);
        slv_reg43   <= ro_reg_mat(11);
        slv_reg44   <= ro_reg_mat(12);
        slv_reg45   <= ro_reg_mat(13);
        slv_reg46   <= ro_reg_mat(14);
        slv_reg47   <= ro_reg_mat(15);
        slv_reg48   <= ro_reg_mat(16);
        slv_reg49   <= ro_reg_mat(17);
        slv_reg50   <= ro_reg_mat(18);
        slv_reg51   <= ro_reg_mat(19);
        slv_reg52   <= ro_reg_mat(20);
        slv_reg53   <= ro_reg_mat(21);
        slv_reg54   <= ro_reg_mat(22);
        slv_reg55   <= ro_reg_mat(23);
        slv_reg56   <= ro_reg_mat(24);
        slv_reg57   <= ro_reg_mat(25);
        slv_reg58   <= ro_reg_mat(26);
        slv_reg59   <= ro_reg_mat(27);
        slv_reg60   <= ro_reg_mat(28);
        slv_reg61   <= ro_reg_mat(29);
        slv_reg62   <= ro_reg_mat(30);
        slv_reg63   <= ro_reg_mat(31);
        slv_reg64   <= ro_reg_mat(32);
        slv_reg65   <= ro_reg_mat(33);
        slv_reg66   <= ro_reg_mat(34);
        slv_reg67   <= ro_reg_mat(35);
        slv_reg68   <= ro_reg_mat(36);
        slv_reg69   <= ro_reg_mat(37);
        slv_reg70   <= ro_reg_mat(38);
        slv_reg71   <= ro_reg_mat(39);
        slv_reg72   <= ro_reg_mat(40);
        slv_reg73   <= ro_reg_mat(41);
        slv_reg74   <= ro_reg_mat(42);
        slv_reg75   <= ro_reg_mat(43);
        slv_reg76   <= ro_reg_mat(44);
        slv_reg77   <= ro_reg_mat(45);
        slv_reg78   <= ro_reg_mat(46);
        slv_reg79   <= ro_reg_mat(47);
        slv_reg80   <= ro_reg_mat(48);
        slv_reg81   <= ro_reg_mat(49);
        slv_reg82   <= ro_reg_mat(50);
        slv_reg83   <= ro_reg_mat(51);
        slv_reg84   <= ro_reg_mat(52);
        slv_reg85   <= ro_reg_mat(53);
        slv_reg86   <= ro_reg_mat(54);
        slv_reg87   <= ro_reg_mat(55);
        slv_reg88   <= ro_reg_mat(56);
        slv_reg89   <= ro_reg_mat(57);
        slv_reg90   <= ro_reg_mat(58);
        slv_reg91   <= ro_reg_mat(59);
        slv_reg92   <= ro_reg_mat(60);
        slv_reg93   <= ro_reg_mat(61);
        slv_reg94   <= ro_reg_mat(62);
        slv_reg95   <= ro_reg_mat(63);
        slv_reg96   <= ro_reg_mat(64);
        slv_reg97   <= ro_reg_mat(65);
        slv_reg98   <= ro_reg_mat(66);
        slv_reg99   <= ro_reg_mat(67);
        slv_reg100  <= ro_reg_mat(68);
        slv_reg101  <= ro_reg_mat(69);
        loc_addr := axi_awaddr(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB);
        if (slv_reg_wren = '1') then
          case loc_addr is
            when b"0000000" =>
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if ( S_AXI_WSTRB(byte_index) = '1' ) then
                  -- Respective byte enables are asserted as per write strobes                   
                  -- slave registor 0
                  slv_reg0(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;
            when b"0000001" =>
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if ( S_AXI_WSTRB(byte_index) = '1' ) then
                  -- Respective byte enables are asserted as per write strobes                   
                  -- slave registor 1
                  slv_reg1(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;
            when b"0000010" =>
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if ( S_AXI_WSTRB(byte_index) = '1' ) then
                  -- Respective byte enables are asserted as per write strobes                   
                  -- slave registor 2
                  slv_reg2(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;
            when b"0000011" =>
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if ( S_AXI_WSTRB(byte_index) = '1' ) then
                  -- Respective byte enables are asserted as per write strobes                   
                  -- slave registor 3
                  rw_reg.A_write_data(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8); --S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                  rw_reg.A_write_en <= '1';
                end if;
              end loop;
            when b"0000100" =>
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if ( S_AXI_WSTRB(byte_index) = '1' ) then
                  -- Respective byte enables are asserted as per write strobes                   
                  -- slave registor 4
                  rw_reg.B_write_data(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8); --S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                  rw_reg.B_write_en <= '1';
                end if;
              end loop;
            when b"0000101" =>
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if ( S_AXI_WSTRB(byte_index) = '1' ) then
                  -- Respective byte enables are asserted as per write strobes                   
                  -- slave registor 5
                  slv_reg5(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;
            when b"0000110" =>
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if ( S_AXI_WSTRB(byte_index) = '1' ) then
                  -- Respective byte enables are asserted as per write strobes                   
                  -- slave registor 6
                  slv_reg6(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;
            when b"0000111" =>
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if ( S_AXI_WSTRB(byte_index) = '1' ) then
                  -- Respective byte enables are asserted as per write strobes                   
                  -- slave registor 7
                  slv_reg7(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;
            when b"0001000" =>
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if ( S_AXI_WSTRB(byte_index) = '1' ) then
                  -- Respective byte enables are asserted as per write strobes                   
                  -- slave registor 8
                  slv_reg8(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;
            when b"0001001" =>
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if ( S_AXI_WSTRB(byte_index) = '1' ) then
                  -- Respective byte enables are asserted as per write strobes                   
                  -- slave registor 9
                  slv_reg9(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;
            when b"0001010" =>
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if ( S_AXI_WSTRB(byte_index) = '1' ) then
                  -- Respective byte enables are asserted as per write strobes                   
                  -- slave registor 10
                  slv_reg10(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;
            when b"0001011" =>
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if ( S_AXI_WSTRB(byte_index) = '1' ) then
                  -- Respective byte enables are asserted as per write strobes                   
                  -- slave registor 11
                  slv_reg11(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;
            when b"0001100" =>
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if ( S_AXI_WSTRB(byte_index) = '1' ) then
                  -- Respective byte enables are asserted as per write strobes                   
                  -- slave registor 12
                  slv_reg12(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;
            when b"0001101" =>
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if ( S_AXI_WSTRB(byte_index) = '1' ) then
                  -- Respective byte enables are asserted as per write strobes                   
                  -- slave registor 13
                  slv_reg13(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;
            when b"0001110" =>
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if ( S_AXI_WSTRB(byte_index) = '1' ) then
                  -- Respective byte enables are asserted as per write strobes                   
                  -- slave registor 14
                  slv_reg14(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;
            when b"0001111" =>
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if ( S_AXI_WSTRB(byte_index) = '1' ) then
                  -- Respective byte enables are asserted as per write strobes                   
                  -- slave registor 15
                  slv_reg15(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;
            when b"0010000" =>
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if ( S_AXI_WSTRB(byte_index) = '1' ) then
                  -- Respective byte enables are asserted as per write strobes                   
                  -- slave registor 16
                  slv_reg16(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;
            when b"0010001" =>
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if ( S_AXI_WSTRB(byte_index) = '1' ) then
                  -- Respective byte enables are asserted as per write strobes                   
                  -- slave registor 17
                  slv_reg17(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;
            when b"0010010" =>
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if ( S_AXI_WSTRB(byte_index) = '1' ) then
                  -- Respective byte enables are asserted as per write strobes                   
                  -- slave registor 18
                  slv_reg18(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;
            when b"0010011" =>
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if ( S_AXI_WSTRB(byte_index) = '1' ) then
                  -- Respective byte enables are asserted as per write strobes                   
                  -- slave registor 19
                  slv_reg19(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;
            when b"0010100" =>
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if ( S_AXI_WSTRB(byte_index) = '1' ) then
                  -- Respective byte enables are asserted as per write strobes                   
                  -- slave registor 20
                  slv_reg20(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;
            when b"0010101" =>
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if ( S_AXI_WSTRB(byte_index) = '1' ) then
                  -- Respective byte enables are asserted as per write strobes                   
                  -- slave registor 21
                  slv_reg21(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;
            when b"0010110" =>
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if ( S_AXI_WSTRB(byte_index) = '1' ) then
                  -- Respective byte enables are asserted as per write strobes                   
                  -- slave registor 22
                  slv_reg22(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;
            when b"0010111" =>
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if ( S_AXI_WSTRB(byte_index) = '1' ) then
                  -- Respective byte enables are asserted as per write strobes                   
                  -- slave registor 23
                  slv_reg23(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;
            when b"0011000" =>
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if ( S_AXI_WSTRB(byte_index) = '1' ) then
                  -- Respective byte enables are asserted as per write strobes                   
                  -- slave registor 24
                  slv_reg24(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;
            when b"0011001" =>
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if ( S_AXI_WSTRB(byte_index) = '1' ) then
                  -- Respective byte enables are asserted as per write strobes                   
                  -- slave registor 25
                  slv_reg25(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;
            when b"0011010" =>
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if ( S_AXI_WSTRB(byte_index) = '1' ) then
                  -- Respective byte enables are asserted as per write strobes                   
                  -- slave registor 26
                  slv_reg26(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;
            when b"0011011" =>
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if ( S_AXI_WSTRB(byte_index) = '1' ) then
                  -- Respective byte enables are asserted as per write strobes                   
                  -- slave registor 27
                  slv_reg27(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;
            when b"0011100" =>
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if ( S_AXI_WSTRB(byte_index) = '1' ) then
                  -- Respective byte enables are asserted as per write strobes                   
                  -- slave registor 28
                  slv_reg28(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;
            when b"0011101" =>
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if ( S_AXI_WSTRB(byte_index) = '1' ) then
                  -- Respective byte enables are asserted as per write strobes                   
                  -- slave registor 29
                  slv_reg29(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;
            when b"0011110" =>
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if ( S_AXI_WSTRB(byte_index) = '1' ) then
                  -- Respective byte enables are asserted as per write strobes                   
                  -- slave registor 30
                  slv_reg30(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;
            when b"0011111" =>
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if ( S_AXI_WSTRB(byte_index) = '1' ) then
                  -- Respective byte enables are asserted as per write strobes                   
                  -- slave registor 31
                  slv_reg31(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;
--            when b"0100000" =>
--              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
--                if ( S_AXI_WSTRB(byte_index) = '1' ) then
--                  -- Respective byte enables are asserted as per write strobes                   
--                  -- slave registor 32
--                  slv_reg32(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
--                end if;
--              end loop;
--            when b"0100001" =>
--              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
--                if ( S_AXI_WSTRB(byte_index) = '1' ) then
--                  -- Respective byte enables are asserted as per write strobes                   
--                  -- slave registor 33
--                  slv_reg33(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
--                end if;
--              end loop;
--            when b"0100010" =>
--              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
--                if ( S_AXI_WSTRB(byte_index) = '1' ) then
--                  -- Respective byte enables are asserted as per write strobes                   
--                  -- slave registor 34
--                  slv_reg34(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
--                end if;
--              end loop;
--            when b"0100011" =>
--              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
--                if ( S_AXI_WSTRB(byte_index) = '1' ) then
--                  -- Respective byte enables are asserted as per write strobes                   
--                  -- slave registor 35
--                  slv_reg35(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
--                end if;
--              end loop;
--            when b"0100100" =>
--              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
--                if ( S_AXI_WSTRB(byte_index) = '1' ) then
--                  -- Respective byte enables are asserted as per write strobes                   
--                  -- slave registor 36
--                  slv_reg36(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
--                end if;
--              end loop;
--            when b"0100101" =>
--              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
--                if ( S_AXI_WSTRB(byte_index) = '1' ) then
--                  -- Respective byte enables are asserted as per write strobes                   
--                  -- slave registor 37
--                  slv_reg37(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
--                end if;
--              end loop;
--            when b"0100110" =>
--              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
--                if ( S_AXI_WSTRB(byte_index) = '1' ) then
--                  -- Respective byte enables are asserted as per write strobes                   
--                  -- slave registor 38
--                  slv_reg38(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
--                end if;
--              end loop;
--            when b"0100111" =>
--              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
--                if ( S_AXI_WSTRB(byte_index) = '1' ) then
--                  -- Respective byte enables are asserted as per write strobes                   
--                  -- slave registor 39
--                  slv_reg39(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
--                end if;
--              end loop;
--            when b"0101000" =>
--              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
--                if ( S_AXI_WSTRB(byte_index) = '1' ) then
--                  -- Respective byte enables are asserted as per write strobes                   
--                  -- slave registor 40
--                  slv_reg40(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
--                end if;
--              end loop;
--            when b"0101001" =>
--              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
--                if ( S_AXI_WSTRB(byte_index) = '1' ) then
--                  -- Respective byte enables are asserted as per write strobes                   
--                  -- slave registor 41
--                  slv_reg41(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
--                end if;
--              end loop;
--            when b"0101010" =>
--              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
--                if ( S_AXI_WSTRB(byte_index) = '1' ) then
--                  -- Respective byte enables are asserted as per write strobes                   
--                  -- slave registor 42
--                  slv_reg42(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
--                end if;
--              end loop;
--            when b"0101011" =>
--              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
--                if ( S_AXI_WSTRB(byte_index) = '1' ) then
--                  -- Respective byte enables are asserted as per write strobes                   
--                  -- slave registor 43
--                  slv_reg43(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
--                end if;
--              end loop;
--            when b"0101100" =>
--              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
--                if ( S_AXI_WSTRB(byte_index) = '1' ) then
--                  -- Respective byte enables are asserted as per write strobes                   
--                  -- slave registor 44
--                  slv_reg44(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
--                end if;
--              end loop;
--            when b"0101101" =>
--              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
--                if ( S_AXI_WSTRB(byte_index) = '1' ) then
--                  -- Respective byte enables are asserted as per write strobes                   
--                  -- slave registor 45
--                  slv_reg45(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
--                end if;
--              end loop;
--            when b"0101110" =>
--              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
--                if ( S_AXI_WSTRB(byte_index) = '1' ) then
--                  -- Respective byte enables are asserted as per write strobes                   
--                  -- slave registor 46
--                  slv_reg46(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
--                end if;
--              end loop;
--            when b"0101111" =>
--              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
--                if ( S_AXI_WSTRB(byte_index) = '1' ) then
--                  -- Respective byte enables are asserted as per write strobes                   
--                  -- slave registor 47
--                  slv_reg47(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
--                end if;
--              end loop;
--            when b"0110000" =>
--              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
--                if ( S_AXI_WSTRB(byte_index) = '1' ) then
--                  -- Respective byte enables are asserted as per write strobes                   
--                  -- slave registor 48
--                  slv_reg48(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
--                end if;
--              end loop;
--            when b"0110001" =>
--              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
--                if ( S_AXI_WSTRB(byte_index) = '1' ) then
--                  -- Respective byte enables are asserted as per write strobes                   
--                  -- slave registor 49
--                  slv_reg49(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
--                end if;
--              end loop;
--            when b"0110010" =>
--              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
--                if ( S_AXI_WSTRB(byte_index) = '1' ) then
--                  -- Respective byte enables are asserted as per write strobes                   
--                  -- slave registor 50
--                  slv_reg50(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
--                end if;
--              end loop;
--            when b"0110011" =>
--              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
--                if ( S_AXI_WSTRB(byte_index) = '1' ) then
--                  -- Respective byte enables are asserted as per write strobes                   
--                  -- slave registor 51
--                  slv_reg51(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
--                end if;
--              end loop;
--            when b"0110100" =>
--              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
--                if ( S_AXI_WSTRB(byte_index) = '1' ) then
--                  -- Respective byte enables are asserted as per write strobes                   
--                  -- slave registor 52
--                  slv_reg52(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
--                end if;
--              end loop;
--            when b"0110101" =>
--              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
--                if ( S_AXI_WSTRB(byte_index) = '1' ) then
--                  -- Respective byte enables are asserted as per write strobes                   
--                  -- slave registor 53
--                  slv_reg53(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
--                end if;
--              end loop;
--            when b"0110110" =>
--              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
--                if ( S_AXI_WSTRB(byte_index) = '1' ) then
--                  -- Respective byte enables are asserted as per write strobes                   
--                  -- slave registor 54
--                  slv_reg54(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
--                end if;
--              end loop;
--            when b"0110111" =>
--              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
--                if ( S_AXI_WSTRB(byte_index) = '1' ) then
--                  -- Respective byte enables are asserted as per write strobes                   
--                  -- slave registor 55
--                  slv_reg55(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
--                end if;
--              end loop;
--            when b"0111000" =>
--              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
--                if ( S_AXI_WSTRB(byte_index) = '1' ) then
--                  -- Respective byte enables are asserted as per write strobes                   
--                  -- slave registor 56
--                  slv_reg56(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
--                end if;
--              end loop;
--            when b"0111001" =>
--              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
--                if ( S_AXI_WSTRB(byte_index) = '1' ) then
--                  -- Respective byte enables are asserted as per write strobes                   
--                  -- slave registor 57
--                  slv_reg57(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
--                end if;
--              end loop;
--            when b"0111010" =>
--              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
--                if ( S_AXI_WSTRB(byte_index) = '1' ) then
--                  -- Respective byte enables are asserted as per write strobes                   
--                  -- slave registor 58
--                  slv_reg58(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
--                end if;
--              end loop;
--            when b"0111011" =>
--              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
--                if ( S_AXI_WSTRB(byte_index) = '1' ) then
--                  -- Respective byte enables are asserted as per write strobes                   
--                  -- slave registor 59
--                  slv_reg59(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
--                end if;
--              end loop;
--            when b"0111100" =>
--              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
--                if ( S_AXI_WSTRB(byte_index) = '1' ) then
--                  -- Respective byte enables are asserted as per write strobes                   
--                  -- slave registor 60
--                  slv_reg60(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
--                end if;
--              end loop;
--            when b"0111101" =>
--              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
--                if ( S_AXI_WSTRB(byte_index) = '1' ) then
--                  -- Respective byte enables are asserted as per write strobes                   
--                  -- slave registor 61
--                  slv_reg61(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
--                end if;
--              end loop;
--            when b"0111110" =>
--              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
--                if ( S_AXI_WSTRB(byte_index) = '1' ) then
--                  -- Respective byte enables are asserted as per write strobes                   
--                  -- slave registor 62
--                  slv_reg62(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
--                end if;
--              end loop;
--            when b"0111111" =>
--              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
--                if ( S_AXI_WSTRB(byte_index) = '1' ) then
--                  -- Respective byte enables are asserted as per write strobes                   
--                  -- slave registor 63
--                  slv_reg63(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
--                end if;
--              end loop;
--            when b"1000000" =>
--              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
--                if ( S_AXI_WSTRB(byte_index) = '1' ) then
--                  -- Respective byte enables are asserted as per write strobes                   
--                  -- slave registor 64
--                  slv_reg64(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
--                end if;
--              end loop;
--            when b"1000001" =>
--              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
--                if ( S_AXI_WSTRB(byte_index) = '1' ) then
--                  -- Respective byte enables are asserted as per write strobes                   
--                  -- slave registor 65
--                  slv_reg65(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
--                end if;
--              end loop;
--            when b"1000010" =>
--              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
--                if ( S_AXI_WSTRB(byte_index) = '1' ) then
--                  -- Respective byte enables are asserted as per write strobes                   
--                  -- slave registor 66
--                  slv_reg66(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
--                end if;
--              end loop;
--            when b"1000011" =>
--              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
--                if ( S_AXI_WSTRB(byte_index) = '1' ) then
--                  -- Respective byte enables are asserted as per write strobes                   
--                  -- slave registor 67
--                  slv_reg67(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
--                end if;
--              end loop;
--            when b"1000100" =>
--              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
--                if ( S_AXI_WSTRB(byte_index) = '1' ) then
--                  -- Respective byte enables are asserted as per write strobes                   
--                  -- slave registor 68
--                  slv_reg68(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
--                end if;
--              end loop;
--            when b"1000101" =>
--              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
--                if ( S_AXI_WSTRB(byte_index) = '1' ) then
--                  -- Respective byte enables are asserted as per write strobes                   
--                  -- slave registor 69
--                  slv_reg69(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
--                end if;
--              end loop;
--            when b"1000110" =>
--              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
--                if ( S_AXI_WSTRB(byte_index) = '1' ) then
--                  -- Respective byte enables are asserted as per write strobes                   
--                  -- slave registor 70
--                  slv_reg70(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
--                end if;
--              end loop;
--            when b"1000111" =>
--              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
--                if ( S_AXI_WSTRB(byte_index) = '1' ) then
--                  -- Respective byte enables are asserted as per write strobes                   
--                  -- slave registor 71
--                  slv_reg71(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
--                end if;
--              end loop;
--            when b"1001000" =>
--              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
--                if ( S_AXI_WSTRB(byte_index) = '1' ) then
--                  -- Respective byte enables are asserted as per write strobes                   
--                  -- slave registor 72
--                  slv_reg72(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
--                end if;
--              end loop;
--            when b"1001001" =>
--              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
--                if ( S_AXI_WSTRB(byte_index) = '1' ) then
--                  -- Respective byte enables are asserted as per write strobes                   
--                  -- slave registor 73
--                  slv_reg73(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
--                end if;
--              end loop;
--            when b"1001010" =>
--              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
--                if ( S_AXI_WSTRB(byte_index) = '1' ) then
--                  -- Respective byte enables are asserted as per write strobes                   
--                  -- slave registor 74
--                  slv_reg74(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
--                end if;
--              end loop;
--            when b"1001011" =>
--              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
--                if ( S_AXI_WSTRB(byte_index) = '1' ) then
--                  -- Respective byte enables are asserted as per write strobes                   
--                  -- slave registor 75
--                  slv_reg75(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
--                end if;
--              end loop;
--            when b"1001100" =>
--              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
--                if ( S_AXI_WSTRB(byte_index) = '1' ) then
--                  -- Respective byte enables are asserted as per write strobes                   
--                  -- slave registor 76
--                  slv_reg76(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
--                end if;
--              end loop;
--            when b"1001101" =>
--              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
--                if ( S_AXI_WSTRB(byte_index) = '1' ) then
--                  -- Respective byte enables are asserted as per write strobes                   
--                  -- slave registor 77
--                  slv_reg77(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
--                end if;
--              end loop;
--            when b"1001110" =>
--              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
--                if ( S_AXI_WSTRB(byte_index) = '1' ) then
--                  -- Respective byte enables are asserted as per write strobes                   
--                  -- slave registor 78
--                  slv_reg78(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
--                end if;
--              end loop;
--            when b"1001111" =>
--              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
--                if ( S_AXI_WSTRB(byte_index) = '1' ) then
--                  -- Respective byte enables are asserted as per write strobes                   
--                  -- slave registor 79
--                  slv_reg79(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
--                end if;
--              end loop;
--            when b"1010000" =>
--              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
--                if ( S_AXI_WSTRB(byte_index) = '1' ) then
--                  -- Respective byte enables are asserted as per write strobes                   
--                  -- slave registor 80
--                  slv_reg80(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
--                end if;
--              end loop;
--            when b"1010001" =>
--              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
--                if ( S_AXI_WSTRB(byte_index) = '1' ) then
--                  -- Respective byte enables are asserted as per write strobes                   
--                  -- slave registor 81
--                  slv_reg81(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
--                end if;
--              end loop;
--            when b"1010010" =>
--              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
--                if ( S_AXI_WSTRB(byte_index) = '1' ) then
--                  -- Respective byte enables are asserted as per write strobes                   
--                  -- slave registor 82
--                  slv_reg82(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
--                end if;
--              end loop;
--            when b"1010011" =>
--              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
--                if ( S_AXI_WSTRB(byte_index) = '1' ) then
--                  -- Respective byte enables are asserted as per write strobes                   
--                  -- slave registor 83
--                  slv_reg83(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
--                end if;
--              end loop;
--            when b"1010100" =>
--              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
--                if ( S_AXI_WSTRB(byte_index) = '1' ) then
--                  -- Respective byte enables are asserted as per write strobes                   
--                  -- slave registor 84
--                  slv_reg84(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
--                end if;
--              end loop;
--            when b"1010101" =>
--              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
--                if ( S_AXI_WSTRB(byte_index) = '1' ) then
--                  -- Respective byte enables are asserted as per write strobes                   
--                  -- slave registor 85
--                  slv_reg85(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
--                end if;
--              end loop;
--            when b"1010110" =>
--              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
--                if ( S_AXI_WSTRB(byte_index) = '1' ) then
--                  -- Respective byte enables are asserted as per write strobes                   
--                  -- slave registor 86
--                  slv_reg86(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
--                end if;
--              end loop;
--            when b"1010111" =>
--              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
--                if ( S_AXI_WSTRB(byte_index) = '1' ) then
--                  -- Respective byte enables are asserted as per write strobes                   
--                  -- slave registor 87
--                  slv_reg87(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
--                end if;
--              end loop;
--            when b"1011000" =>
--              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
--                if ( S_AXI_WSTRB(byte_index) = '1' ) then
--                  -- Respective byte enables are asserted as per write strobes                   
--                  -- slave registor 88
--                  slv_reg88(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
--                end if;
--              end loop;
--            when b"1011001" =>
--              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
--                if ( S_AXI_WSTRB(byte_index) = '1' ) then
--                  -- Respective byte enables are asserted as per write strobes                   
--                  -- slave registor 89
--                  slv_reg89(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
--                end if;
--              end loop;
--            when b"1011010" =>
--              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
--                if ( S_AXI_WSTRB(byte_index) = '1' ) then
--                  -- Respective byte enables are asserted as per write strobes                   
--                  -- slave registor 90
--                  slv_reg90(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
--                end if;
--              end loop;
--            when b"1011011" =>
--              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
--                if ( S_AXI_WSTRB(byte_index) = '1' ) then
--                  -- Respective byte enables are asserted as per write strobes                   
--                  -- slave registor 91
--                  slv_reg91(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
--                end if;
--              end loop;
--            when b"1011100" =>
--              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
--                if ( S_AXI_WSTRB(byte_index) = '1' ) then
--                  -- Respective byte enables are asserted as per write strobes                   
--                  -- slave registor 92
--                  slv_reg92(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
--                end if;
--              end loop;
--            when b"1011101" =>
--              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
--                if ( S_AXI_WSTRB(byte_index) = '1' ) then
--                  -- Respective byte enables are asserted as per write strobes                   
--                  -- slave registor 93
--                  slv_reg93(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
--                end if;
--              end loop;
--            when b"1011110" =>
--              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
--                if ( S_AXI_WSTRB(byte_index) = '1' ) then
--                  -- Respective byte enables are asserted as per write strobes                   
--                  -- slave registor 94
--                  slv_reg94(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
--                end if;
--              end loop;
--            when b"1011111" =>
--              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
--                if ( S_AXI_WSTRB(byte_index) = '1' ) then
--                  -- Respective byte enables are asserted as per write strobes                   
--                  -- slave registor 95
--                  slv_reg95(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
--                end if;
--              end loop;
--            when b"1100000" =>
--              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
--                if ( S_AXI_WSTRB(byte_index) = '1' ) then
--                  -- Respective byte enables are asserted as per write strobes                   
--                  -- slave registor 96
--                  slv_reg96(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
--                end if;
--              end loop;
--            when b"1100001" =>
--              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
--                if ( S_AXI_WSTRB(byte_index) = '1' ) then
--                  -- Respective byte enables are asserted as per write strobes                   
--                  -- slave registor 97
--                  slv_reg97(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
--                end if;
--              end loop;
--            when b"1100010" =>
--              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
--                if ( S_AXI_WSTRB(byte_index) = '1' ) then
--                  -- Respective byte enables are asserted as per write strobes                   
--                  -- slave registor 98
--                  slv_reg98(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
--                end if;
--              end loop;
--            when b"1100011" =>
--              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
--                if ( S_AXI_WSTRB(byte_index) = '1' ) then
--                  -- Respective byte enables are asserted as per write strobes                   
--                  -- slave registor 99
--                  slv_reg99(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
--                end if;
--              end loop;
--            when b"1100100" =>
--              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
--                if ( S_AXI_WSTRB(byte_index) = '1' ) then
--                  -- Respective byte enables are asserted as per write strobes                   
--                  -- slave registor 100
--                  slv_reg100(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
--                end if;
--              end loop;
--            when b"1100101" =>
--              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
--                if ( S_AXI_WSTRB(byte_index) = '1' ) then
--                  -- Respective byte enables are asserted as per write strobes                   
--                  -- slave registor 101
--                  slv_reg101(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
--                end if;
--              end loop;
            when b"1100110" =>
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if ( S_AXI_WSTRB(byte_index) = '1' ) then
                  -- Respective byte enables are asserted as per write strobes                   
                  -- slave registor 102
                  slv_reg102(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;
            when b"1100111" =>
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if ( S_AXI_WSTRB(byte_index) = '1' ) then
                  -- Respective byte enables are asserted as per write strobes                   
                  -- slave registor 103
                  slv_reg103(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;
            when b"1101000" =>
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if ( S_AXI_WSTRB(byte_index) = '1' ) then
                  -- Respective byte enables are asserted as per write strobes                   
                  -- slave registor 104
                  slv_reg104(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;
            when b"1101001" =>
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if ( S_AXI_WSTRB(byte_index) = '1' ) then
                  -- Respective byte enables are asserted as per write strobes                   
                  -- slave registor 105
                  slv_reg105(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;
            when b"1101010" =>
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if ( S_AXI_WSTRB(byte_index) = '1' ) then
                  -- Respective byte enables are asserted as per write strobes                   
                  -- slave registor 106
                  slv_reg106(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;
            when b"1101011" =>
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if ( S_AXI_WSTRB(byte_index) = '1' ) then
                  -- Respective byte enables are asserted as per write strobes                   
                  -- slave registor 107
                  slv_reg107(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;
            when b"1101100" =>
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if ( S_AXI_WSTRB(byte_index) = '1' ) then
                  -- Respective byte enables are asserted as per write strobes                   
                  -- slave registor 108
                  slv_reg108(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;
            when b"1101101" =>
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if ( S_AXI_WSTRB(byte_index) = '1' ) then
                  -- Respective byte enables are asserted as per write strobes                   
                  -- slave registor 109
                  slv_reg109(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;
            when b"1101110" =>
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if ( S_AXI_WSTRB(byte_index) = '1' ) then
                  -- Respective byte enables are asserted as per write strobes                   
                  -- slave registor 110
                  slv_reg110(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;
            when b"1101111" =>
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if ( S_AXI_WSTRB(byte_index) = '1' ) then
                  -- Respective byte enables are asserted as per write strobes                   
                  -- slave registor 111
                  slv_reg111(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;
            when b"1110000" =>
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if ( S_AXI_WSTRB(byte_index) = '1' ) then
                  -- Respective byte enables are asserted as per write strobes                   
                  -- slave registor 112
                  slv_reg112(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;
            when b"1110001" =>
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if ( S_AXI_WSTRB(byte_index) = '1' ) then
                  -- Respective byte enables are asserted as per write strobes                   
                  -- slave registor 113
                  slv_reg113(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;
            when b"1110010" =>
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if ( S_AXI_WSTRB(byte_index) = '1' ) then
                  -- Respective byte enables are asserted as per write strobes                   
                  -- slave registor 114
                  slv_reg114(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;
            when b"1110011" =>
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if ( S_AXI_WSTRB(byte_index) = '1' ) then
                  -- Respective byte enables are asserted as per write strobes                   
                  -- slave registor 115
                  slv_reg115(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;
            when b"1110100" =>
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if ( S_AXI_WSTRB(byte_index) = '1' ) then
                  -- Respective byte enables are asserted as per write strobes                   
                  -- slave registor 116
                  slv_reg116(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;
            when b"1110101" =>
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if ( S_AXI_WSTRB(byte_index) = '1' ) then
                  -- Respective byte enables are asserted as per write strobes                   
                  -- slave registor 117
                  slv_reg117(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;
            when b"1110110" =>
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if ( S_AXI_WSTRB(byte_index) = '1' ) then
                  -- Respective byte enables are asserted as per write strobes                   
                  -- slave registor 118
                  slv_reg118(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;
            when b"1110111" =>
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if ( S_AXI_WSTRB(byte_index) = '1' ) then
                  -- Respective byte enables are asserted as per write strobes                   
                  -- slave registor 119
                  slv_reg119(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;
            when b"1111000" =>
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if ( S_AXI_WSTRB(byte_index) = '1' ) then
                  -- Respective byte enables are asserted as per write strobes                   
                  -- slave registor 120
                  slv_reg120(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;
            when b"1111001" =>
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if ( S_AXI_WSTRB(byte_index) = '1' ) then
                  -- Respective byte enables are asserted as per write strobes                   
                  -- slave registor 121
                  slv_reg121(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;
            when b"1111010" =>
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if ( S_AXI_WSTRB(byte_index) = '1' ) then
                  -- Respective byte enables are asserted as per write strobes                   
                  -- slave registor 122
                  slv_reg122(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;
            when b"1111011" =>
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if ( S_AXI_WSTRB(byte_index) = '1' ) then
                  -- Respective byte enables are asserted as per write strobes                   
                  -- slave registor 123
                  slv_reg123(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;
            when b"1111100" =>
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if ( S_AXI_WSTRB(byte_index) = '1' ) then
                  -- Respective byte enables are asserted as per write strobes                   
                  -- slave registor 124
                  slv_reg124(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;
            when b"1111101" =>
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if ( S_AXI_WSTRB(byte_index) = '1' ) then
                  -- Respective byte enables are asserted as per write strobes                   
                  -- slave registor 125
                  slv_reg125(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;
            when b"1111110" =>
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if ( S_AXI_WSTRB(byte_index) = '1' ) then
                  -- Respective byte enables are asserted as per write strobes                   
                  -- slave registor 126
                  slv_reg126(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;
            when b"1111111" =>
              for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                if ( S_AXI_WSTRB(byte_index) = '1' ) then
                  -- Respective byte enables are asserted as per write strobes                   
                  -- slave registor 127
                  slv_reg127(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                end if;
              end loop;
            when others =>
            --------------------- Read Write Registers  -------------------
              -- The register are written starting from the right (i.e. LSB)
              slv_reg0 <= slv_reg0;
              slv_reg1 <= slv_reg1;
              slv_reg2 <= slv_reg2;
              slv_reg3 <= slv_reg3;
              slv_reg4 <= slv_reg4;
              slv_reg5 <= slv_reg5;
              slv_reg6 <= slv_reg6;
              slv_reg7 <= slv_reg7;
              slv_reg8 <= slv_reg8;
              slv_reg9 <= slv_reg9;
              slv_reg10 <= slv_reg10;
              slv_reg11 <= slv_reg11;
              slv_reg12 <= slv_reg12;
              slv_reg13 <= slv_reg13;
              slv_reg14 <= slv_reg14;
              slv_reg15 <= slv_reg15;
              slv_reg16 <= slv_reg16;
              slv_reg17 <= slv_reg17;
              slv_reg18 <= slv_reg18;
              slv_reg19 <= slv_reg19;
              slv_reg20 <= slv_reg20;
              slv_reg21 <= slv_reg21;
              slv_reg22 <= slv_reg22;
              slv_reg23 <= slv_reg23;
              slv_reg24 <= slv_reg24;
              slv_reg25 <= slv_reg25;
              slv_reg26 <= slv_reg26;
              slv_reg27 <= slv_reg27;
              slv_reg28 <= slv_reg28;
              slv_reg29 <= slv_reg29;
              slv_reg30 <= slv_reg30;
              slv_reg31 <= slv_reg31;

              slv_reg102 <= slv_reg102;
              slv_reg103 <= slv_reg103;
              slv_reg104 <= slv_reg104;
              slv_reg105 <= slv_reg105;
              slv_reg106 <= slv_reg106;
              slv_reg107 <= slv_reg107;
              slv_reg108 <= slv_reg108;
              slv_reg109 <= slv_reg109;
              slv_reg110 <= slv_reg110;
              slv_reg111 <= slv_reg111;
              slv_reg112 <= slv_reg112;
              slv_reg113 <= slv_reg113;
              slv_reg114 <= slv_reg114;
              slv_reg115 <= slv_reg115;
              slv_reg116 <= slv_reg116;
              slv_reg117 <= slv_reg117;
              slv_reg118 <= slv_reg118;
              slv_reg119 <= slv_reg119;
              slv_reg120 <= slv_reg120;
              slv_reg121 <= slv_reg121;
              slv_reg122 <= slv_reg122;
              slv_reg123 <= slv_reg123;
              slv_reg124 <= slv_reg124;
              slv_reg125 <= slv_reg125;
              slv_reg126 <= slv_reg126;
              slv_reg127 <= slv_reg127;
          end case;
        end if;
      end if;
    end if;                   
  end process; 

  -- Implement write response logic generation
  -- The write response and response valid signals are asserted by the slave 
  -- when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.  
  -- This marks the acceptance of address and indicates the status of 
  -- write transaction.

  process (S_AXI_ACLK)
  begin
    if rising_edge(S_AXI_ACLK) then 
      if S_AXI_ARESETN = '0' then
        axi_bvalid  <= '0';
        axi_bresp   <= "00"; --need to work more on the responses
      else
        if (axi_awready = '1' and S_AXI_AWVALID = '1' and axi_wready = '1' and S_AXI_WVALID = '1' and axi_bvalid = '0'  ) then
          axi_bvalid <= '1';
          axi_bresp  <= "00"; 
        elsif (S_AXI_BREADY = '1' and axi_bvalid = '1') then   --check if bready is asserted while bvalid is high)
          axi_bvalid <= '0';                                 -- (there is a possibility that bready is always asserted high)
        end if;
      end if;
    end if;                   
  end process; 

  -- Implement axi_arready generation
  -- axi_arready is asserted for one S_AXI_ACLK clock cycle when
  -- S_AXI_ARVALID is asserted. axi_awready is 
  -- de-asserted when reset (active low) is asserted. 
  -- The read address is also latched when S_AXI_ARVALID is 
  -- asserted. axi_araddr is reset to zero on reset assertion.

  process (S_AXI_ACLK)
  begin
    if rising_edge(S_AXI_ACLK) then 
      A_req       <= '0';
      B_req       <= '0';
      if S_AXI_ARESETN = '0' then
        axi_arready <= '0';
        axi_araddr  <= (others => '1');
      else
        if (axi_arready = '0' and S_AXI_ARVALID = '1') then
          -- indicates that the slave has acceped the valid read address
          if S_AXI_ARADDR = b"0100011" & "00" then -- 35
            axi_arready <= not ro_reg.A_empty;
            A_req       <= not ro_reg.A_empty;
          elsif S_AXI_ARADDR = b"0100100" & "00" then -- 36
            axi_arready <= not ro_reg.B_empty;
            B_req       <= not ro_reg.B_empty;
          else
            axi_arready <= '1';
          end if;
          -- Read Address latching 
          axi_araddr  <= S_AXI_ARADDR;           
        else
          axi_arready <= '0';
        end if;
      end if;
    end if;                   
  end process; 

  -- Implement axi_arvalid generation
  -- axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both 
  -- S_AXI_ARVALID and axi_arready are asserted. The slave registers 
  -- data are available on the axi_rdata bus at this instance. The 
  -- assertion of axi_rvalid marks the validity of read data on the 
  -- bus and axi_rresp indicates the status of read transaction.axi_rvalid 
  -- is deasserted on reset (active low). axi_rresp and axi_rdata are 
  -- cleared to zero on reset (active low).  
  process (S_AXI_ACLK)
  begin
    if rising_edge(S_AXI_ACLK) then
      rw_reg.A_read_en <= '0';
      rw_reg.B_read_en <= '0';
      if S_AXI_ARESETN = '0' then
        axi_rvalid <= '0';
        axi_rresp  <= "00";
        A_req_r     <= '0';
        B_req_r     <= '0';
      else
        if (axi_arready = '1' and S_AXI_ARVALID = '1' and axi_rvalid = '0') then
          -- Valid read data is available at the read data bus
          axi_rvalid <= '1';
          axi_rresp  <= "00"; -- 'OKAY' response
          A_req_r     <= A_req;
          B_req_r     <= B_req;
        elsif (axi_rvalid = '1' and S_AXI_RREADY = '1') then
          -- Read data is accepted by the master
          axi_rvalid <= '0';
          A_req_r     <= '0';
          B_req_r     <= '0';
          rw_reg.A_read_en <= A_req_r;
          rw_reg.B_read_en <= B_req_r;
        end if;            
      end if;
    end if;
  end process;

  -- Implement memory mapped register select and read logic generation
  -- Slave register read enable is asserted when valid address is available
  -- and the slave is ready to accept the read address.
  slv_reg_rden <= axi_arready and S_AXI_ARVALID and (not axi_rvalid) ;

  process (slv_reg0, slv_reg1, slv_reg2, slv_reg3, slv_reg4, slv_reg5, slv_reg6, slv_reg7, slv_reg8, slv_reg9, slv_reg10, slv_reg11, slv_reg12, slv_reg13, slv_reg14, slv_reg15, slv_reg16, slv_reg17, slv_reg18, slv_reg19, slv_reg20, slv_reg21, slv_reg22, slv_reg23, slv_reg24, slv_reg25, slv_reg26, slv_reg27, slv_reg28, slv_reg29, slv_reg30, slv_reg31, slv_reg32, slv_reg33, slv_reg34, slv_reg35, slv_reg36, slv_reg37, slv_reg38, slv_reg39, slv_reg40, slv_reg41, slv_reg42, slv_reg43, slv_reg44, slv_reg45, slv_reg46, slv_reg47, slv_reg48, slv_reg49, slv_reg50, slv_reg51, slv_reg52, slv_reg53, slv_reg54, slv_reg55, slv_reg56, slv_reg57, slv_reg58, slv_reg59, slv_reg60, slv_reg61, slv_reg62, slv_reg63, slv_reg64, slv_reg65, slv_reg66, slv_reg67, slv_reg68, slv_reg69, slv_reg70, slv_reg71, slv_reg72, slv_reg73, slv_reg74, slv_reg75, slv_reg76, slv_reg77, slv_reg78, slv_reg79, slv_reg80, slv_reg81, slv_reg82, slv_reg83, slv_reg84, slv_reg85, slv_reg86, slv_reg87, slv_reg88, slv_reg89, slv_reg90, slv_reg91, slv_reg92, slv_reg93, slv_reg94, slv_reg95, slv_reg96, slv_reg97, slv_reg98, slv_reg99, slv_reg100, slv_reg101, slv_reg102, slv_reg103, slv_reg104, slv_reg105, slv_reg106, slv_reg107, slv_reg108, slv_reg109, slv_reg110, slv_reg111, slv_reg112, slv_reg113, slv_reg114, slv_reg115, slv_reg116, slv_reg117, slv_reg118, slv_reg119, slv_reg120, slv_reg121, slv_reg122, slv_reg123, slv_reg124, slv_reg125, slv_reg126, slv_reg127, axi_araddr, S_AXI_ARESETN, slv_reg_rden)
  variable loc_addr :std_logic_vector(OPT_MEM_ADDR_BITS downto 0);
  begin
      -- Address decoding for reading registers
      loc_addr := axi_araddr(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB);
      case loc_addr is
        when b"0000000" =>
          reg_data_out <= slv_reg0;
        when b"0000001" =>
          reg_data_out <= slv_reg1;
        when b"0000010" =>
          reg_data_out <= slv_reg2;
        when b"0000011" =>
          reg_data_out <= slv_reg3;
        when b"0000100" =>
          reg_data_out <= slv_reg4;
        when b"0000101" =>
          reg_data_out <= slv_reg5;
        when b"0000110" =>
          reg_data_out <= slv_reg6;
        when b"0000111" =>
          reg_data_out <= slv_reg7;
        when b"0001000" =>
          reg_data_out <= slv_reg8;
        when b"0001001" =>
          reg_data_out <= slv_reg9;
        when b"0001010" =>
          reg_data_out <= slv_reg10;
        when b"0001011" =>
          reg_data_out <= slv_reg11;
        when b"0001100" =>
          reg_data_out <= slv_reg12;
        when b"0001101" =>
          reg_data_out <= slv_reg13;
        when b"0001110" =>
          reg_data_out <= slv_reg14;
        when b"0001111" =>
          reg_data_out <= slv_reg15;
        when b"0010000" =>
          reg_data_out <= slv_reg16;
        when b"0010001" =>
          reg_data_out <= slv_reg17;
        when b"0010010" =>
          reg_data_out <= slv_reg18;
        when b"0010011" =>
          reg_data_out <= slv_reg19;
        when b"0010100" =>
          reg_data_out <= slv_reg20;
        when b"0010101" =>
          reg_data_out <= slv_reg21;
        when b"0010110" =>
          reg_data_out <= slv_reg22;
        when b"0010111" =>
          reg_data_out <= slv_reg23;
        when b"0011000" =>
          reg_data_out <= slv_reg24;
        when b"0011001" =>
          reg_data_out <= slv_reg25;
        when b"0011010" =>
          reg_data_out <= slv_reg26;
        when b"0011011" =>
          reg_data_out <= slv_reg27;
        when b"0011100" =>
          reg_data_out <= slv_reg28;
        when b"0011101" =>
          reg_data_out <= slv_reg29;
        when b"0011110" =>
          reg_data_out <= slv_reg30;
        when b"0011111" =>
          reg_data_out <= slv_reg31;
        when b"0100000" =>
          reg_data_out <= slv_reg32;
        when b"0100001" =>
          reg_data_out <= slv_reg33;
        when b"0100010" =>
          reg_data_out <= slv_reg34;
        when b"0100011" =>
          reg_data_out <= x"00" & b"00" & ro_reg.A_read_data;
        when b"0100100" =>
          reg_data_out <= x"00" & b"00" & ro_reg.B_read_data;
        when b"0100101" =>
          reg_data_out <= slv_reg37;
        when b"0100110" =>
          reg_data_out <= slv_reg38;
        when b"0100111" =>
          reg_data_out <= slv_reg39;
        when b"0101000" =>
          reg_data_out <= slv_reg40;
        when b"0101001" =>
          reg_data_out <= slv_reg41;
        when b"0101010" =>
          reg_data_out <= slv_reg42;
        when b"0101011" =>
          reg_data_out <= slv_reg43;
        when b"0101100" =>
          reg_data_out <= slv_reg44;
        when b"0101101" =>
          reg_data_out <= slv_reg45;
        when b"0101110" =>
          reg_data_out <= slv_reg46;
        when b"0101111" =>
          reg_data_out <= slv_reg47;
        when b"0110000" =>
          reg_data_out <= slv_reg48;
        when b"0110001" =>
          reg_data_out <= slv_reg49;
        when b"0110010" =>
          reg_data_out <= slv_reg50;
        when b"0110011" =>
          reg_data_out <= slv_reg51;
        when b"0110100" =>
          reg_data_out <= slv_reg52;
        when b"0110101" =>
          reg_data_out <= slv_reg53;
        when b"0110110" =>
          reg_data_out <= slv_reg54;
        when b"0110111" =>
          reg_data_out <= slv_reg55;
        when b"0111000" =>
          reg_data_out <= slv_reg56;
        when b"0111001" =>
          reg_data_out <= slv_reg57;
        when b"0111010" =>
          reg_data_out <= slv_reg58;
        when b"0111011" =>
          reg_data_out <= slv_reg59;
        when b"0111100" =>
          reg_data_out <= slv_reg60;
        when b"0111101" =>
          reg_data_out <= slv_reg61;
        when b"0111110" =>
          reg_data_out <= slv_reg62;
        when b"0111111" =>
          reg_data_out <= slv_reg63;
        when b"1000000" =>
          reg_data_out <= slv_reg64;
        when b"1000001" =>
          reg_data_out <= slv_reg65;
        when b"1000010" =>
          reg_data_out <= slv_reg66;
        when b"1000011" =>
          reg_data_out <= slv_reg67;
        when b"1000100" =>
          reg_data_out <= slv_reg68;
        when b"1000101" =>
          reg_data_out <= slv_reg69;
        when b"1000110" =>
          reg_data_out <= slv_reg70;
        when b"1000111" =>
          reg_data_out <= slv_reg71;
        when b"1001000" =>
          reg_data_out <= slv_reg72;
        when b"1001001" =>
          reg_data_out <= slv_reg73;
        when b"1001010" =>
          reg_data_out <= slv_reg74;
        when b"1001011" =>
          reg_data_out <= slv_reg75;
        when b"1001100" =>
          reg_data_out <= slv_reg76;
        when b"1001101" =>
          reg_data_out <= slv_reg77;
        when b"1001110" =>
          reg_data_out <= slv_reg78;
        when b"1001111" =>
          reg_data_out <= slv_reg79;
        when b"1010000" =>
          reg_data_out <= slv_reg80;
        when b"1010001" =>
          reg_data_out <= slv_reg81;
        when b"1010010" =>
          reg_data_out <= slv_reg82;
        when b"1010011" =>
          reg_data_out <= slv_reg83;
        when b"1010100" =>
          reg_data_out <= slv_reg84;
        when b"1010101" =>
          reg_data_out <= slv_reg85;
        when b"1010110" =>
          reg_data_out <= slv_reg86;
        when b"1010111" =>
          reg_data_out <= slv_reg87;
        when b"1011000" =>
          reg_data_out <= slv_reg88;
        when b"1011001" =>
          reg_data_out <= slv_reg89;
        when b"1011010" =>
          reg_data_out <= slv_reg90;
        when b"1011011" =>
          reg_data_out <= slv_reg91;
        when b"1011100" =>
          reg_data_out <= slv_reg92;
        when b"1011101" =>
          reg_data_out <= slv_reg93;
        when b"1011110" =>
          reg_data_out <= slv_reg94;
        when b"1011111" =>
          reg_data_out <= slv_reg95;
        when b"1100000" =>
          reg_data_out <= slv_reg96;
        when b"1100001" =>
          reg_data_out <= slv_reg97;
        when b"1100010" =>
          reg_data_out <= slv_reg98;
        when b"1100011" =>
          reg_data_out <= slv_reg99;
        when b"1100100" =>
          reg_data_out <= slv_reg100;
        when b"1100101" =>
          reg_data_out <= slv_reg101;
        when b"1100110" =>
          reg_data_out <= slv_reg102;
        when b"1100111" =>
          reg_data_out <= slv_reg103;
        when b"1101000" =>
          reg_data_out <= slv_reg104;
        when b"1101001" =>
          reg_data_out <= slv_reg105;
        when b"1101010" =>
          reg_data_out <= slv_reg106;
        when b"1101011" =>
          reg_data_out <= slv_reg107;
        when b"1101100" =>
          reg_data_out <= slv_reg108;
        when b"1101101" =>
          reg_data_out <= slv_reg109;
        when b"1101110" =>
          reg_data_out <= slv_reg110;
        when b"1101111" =>
          reg_data_out <= slv_reg111;
        when b"1110000" =>
          reg_data_out <= slv_reg112;
        when b"1110001" =>
          reg_data_out <= slv_reg113;
        when b"1110010" =>
          reg_data_out <= slv_reg114;
        when b"1110011" =>
          reg_data_out <= slv_reg115;
        when b"1110100" =>
          reg_data_out <= slv_reg116;
        when b"1110101" =>
          reg_data_out <= slv_reg117;
        when b"1110110" =>
          reg_data_out <= slv_reg118;
        when b"1110111" =>
          reg_data_out <= slv_reg119;
        when b"1111000" =>
          reg_data_out <= slv_reg120;
        when b"1111001" =>
          reg_data_out <= slv_reg121;
        when b"1111010" =>
          reg_data_out <= slv_reg122;
        when b"1111011" =>
          reg_data_out <= slv_reg123;
        when b"1111100" =>
          reg_data_out <= slv_reg124;
        when b"1111101" =>
          reg_data_out <= slv_reg125;
        when b"1111110" =>
          reg_data_out <= slv_reg126;
        when b"1111111" =>
          reg_data_out <= slv_reg127;
        when others =>
          reg_data_out  <= (others => '0');
      end case;
  end process; 

  -- Output register or memory read data
  process( S_AXI_ACLK ) is
  begin
    if (rising_edge (S_AXI_ACLK)) then
      if ( S_AXI_ARESETN = '0' ) then
        axi_rdata  <= (others => '0');
      else
        if (slv_reg_rden = '1') then
          -- When there is a valid read address (S_AXI_ARVALID) with 
          -- acceptance of read address by the slave (axi_arready), 
          -- output the read dada 
          -- Read address mux
            axi_rdata <= reg_data_out;     -- register read data
        end if;   
      end if;
    end if;
  end process;


  --------------------
  -- ro_reg: Read Only Register
  --------------------
  -- AXI Address is shifted by 32 with respect to ro_reg_mat address.
  --------  Test  Triggers  -------
  -- A FIFO Trigger Number (Test Mode)
  ro_reg_mat(0)(11 DOWNTO 0)   <= ro_reg.atest_Ntrig;
  -- B FIFO Trigger Number (Test Mode)
  ro_reg_mat(0)(27 DOWNTO 16)  <= ro_reg.btest_Ntrig;
  --------  Trigger  Voter  -------
  -- Voted Trigger Number Valid
  ro_reg_mat(1)(12)            <= ro_reg.Ntrig_voter_v;
  -- Voted Trigger Number
  ro_reg_mat(1)(11 DOWNTO 0)   <= ro_reg.Ntrig_voter;
  -------- Trigger Counters -------
  -- Local Trigger Number
  ro_reg_mat(1)(27 DOWNTO 16)  <= ro_reg.Ntrig_local;
  -- FPGA A Trigger Number
  ro_reg_mat(2)(11 DOWNTO 0)   <= ro_reg.Ntrig_devA;
  -- FPGA B Trigger Number
  ro_reg_mat(2)(27 DOWNTO 16)  <= ro_reg.Ntrig_devB;
  -- Reg 35 and 36 used to read data from A and B FIFO respectively.
  -------- XFIFO -------
  -- A FIFO Full
  ro_reg_mat(5)(0)             <= ro_reg.AFIFO_isfull;
  -- A FIFO Almost Full
  ro_reg_mat(5)(1)             <= ro_reg.AFIFO_isafull;
  -- A FIFO Prog Full
  ro_reg_mat(5)(2)             <= ro_reg.AFIFO_ispfull;
  -- A FIFO Empty
  ro_reg_mat(5)(3)             <= ro_reg.AFIFO_isempty;
  -- B FIFO Full
  ro_reg_mat(5)(4)             <= ro_reg.BFIFO_isfull;
  -- B FIFO Almost Full
  ro_reg_mat(5)(5)             <= ro_reg.BFIFO_isafull;
  -- B FIFO Prog Full
  ro_reg_mat(5)(6)             <= ro_reg.BFIFO_ispfull;
  -- B FIFO Empty
  ro_reg_mat(5)(7)             <= ro_reg.BFIFO_isempty;

  --------------------
  -- rw_reg: Read Write Registers
  --------------------
  -------- RESET -------
  -- Reset Aux Bus
  rw_reg.reset                 <= slv_reg0(0);
  -- Reset FIFOs
  rw_reg.fiforeset             <= slv_reg0(1);
  -- Trigger Counters Reset (A+B+Local)
  rw_reg.triggerreset          <= slv_reg0(2);
  -------- TEST -------
  -- Enable Test Mode: 0 Disable, 1 Enable.
  rw_reg.test_mode             <= slv_reg1(0);
  -- Trigger Test Mode : '0' : count real trigger, '1' : use value in rw_reg.test_Ntrig
  rw_reg.test_trig_mode        <= slv_reg1(1);
  -- Test Trigger Number
  rw_reg.test_Ntrig            <= slv_reg1(15 DOWNTO 4);
  -- A Busy flag in test mode
  rw_reg.A_is_busy             <= slv_reg1(2);
  -- B Busy flag in test mode
  rw_reg.B_is_busy             <= slv_reg1(3);
  -------- AXI FIFO -------
  rw_reg.A_FIFO_read_en        <= slv_reg2(0);
  rw_reg.B_FIFO_read_en        <= slv_reg2(1);
  rw_reg.A_FIFO_write_en       <= slv_reg2(4);
  rw_reg.B_FIFO_write_en       <= slv_reg2(5);
  
end arch_imp;