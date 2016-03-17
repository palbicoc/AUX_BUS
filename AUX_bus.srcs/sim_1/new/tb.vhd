----------------------------------------------------------------------------------
-- Company: LNF - INFN
-- Authors: Albicocco Pietro
-- Contact: pietro.albicocco@lnf.infn.it
----------------------------------------------------------------------------------
-- File Name: tb.vhd
-- Target Devices: Xilinx - 7 Series
-- Tool Versions: VIVADO 2015.2
-- Description: AUXBUS TestBench.
-- 
-- Dependencies: 
--
----------------------------------------------------------------------------------
-- Revision History:
-- Revision 1.0 - Albicocco P. - First Version
-- Revision 2.0 - 03/2016 - Albicocco P. - Integrated Test Strategy 
----------------------------------------------------------------------------------
-- Additional Comments:
-- set StdArithNoWarnings 1
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity tb is
Generic (
  test_env : integer := 2 -- 0 : Test AXI-4 Lite Interface to/from A and B FIFO.
                          -- 1 : Test AUX BUS by using the internal PRBS generator.
                          -- 2 : Test AUX BUS by using stimuli from testbench.
);
end tb;

architecture a of tb is
------------------------------------------------------------------
---- FUNCTIONS ----
------------------------------------------------------------------
 
------------------------------------------------------------------
---- CONSTANTS ----
------------------------------------------------------------------
constant clock_period : integer := 10;
constant clk_period   : time    := 10 ns;
------------------------------------------------------------------
---- COMPONENTS ----
------------------------------------------------------------------
component auxbus is
Generic (
  clock_period : integer := 10;
  -------- AXI-4  LITE -------
  C_S_AXI_DATA_WIDTH  : integer := 32;
  C_S_AXI_ADDR_WIDTH  : integer := 9
  );
Port (
  -------- SYSTEM SIGNALS -------
  -- System clock
  clk : in STD_LOGIC;
  clk2x : in STD_LOGIC;
  -- System reset
  rst : in STD_LOGIC;
  --------  Trigger PORTS  -------
  -- Local Input Trigger
  trig_in       : in  STD_LOGIC;
  -- A Input Trigger
  atrig_det     : in  STD_LOGIC;
  -- B Input Trigger
  btrig_det     : in  STD_LOGIC;
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
end component auxbus;
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
---- FUNCTIONS ----
-----------------------------------------------------------------
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
------------------------------------------------------------------
---- SIGNALS ----
------------------------------------------------------------------
--------------------
-- AUXBUS
--------------------
-------- SYSTEM SIGNALS -------
-- System clock
signal clk : STD_LOGIC;
signal clk2x : STD_LOGIC;
-- System reset
signal rst : STD_LOGIC := '1';
-------- A FIFO Interface -------
signal A_Wr_clk      : STD_LOGIC;
signal A_Din         : STD_LOGIC_VECTOR(22-1 DOWNTO 0);
signal A_Wr_en       : STD_LOGIC;
signal A_Full        : STD_LOGIC;
signal A_Almost_full : STD_LOGIC;
-------- B FIFO Interface -------
signal B_Wr_clk      : STD_LOGIC;
signal B_Din         : STD_LOGIC_VECTOR(22-1 DOWNTO 0);
signal B_Wr_en       : STD_LOGIC;
signal B_Full        : STD_LOGIC;
signal B_Almost_full : STD_LOGIC;
-------- ROCK OUTPUT -------
-- Trigger Bus, first valid trigger is 001
signal xt : STD_LOGIC_VECTOR (11 downto 0);
-- Trigger Bus Data is valide, Active LOW
signal xtrgv_n : STD_LOGIC;
-- Address Bus
signal xa : STD_LOGIC_VECTOR (3 downto 0);
-- Address Bus is Valid
signal xas_n : STD_LOGIC;
-- ROCK ready to read from slave, Active LOW
-- ROCK finished to read from slave, Active HIGH
signal xds : STD_LOGIC;
-- Master is initiating a synch check, Active LOW
signal xsyncrd_n : STD_LOGIC;
-- ROCK send a system HALT due to Error,
signal xsyshalt : STD_LOGIC;
-- ROCK produces a create level AUX reset
signal xsysreset : STD_LOGIC;
-------- ROCK OPEN COLLECOTR INPUT -------
-- Slave xsds bit is valid, Active HIGH
signal xbk : STD_LOGIC;
-- Slave has an error, Active LOW
signal xberr_n : STD_LOGIC;
-- Slave is full, Active LOW
signal xbusy_n : STD_LOGIC;
-------- ROCK TRISTATE INPUT -------
-- Slave data is valid, Active LOW
-- Slave recognized Master finished cycle, Active HIGH
signal xdk : STD_LOGIC;
-- Actual Slave Data Word is the last, Active LOW
signal xeob_n : STD_LOGIC;
-- Slave Data
signal xd : STD_LOGIC_VECTOR (19 downto 0);
-- Slave has data for a given Trigger Number
-- Can be either tristate or always enabled
signal xsds : STD_LOGIC;
-------- BACKPLANE HARDWIRED INPUT -------
-- Slave Geographical Address
signal sa : STD_LOGIC_VECTOR (3 downto 0);
--------------------
-- TB STIMULI
--------------------
-- stimuli reset
signal rstt   : std_logic := '1';
signal trigger: std_logic := '0';
--------------------
-- AXI-4 LITE
--------------------
-- Width of S_AXI data bus
constant C_S_AXI_DATA_WIDTH  : integer := 32;
-- Width of S_AXI address bus
constant C_S_AXI_ADDR_WIDTH  : integer := 9;
-- Global Signals
signal S_AXI_ACLK    : STD_LOGIC := '0';
signal S_AXI_ARESETN : STD_LOGIC := '1';
-- Address Write Channel
signal S_AXI_AWADDR  : STD_LOGIC_VECTOR (C_S_AXI_ADDR_WIDTH-1 downto 0) := "000000000";
signal S_AXI_AWPROT  : STD_LOGIC_VECTOR (2 downto 0) := "000";
signal S_AXI_AWVALID : STD_LOGIC := '0';
signal S_AXI_AWREADY : STD_LOGIC;
-- Data Write Channel
signal S_AXI_WDATA   : STD_LOGIC_VECTOR (C_S_AXI_DATA_WIDTH-1 downto 0) := x"0000_0000";
signal S_AXI_WSTRB   : STD_LOGIC_VECTOR ((C_S_AXI_DATA_WIDTH/8)-1 downto 0) := x"0";
signal S_AXI_WVALID  : STD_LOGIC := '0';
signal S_AXI_WREADY  : STD_LOGIC;
-- Write Response Channel
signal S_AXI_BRESP   : STD_LOGIC_VECTOR (1 downto 0);
signal S_AXI_BVALID  : STD_LOGIC;
signal S_AXI_BREADY  : STD_LOGIC := '0';
-- Address Read Channel
signal S_AXI_ARADDR  : STD_LOGIC_VECTOR (C_S_AXI_ADDR_WIDTH-1 downto 0) := "000000000";
signal S_AXI_ARPROT  : STD_LOGIC_VECTOR (2 downto 0) := "000";
signal S_AXI_ARVALID : STD_LOGIC := '0';
signal S_AXI_ARREADY : STD_LOGIC; 
-- Data Read Channel
signal S_AXI_RDATA   : STD_LOGIC_VECTOR (C_S_AXI_DATA_WIDTH-1 downto 0); 
signal S_AXI_RRESP   : STD_LOGIC_VECTOR (1 downto 0); 
signal S_AXI_RVALID  : STD_LOGIC; 
signal S_AXI_RREADY  : STD_LOGIC := '0';
-- Test Signals
signal axi_rx_data   : STD_LOGIC_VECTOR (C_S_AXI_DATA_WIDTH-1 downto 0) := x"0000_0000"; 
signal axi_rx_dv     : STD_LOGIC := '0';
--------------------
-- FIFO WRITE
--------------------
-- N data to write
signal an     : integer := 0;
signal bn     : integer := 0;
-- Data Type
type fifot is array (0 to 15) of std_logic_vector(21 downto 0);
-- Fifo data
signal ad     : fifot;
signal bd     : fifot;
-- Fifo Write
signal aw     : std_logic := '0';
signal bw     : std_logic := '0';
-- Fifodone
signal adone  : std_logic := '0';
signal bdone  : std_logic := '0';
--------------------
-- AUXBUS STIMULI
--------------------
signal trig_num      : integer   := 0;
signal founddata     : std_logic := '0';
signal rx_data       : std_logic_vector(19 downto 0) := (others => '0');
signal xsds_inertial : std_logic := '0';
signal xd_inertial   : std_logic_vector(19 downto 0) := (others => '0');
--------------------
-- CHECK RX DATA
--------------------
signal xeob_n_i      : std_logic;
signal xeob_n_t      : std_logic;
signal a_data        : std_logic_vector(11 downto 0) := (others => '0');
signal a_valid       : std_logic := '0';
signal a_data_check  : std_logic_vector(11 downto 0) := (others => '0');
signal a_clk         : std_logic := '1';
signal b_data        : std_logic_vector(11 downto 0) := (others => '0');
signal b_valid       : std_logic := '0';
signal b_data_check  : std_logic_vector(11 downto 0) := (others => '0');
signal b_clk         : std_logic := '1';
signal ssel          : std_logic;
signal test          : std_logic := 'Z';
signal xdk_i         : std_logic;
begin
--------------------
-- CHECK RX DATA
--------------------
ssel <= and_reduce (xa xnor sa);
xeob_n_t      <= '1' when xeob_n = '1' else '0' when (xeob_n = '0' or xeob_n = 'Z') else 'X';
xdk_i         <= '0' when xdk = '0' else '1';
process
variable inc          : integer   := 0;
variable van          : integer   := 0;
variable vbn          : integer   := 0;
variable vai          : integer   := 0;
variable vbi          : integer   := 0;
begin
  wait until rising_edge(xtrgv_n);--(ssel);
  if xsyncrd_n = '0' then
    wait until rising_edge(xsyncrd_n);
  else
    if test_env=1 then
    -- STIMULI FROM INTERNAL PRBS
      test <= '0';
      -- TEST MODE
      wait until falling_edge(xdk);
      if to_integer(unsigned(xd(xd'high downto xd'high-6))) < 48 then
        a_data   <= xd(xd'high-8 downto 0);
        a_valid  <= '1';
        a_clk    <= '0';
      else
        b_data   <= xd(xd'high-8 downto 0);
        b_valid  <= '1';
        b_clk    <= '0';
      end if;
      while xeob_n_t/='0' loop
        test <= '1';
        wait until rising_edge(xdk_i);
        a_valid  <= '1';
        a_clk    <= '1';
        b_valid  <= '1';
        b_clk    <= '1';
        wait until falling_edge(xdk);
        if to_integer(unsigned(xd(xd'high downto xd'high-6))) < 48 then
          a_data   <= xd(xd'high-8 downto 0);
          a_valid  <= '1';
          a_clk    <= '0';
        else
          b_data   <= xd(xd'high-8 downto 0);
          b_valid  <= '1';
          b_clk    <= '0';
        end if;
      end loop;
      test <= '0';
      wait until rising_edge(xdk_i);
      a_valid  <= '1';
      a_clk    <= '1';
      b_valid  <= '1';
      b_clk    <= '1';
      inc := inc+1;
    elsif test_env=2 then
    --STIMULI FROM TB 
      van := inc mod 9;
      vbn := inc mod 7;
      for ai in 1 to van loop
        wait until falling_edge(xdk);
        assert ( xd=std_logic_vector(to_unsigned(inc+ai,20)) ) report "ERROR: wrong data received: " &
        integer'image(to_integer(unsigned(xd))) & "/=" & integer'image(inc+ai)
        severity FAILURE;
        --report integer'image(to_integer(unsigned(xd))) & "==" & integer'image(inc+ai);
      end loop;
      for bi in 1 to vbn loop
        wait until falling_edge(xdk);
        assert (xd=std_logic_vector(to_unsigned(inc+bi+48*(2**13),20)) ) report "ERROR: wrong data received: " &
        integer'image(to_integer(unsigned(xd))) & "==" & integer'image(inc+bi)
        severity FAILURE;
        --report integer'image(to_integer(unsigned(xd))) & "==" & integer'image(inc+bi);
      end loop;
      inc := inc+1;
    end if;
  end if;
end process;
--------------------
-- PRBS_ANY: A DATA CHECK
--------------------
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
  CLK           => a_clk,
  DATA_IN       => a_data,
  EN            => a_valid,
  DATA_OUT      => a_data_check
);
--------------------
-- PRBS_ANY: B DATA CHECK
--------------------
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
  CLK           => b_clk,
  DATA_IN       => b_data,
  EN            => b_valid,
  DATA_OUT      => b_data_check
);
--------------------
-- AUXBUS STIMULI
--------------------
xsds_inertial <= '1' when xsds = '1' else '0' when (xsds = '0' or xsds = 'Z') else 'X';-- after 35 ns;
xd_inertial   <= xd;--   after 15 ns;
process
  --------------------
  -- Sync Cycle
  --------------------
  procedure sync_cycle is
  constant tn   : std_logic_vector(11 downto 0) := std_logic_vector(to_unsigned(trig_num,12));
  begin
    -- Trigger Bus, first valid trigger is 001
    xt            <= (others=> '0');
  -- Master is initiating a synch check, Active LOW
    xsyncrd_n     <= '0';
    wait for 50 ns;
    -- Trigger Bus Data is valide, Active LOW
    xtrgv_n       <= '0';
    wait until xbk = 'Z' for 1 us;
  --    if xbk = '0' then
  --      report "No response during Trigger Cycle with Trigger Number " & integer'image(trig_num) & "." severity WARNING;
  --    else
      founddata <= not xsds_inertial;
      wait for 5 ns;
      assert not(xbk='0') report "ERROR: xbk asserted to '0' before xtrgv_n is released during trigger cycle with Trigger Number " & integer'image(trig_num) & "." severity FAILURE;
  --    end if;
    -- Trigger Bus Data is valide, Active LOW
    xtrgv_n       <= '1';
    -- Trigger Bus, first valid trigger is 001
    xt            <= (others => '0');
  end sync_cycle;
  --------------------
  -- Sync Readout Cycle
  --------------------
  procedure sync_readout (target : std_logic_vector(3 downto 0); founddata : std_logic) is
  begin
    if founddata = '0' then
      report "Error: xsds not asserted low during sync cycle." severity FAILURE;
      return;
    end if;
    -- Address Bus
    xa            <= target;
    wait for 40 ns;
    -- Address Bus is Valid
    xas_n         <= '0';
    RO_loop: loop
      -- ROCK ready to read from slave, Active LOW
      -- ROCK finished to read from slave, Active HIGH
      xds           <= '0';
      wait until xdk = '0' for 1 us;
      if xdk /= '0' then
        report "No response from target " & integer'image(to_integer(unsigned(target))) & "during Sync Readout Cycle " & "." severity FAILURE;
        exit RO_loop;
      end if;
      rx_data <= xd_inertial;
      -- ROCK ready to read from slave, Active LOW
      -- ROCK finished to read from slave, Active HIGH
      xds           <= '1';
      wait for 15 ns;
      exit RO_loop when xeob_n = '0';
      report "xeob_n not asserted low during Sync Readout" & "." severity FAILURE;
    end loop;
    wait for 5 ns;
    -- Address Bus is Valid
    xas_n         <= '1';
    wait for 50 ns;
    -- Address Bus
    xa            <= X"0";
    -- Master is initiating a synch check, Active LOW
    xsyncrd_n     <= '1';
  end sync_readout;
  --------------------
  -- Set in Idle
  --------------------
  procedure idle is
  begin
    -- Trigger Bus, first valid trigger is 001
    xt            <= (others => '0');
    -- Trigger Bus Data is valide, Active LOW
    xtrgv_n       <= '1';
    -- Address Bus
    xa            <= X"0";
    -- Address Bus is Valid
    xas_n         <= '1';
    -- ROCK ready to read from slave, Active LOW
    -- ROCK finished to read from slave, Active HIGH
    xds           <= '1';
    -- Master is initiating a synch check, Active LOW
    xsyncrd_n     <= '1';
    -- ROCK send a system HALT due to Error,
    xsyshalt      <= '1';
    -- ROCK produces a create level AUX reset
    xsysreset     <= '1';
    -- Other Signals
    founddata     <= '0';
    rx_data       <= (others => '0');
  end idle;
  --------------------
  -- Trigger Cycle
  --------------------
  procedure trigger_cycle (trig_num :integer) is
  constant tn   : std_logic_vector(11 downto 0) := std_logic_vector(to_unsigned(trig_num,12));
  begin
    -- Trigger Bus, first valid trigger is 001
    xt            <= tn;
    wait for 40 ns;
    -- Trigger Bus Data is valide, Active LOW
    xtrgv_n       <= '0';
    wait until xbk = 'Z' for 1 us;
--    if xbk = '0' then
--      report "No response during Trigger Cycle with Trigger Number " & integer'image(trig_num) & "." severity WARNING;
--    else
      founddata <= not xsds_inertial;
      wait for 5 ns;
      assert not(xbk='0') report "ERROR: xbk asserted to '0' before xtrgv_n is released during trigger cycle with Trigger Number " & integer'image(trig_num) & "." severity FAILURE;
--    end if;
    -- Trigger Bus Data is valide, Active LOW
    xtrgv_n       <= '1';
    -- Trigger Bus, first valid trigger is 001
    xt            <= (others => '0');
  end trigger_cycle;
  --------------------
  -- Trigger Readout Cycle
  --------------------
  procedure trigger_readout (target : std_logic_vector(3 downto 0); trig_num : integer; founddata : std_logic) is
  begin
    if founddata = '0' then
      --report "No found data, exiting from readout cycle." severity note;
      return;
    end if;
    -- Address Bus
    xa            <= target;
    wait for 40 ns;
    -- Address Bus is Valid
    xas_n         <= '0';
    RO_loop: loop
      -- ROCK ready to read from slave, Active LOW
      -- ROCK finished to read from slave, Active HIGH
      xds           <= '0';
      wait until xdk = '0' for 1 us;
      if xdk /= '0' then
        report "No response from target " & integer'image(to_integer(unsigned(target))) & "during Readout Cycle with Trigger Number " & integer'image(trig_num) & "." severity FAILURE;
        exit RO_loop;
      end if;
      rx_data <= xd_inertial;
      -- ROCK ready to read from slave, Active LOW
      -- ROCK finished to read from slave, Active HIGH
      xds           <= '1';
      wait for 15 ns;
      exit RO_loop when xeob_n = '0';
    end loop;
    wait for 5 ns;
    -- Address Bus is Valid
    xas_n         <= '1';
    wait for 50 ns;
    -- Address Bus
    xa            <= X"0";
  end trigger_readout;
  variable tst  : time := 300 ps;
begin
  tst := (tst + 300 ps);
  -- idle
  idle;
  if rstt='1' then
    wait until rstt = '0';
  end if;
  if test_env=0 then
    wait;
  end if;
  wait for 100 ns;
  trig_num <= trig_num + 1;
  wait for tst;
  --report "Start AUX Trigger Cycle..." severity NOTE;
  trigger_cycle(trig_num);
  --report "Done." severity NOTE;
  wait for 150 ns;
  wait for tst;
  --report "Start AUX Trigger Readout Cycle..." severity NOTE;
  trigger_readout(sa, trig_num, founddata);
  --report "Done." severity NOTE;
  --wait for 100 ns;
  --trig_num <= trig_num + 1;
  wait for 10 ns;
  wait for tst;
  idle;
  wait for 1 us;
  wait for tst;
  sync_cycle;
  wait for 150 ns;
  wait for tst;
  sync_readout(sa, founddata);
  wait for 10 ns;
  --wait;
end process;
--------------------
-- TIMING REPORT
--------------------
-- trigger (35 ns)
process
  variable time_diff : time;
  variable curr_time : time;
begin
  wait until falling_edge(xtrgv_n);
  wait until xsds = '0';
  curr_time := now;
  wait until xbk = 'Z';
  time_diff := now - curr_time;
  --report "--------- - - 35ns -> " & time'image(time_diff) severity NOTE;
  assert time_diff >= 35 ns report "TRIGGER TIMING ERROR." severity FAILURE;
end process;
-- readout (15 ns)
process
  variable time_diff : time;
  variable curr_time : time;
  variable xd_temp   : std_logic_vector(19 DOWNTO 0);
begin
  wait until falling_edge(xds);
  wait until xd'event;
  xd_temp := xd;
  curr_time := now;
  loop ---------- Note: The most of the times (not always) there is a second event in xd.
    wait until falling_edge(xdk) or xd'event;
    if xd_temp = xd then
      exit;
    end if;
    xd_temp := xd;
    curr_time := now;
  end loop;
  time_diff := now - curr_time;
  --report "--------- - - 15ns -> " & time'image(time_diff) severity NOTE;
  assert time_diff >= 15 ns report "READOUT TIMING ERROR." severity FAILURE;
end process;
--------------------
-- FIFO STIMULI
--------------------
-- Data from FIFO:
--    a_d/b_d: 22 bit data
--      00&DATA| is data  , not last  , DATA
--      01&DATA| is data  , is  last  , DATA
--      10&EV_N| is header, data exist, EVENT NUMBER
--      11&EV_N| is header, no data   , EVENT NUMBER
--    a_dv/b_dv: data valid
process 
variable inc          : integer   := 0;
variable van          : integer   := 0;
variable vbn          : integer   := 0;
variable a_dataexist  : std_logic := '0';
variable a_dataislast : std_logic := '0';
variable b_dataexist  : std_logic := '0';
variable b_dataislast : std_logic := '0';
begin
  if rstt='1' then
    inc := 0;
    aw <= '0';
    an <= 0;
    van:= 0;
    ad <= (others => (others => '0') );
    bw <= '0';
    bn <= 0;
    vbn:= 0;
    bd <= (others => (others => '0') );
    a_dataexist  := '0';
    a_dataislast := '0';
    b_dataexist  := '0';
    b_dataislast := '0';
    wait until rstt = '0';
  end if;
  wait for 40 ns;
  if test_env/=2 then
    wait;
  end if;
  wait until clk'event and clk='1';
  wait for clk_period/5;
  van  := inc mod 9;
  an   <= van;
  -- Header
  if van/=0 then
    a_dataexist := '0';
  else 
    a_dataexist :=  '1';
  end if;
  ad(0) <= '1' & a_dataexist & X"00" & std_logic_vector(to_unsigned(inc+1, 12));
  -- Data
  for idx in 1 to van loop
    if idx=van then
      a_dataislast := '1';
    else 
      a_dataislast :=  '0';
    end if;
    ad(idx) <= '0' & a_dataislast & std_logic_vector(to_unsigned(inc+idx, 20));
  end loop;
  ad(van+1 to ad'high) <= (others => (others=>'0') );
  vbn  := (inc) mod 7;
  bn   <= vbn;
  -- Header
  if vbn/=0 then
    b_dataexist := '0';
  else 
    b_dataexist :=  '1';
  end if;
  bd(0) <= '1' & b_dataexist & X"00" & std_logic_vector(to_unsigned(inc+1, 12));
  -- Data
  for idx in 1 to vbn loop
    if idx=vbn then
      b_dataislast := '1';
    else 
      b_dataislast :=  '0';
    end if;
    bd(idx) <= '0' & b_dataislast & std_logic_vector(to_unsigned(inc+idx, 20));
  end loop;
  bd(vbn+1 to bd'high) <= (others => (others=>'0') );
  wait until clk'event and clk='1';
  wait for clk_period/5;
  inc := inc + 1;
  aw <= '1';
  bw <= '1';
  wait until clk'event and clk='1';
  wait for clk_period/5;
  aw <= '0';
  bw <= '0';
  if adone = '0' or bdone = '0' then
    wait until adone = '1' and bdone = '1';
  end if;
end process;
--------------------
-- AFIFO WRITE
--------------------
A_Wr_clk <= clk;
aw_pr: process
  variable acnt   : integer := 0;
begin
  acnt := 0;
  adone <= '1';
  A_Din <= (others => '0');
  A_Wr_en <= '0';
  wait until aw='1';
  adone <= '0';
  wait until clk'event and clk='1';
  wait for clk_period/5;
  while acnt <= an loop
    if A_Full='0' then
      A_Din <= ad(acnt);
      A_Wr_en <= '1';
      acnt := acnt +1;
    else
      A_Din <= ad(acnt);
      A_Wr_en <= '0';
      acnt := acnt;
    end if;
    wait until clk'event and clk='1';
    wait for clk_period/5;
  end loop;
END PROCESS;
--------------------
-- BFIFO WRITE
--------------------
B_Wr_clk <= clk;
bw_pr: process
  variable bcnt   : integer := 0;
begin
  bcnt := 0;
  bdone <= '1';
  B_Din <= (others => '0');
  B_Wr_en <= '0';
  wait until bw='1';
  bdone <= '0';
  wait until clk'event and clk='1';
  wait for clk_period/5;
  while bcnt <= bn loop
    if B_Full='0' then
      B_Din <= bd(bcnt);
      B_Wr_en <= '1';
      bcnt := bcnt +1;
    else
      B_Din <= bd(bcnt);
      B_Wr_en <= '0';
      bcnt := bcnt;
    end if;
  wait until clk'event and clk='1';
  wait for clk_period/5;
  end loop;
end process;
--------------------
-- TRIGGER PROCESS
--------------------
tr_pr: process
begin
  trigger <= '0';
  wait for clk_period*1;
  if rst = '1' then
    wait until rst='0';
  end if;
  wait for clk_period*50;
  wait until clk'event and clk='1';
  wait for clk_period/5;
  if xsyncrd_n='1' then
    trigger <= '1';
  end if;
  wait for clk_period*10;
end process;
--------------------
-- CLK GEN
--------------------
process begin
  clk <= '0';
  wait for 400 ns; -- Wait for global reset
  while 1 = 1 loop
    clk <= '0';
    wait for clk_period/2;
    clk <= '1'; 
    wait for clk_period/2;
  end loop;
end process;
--------------------
-- CLK2X GEN
--------------------
process begin
  clk2x <= '0';
  wait for 400 ns;-- Wait for global reset
  wait for clk_period/4; -- 0 phase
  while 1 = 1 loop
    clk2x <= '0';
    wait for clk_period/4;
    clk2x <= '1'; 
    wait for clk_period/4;
  end loop;
end process;
--------------------
-- RST GEN
--------------------
process begin
  rst <= '1';
  wait for 1000 ns;
  rst <= '0';
  wait;
end process;
--------------------
-- STIMULI RESET
--------------------
process begin
  rstt <= '1';
  wait until rst = '0';
  wait for 1000 ns;
  rstt <= '0';
  wait until rst = '1';
end process;
--------------------
-- UUT
--------------------
-- Geographical Address
sa <= "0010";
-- Instantiation
uut: auxbus
Generic Map(
    clock_period => clock_period
    )
Port Map(
  -------- SYSTEM SIGNALS -------
  -- System clock
  clk            => clk,
  clk2x          => clk2x,
  -- System reset
  rst            => rst,
  -------- Trigger  Signals -------
  -- Local Input Trigger
  trig_in       => trigger,
  -- A Input Trigger
  atrig_det     => '0',
  -- B Input Trigger
  btrig_det     => '0',
  -------- A FIFO Interface -------
  A_Wr_clk      => A_Wr_clk,
  A_Din         => A_Din,
  A_Wr_en       => A_Wr_en,
  A_Full        => A_Full,
  A_Almost_full => A_Almost_full,
  -------- B FIFO Interface -------
  B_Wr_clk      => B_Wr_clk,
  B_Din         => B_Din,
  B_Wr_en       => B_Wr_en,
  B_Full        => B_Full,
  B_Almost_full => B_Almost_full,
  --------   AXI-4  PORTS   -------
  S_AXI_ACLK    => S_AXI_ACLK,
  S_AXI_ARESETN => S_AXI_ARESETN,
  S_AXI_AWADDR  => S_AXI_AWADDR,
  S_AXI_AWPROT  => S_AXI_AWPROT,
  S_AXI_AWVALID => S_AXI_AWVALID,
  S_AXI_AWREADY => S_AXI_AWREADY,
  S_AXI_WDATA   => S_AXI_WDATA,
  S_AXI_WSTRB   => S_AXI_WSTRB,
  S_AXI_WVALID  => S_AXI_WVALID,
  S_AXI_WREADY  => S_AXI_WREADY,
  S_AXI_BRESP   => S_AXI_BRESP,
  S_AXI_BVALID  => S_AXI_BVALID,
  S_AXI_BREADY  => S_AXI_BREADY,
  S_AXI_ARADDR  => S_AXI_ARADDR,
  S_AXI_ARPROT  => S_AXI_ARPROT,
  S_AXI_ARVALID => S_AXI_ARVALID,
  S_AXI_ARREADY => S_AXI_ARREADY,
  S_AXI_RDATA   => S_AXI_RDATA,
  S_AXI_RRESP   => S_AXI_RRESP,
  S_AXI_RVALID  => S_AXI_RVALID,
  S_AXI_RREADY  => S_AXI_RREADY,
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
-- AXI-4 LITE
--------------------
-- Global Signals
S_AXI_ACLK    <= clk;
S_AXI_ARESETN <= not rst;
axi_pr: process
  constant ADDR_LSB          : integer := (C_S_AXI_DATA_WIDTH/32)+ 1;
  constant OPT_MEM_ADDR_BITS : integer := 6;
  --------------------
  -- AXI Idle
  --------------------
  procedure axi_idle is
  begin
    wait until falling_edge(S_AXI_ACLK);
    -- Address Write Channel
    S_AXI_AWADDR  <= "000000000";
    S_AXI_AWPROT  <= "000";
    S_AXI_AWVALID <= '0';
    -- Data Write Channel
    S_AXI_WDATA   <= x"0000_0000";
    S_AXI_WSTRB   <= x"0";
    S_AXI_WVALID  <= '0';
    -- Write Response Channel
    S_AXI_BREADY  <= '0';
    -- Address Read Channel
    S_AXI_ARADDR  <= "000000000";
    S_AXI_ARPROT  <= "000";
    S_AXI_ARVALID <= '0';
    -- Data Read Channel
    S_AXI_RREADY  <= '0';
    wait until rising_edge(S_AXI_ACLK);
  end procedure;
  --------------------
  -- AXI Read
  --------------------
  --procedure axi_read (Address: std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0) ) is
  procedure axi_read (Address: integer ) is
  begin
    wait until rising_edge(S_AXI_ACLK);
    -- Set Read Address
    S_AXI_ARADDR <= std_logic_vector(to_unsigned(Address, OPT_MEM_ADDR_BITS+1)) & std_logic_vector(to_unsigned(0, ADDR_LSB));
    -- Assert Read Address Valid
    S_AXI_ARVALID <= '1';
    wait until S_AXI_ARREADY='1';
    wait until rising_edge(S_AXI_ACLK); 
    -- Read Address Channel Done
    S_AXI_ARVALID <= '0';
    -- Ready to read data
    S_AXI_RREADY <= '1';
    -- Wait for read valid data
    wait until S_AXI_RVALID='1';
    wait until rising_edge(S_AXI_ACLK);
    -- Check read response is successful
    if (S_AXI_RRESP = "00") then
      axi_rx_data <= S_AXI_RDATA;
      axi_rx_dv   <= '1';
    else
      axi_rx_data <= x"FF00_00FF";
    end if;
    -- Read Data Channel Done 
    S_AXI_RREADY <= '0';
    wait until rising_edge(S_AXI_ACLK);
    axi_rx_dv   <= '0';
  end procedure;
  --------------------
  -- AXI Write
  --------------------
  --procedure axi_write (Address: std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0); Data: STD_LOGIC_VECTOR (C_S_AXI_DATA_WIDTH-1 downto 0) ) is
  procedure axi_write (Address: integer; Data: integer ) is
    constant timeout      : integer   := 8;
    variable timeout_cnt  : integer   := 0;
    variable awready_flag : std_logic := '0';
    variable wready_flag  : std_logic := '0';
  begin
    wait until rising_edge(S_AXI_ACLK);
    -- Ready to accept BRESP
    S_AXI_BREADY <= '1';
    -- Set Write Address
    S_AXI_AWADDR <= std_logic_vector(to_unsigned(Address, OPT_MEM_ADDR_BITS+1)) & std_logic_vector(to_unsigned(0, ADDR_LSB));
    -- Assert Write Address Valid
    S_AXI_AWVALID <= '1';
    -- Set Write Data
    S_AXI_WDATA <= std_logic_vector(to_unsigned(Data, C_S_AXI_DATA_WIDTH));
    -- Assert Write Data Valid
    S_AXI_WVALID <= '1';
    -- Write Enable for All Bytes
    S_AXI_WSTRB <= (others => '1');
    while (awready_flag /= '1' or wready_flag /= '1') and (timeout_cnt /= timeout) loop
      wait until rising_edge(S_AXI_ACLK); 
      if (S_AXI_AWREADY='1') then
        S_AXI_AWVALID <= '0';
        awready_flag  := '1';
      end if;
      if (S_AXI_WREADY='1') then
        S_AXI_WVALID <= '0';
        wready_flag  := '1';
      end if;
      timeout_cnt := timeout_cnt + 1;
    end loop;
    S_AXI_AWVALID <= '0';
    S_AXI_WVALID <= '0';
    if S_AXI_BVALID/='1' then
      wait until S_AXI_BVALID='1';
    end if;
    assert (S_AXI_BRESP = "00") report " ------  ERROR: WRITE PROCESS FAILED." severity FAILURE;
    wait until rising_edge(S_AXI_ACLK);
    S_AXI_BREADY <= '0';
  end procedure;
  
begin
  wait until S_AXI_ARESETN = '1';
  axi_idle;
  wait until rising_edge(S_AXI_ACLK);
  -- Reset AUX BUS
  axi_write(0, 1);
  report "-- Write 1 @ Reg 0 (Reset AUX):";
  -- Read Reg 0
  axi_read(0);
  report "   Read Reg 0: " & integer'image(to_integer(unsigned(axi_rx_data)));
  if test_env=1 then
    -- Enable AUXBUS Test Mode.
    axi_write(1, 3);
    -- Run AUX.
    axi_write(0, 0);
    wait;
  elsif test_env=2 then
    -- Leave default configuration.
    -- Run AUX.
    axi_write(0, 0);
    wait;
  end if;
  -- Enable AXI FIFO READ and WRITE
  axi_write(2, 3+48); -- 51 -- x33 @ 8
  report "-- Write x33 @ Reg 2 (Enable AXI FIFO READ and WRITE):";
  -- Read Reg 2
  axi_read(2);
  report "   Read Reg 2: " & integer'image(to_integer(unsigned(axi_rx_data)));
  -- AUX run
  report "-- Write 0 @ Reg 0 (Run AUX).";
  axi_write(0, 0);
  -- Write 1:3 in A FIFO
  report "-- Write 1024+[1:3] @ FIFO A:";
  axi_write(3, 1024+3);
  axi_write(3, 1024+4);
  axi_write(3, 1024+5);
  -- Read 1:3 from A FIFO
  report "   Read FIFO A:";
  axi_read(35);
  report "                  " & integer'image(to_integer(unsigned(axi_rx_data)));
  axi_read(35);
  report "                  " & integer'image(to_integer(unsigned(axi_rx_data)));
  axi_read(35);
  report "                  " & integer'image(to_integer(unsigned(axi_rx_data)));
  -- Write 1:3 in B FIFO
  report "-- Write 2048+[1:3] @ FIFO B:";
  axi_write(4, 2048+3);
  axi_write(4, 2048+4);
  axi_write(4, 2048+5);
  -- Read 1:3 from B FIFO
  report "   Read FIFO B:";
  axi_read(36);
  report "                  " & integer'image(to_integer(unsigned(axi_rx_data)));
  axi_read(36);
  report "                  " & integer'image(to_integer(unsigned(axi_rx_data)));
  axi_read(36);
  report "                  " & integer'image(to_integer(unsigned(axi_rx_data)));
  wait;
end process;

end a;
