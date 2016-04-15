----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 13.01.2016 14:56:57
-- Design Name: 
-- Module Name: vme64x_top_tb - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- librerie per simulazione vme64x ...
library work; 
use work.VME64xSim.all;
use work.VME64x.all;

-- vme64x che non servono per la simulazione
-- use work.VME_CR_pack.all;
-- use work.VME_CSR_pack.all; 
-- use work.wishbone_pkg.all;
-- use work.vme64x_pack.all; 

library std;
use std.textio.all; 

use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity vme64x_top_tb is
end vme64x_top_tb;


architecture AUX_Behavioral of vme64x_top_tb is

	-- Component Declaration of UUT
   
	COMPONENT VME64x_top
	PORT 	(
		clk_p 				: in  STD_LOGIC;
		clk_n 				: in  STD_LOGIC;
		-- Segnali Bus VME
		VME_sysres_n		: in STD_LOGIC;
		VME_data 			: inout  STD_LOGIC_VECTOR (31 downto 0); -- ALSO AUX
		VME_dataOE 			: out STD_LOGIC;
		VME_data_DIR 		: out STD_LOGIC;
		VME_DSy 				: in  STD_LOGIC_VECTOR (1 downto 0);
		VME_addr 			: inout  STD_LOGIC_VECTOR (31 downto 1);
		VME_addrOE 			: out STD_LOGIC;
		VME_addr_DIR 		: out STD_LOGIC;
		VME_WRITEy 			: in  STD_LOGIC;
		VME_LWordy 			: inout  STD_LOGIC;
		VME_oeabBERR		: out STD_LOGIC;
		VME_oeabDTACK 		: out STD_LOGIC;
		VME_DTACKa 			: out STD_LOGIC;
		VME_ASy 				: in  STD_LOGIC;
		VME_IACKy 			: in  STD_LOGIC;
   	VME_IACKINy  		: in  std_logic;
   	VME_IACKOUTa 		: out std_logic;
		VME_oeabRETRY 		: out STD_LOGIC;
		VME_RETRYa 			: out STD_LOGIC;
		VME_am 				: in  STD_LOGIC_VECTOR (5 downto 0);			
		VME_switch 			: in 	STD_LOGIC_VECTOR (7 downto 0);
		VME_irq 				: out STD_LOGIC_VECTOR (7 downto 1);
		VME_ga_n				: in  STD_LOGIC_VECTOR (4 downto 0);
		VME_gap_n			: in  STD_LOGIC;
		VME_sysclk			: in  STD_LOGIC;
		VME_statrd_n		: out STD_LOGIC;
		-- Segnali Bus AUX 
		AUX_xsel_n        : out STD_LOGIC;
      AUX_xsds_n	      : out STD_LOGIC;
      AUX_xeob_n	      : out STD_LOGIC;
      AUX_xdk_n	      : out STD_LOGIC;
      AUX_xbusy	      : out STD_LOGIC;
      AUX_xbk_n	      : out STD_LOGIC;
      AUX_xberr	      : out STD_LOGIC;
      AUX_xds_n	      : in  STD_LOGIC;
      AUX_on_n	         : out STD_LOGIC;
      AUX_xtrig         : in  STD_LOGIC_VECTOR (3 downto 0);
      AUX_xas_n		   : in  STD_LOGIC;
      AUX_xtrgv_n	      : in  STD_LOGIC;
		AUX_xsyncrd_n	   : in  STD_LOGIC;
		AUX_xa_sel		   : in  STD_LOGIC;
		Led_red				: out STD_LOGIC_VECTOR (2 downto 0);           			
		Led_yellow			: out STD_LOGIC_VECTOR (2 downto 0)           				
		);
	END COMPONENT;

	-- Generic
	-- Constant xxx

	-- UUT BiDirs            	
	signal VME_data 		: STD_LOGIC_VECTOR (31 downto 0);
	signal VME_addr 		: STD_LOGIC_VECTOR (31 downto 0);
   
   -- UUT Inputs ( := )
   signal clk_p 			: STD_LOGIC := '0';
   signal clk_n 			: STD_LOGIC := '1';
	signal VME_sysres_n	: STD_LOGIC;
	signal VME_DSy 		: STD_LOGIC_VECTOR (1 downto 0);
	signal VME_WRITEy 	: STD_LOGIC;
--	alias  VME_LWordy 	: STD_LOGIC IS VME_addr(0);
	signal VME_ASy 		: STD_LOGIC;
	signal VME_IACKy 		: STD_LOGIC;
	signal VME_am 			: STD_LOGIC_VECTOR (5 downto 0);			
	signal VME_switch 	: STD_LOGIC_VECTOR (7 downto 0) := BA;
	signal VME_ga_n		: STD_LOGIC_VECTOR (4 downto 0) := "11111"; -- simulo old vme bus := VME_GA(4 downto 0);
	signal VME_gap_n		: STD_LOGIC := '1'; -- simulo old vme bus := VME_GA(5);
	signal VME_sysclk		: STD_LOGIC;
	signal AUX_xds_n	   : STD_LOGIC;
	signal AUX_xtrig     : STD_LOGIC_VECTOR (3 downto 0);
	signal AUX_xas_n		: STD_LOGIC;
	signal AUX_xtrgv_n	: STD_LOGIC;
	signal AUX_xsyncrd_n	: STD_LOGIC;
	signal AUX_xa_sel		: STD_LOGIC;		
     
 	-- UUT Outputs
	signal VME_dataOE 	: STD_LOGIC;
	signal VME_data_DIR 	: STD_LOGIC;
	signal VME_addrOE 	: STD_LOGIC;
	signal VME_addr_DIR 	: STD_LOGIC;
	signal VME_oeabBERR	: STD_LOGIC;
	signal VME_oeabDTACK : STD_LOGIC;
	signal VME_DTACKa 	: STD_LOGIC;
	signal VME_oeabRETRY : STD_LOGIC;
	signal VME_RETRYa 	: STD_LOGIC;
	signal VME_irq 		: STD_LOGIC_VECTOR (7 downto 1);
	signal VME_statrd_n	: STD_LOGIC;
	signal AUX_xsel_n    : STD_LOGIC;
	signal AUX_xsds_n	   : STD_LOGIC;
	signal AUX_xeob_n	   : STD_LOGIC;
	signal AUX_xdk_n	   : STD_LOGIC;
	signal AUX_xbusy	   : STD_LOGIC;
	signal AUX_xbk_n	   : STD_LOGIC;
	signal AUX_xberr	   : STD_LOGIC;
	signal AUX_on_n	   : STD_LOGIC;
	signal Led_red		   : STD_LOGIC_VECTOR (2 downto 0);
	signal Led_yellow	   : STD_LOGIC_VECTOR (2 downto 0);
	
	-- Others signal
	signal VME_IACKINy 	: STD_LOGIC;
	signal VME_IACKOUTa 	: STD_LOGIC;
	
   -- Flags
   signal ReadInProgress : std_logic := '0';	
   signal WriteInProgress : std_logic := '0';

      -- Buffer and type   
   signal s_Buffer_BLT 			: t_Buffer_BLT;
   signal s_Buffer_MBLT 		: t_Buffer_MBLT;
   signal s_dataTransferType 	: t_dataTransferType;
   signal s_AddressingType 	: t_Addressing_Type;
   
   -- Control signals
   signal s_dataToSend 			: std_logic_vector(31 downto 0) := (others => '0');
   signal s_dataToReceive 		: std_logic_vector(31 downto 0) := (others => '0');
   signal s_address 				: std_logic_vector(63 downto 0) := (others => '0');
   signal csr_address 			: std_logic_vector(19 downto 0) := (others => '0');
   signal s_num 					: std_logic_vector( 8 downto 0) := (others => '0');

  	-- Records
	signal VME64xBus_out   : VME64xBusOut_Record := VME64xBusOut_Default;
	signal VME64xBus_in    : VME64xBusIn_Record;
	
   -- BUS VME testbench signal
	signal BUS_DATA	 			: STD_LOGIC_VECTOR (31 downto 0) :=(others => '1');
	signal BUS_ADDR	 			: STD_LOGIC_VECTOR (31 downto 0) :=(others => '1');
--	alias  BUS_LWORD_n			: STD_LOGIC IS BUS_ADDR(0); 
	signal BUS_DS_n 				: STD_LOGIC_VECTOR ( 1 downto 0) :=(others => '1');
	signal BUS_AM	 				: STD_LOGIC_VECTOR ( 5 downto 0) :=(others => '1');
	signal BUS_SYSRES_n			: STD_LOGIC := '1';   
	signal BUS_SYSCLK				: STD_LOGIC := '1'; 
	signal BUS_AS_n				: STD_LOGIC := '1'; 
	signal BUS_IACK_n				: STD_LOGIC := '1'; 
	signal BUS_IACKIN_n			: STD_LOGIC := '1'; 
	signal BUS_IACKOUT_n			: STD_LOGIC; --out 
	signal BUS_DTACK_n			: STD_LOGIC; --out
	signal BUS_WRITE_n			: STD_LOGIC := '1'; 
	signal BUS_RETRY_n			: STD_LOGIC; --out
	signal BUS_BERR_n				: STD_LOGIC; --out
	signal BUS_IRQ	 				: STD_LOGIC_VECTOR ( 7 downto 1); --out
	  
   -- BUS AUX testbench signal
	signal BUS_XD 					: STD_LOGIC_VECTOR (19 downto 0); -- out
	signal BUS_XT 					: STD_LOGIC_VECTOR (11 downto 0) :=(others => '1');
	signal BUS_XSDS_n				: STD_LOGIC; --out   
	signal BUS_XAS_n				: STD_LOGIC := '1';   
	signal BUS_XTRGV_n			: STD_LOGIC := '1';   
	signal BUS_XDS_n				: STD_LOGIC := '1';     
	signal BUS_XSYNCRD_n			: STD_LOGIC := '1';   
	signal BUS_XDK_n				: STD_LOGIC := '1';     
	signal BUS_XEOB_n				: STD_LOGIC := '1';     
	signal BUS_XA_SEL				: STD_LOGIC := '1';     
	signal BUS_XBK					: STD_LOGIC; --out     
	signal BUS_XBUSY_n			: STD_LOGIC; --out    
	signal BUS_XBERR_n			: STD_LOGIC; --out    
	
	signal BUS_XT1					: STD_LOGIC := '0';
	signal BUS_XT2					: STD_LOGIC := '0';
	signal BUS_XRES				: STD_LOGIC := '0';
	signal BUS_XCLK				: STD_LOGIC := '0';
	
	signal STAT_REG	: STD_LOGIC_VECTOR (7 downto 0);
		
 	-- Other Components 
	COMPONENT sn74vme
	GENERIC ( NUMOFBIT : integer); 
	PORT(
		I1OEAB 	: in  STD_LOGIC;
		I1A 		: in  STD_LOGIC;
		I1Y 		: out STD_LOGIC;
		O1B 		: inout  STD_LOGIC;
		I2OEAB 	: in  STD_LOGIC;
		I2A 		: in  STD_LOGIC;
		I2Y 		: out STD_LOGIC;
		O2B 		: inout  STD_LOGIC;
		OEn 		: in  STD_LOGIC;
		DIR 		: in  STD_LOGIC;
		I3A 		: inout  STD_LOGIC_VECTOR (NUMOFBIT - 1 downto 0);
		O3B 		: inout  STD_LOGIC_VECTOR (NUMOFBIT - 1 downto 0)
		);
	END COMPONENT;

   -- ram block ...
 	
   -- Clock period definitions
   constant CLK_period 		: time := 5 ns; 					-- 200 MHz
   
   -- constant definition
	
   -- procedure declaration

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
--------------------
-- PRBS_ANY
--------------------
-- PRBS-15 Settings
constant A_INV_PATTERN : boolean := true;
constant B_INV_PATTERN : boolean := false;
constant POLY_LENGHT   : natural range 0 to 63  := 15;
constant POLY_TAP      : natural range 0 to 63  := 14;
--------------------
-- CHECK RX DATA
--------------------
signal a_data        : std_logic_vector(11 downto 0) := (others => '0');
signal a_valid       : std_logic := '0';
signal a_data_check  : std_logic_vector(11 downto 0) := (others => '0');
signal a_clk         : std_logic := '1';
signal b_data        : std_logic_vector(11 downto 0) := (others => '0');
signal b_valid       : std_logic := '0';
signal b_data_check  : std_logic_vector(11 downto 0) := (others => '0');
signal b_clk         : std_logic := '1';
--------------------
-- AUXBUS STIMULI
--------------------
signal rst           : std_logic := '1';
signal trigger       : std_logic := '0';
signal trig_num      : integer   := 0;
signal founddata     : std_logic := '0';
signal rx_data       : std_logic_vector(19 downto 0) := (others => '0');
   
begin

	-- Instantiate the Unit Under Test (UUT)
	uut: VME64x_top
	PORT MAP	(
		clk_p 		  	=>	clk_p, 		     
		clk_n 		  	=>	clk_n, 		     
		VME_sysres_n  	=>	VME_sysres_n, 
		VME_data 	  	=>	VME_data, 	   
		VME_dataOE 	  	=>	VME_dataOE, 	 
		VME_data_DIR  	=>	VME_data_DIR, 
		VME_DSy 		  	=>	VME_DSy, 		   
		VME_addr 	  	=>	VME_addr(31 downto 1), 	   
		VME_addrOE 	  	=>	VME_addrOE, 	 
		VME_addr_DIR  	=>	VME_addr_DIR, 
		VME_WRITEy 	  	=>	VME_WRITEy, 	 
		VME_LWordy 	  	=>	VME_addr(0), 	 
		VME_oeabBERR 	=>	VME_oeabBERR, 	  
		VME_oeabDTACK 	=>	VME_oeabDTACK,
		VME_DTACKa 	  	=>	VME_DTACKa, 	 
		VME_ASy 		  	=>	VME_ASy, 		   
		VME_IACKy 	  	=>	VME_IACKy, 	  
   	VME_IACKINy  	=> VME_IACKINy, 
   	VME_IACKOUTa 	=> VME_IACKOUTa,
		VME_oeabRETRY 	=>	VME_oeabRETRY,
		VME_RETRYa 	  	=>	VME_RETRYa, 	 
		VME_am 		  	=>	VME_am, 		    
		VME_switch 	  	=>	VME_switch, 	 
		VME_irq 		  	=>	VME_irq, 		   
		VME_ga_n		  	=>	VME_ga_n,		   
		VME_gap_n	  	=>	VME_gap_n,	   
		VME_sysclk	  	=>	VME_sysclk,	  
		VME_statrd_n  	=>	VME_statrd_n,
		AUX_xsel_n    	=>	AUX_xsel_n,   
    AUX_xsds_n	  	=>	AUX_xsds_n,	  
    AUX_xeob_n	  	=>	AUX_xeob_n,	  
    AUX_xdk_n	  	  =>	AUX_xdk_n,	   
    AUX_xbusy	  	  =>	AUX_xbusy,	   
    AUX_xbk_n	  	  =>	AUX_xbk_n,	   
    AUX_xberr	  	  =>	AUX_xberr,	   
    AUX_xds_n	  	  =>	AUX_xds_n,	   
    AUX_on_n	     	=>	AUX_on_n,	    
    AUX_xtrig     	=>	AUX_xtrig,    
    AUX_xas_n	  	  =>	AUX_xas_n,	   
    AUX_xtrgv_n	  	=>	AUX_xtrgv_n,	 
		AUX_xsyncrd_n 	=>	AUX_xsyncrd_n,
		AUX_xa_sel	  	=>	AUX_xa_sel,
		Led_red		      => Led_red,		  
		Led_yellow	    => Led_yellow	     	  
		);
	
	U15_sn74vme: sn74vme 
	GENERIC MAP ( NUMOFBIT => 8 ) 
	PORT MAP(
		I1OEAB	=> '0',
		I1A		=> '0',
		I1Y 		=> open,
		O1B 		=> open,
		I2OEAB 	=> '0',
		I2A 		=> '0',
		I2Y 		=> open,
		O2B 		=> open,
		OEn 		=> VME_dataOE,
		DIR 		=> VME_data_DIR,
		I3A 		=> VME_data(7 downto 0),
		O3B 		=> BUS_DATA(7 downto 0)
		);	
	
	U16_sn74vme: sn74vme 
	GENERIC MAP ( NUMOFBIT => 8 ) 
	PORT MAP(
		I1OEAB	=> '0',
		I1A		=> '0',
		I1Y 		=> VME_Dsy(1),
		O1B 		=> BUS_DS_n(1),
		I2OEAB 	=> '0',
		I2A 		=> '0',
		I2Y 		=> VME_Dsy(0),
		O2B 		=> BUS_DS_n(0),
		OEn 		=> VME_dataOE,
		DIR 		=> VME_data_DIR,
		I3A 		=> VME_data(15 downto 8),
		O3B 		=> BUS_DATA(15 downto 8)
		);	
	
	U17_sn74vme: sn74vme 
	GENERIC MAP ( NUMOFBIT => 8 ) 
	PORT MAP(
		I1OEAB	=> '0',
		I1A		=> '0',
		I1Y 		=> open,
		O1B 		=> open,
		I2OEAB 	=> '0',
		I2A 		=> '0',
		I2Y 		=> open,
		O2B 		=> open,
		OEn 		=> VME_dataOE,
		DIR 		=> VME_data_DIR,
		I3A 		=> VME_data(23 downto 16),
		O3B 		=> BUS_DATA(23 downto 16)
		);	
	
	U18_sn74vme: sn74vme 
	GENERIC MAP ( NUMOFBIT => 8 ) 
	PORT MAP(
		I1OEAB	=> '0',
		I1A		=> '0',
		I1Y 		=> open,
		O1B 		=> open,
		I2OEAB 	=> '0',
		I2A 		=> '0',
		I2Y 		=> open,
		O2B 		=> open,
		OEn 		=> VME_dataOE,
		DIR 		=> VME_data_DIR,
		I3A 		=> VME_data(31 downto 24),
		O3B 		=> BUS_DATA(31 downto 24)
		);	
	
	U21_sn74vme: sn74vme 
	GENERIC MAP ( NUMOFBIT => 8 ) 
	PORT MAP(
		I1OEAB	=> '0',
		I1A		=> '0',
		I1Y 		=> VME_ASy,
		O1B 		=> BUS_AS_n,
		I2OEAB 	=> '0',
		I2A 		=> '0',
		I2Y 		=> VME_IACKy,
		O2B 		=> BUS_IACK_n,
		OEn 		=> VME_addrOE,
		DIR 		=> VME_addr_DIR,
		I3A 		=> VME_addr(7 downto 0),
		O3B 		=> BUS_ADDR(7 downto 0)
		);	
		
	U22_sn74vme: sn74vme 
	GENERIC MAP ( NUMOFBIT => 8 ) 
	PORT MAP(
		I1OEAB	=> '0',
		I1A		=> '0',
		I1Y 		=> VME_IACKINy,
		O1B 		=> BUS_IACKIN_n,
		I2OEAB 	=> '1',
		I2A 		=> VME_IACKOUTa,
		I2Y 		=> open,
		O2B 		=> BUS_IACKOUT_n,
		OEn 		=> VME_addrOE,
		DIR 		=> VME_addr_DIR,
		I3A 		=> VME_addr(15 downto 8),
		O3B 		=> BUS_ADDR(15 downto 8)
		);	
		
	U23_sn74vme: sn74vme 
	GENERIC MAP ( NUMOFBIT => 8 ) 
	PORT MAP(
		I1OEAB	=> VME_oeabDTACK,
		I1A		=> VME_DTACKa,
		I1Y 		=> open,
		O1B 		=> BUS_DTACK_n,
		I2OEAB 	=> '0',
		I2A 		=> '0',
		I2Y 		=> VME_WRITEy,
		O2B 		=> BUS_WRITE_n,
		OEn 		=> VME_addrOE,
		DIR 		=> VME_addr_DIR,
		I3A 		=> VME_addr(23 downto 16),
		O3B 		=> BUS_ADDR(23 downto 16)
		);	
		
	U24_sn74vme: sn74vme 
	GENERIC MAP ( NUMOFBIT => 8 ) 
	PORT MAP(
		I1OEAB	=> VME_oeabRETRY,
		I1A		=> VME_RETRYa,
		I1Y 		=> open,
		O1B 		=> BUS_RETRY_n,
		I2OEAB 	=> '0',
		I2A 		=> '0',
		I2Y 		=> open,
		O2B 		=> open,
		OEn 		=> VME_addrOE,
		DIR 		=> VME_addr_DIR,
		I3A 		=> VME_addr(31 downto 24),
		O3B 		=> BUS_ADDR(31 downto 24)
		);	
		
	U19_sn74vme: sn74vme 
	GENERIC MAP ( NUMOFBIT => 6 ) 
	PORT MAP(
		I1OEAB	=> VME_oeabBERR,
		I1A		=> '0',
		I1Y 		=> open,
		O1B 		=> BUS_BERR_n,
		I2OEAB 	=> VME_IRQ(1),
		I2A 		=> '0',
		I2Y 		=> open,
		O2B 		=> BUS_IRQ(1),
		OEn 		=> '0',
		DIR 		=> '0',
		I3A 		=> VME_am(5 downto 0),
		O3B 		=> BUS_AM(5 downto 0)
		);	
		
	--in realta' sono su U19 ...
	VME_sysclk 		<= BUS_SYSCLK;	
	VME_sysres_n 	<= BUS_SYSRES_n;	
		
	U51_LCV07A:
	for i in 2 to 7 generate
		BUS_IRQ(i) <= '0' when (VME_IRQ(i) = '1') else 'Z';
	end generate;
	
-- AUX BUS
  BUS_XT2 <= trigger;
	-- in realta arrivano differenziali su U31 ...
	AUX_xtrig <= BUS_XCLK & BUS_XRES & BUS_XT2 & BUS_XT1;

	U25_sn74vme: sn74vme 
	GENERIC MAP ( NUMOFBIT => 8 ) 
	PORT MAP(
		I1OEAB	=> '0',
		I1A		=> '0',
		I1Y 		=> open,
		O1B 		=> open,
		I2OEAB 	=> '1',
		I2A 		=> AUX_xsds_n,
		I2Y 		=> open,
		O2B 		=> BUS_XSDS_n,
		OEn 		=> AUX_xsel_n,
		DIR 		=> '1',
		I3A 		=> VME_data(7 downto 0),
		O3B 		=> BUS_XD(7 downto 0)
		);	
	
	U26_sn74vme: sn74vme 
	GENERIC MAP ( NUMOFBIT => 8 ) 
	PORT MAP(
		I1OEAB	=> '0',
		I1A		=> '0',
		I1Y 		=> AUX_xas_n,
		O1B 		=> BUS_XAS_n,
		I2OEAB 	=> '0',
		I2A 		=> '0',
		I2Y 		=> AUX_xtrgv_n,
		O2B 		=> BUS_XTRGV_n,
		OEn 		=> AUX_xsel_n,
		DIR 		=> '1',
		I3A 		=> VME_data(15 downto 8),
		O3B 		=> BUS_XD(15 downto 8)
		);	
	
	U27_sn74vme: sn74vme 
	GENERIC MAP ( NUMOFBIT => 4 ) 
	PORT MAP(
		I1OEAB	=> '0',
		I1A		=> '0',
		I1Y 		=> AUX_xds_n,
		O1B 		=> BUS_XDS_n,
		I2OEAB 	=> '0',
		I2A 		=> '0',
		I2Y 		=> AUX_xsyncrd_n,
		O2B 		=> BUS_XSYNCRD_n,
		OEn 		=> AUX_xsel_n,
		DIR 		=> '1',
		I3A 		=> VME_data(19 downto 16),
		O3B 		=> BUS_XD(19 downto 16)
		);	
		
	-- in realta sono su U27 ...
-- out alp:
--	AUX_xdk_n  <= BUS_XDK_n  when AUX_xsel_n = '0' else 'Z';
--	AUX_xeob_n <= BUS_XEOB_n when AUX_xsel_n = '0' else 'Z';
-- in alp:
	BUS_xdk_n  <= AUX_XDK_n  when AUX_xsel_n = '0' else 'Z';
	BUS_xeob_n <= AUX_XEOB_n when AUX_xsel_n = '0' else 'Z';
	
	U28_sn74vme: sn74vme 
	GENERIC MAP ( NUMOFBIT => 8 ) 
	PORT MAP(
		I1OEAB	=> '0',
		I1A		=> '0',
		I1Y 		=> AUX_xa_sel,
		O1B 		=> BUS_XA_SEL,
		I2OEAB 	=> AUX_xbk_n,
		I2A 		=> '0',
		I2Y 		=> BUS_XBK,
		O2B 		=> open,
		OEn 		=> AUX_on_n,
		DIR 		=> '0',
		I3A 		=> VME_data(27 downto 20),
		O3B 		=> BUS_XT(7 downto 0)
		);	
	
	U20_sn74vme: sn74vme 
	GENERIC MAP ( NUMOFBIT => 4 ) 
	PORT MAP(
		I1OEAB	=> AUX_xbusy,
		I1A		=> '0',
		I1Y 		=> open,
		O1B 		=> BUS_XBUSY_n,
		I2OEAB 	=> AUX_xberr,
		I2A 		=> '0',
		I2Y 		=> open,
		O2B 		=> BUS_XBERR_n,
		OEn 		=> AUX_on_n,
		DIR 		=> '0',
		I3A 		=> VME_data(31 downto 28),
		O3B 		=> BUS_XT(11 downto 8)
		);	
	
	U52_sn74vme: sn74vme 
	GENERIC MAP ( NUMOFBIT => 8 ) 
	PORT MAP(
		I1OEAB	=> '0',
		I1A		=> '0',
		I1Y 		=> open,
		O1B 		=> open,
		I2OEAB 	=> '0',
		I2A 		=> '0',
		I2Y 		=> open,
		O2B 		=> open,
		OEn 		=> VME_statrd_n,
		DIR 		=> '1',
		I3A 		=> STAT_REG(7 downto 0),
		O3B 		=> BUS_DATA(7 downto 0)
		);	
	
	STAT_REG <= "00" & AUX_xbk_n & AUX_xeob_n & AUX_xsds_n & AUX_xbusy & AUX_xberr & AUX_on_n;	
	
	-- VME BUS SIGNAL from vme64x simulation 
	BUS_IACKIN_n  						<= VME64xBus_out.Vme64xIACKIN;
	BUS_IACK_n    						<= VME64xBus_out.Vme64xIACK;
	BUS_AS_n      						<= VME64xBus_out.Vme64xAsN;
	BUS_WRITE_n   						<= VME64xBus_out.Vme64xWRITEN;
	BUS_AM        						<= VME64xBus_out.Vme64xAM;
	BUS_DS_n(1)   						<= VME64xBus_out.Vme64xDs1N;
	BUS_DS_n(0)   						<= VME64xBus_out.Vme64xDs0N;
	BUS_ADDR(0)   						<= VME64xBus_out.Vme64xLWORDN;
	BUS_ADDR(31 downto 1)			<= VME64xBus_out.Vme64xADDR;
	BUS_DATA      						<= VME64xBus_out.Vme64xDATA;	
  	VME64xBus_in.Vme64xLWORDN  <= to_UX01(BUS_ADDR(0));
  	VME64xBus_in.Vme64xADDR    <= to_UX01(BUS_ADDR(31 downto 1));
	VME64xBus_in.Vme64xDATA    <= to_UX01(BUS_DATA);
	VME64xBus_in.Vme64xDtackN  <= to_UX01(BUS_DTACK_n);				
	VME64xBus_in.Vme64xBerrN   <= to_UX01(BUS_BERR_n);					
	VME64xBus_in.Vme64xRetryN  <= to_UX01(BUS_RETRY_n);
	VME64xBus_in.Vme64xIRQ     <= BUS_IRQ; 									-- era _n perche'?
	VME64xBus_in.Vme64xIACKOUT <= BUS_IACKOUT_n;

	PULLUP_DTACK_n : PULLUP
	port map (
	   O => BUS_DTACK_n     -- Pullup output (connect directly to top-level port)
	);
			
	PULLUP_BERR_n : PULLUP
	port map (
	   O => BUS_BERR_n     -- Pullup output (connect directly to top-level port)
	);
			
	PULLUP_RETRY_n : PULLUP
	port map (
	   O => BUS_RETRY_n     -- Pullup output (connect directly to top-level port)
	);
	
	PULLUP_XBUSY_n : PULLUP
	port map (
	   O => BUS_XBUSY_n     -- Pullup output (connect directly to top-level port)
	);
	
	PULLUP_XBERR_n : PULLUP
	port map (
	   O => BUS_XBERR_n     -- Pullup output (connect directly to top-level port)
	);
	
	PULLUP_XBK : PULLUP
	port map (
	   O => BUS_XBK     -- Pullup output (connect directly to top-level port)
	);
	
	
	BUS_PULL_UP: 
	for i in 0 to 31 generate
		data_pull_up : PULLUP
				port map (
   					O => BUS_DATA(i)
						);
		addr_pull_up : PULLUP
				port map (
   					O => BUS_ADDR(i)
						);
	end generate;
	
		
			
	-- Clock process definitions
   CLK_process :process
   begin
		clk_p <= '0';
		clk_n <= '1';
		wait for CLK_period/2;
		clk_p <= '1';
		clk_n <= '0';
		wait for CLK_period/2;
   end process;

   
   -- Stimuli process
   VME_stimuli_proc: process
   	--variable s : line;
   	
  ---------- in alp: -----------
  procedure W_CSR( address         : in integer; data      : in integer range 0 to 2**08-1 ) is
  begin s_AddressingType <= CR_CSR; s_dataTransferType <= D08Byte3; s_dataToSend <= std_logic_vector(to_unsigned(data,32)); wait for 1 ns;
    WriteCSR(c_address => std_logic_vector(to_unsigned(address, 20)), s_dataToSend => s_dataToSend,
             s_dataTransferType => s_dataTransferType, s_AddressingType => s_AddressingType, VME64xBus_In => VME64xBus_in, VME64xBus_Out => VME64xBus_Out);
    wait for 20 ns;
  end procedure;
  procedure W_CSR( address         : in std_logic_vector(19 downto 0); data      : in std_logic_vector(7 downto 0) ) is
  begin s_AddressingType <= CR_CSR; s_dataTransferType <= D08Byte3; s_dataToSend <= x"000000" & data; wait for 1 ns;
    WriteCSR(c_address          => address, s_dataToSend => s_dataToSend,
             s_dataTransferType => s_dataTransferType, s_AddressingType => s_AddressingType, VME64xBus_In => VME64xBus_in, VME64xBus_Out => VME64xBus_Out);
    wait for 20 ns;
  end procedure;
  procedure axi_write( address         : in integer; data      : in integer ) is
  begin s_AddressingType <= A32; s_dataTransferType <= D32; s_dataToSend <= std_logic_vector(to_unsigned(data,32)); wait for 1 ns;
    S_Write(v_address        => x"00000000" & x"0800" & std_logic_vector(to_unsigned(address, 14)) & "00" , s_dataToSend => s_dataToSend,
            s_dataTransferType => s_dataTransferType, s_AddressingType => s_AddressingType, VME64xBus_In => VME64xBus_In, VME64xBus_Out    => VME64xBus_Out);
    wait for 100 ns;
  end procedure;
  procedure axi_write( address         : in std_logic_vector(13 downto 0); data      : in std_logic_vector(31 downto 0) ) is
  begin s_AddressingType <= A32; s_dataTransferType <= D32; s_dataToSend <= data; wait for 1 ns;
    S_Write(v_address        => x"00000000" & x"0800" & address & "00" , s_dataToSend => s_dataToSend,
            s_dataTransferType => s_dataTransferType, s_AddressingType => s_AddressingType, VME64xBus_In => VME64xBus_In, VME64xBus_Out    => VME64xBus_Out);
    wait for 100 ns;
  end procedure;
  procedure axi_read( address         : in integer; data      : in integer range 0 to 2**8-1 ) is begin
     -- create the procedure in pack
  end procedure;
  ----------------------
   
   begin	


    BUS_SYSRES_n <= '0'; -- hold reset state for 100 ns.
    wait for 102 ns;	
    wait for 1 us;
    BUS_SYSRES_n <= '1';
    
    
      VME64xBus_Out.Vme64xIACK <= '1';
      VME64xBus_Out.Vme64xIACKIN <= '1';
      
      wait for 10 us;                   -- wait until the initialization finish (wait more than 8705 ns)
   
    ------------------------------------------------------------------------------
    -- Configure window to access WB bus (ADER)
    ------------------------------------------------------------------------------

    wait for 50 ns;
    report "START WRITE ADER";
    --W_CSR(x"FFF63", x"08"); -- 0x0FFF63: "00001000"
    W_CSR(c_FUNC0_ADER_3, ADER0_A32(31 downto 24)); -- 0x07FF63: BA(7 downto 3) & "000"
    
    W_CSR(c_FUNC0_ADER_2, ADER0_A32(23 downto 16)); -- 0x07FF67: "00000000"

    W_CSR(c_FUNC0_ADER_1, ADER0_A32(15 downto  8)); -- 0x07FF6B: "00000000"
    
    W_CSR(c_FUNC0_ADER_0, ADER0_A32( 7 downto  0)); -- 0x07FF6F: Addr Modifier & "00" : 0x24 per AM = 0x09
    report "THE MASTER HAS WRITTEN CORRECTLY ALL THE ADERs";

    ------------------------------------------------------------------------------
    -- Enables the VME64x core
    ------------------------------------------------------------------------------
    -- Module Enabled:
    W_CSR(c_BIT_SET_REG, x"10"); -- 0x07FF6B: "00010000"
    
    report "THE MASTER HAS ENABLED THE BOARD";

    ------------------------------------------------------------------------------
    -- Access to AXI registers
    ------------------------------------------------------------------------------
    -- Reset AUX BUS
    axi_write(0,1);
    -- Enable AUX BUS Test Mode
    axi_write(1,3);
    -- Run AUX BUS
    axi_write(0,0);
    report "THE MASTER HAS SET THE AUX IN BUILT_IN TEST MODE";
    
    -- Enable AUX BUS
    W_CSR(c_USR_BIT_SET_REG, "00000000");
    report "THE MASTER HAS ENABLED THE AUX";
--	wait for 1 us;
--	 -- Enable AUX BUS
--     W_CSR(c_USR_BIT_CLR_REG, "00000000");
--     report "THE MASTER HAS DISENABLED THE AUX";
    wait;
   end process;
	
--------------------
-- CHECK RX DATA
--------------------
process
variable inc          : integer   := 0;
variable van          : integer   := 0;
variable vbn          : integer   := 0;
variable vai          : integer   := 0;
variable vbi          : integer   := 0;
begin
  wait until rising_edge(BUS_xtrgv_n);
  if BUS_xsyncrd_n = '0' then
    wait until rising_edge(BUS_xsyncrd_n);
  else
    -- TEST MODE
    wait until falling_edge(BUS_xdk_n);
    if to_integer(unsigned(BUS_xd(BUS_xd'high downto BUS_xd'high-6))) < 48 then
      a_data   <= BUS_xd(BUS_xd'high-8 downto 0);
      a_valid  <= '1';
      a_clk    <= '0';
    else
      b_data   <= BUS_xd(BUS_xd'high-8 downto 0);
      b_valid  <= '1';
      b_clk    <= '0';
    end if;
    while BUS_xeob_n/='0' loop
      wait until BUS_xdk_n'event and BUS_xdk_n='1';--rising_edge(BUS_xdk_n);
      a_valid  <= '1';
      a_clk    <= '1';
      b_valid  <= '1';
      b_clk    <= '1';
      wait until falling_edge(BUS_xdk_n);
      if to_integer(unsigned(BUS_xd(BUS_xd'high downto BUS_xd'high-6))) < 48 then
        a_data   <= BUS_xd(BUS_xd'high-8 downto 0);
        a_valid  <= '1';
        a_clk    <= '0';
      else
        b_data   <= BUS_xd(BUS_xd'high-8 downto 0);
        b_valid  <= '1';
        b_clk    <= '0';
      end if;
    end loop;
    wait until BUS_xdk_n'event and BUS_xdk_n='1';--rising_edge(BUS_xdk_n);
    a_valid  <= '1';
    a_clk    <= '1';
    b_valid  <= '1';
    b_clk    <= '1';
    inc := inc+1;
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
process
  --------------------
  -- Sync Cycle
  --------------------
  procedure sync_cycle is
  constant tn   : std_logic_vector(11 downto 0) := std_logic_vector(to_unsigned(trig_num,12));
  begin
    -- Trigger Bus, first valid trigger is 001
    BUS_xt            <= (others=> '0');
  -- Master is initiating a synch check, Active LOW
    BUS_xsyncrd_n     <= '0';
    wait for 50 ns;
    -- Trigger Bus Data is valide, Active LOW
    BUS_xtrgv_n       <= '0';
    wait until BUS_xbk = '1' for 1 us;
--      if BUS_xbk = '0' then
--        report "No response during Trigger Cycle with Trigger Number " & integer'image(trig_num) & "." severity WARNING;
--      end if;
      founddata <= not BUS_xsds_n;
      wait for 5 ns;
      assert not(BUS_xbk='0') report "ERROR: xbk asserted to '0' before xtrgv_n is released during trigger cycle with Trigger Number " & integer'image(trig_num) & "." severity FAILURE;
    -- Trigger Bus Data is valide, Active LOW
    BUS_xtrgv_n       <= '1';
    -- Trigger Bus, first valid trigger is 001
    BUS_xt            <= (others => '0');
  end sync_cycle;
  --------------------
  -- Sync Readout Cycle
  --------------------
  procedure sync_readout (founddata : std_logic) is
  begin
    if founddata = '0' then
      report "Error: xsds not asserted low during sync cycle." severity FAILURE;
      return;
    end if;
    -- Address Bus
    BUS_xa_sel            <= '1';
    wait for 40 ns;
    -- Address Bus is Valid
    BUS_xas_n         <= '0';
    wait for 1 ns;
    RO_loop: loop
      -- ROCK ready to read from slave, Active LOW
      -- ROCK finished to read from slave, Active HIGH
      BUS_xds_n         <= '0';
      wait until BUS_xdk_n = '0' for 1 us;
      if BUS_xdk_n /= '0' then
        report "No response from target " & "during Sync Readout Cycle " & "." severity FAILURE;
        exit RO_loop;
      end if;
      rx_data <= BUS_xd;
      -- ROCK ready to read from slave, Active LOW
      -- ROCK finished to read from slave, Active HIGH
      BUS_xds_n           <= '1';
      wait for 15 ns;
      exit RO_loop when BUS_xeob_n = '0';
      report "xeob_n not asserted low during Sync Readout" & "." severity FAILURE;
    end loop;
    wait for 5 ns;
    -- Address Bus is Valid
    BUS_xas_n         <= '1';
    wait for 50 ns;
    -- Address Bus
    BUS_xa_sel            <= '0';
    -- Master is initiating a synch check, Active LOW
    BUS_xsyncrd_n     <= '1';
  end sync_readout;
  --------------------
  -- Set in Idle
  --------------------
  procedure idle is
  begin
    -- Trigger Bus, first valid trigger is 001
    BUS_xt            <= (others => '0');
    -- Trigger Bus Data is valide, Active LOW
    BUS_xtrgv_n       <= '1';
    -- Address Bus
    BUS_xa_sel        <= '0';
    -- Address Bus is Valid
    BUS_xas_n         <= '1';
    -- ROCK ready to read from slave, Active LOW
    -- ROCK finished to read from slave, Active HIGH
    BUS_xds_n         <= '1';
    -- Master is initiating a synch check, Active LOW
    BUS_xsyncrd_n     <= '1';
    -- ROCK send a system HALT due to Error,
    --xsyshalt      <= '1';
    -- ROCK produces a create level AUX reset
    --xsysreset     <= '1';
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
    -- Trigger Bus, first valid trigger is 000
    BUS_xt            <= tn;
    wait for 40 ns;
    -- Trigger Bus Data is valide, Active LOW
    BUS_xtrgv_n       <= '0';
    wait until BUS_xbk = '1' for 1 us;
--    if xbk = '0' then
--      report "No response during Trigger Cycle with Trigger Number " & integer'image(trig_num) & "." severity WARNING;
--    else
      founddata <= not BUS_xsds_n;
      wait for 5 ns;
      assert not(BUS_xbk='0') report "ERROR: xbk asserted to '0' before xtrgv_n is released during trigger cycle with Trigger Number " & integer'image(trig_num) & "." severity FAILURE;
--    end if;
    -- Trigger Bus Data is valide, Active LOW
    BUS_xtrgv_n       <= '1';
    -- Trigger Bus, first valid trigger is 001
    BUS_xt            <= (others => '0');
  end trigger_cycle;
  --------------------
  -- Trigger Readout Cycle
  --------------------
  procedure trigger_readout (trig_num : integer; founddata : std_logic) is
  begin
    if founddata = '0' then
      --report "No found data, exiting from readout cycle." severity note;
      return;
    end if;
    -- Address Bus
    BUS_xa_sel        <= '1';
    wait for 40 ns;
    -- Address Bus is Valid
    BUS_xas_n         <= '0';
    wait for 1 ns;
    RO_loop: loop
      -- ROCK ready to read from slave, Active LOW
      -- ROCK finished to read from slave, Active HIGH
      BUS_xds_n         <= '0';
      wait until BUS_xdk_n = '0' for 1 us;
      if BUS_xdk_n /= '0' then
        report "No response from target " & "during Readout Cycle with Trigger Number " & integer'image(trig_num) & "." severity FAILURE;
        exit RO_loop;
      end if;
      rx_data <= BUS_xd;
      wait for 4 ns;
      BUS_xds_n         <= '1';
      wait for 1 ns;
      -- ROCK ready to read from slave, Active LOW
      -- ROCK finished to read from slave, Active HIGH
      exit RO_loop when BUS_xeob_n = '0';
      wait for 15 ns;
    end loop;
    wait for 10 ns;
    -- Address Bus is Valid
    BUS_xas_n         <= '1';
    wait for 40 ns;
    -- Address Bus
    BUS_xa_sel        <= '0';
  end trigger_readout;
  variable tst  : time := 300 ps;
begin
  tst := (tst + 300 ps);
  -- idle
  idle;
  wait for 100 ns;
  if AUX_on_n='1' then
    wait until AUX_on_n = '0';
      wait for 100 ns;
  end if;
  trig_num <= trig_num + 1;
  wait for tst;
  --report "Start AUX Trigger Cycle..." severity NOTE;
  trigger_cycle(trig_num);
  --report "Done." severity NOTE;
  wait for 150 ns;
  wait for tst;
  --report "Start AUX Trigger Readout Cycle..." severity NOTE;
  trigger_readout(trig_num, founddata);
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
  sync_readout(founddata);
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
  wait until falling_edge(BUS_xtrgv_n);
  wait until BUS_xsds_n = '0';
  curr_time := now;
  wait until BUS_xbk = '1'; --'Z'
  time_diff := now - curr_time;
  --report "--------- - - 35ns -> " & time'image(time_diff) severity NOTE;
  assert time_diff >= 35 ns report "TRIGGER TIMING ERROR:35ns -> " & time'image(time_diff) severity FAILURE;
end process;
-- readout (15 ns)
process
  variable time_diff : time;
  variable curr_time : time;
  variable xd_temp   : std_logic_vector(19 DOWNTO 0);
begin
  wait until rising_edge(BUS_xds_n);
  wait until BUS_xd'event;
  xd_temp := BUS_xd;
  curr_time := now;
  loop ---------- Note: There could be a second event in xd.
    wait until falling_edge(BUS_xdk_n) or BUS_xd'event;
    if xd_temp = BUS_xd then
      exit;
    end if;
    xd_temp := BUS_xd;
    curr_time := now;
  end loop;
  time_diff := now - curr_time;
  --report "--------- - - 15ns -> " & time'image(time_diff) severity NOTE;
  assert time_diff >= 15 ns report "READOUT TIMING ERROR: 15ns -> " & time'image(time_diff) severity FAILURE;
end process;

rst <= not BUS_SYSRES_n;

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
  wait until clk_p'event and clk_p='1';
  wait for clk_period/5;
  if BUS_xsyncrd_n='1'and AUX_xbusy='0' then
    trigger <= '1';
  end if;
  wait for clk_period*10;
end process;

end AUX_Behavioral;
