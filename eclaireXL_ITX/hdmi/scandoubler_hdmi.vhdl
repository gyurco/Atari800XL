---------------------------------------------------------------------------
-- (c) 2016 mark watson
-- I am happy for anyone to use this for non-commercial use.
-- If my vhdl files are used commercially or otherwise sold,
-- please contact me for explicit permission at scrameta (gmail).
-- This applies for source and binary form and derived works.
---------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.numeric_std.all;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_MISC.all;
use work.pixels.all;

ENTITY scandoubler_hdmi IS
GENERIC(
	enable_area_scaler : integer;
	enable_polyphasic_scaler : integer
);
PORT 
( 
	-- Atari clock_domain
	CLK_ATARI_IN : IN STD_LOGIC;           -- 56MHz approx (PAL 50Hz exactly/NTSC 59.94Hz exactly)

	RESET_N : IN STD_LOGIC;

 	-- Audio
 	audio_left : in std_logic_vector(15 downto 0);
 	audio_right: in std_logic_vector(15 downto 0);
	
	-- GTIA interface
	pal : in std_logic;
	scanlines_on : in std_logic;
	csync_on : in std_logic;
	colour_enable : in std_logic;  -- 720 pixels/line (at least...)
	colour_in : in std_logic_vector(7 downto 0);
	vsync_in : in std_logic;       -- high for new 
	hsync_in : in std_logic;       -- high for new line
	format : in std_logic_vector(1 downto 0);  -- "00"=VGA,"01"=DVI,"10"=HDMI
	
	--HDMI clock domain
	CLK_HDMI_IN : IN STD_LOGIC;   -- 135MHz exactly
	CLK_PIXEL_IN : IN STD_LOGIC;  -- 27 MHz exactly (aligned with HDMI)
	CLK_HDMI_SELECT : OUT STD_LOGIC_VECTOR(2 downto 0); 

	-- VGA output - in clk pixel domain
	O_hsync : out std_logic;
	O_vsync : out std_logic;
	O_blank : out std_logic;
	O_red : out std_logic_vector(7 downto 0);
	O_green : out std_logic_vector(7 downto 0);
	O_blue : out std_logic_vector(7 downto 0);

	-- TO TV...
	O_TMDS_H : OUT STD_LOGIC_VECTOR(7 downto 0);
	O_TMDS_L : OUT STD_LOGIC_VECTOR(7 downto 0);
	
	-- I2C params
    scl_in           : in std_logic;
    sda_in           : in std_logic;
	 scl_wen          : out std_logic;
	 sda_wen          : out std_logic 
);
END scandoubler_hdmi;

ARCHITECTURE vhdl OF scandoubler_hdmi IS

component hdmi_line_buffer IS
	PORT
	(
		data		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		rdaddress		: IN STD_LOGIC_VECTOR (10 DOWNTO 0);
		rdclock		: IN STD_LOGIC ;
		wraddress		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		wrclock		: IN STD_LOGIC  := '1';
		wren		: IN STD_LOGIC  := '0';
		q		: OUT STD_LOGIC_VECTOR (63 DOWNTO 0)
	);
END component;

signal colour_mask : std_logic_vector(7 downto 0);

-- TODO: NTSC!
-- ModeLine " 720x 480@59.94Hz"  27.00  720  736  798  858  480  489  495  525 -HSync -VSync

signal hsync_next		: std_logic;
signal vsync_next		: std_logic;
signal blank_next		: std_logic;
signal red_next		: std_logic_vector(7 downto 0);
signal green_next		: std_logic_vector(7 downto 0);
signal blue_next		: std_logic_vector(7 downto 0);

signal hsync_reg		: std_logic;
signal vsync_reg		: std_logic;
signal blank_reg		: std_logic;
signal red_reg		: std_logic_vector(7 downto 0);
signal green_reg		: std_logic_vector(7 downto 0);
signal blue_reg		: std_logic_vector(7 downto 0);
signal hs_hsync_next		: std_logic;
signal hs_vsync_next		: std_logic;
signal hs_hsync_reg		: std_logic;
signal hs_vsync_reg		: std_logic;
signal hs_blank_reg		: std_logic;
signal hs_red_reg		: std_logic_vector(7 downto 0);
signal hs_green_reg		: std_logic_vector(7 downto 0);
signal hs_blue_reg		: std_logic_vector(7 downto 0);
signal hs_red_reg2		: std_logic_vector(7 downto 4);
signal hs_green_reg2		: std_logic_vector(7 downto 4);
signal hs_blue_reg2		: std_logic_vector(7 downto 4);

--
signal cap_vcount_next : std_logic_vector(2 downto 0);
signal cap_vcount_reg : std_logic_vector(2 downto 0);
signal cap_hcount_next : std_logic_vector(10 downto 0);
signal cap_hcount_reg : std_logic_vector(10 downto 0);
signal cap_vsync_reg : std_logic;
signal cap_hsync_reg : std_logic;
signal cap_frame_start_flip_next : std_logic;
signal cap_frame_start_flip_reg : std_logic;
signal cap_line_start_raw : std_logic;
signal cap_line_start : std_logic;
signal cap_format : std_logic_vector(1 downto 0);
signal cap_line_start_flip_next : std_logic;
signal cap_line_start_flip_reg : std_logic;
signal cap_vcount_delay_reg : std_logic_vector(14 downto 0);
signal cap_vcount_delay_next : std_logic_vector(14 downto 0);

-- area scaling setup
signal out_colour_raw_lines : std_logic_vector(63 downto 0);

signal out_haddr_next : std_logic_vector(10 downto 0);
signal out_haddr_reg : std_logic_vector(10 downto 0);

signal out_vaddr_next : std_logic_vector(8 downto 0);
signal out_vaddr_reg : std_logic_vector(8 downto 0);

signal out_vaddr_in_next : std_logic_vector(8 downto 0);
signal out_vaddr_in_reg : std_logic_vector(8 downto 0);

signal out_pixels_next : t_Pixel4x4;
signal out_pixels_reg : t_Pixel4x4;

signal out_next_x : std_logic;
signal out_next_x_reg : std_logic;
signal out_next_x_size : std_logic_vector(1 downto 0);
signal out_next_y : std_logic;

-- crtc
signal crtc_inc_line : std_logic;
signal crtc_inc_frame : std_logic;
signal crtc_hsync : std_logic;
signal crtc_vsync : std_logic;
signal crtc_blank : std_logic;
signal crtc_field2 : std_logic;
signal crtc_video_id_code : std_logic_vector(7 downto 0);
signal crtc_scaler_select : std_logic;

signal out_resync_required_reg : std_logic;
signal out_resync_required_next : std_logic;

--signal out_colour_raw : std_logic_vector(7 downto 0);
signal out_colour : std_logic_vector(31 downto 0);
signal out_pal : std_logic;
signal out_scanlines : std_logic;
signal out_csync : std_logic;
signal out_frame_start_flip_next : std_logic;
signal out_frame_start_flip_reg : std_logic;
signal out_frame_start : std_logic;
signal out_line_start_flip_next : std_logic;
signal out_line_start_flip_reg : std_logic;
signal out_line_start : std_logic;
signal out_resync_frame_start : std_logic;
signal out_format : std_logic_vector(1 downto 0);

-- signed audio
signal audio_left_signed : std_logic_vector(15 downto 0);
signal audio_right_signed: std_logic_vector(15 downto 0);

-- audio synchronizer
signal audio_left_reg1  : std_logic_vector(15 downto 0);
signal audio_right_reg1 : std_logic_vector(15 downto 0);
signal audio_left_reg2  : std_logic_vector(15 downto 0);
signal audio_right_reg2 : std_logic_vector(15 downto 0);

-- hdmi/dvi->tmds
signal hdmi_encoded_red   : std_logic_vector(9 downto 0);
signal hdmi_encoded_green : std_logic_vector(9 downto 0);
signal hdmi_encoded_blue  : std_logic_vector(9 downto 0);
signal dvi_encoded_red   : std_logic_vector(9 downto 0);
signal dvi_encoded_green : std_logic_vector(9 downto 0);
signal dvi_encoded_blue  : std_logic_vector(9 downto 0);

signal encoded_red_next   : std_logic_vector(9 downto 0);
signal encoded_green_next : std_logic_vector(9 downto 0);
signal encoded_blue_next  : std_logic_vector(9 downto 0);
signal encoded_red_reg   : std_logic_vector(9 downto 0);
signal encoded_green_reg : std_logic_vector(9 downto 0);
signal encoded_blue_reg  : std_logic_vector(9 downto 0);

-- fast regs
signal mod5_reg	: std_logic_vector(4 downto 0) := "00000";	-- modulus 5 counter
signal mod5_next	: std_logic_vector(4 downto 0) := "00000";	-- modulus 5 counter
signal shift_r_reg	: std_logic_vector(9 downto 0) := "0000000000";
signal shift_g_reg	: std_logic_vector(9 downto 0) := "0000000000";
signal shift_b_reg	: std_logic_vector(9 downto 0) := "0000000000";
signal shift_clk_reg : std_logic_vector(9 downto 0) := "0000000000";

signal nshift_r_reg	: std_logic_vector(9 downto 0) := "0000000000";
signal nshift_g_reg	: std_logic_vector(9 downto 0) := "0000000000";
signal nshift_b_reg	: std_logic_vector(9 downto 0) := "0000000000";
signal nshift_clk_reg : std_logic_vector(9 downto 0) := "0000000000";	

signal shift_r_next	: std_logic_vector(9 downto 0) := "0000000000";
signal shift_g_next	: std_logic_vector(9 downto 0) := "0000000000";
signal shift_b_next	: std_logic_vector(9 downto 0) := "0000000000";	
signal shift_clk_next : std_logic_vector(9 downto 0) := "0000000000";
	
-- i2c
signal multiscale_sda_wen : std_logic;
signal crtc_sda_wen : std_logic;
signal multiscale_scl_wen : std_logic;
signal crtc_scl_wen : std_logic;
	
BEGIN

--------------------------------------------------------
-- Capture side
-- Store 4 lines of data in dual port ram

-- register
process(CLK_ATARI_IN,reset_n)
begin
	if (reset_n = '0') then
		cap_hcount_reg <= (others=>'0');
		cap_vcount_reg <= (others=>'0');
		cap_vsync_reg <= '0';
		cap_hsync_reg <= '0';
		cap_line_start_flip_reg <= '0';
		cap_frame_start_flip_reg <= '0';
		cap_vcount_delay_reg <= (others=>'0');
	elsif (CLK_ATARI_IN'event and CLK_ATARI_IN='1') then
		cap_hcount_reg <= cap_hcount_next;
		cap_vcount_reg <= cap_vcount_next;
		cap_vsync_reg <= vsync_in;
		cap_hsync_reg <= hsync_in;
		cap_line_start_flip_reg <= cap_line_start_flip_next;
		cap_frame_start_flip_reg <= cap_frame_start_flip_next;
		cap_vcount_delay_reg <= cap_vcount_delay_next;
	end if;
end process;

cap_line_start_raw <= not(hsync_in) and cap_hsync_reg;
hsync_delay : entity work.delay_line
	generic map (COUNT=>184)
	port map(clk=>clk_atari_in,sync_reset=>'0',data_in=>cap_line_start_raw,enable=>colour_enable,reset_n=>'1',data_out=>cap_line_start);				

-- our location
process(cap_hcount_reg, colour_enable, cap_line_start)
begin
	colour_mask <= x"ff";

	cap_hcount_next <= cap_hcount_reg;
	if (colour_enable = '1') then
		cap_hcount_next <= std_logic_vector(unsigned(cap_hcount_reg)+1);
	end if;
	if (cap_line_start = '1') then
		cap_hcount_next <= (others=>'0');
	end if;
	if (or_reduce(cap_hcount_reg(10 downto 6))='0') then
		colour_mask <= x"00";
	end if;
	if (cap_hcount_reg(10 downto 7) >= "1011") then --1408
		colour_mask <= x"00";
	end if;
end process;

process(cap_vcount_reg, cap_line_start, cap_vsync_reg, vsync_in, cap_frame_start_flip_reg, cap_line_start_flip_reg, cap_vcount_delay_reg)
begin
	cap_vcount_next <= cap_vcount_reg;
	cap_frame_start_flip_next <= cap_frame_start_flip_reg;
	cap_line_start_flip_next <= cap_line_start_flip_reg;
	cap_vcount_delay_next <= cap_vcount_delay_reg;
	
	if (cap_line_start = '1') then
		cap_vcount_next <= std_logic_vector(unsigned(cap_vcount_reg)+1);
		cap_line_start_flip_next <= not(cap_line_start_flip_reg);		
		
		cap_vcount_delay_next(14 downto 0) <= cap_vcount_delay_reg(13 downto 0)&'0';
		
		if (cap_vcount_delay_reg(14) = '1') then		
			cap_vcount_next <= (others=>'0');		
			cap_frame_start_flip_next <= not(cap_frame_start_flip_reg);		
		end if;
	end if;
	
	if (cap_vsync_reg = '1' and vsync_in = '0') then
		cap_vcount_delay_next(0) <= '1';
	end if;
end process;

hdmi_line_buffer_inst : hdmi_line_buffer
port map 
	(
		-- 8 bit write
		-- 4 lines
		-- low bit is line, so we can read all lines at once
		data		=> colour_in and colour_mask, --"00000"&cap_vcount_reg(2 downto 0),
		--data		=> "0000"&cap_hcount_reg(3 downto 0),
		--data		=> "0000"&cap_hcount_reg(0 downto 0)&"000",
		wraddress	=> cap_hcount_reg&cap_vcount_reg,
		wrclock		=> CLK_ATARI_IN,
		wren		=> colour_enable, -- 1824 times/line

		-- 32 bit read (to read all lines at once!)
		rdaddress	=> out_haddr_next,
		rdclock		=> CLK_PIXEL_IN,
		q		=> out_colour_raw_lines
	);
-- Audio should be signed

audio_left_signed  <= std_logic_vector(to_signed(to_integer(unsigned(audio_left))-32768,16));
audio_right_signed <= std_logic_vector(to_signed(to_integer(unsigned(audio_right))-32768,16));

--------------------------------------------------------
-- Output side
-- Retrieve data from dual port ram, do palette lookup and send to hdmi encoder

pal_synchronizer : entity work.synchronizer
	port map (clk=>clk_pixel_in, raw=>pal, sync=>out_pal);						

scanline_synchronizer : entity work.synchronizer
	port map (clk=>clk_pixel_in, raw=>scanlines_on, sync=>out_scanlines);						

csync_synchronizer : entity work.synchronizer
	port map (clk=>clk_pixel_in, raw=>csync_on, sync=>out_csync);						

cap_vsync_synchronizer : entity work.synchronizer
	port map (clk=>clk_pixel_in, raw=>cap_frame_start_flip_reg, sync=>out_frame_start_flip_next);			
cap_hsync_synchronizer : entity work.synchronizer
	port map (clk=>clk_pixel_in, raw=>cap_line_start_flip_reg, sync=>out_line_start_flip_next);
	
cap_format0_synchronizer : entity work.synchronizer
	port map (clk=>clk_pixel_in, raw=>format(0), sync=>out_format(0));						
cap_format1_synchronizer : entity work.synchronizer
	port map (clk=>clk_pixel_in, raw=>format(1), sync=>out_format(1));						

process(out_colour_raw_lines,out_vaddr_reg)
begin
	out_colour <= (others=>'0');

	case out_vaddr_reg(2 downto 0) is
	when "000" => 
		out_colour <= out_colour_raw_lines(31 downto 0);
	when "001" => 
		out_colour <= out_colour_raw_lines(39 downto 8);
	when "010" => 
		out_colour <= out_colour_raw_lines(47 downto 16);
	when "011" => 
		out_colour <= out_colour_raw_lines(55 downto 24);
	when "100" => 
		out_colour <= out_colour_raw_lines(63 downto 32);
	when "101" => 
		out_colour(23 downto 0) <= out_colour_raw_lines(63 downto 40);
		out_colour(31 downto 24) <= out_colour_raw_lines(7 downto 0);
	when "110" => 
		out_colour(15 downto 0) <= out_colour_raw_lines(63 downto 48);
		out_colour(31 downto 16) <= out_colour_raw_lines(15 downto 0);
	when "111" => 
		out_colour(7 downto 0) <= out_colour_raw_lines(63 downto 56);		
		out_colour(31 downto 8) <= out_colour_raw_lines(23 downto 0);
	end case;
end process;

--1 2
--3 4
-- shift pixels, when next requested
-- moving to the right
process(crtc_inc_line, out_next_x, out_next_x_size, out_haddr_reg)
begin
	out_haddr_next <= out_haddr_reg;

	if (out_next_x='1') then
		out_haddr_next <= std_logic_vector(unsigned(out_haddr_reg) + unsigned(out_next_x_size)); --read next address, next cycle
	end if;

	if (crtc_inc_line='1') then
		out_haddr_next <= (others=>'0') ; --"00000000100"; --param?
	end if;
end process;

process(out_pixels_reg, out_next_x_reg,crtc_inc_line)
begin
	for i in 0 to 2 loop
		for j in 0 to 3 loop
				out_pixels_next(pixel4x4_idx(i,j)) <= out_pixels_reg(pixel4x4_idx(i,j));
		end loop;
	end loop;
	--out_pixels_next(0 to 2,0 to 3,0 to 2) <= out_pixels_reg(0 to 2,0 to 3,0 to 2);

	if (out_next_x_reg='1') then		
		for i in 0 to 2 loop
			for j in 0 to 3 loop
					out_pixels_next(pixel4x4_idx(i,j)) <= out_pixels_reg(pixel4x4_idx(i+1,j));
			end loop;
		end loop;		
		--out_pixels_next(0 to 2,0 to 3,0 to 2) <= out_pixels_reg(1 to 3,0 to 3,0 to 2);
	end if;

	if (crtc_inc_line='1') then
		for i in 0 to 2 loop
			for j in 0 to 3 loop
				out_pixels_next(pixel4x4_idx(i,j)).red <= x"00";
				out_pixels_next(pixel4x4_idx(i,j)).green <= x"00";
				out_pixels_next(pixel4x4_idx(i,j)).blue <= x"00";
			end loop;
		end loop;			
		--out_pixels_next(0 to 2,0 to 3,0 to 2) <= (others=>'0');
	end if;
end process;

process(out_next_y, out_vaddr_reg, crtc_inc_frame)
begin
	out_vaddr_next <= out_vaddr_reg;

	if (out_next_y='1') then
		out_vaddr_next <= out_vaddr_reg + 1; 
	end if;

	if (crtc_inc_frame='1') then
		out_vaddr_next <= (others=>'0');
	end if;
end process;

-- colour palette
-- TODO- share!!
palette4 : entity work.gtia_palette
	port map (PAL=>out_pal,ATARI_COLOUR=>out_colour(7 downto 0), R_next=>out_pixels_next(pixel4x4_idx(3,0)).red, G_next=>out_pixels_next(pixel4x4_idx(3,0)).green, B_next=>out_pixels_next(pixel4x4_idx(3,0)).blue);		
palette5 : entity work.gtia_palette
	port map (PAL=>out_pal,ATARI_COLOUR=>out_colour(15 downto 8), R_next=>out_pixels_next(pixel4x4_idx(3,1)).red, G_next=>out_pixels_next(pixel4x4_idx(3,1)).green, B_next=>out_pixels_next(pixel4x4_idx(3,1)).blue);		
palette6 : entity work.gtia_palette
	port map (PAL=>out_pal,ATARI_COLOUR=>out_colour(23 downto 16), R_next=>out_pixels_next(pixel4x4_idx(3,2)).red, G_next=>out_pixels_next(pixel4x4_idx(3,2)).green, B_next=>out_pixels_next(pixel4x4_idx(3,2)).blue);		
palette7 : entity work.gtia_palette
	port map (PAL=>out_pal,ATARI_COLOUR=>out_colour(31 downto 24), R_next=>out_pixels_next(pixel4x4_idx(3,3)).red, G_next=>out_pixels_next(pixel4x4_idx(3,3)).green, B_next=>out_pixels_next(pixel4x4_idx(3,3)).blue);			

multiscale_impl : entity work.multiscale
	generic map(
		enable_area => enable_area_scaler,
		enable_polyphasic => enable_polyphasic_scaler
   )
	port map 
	(
		CLOCK => clk_pixel_in,
		RESET_N => reset_n,
		
		scaler_select => crtc_scaler_select,

		pixels => out_pixels_reg,
		next_y_in => crtc_inc_line,      --reset_x
		next_frame_in => crtc_inc_frame, --reset y
		next_x => out_next_x,
		next_y => out_next_y,
		next_x_size => out_next_x_size,
		field2 => crtc_field2, -- field 2 is half lower
		
		hsync_in => crtc_hsync,
		vsync_in => crtc_vsync,
		blank_in => crtc_blank,

		r => red_next,
		g => green_next,
		b => blue_next,
		hsync => hsync_next,
		vsync => vsync_next,
		blank => blank_next,
				
		scl_in => scl_in,
		sda_in => sda_in,	
		scl_wen => multiscale_scl_wen,
		sda_wen => multiscale_sda_wen
	);	

-- Resynchronization logic
-- Compare what is in line buffer, with what we are reading	
	out_frame_start <= out_frame_start_flip_reg xor out_frame_start_flip_next;
	out_line_start <= out_line_start_flip_reg xor out_line_start_flip_next;

	process(out_vaddr_in_reg, out_frame_start, out_line_start)
	begin
		out_vaddr_in_next <= out_vaddr_in_reg;

		if (out_frame_start='1') then
			out_vaddr_in_next <= (others=>'0');		
		elsif (out_line_start='1') then
			out_vaddr_in_next <= out_vaddr_in_reg+1;
		end if;
	end process;	
	
	process(out_frame_start,out_resync_required_reg,out_vaddr_in_reg,out_vaddr_reg)		
		variable lowerbound : std_logic_vector(8 downto 0);
		variable upperbound : std_logic_vector(8 downto 0);
	begin		
		out_resync_required_next <= out_resync_required_reg;
		out_resync_frame_start <= '0';			
		
		lowerbound := out_vaddr_in_reg-7;
		upperbound := out_vaddr_in_reg-4;
		
		if (not(out_vaddr_reg>=lowerbound and out_vaddr_reg<=upperbound) and or_reduce(out_vaddr_reg(7 downto 3))='1' and or_reduce(out_vaddr_in_reg(7 downto 3))='1') then
			out_resync_required_next <= '1';
		end if;
		
		if (out_resync_required_reg='1' and out_vaddr_in_reg="00000110") then
			out_resync_required_next <= '0';
			out_resync_frame_start <= '1';
		end if;	
	end process;

crtc_impl : entity work.crtc
	port map
	(
		clk_pixel => clk_pixel_in,
		reset_n => reset_n,

		resync_start_frame => out_resync_frame_start,

		hsync => crtc_hsync,
		vsync => crtc_vsync,
		blank => crtc_blank,

		inc_line => crtc_inc_line,
		inc_frame => crtc_inc_frame,
		field2 => crtc_field2, -- field 2 is half lower		

		clock_select => clk_hdmi_select,
		video_id_code => crtc_video_id_code,
		scaler_select => crtc_scaler_select,

		scl_in => scl_in,
		sda_in => sda_in,	
		scl_wen => crtc_scl_wen,
		sda_wen => crtc_sda_wen
	);

hdmiav_inst : entity work.hdmi
port map (
	I_CLK_PIXEL => clk_pixel_in,
	I_RESET => not(reset_n),
	I_AUDIO_PCM_L   => audio_left_reg2,
	I_AUDIO_PCM_R   => audio_right_reg2,
	I_HSYNC		=> hsync_reg,
	I_VSYNC		=> vsync_reg,
	I_BLANK		=> blank_reg,
	I_R		=> red_reg,
	I_G		=> green_reg,
	I_B		=> blue_reg,
	I_VIDEO_ID_CODE => crtc_video_id_code,
	O_R	=> hdmi_encoded_red,
	O_G	=> hdmi_encoded_green,
	O_B	=> hdmi_encoded_blue);
	
dvi_inst: entity work.dvi
port map (
	I_CLK_PIXEL	=> clk_pixel_in,

	I_HSYNC		=> hsync_reg,
	I_VSYNC		=> vsync_reg,
	I_BLANK		=> blank_reg,
	I_RED		=> red_reg,
	I_GREEN		=> green_reg,
	I_BLUE		=> blue_reg,
	O_R	=> dvi_encoded_red,
	O_G	=> dvi_encoded_green,
	O_B	=> dvi_encoded_blue);

process (out_format,dvi_encoded_red,dvi_encoded_green,dvi_encoded_blue,hdmi_encoded_red,hdmi_encoded_green,hdmi_encoded_blue)
begin
	encoded_red_next <= (others=>'0');
	encoded_green_next <= (others=>'0');
	encoded_blue_next <= (others=>'0');

	case out_format is
		when "01" =>
			encoded_red_next   <= dvi_encoded_red;
			encoded_green_next <= dvi_encoded_green;
			encoded_blue_next  <= dvi_encoded_blue;
		when "10" =>
			encoded_red_next   <= hdmi_encoded_red;
			encoded_green_next <= hdmi_encoded_green;
			encoded_blue_next  <= hdmi_encoded_blue;
		when others =>
			encoded_red_next <= (others=>'0');
			encoded_green_next <= (others=>'0');
			encoded_blue_next <= (others=>'0');
	end case;
end process;

process (CLK_HDMI_IN,RESET_N)
begin
	if (RESET_N='0') then
		mod5_reg <= "00001";
		shift_r_reg <= (others=>'0');
		shift_g_reg <= (others=>'0');
		shift_b_reg <= (others=>'0');
		shift_clk_reg <= (others=>'0');
		nshift_r_reg <= (others=>'0');
		nshift_g_reg <= (others=>'0');
		nshift_b_reg <= (others=>'0');
		nshift_clk_reg <= (others=>'0');
	elsif (CLK_HDMI_IN'event and CLK_HDMI_IN = '1') then
		mod5_reg <= mod5_next;
		shift_r_reg <= shift_r_next;
		shift_g_reg <= shift_g_next;
		shift_b_reg <= shift_b_next;
		shift_clk_reg <= shift_clk_next;
		nshift_r_reg <= not(shift_r_next);
		nshift_g_reg <= not(shift_g_next);
		nshift_b_reg <= not(shift_b_next);
		nshift_clk_reg <= not(shift_clk_next);
	end if;
end process;
	
process(encoded_red_reg,encoded_green_reg,encoded_blue_reg,shift_r_reg,shift_g_reg,shift_b_reg,mod5_reg,shift_clk_reg)
begin		
	mod5_next <= mod5_reg(3 downto 0)&mod5_reg(4);

	if mod5_reg(0) = '1' then			
		shift_r_next <= encoded_red_reg;
		shift_g_next <= encoded_green_reg;
		shift_b_next <= encoded_blue_reg;
		shift_clk_next <= "0000011111";
	else
		shift_r_next <= "00" & shift_r_reg(9 downto 2);
		shift_g_next <= "00" & shift_g_reg(9 downto 2);
		shift_b_next <= "00" & shift_b_reg(9 downto 2);
		shift_clk_next <= "00" & shift_clk_reg(9 downto 2);
	end if;		
end process;
	

process(clk_pixel_in)
begin
	if (clk_pixel_in'event and clk_pixel_in='1') then
		audio_left_reg1 <= audio_left_signed;
		audio_left_reg2 <= audio_left_reg1;
		audio_right_reg1 <= audio_right_signed;
		audio_right_reg2 <= audio_right_reg1;

		out_haddr_reg <= out_haddr_next;
		out_vaddr_reg <= out_vaddr_next;
		out_vaddr_in_reg <= out_vaddr_in_next;

		out_pixels_reg <= out_pixels_next;
		out_next_x_reg <= out_next_x;

		out_frame_start_flip_reg <= out_frame_start_flip_next;
		out_line_start_flip_reg <= out_line_start_flip_next;
		
		out_resync_required_reg <= out_resync_required_next;
		
		hsync_reg <= hsync_next;
		vsync_reg <= vsync_next;
		blank_reg <= blank_next;
		red_reg <= red_next;
		green_reg <= green_next;
		blue_reg <= blue_next;

		encoded_blue_reg <= encoded_blue_next;
		encoded_green_reg <= encoded_green_next;
		encoded_red_reg <= encoded_red_next;
	end if;
end process;

process(clk_hdmi_in)
begin
	if (clk_hdmi_in'event and clk_hdmi_in='1') then
		hs_hsync_reg <= hs_hsync_next;
		hs_vsync_reg <= hs_vsync_next;
		hs_blank_reg <= blank_reg;
		hs_red_reg <= red_reg;
		hs_green_reg <= green_reg;
		hs_blue_reg <= blue_reg;
		hs_red_reg2(7 downto 4) <= hs_red_reg(7 downto 4);
		hs_green_reg2(7 downto 4) <= hs_green_reg(7 downto 4);
		hs_blue_reg2(7 downto 4) <= hs_blue_reg(7 downto 4);
	end if;
end process;

process(out_csync,hsync_reg,vsync_reg)
begin
	if (out_csync = '1') then
		hs_hsync_next <= not(hsync_reg xor vsync_reg);
		hs_vsync_next <='1';
	else
		hs_hsync_next <= not(hsync_reg);			
		hs_vsync_next <= not(vsync_reg);
	end if;
end process;

-- VGA outputs - with specified timings
O_hsync <= hs_hsync_reg;
O_vsync <= hs_vsync_reg;
O_blank <= hs_blank_reg;
O_red <= hs_red_reg2(7 downto 4)&hs_red_reg(3 downto 0); -- on different ddr edges
O_green <= hs_green_reg2(7 downto 4)&hs_green_reg(3 downto 0);
O_blue <= hs_blue_reg2(7 downto 4)&hs_blue_reg(3 downto 0);

-- TMDS outputs - with specified timings
O_TMDS_H <= shift_r_reg(0) & nshift_r_reg(0) & shift_g_reg(0) & nshift_g_reg(0) & shift_b_reg(0) & nshift_b_reg(0) & shift_clk_reg(0) & nshift_clk_reg(0);
O_TMDS_L <= shift_r_reg(1) & nshift_r_reg(1) & shift_g_reg(1) & nshift_g_reg(1) & shift_b_reg(1) & nshift_b_reg(1) & shift_clk_reg(1) & nshift_clk_reg(1);

-- I2C outputs
sda_wen <= multiscale_sda_wen or crtc_sda_wen;
scl_wen <= multiscale_scl_wen or crtc_scl_wen;

end vhdl;


