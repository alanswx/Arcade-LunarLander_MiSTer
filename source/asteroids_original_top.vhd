--
-- A simulation model of Asteroids hardware modified to drive a real vector monitor using a VGA DAC 
-- James Sweet 2016
-- This is not endorsed by fpgaarcade, please do not bother MikeJ with support requests
--
--
-- Built upon model of Asteroids Deluxe hardware
-- Copyright (c) MikeJ - May 2004
--
--
-- All rights reserved
--
-- Redistribution and use in source and synthezised forms, with or without
-- modification, are permitted provided that the following conditions are met:
--
-- Redistributions of source code must retain the above copyright notice,
-- this list of conditions and the following disclaimer.
--
-- Redistributions in synthesized form must reproduce the above copyright
-- notice, this list of conditions and the following disclaimer in the
-- documentation and/or other materials provided with the distribution.
--
-- Neither the name of the author nor the names of other contributors may
-- be used to endorse or promote products derived from this software without
-- specific prior written permission.
--
-- THIS CODE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
-- THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
-- PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
-- LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
-- CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
-- SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
-- INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
-- CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
-- ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
-- POSSIBILITY OF SUCH DAMAGE.
--
-- You are responsible for any legal issues arising from your use of this code.
--
-- The latest version of this file can be found at: www.fpgaarcade.com
--
-- Email support@fpgaarcade.com
--
-- Revision list
--
-- version 001 initial release
--
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_arith.all;
  use ieee.std_logic_unsigned.all;

    --
    -- Notes :
    --
    -- Button shorts input to ground when pressed
	 -- 
	 -- ToDo:
			-- Model sound effects for thump-thump, ship and saucer fire and saucer warble 
			-- Add player control switching and screen flip for cocktail mode 
			-- General cleanup
    

entity ASTEROIDS_TOP is
  port (
  
	 debug_led						: out std_logic_vector(2 downto 0);
  
    SW            			   : in std_logic_vector(15 downto 1); -- active low
	 SELF_TEST		    			: in std_logic; -- active low
    --
	 START_LED1_O			 		: out std_logic;
	 START_LED2_O			 		: out std_logic;
	 --
	 SOUND_OUT						: out std_logic;
    --
	 -- External program ROM
	 PROG_ROM_ADDR					: out std_logic_vector(18 downto 0);
	 PROG_ROM_DATA					: in	std_logic_vector(7 downto 0);
	 PROG_ROM_WE					: out std_logic; 
	 PROG_ROM_OE					: out std_logic;
    --
	 X_DEFLECT						: out std_logic_vector(9 downto 0);
	 Y_DEFLECT						: out std_logic_vector(9 downto 0);	 
	 O_VIDEO_Z 						: out std_logic_vector(3 downto 0);
	 DAC_CLK							: out std_logic;
	 --
    RESET_L           			: in  std_logic;
    -- ref clock in
    CLK_IN            			: in  std_logic
	
    );
end;

architecture RTL of ASTEROIDS_TOP is

	signal reset_dll_h         : std_logic;
	signal clk_6               : std_logic := '0';
	signal clk_12					: std_logic := '0';
	signal delay_count         : std_logic_vector(7 downto 0) := (others => '0');
	signal reset_6_l           : std_logic;
	signal clk_cnt             : std_logic_vector(2 downto 0) := "000";
	signal x_vector            : std_logic_vector(9 downto 0);
	signal y_vector            : std_logic_vector(9 downto 0);
	signal z_vector            : std_logic_vector(3 downto 0);
	signal beam_on             : std_logic;
	signal beam_ena            : std_logic;
	signal selftest				: STD_LOGIC;
	signal reset_h					: STD_LOGIC;
	signal xval						: STD_LOGIC_VECTOR(9 downto 0);
	signal yval						: STD_LOGIC_VECTOR(9 downto 0);
	signal audio					: STD_LOGIC_VECTOR(7 downto 0);
	signal zval						: STD_LOGIC_VECTOR(3 downto 0);
	signal start_LED1				: std_logic;
	signal start_LED2				: std_logic;
	
	

begin


debug_led(2) <= '1';  -- Not currently using these, just turn them off
debug_led(1) <= '1';
debug_led(0) <= '1';

RESET_H <= not RESET_L; -- Creates active high reset signal from active low reset
START_LED1_O <= not start_LED1; 	-- Start LEDs are switched on the anode side on this setup
START_LED2_O <= not start_LED2;
X_DEFLECT <= xval;
Y_DEFLECT <= yval;
DAC_CLK <= clk_6;

-- Used by external program ROM
PROG_ROM_WE <= '1';
PROG_ROM_OE <= '0';
prog_rom_addr(18 downto 13) <= (others => '0'); -- Tie unused ROM address pins low

	 
clock: entity work.clock_pll
port map(
		inclk0 => CLK_IN,
		c0	=> clk_12,
		areset => reset_h,
		locked => open
		);
		
Clock_Div: process(clk_12)
	begin
		if rising_edge(clk_12) then
			clk_6 <= (not clk_6);
		end if;
	end process;
	

  	AudioDAC: work.deltasigma PORT MAP(
		inval => audio,
		output => sound_out,
		clk => clk_in,
		reset => reset_h
	);
--  

  p_delay : process(RESET_L, clk_6)
  begin
    if (RESET_L = '0') then
      delay_count <= x"00"; -- longer delay for cpu
      reset_6_l <= '0';
    elsif rising_edge(clk_6) then
      if (delay_count(7 downto 0) = (x"FF")) then
        delay_count <= (x"FF");
        reset_6_l <= '1';
      else
        delay_count <= delay_count + "1";
        reset_6_l <= '0';
      end if;
    end if;
  end process;


	
	Inst_ASTEROIDS: work.ASTEROIDS PORT MAP(
		BUTTON => SW,
		SELF_TEST_SWITCH_L => Self_Test,
		AUDIO_OUT => audio,
		X_VECTOR => xval,
		Y_VECTOR => yval,
		Z_VECTOR => O_VIDEO_Z,
		BEAM_ON => open,
		BEAM_ENA => open,
		START1_LED_L => Start_LED1,
		START2_LED_L => Start_LED2,
		L_COIN_COUNTER => open,
		C_COIN_COUNTER => open,
		R_COIN_COUNTER => open,
		RESET_6_L => reset_l,
	   PROG_ROM_ADDR => prog_rom_addr(12 downto 0),
	   PROG_ROM_DATA => prog_rom_data,
		CLK_6 => clk_6
	);


end RTL;
