LIBRARY ieee;
USE ieee.std_logic_1164.all;
--USE ieee.std_logic_arith.all;
--USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.all;
use work.pixels.all;

--TODO: scanlines!!
--out_colour(7 downto 4) <= out_colour_raw(7 downto 4);
--out_colour(3 downto 0) <= out_colour_raw(3 downto 0) when (not(out_scanlines) or vcnt(0))='1' else '0'&out_colour_raw(3 downto 1);

ENTITY polyphasicscale IS
  PORT(
    clock   : IN     STD_LOGIC;                             --system clock
    reset_n : IN     STD_LOGIC;                             --asynchronous reset

    -- input pixels
    pixels : in t_Pixel4x4;

    -- next output line
    next_y_in : in std_logic;
    next_frame_in : in std_logic;
    field2 : in std_logic;
    
    -- sync/blank from crtc -> need to be delayed in line with pipeline
    hsync_in : in std_logic;
    vsync_in : in std_logic;
    blank_in : in std_logic; 
	 
    -- need to provide control signals:
    next_x : OUT STD_LOGIC;
	 next_x_size : out std_logic_vector(1 downto 0);
    next_y : OUT STD_LOGIC;	 

    -- need to output
    -- current pixel
    r : out std_logic_vector(7 downto 0);
    g : out std_logic_vector(7 downto 0);
    b : out std_logic_vector(7 downto 0);
    hsync : out std_logic;
    vsync : out std_logic;
    blank : out std_logic;
	 
    -- to set up params
    sda : inout std_logic;
    scl : inout std_logic	 
  );
END polyphasicscale;

-- customscalex:568 customscaley:256 xdelta:640 ydelta:102 TA:65536
ARCHITECTURE vhdl OF polyphasicscale IS
	signal param_xthreshold_next : unsigned(10 downto 0);
	signal param_xthreshold_reg : unsigned(10 downto 0);
	signal param_ythreshold_next : unsigned(10 downto 0);
	signal param_ythreshold_reg : unsigned(10 downto 0);
	signal param_xdelta_next : unsigned(10 downto 0);
	signal param_xdelta_reg : unsigned(10 downto 0);
	signal param_ydeltaeach_next : unsigned(10 downto 0);
	signal param_ydeltaeach_reg : unsigned(10 downto 0);	
	signal param_xaddrskip_next : unsigned(1 downto 0); -- We only support upscaling, so for some cases need to skip 2 pixels
	signal param_xaddrskip_reg : unsigned(1 downto 0);
	
	-- stage 1:5 Delay syncs in line with pipeline
	signal hsync_next : std_logic_vector(6 downto 1);
	signal hsync_reg : std_logic_vector(6 downto 1);
	signal vsync_next : std_logic_vector(6 downto 1);
	signal vsync_reg : std_logic_vector(6 downto 1);
	signal blank_next : std_logic_vector(6 downto 1);
	signal blank_reg : std_logic_vector(6 downto 1);
	
	-- stage 1 : Accumulators/ data request
	signal xacc_next : unsigned(11 downto 0);
	signal xacc_reg : unsigned(11 downto 0);
	signal yacc_next : unsigned(11 downto 0);
	signal yacc_reg : unsigned(11 downto 0);
	signal next_x_delay1_next : std_logic;
	signal next_x_delay1_reg : std_logic;	
	
	-- stage 2 : Coefs calc
	type t_Coef is record
		 c1  : signed(8 downto 0);
		 c2  : signed(8 downto 0);
		 c3  : signed(8 downto 0);
		 c4  : signed(8 downto 0);
	end record t_Coef;  	
	
	signal coefx_next: t_Coef;
	signal coefx_reg : t_Coef;
	signal coefx3_next: t_Coef;
	signal coefx3_reg : t_Coef;	
	signal coefx4_next: t_Coef;
	signal coefx4_reg : t_Coef;		
	signal coefy_next: t_Coef;
	signal coefy_reg : t_Coef;
	signal next_x_delay2_next : std_logic;
	signal next_x_delay2_reg : std_logic;		

	-- stage 3 : Y mult
	signal ry1_next : signed(17 downto 0);
	signal ry1_reg : signed(17 downto 0);
	signal ry2_next : signed(17 downto 0);
	signal ry2_reg : signed(17 downto 0);
	signal ry3_next : signed(17 downto 0);
	signal ry3_reg : signed(17 downto 0);
	signal ry4_next : signed(17 downto 0);
	signal ry4_reg : signed(17 downto 0);

	signal gy1_next : signed(17 downto 0);
	signal gy1_reg : signed(17 downto 0);
	signal gy2_next : signed(17 downto 0);
	signal gy2_reg : signed(17 downto 0);
	signal gy3_next : signed(17 downto 0);
	signal gy3_reg : signed(17 downto 0);
	signal gy4_next : signed(17 downto 0);
	signal gy4_reg : signed(17 downto 0);

	signal by1_next : signed(17 downto 0);
	signal by1_reg : signed(17 downto 0);
	signal by2_next : signed(17 downto 0);
	signal by2_reg : signed(17 downto 0);
	signal by3_next : signed(17 downto 0);
	signal by3_reg : signed(17 downto 0);
	signal by4_next : signed(17 downto 0);
	signal by4_reg : signed(17 downto 0);
	signal next_x_delay3_next : std_logic;
	signal next_x_delay3_reg : std_logic;	

	-- stage 4: X pixels
	signal pixel_rx1_next : signed(8 downto 0);
	signal pixel_rx1_reg : signed(8 downto 0);
	signal pixel_rx2_next : signed(8 downto 0);
	signal pixel_rx2_reg : signed(8 downto 0);
	signal pixel_rx3_next : signed(8 downto 0);
	signal pixel_rx3_reg : signed(8 downto 0);
	signal pixel_rx4_next : signed(8 downto 0);
	signal pixel_rx4_reg : signed(8 downto 0);

	signal pixel_gx1_next : signed(8 downto 0);
	signal pixel_gx1_reg : signed(8 downto 0);
	signal pixel_gx2_next : signed(8 downto 0);
	signal pixel_gx2_reg : signed(8 downto 0);
	signal pixel_gx3_next : signed(8 downto 0);
	signal pixel_gx3_reg : signed(8 downto 0);
	signal pixel_gx4_next : signed(8 downto 0);
	signal pixel_gx4_reg : signed(8 downto 0);

	signal pixel_bx1_next : signed(8 downto 0);
	signal pixel_bx1_reg : signed(8 downto 0);
	signal pixel_bx2_next : signed(8 downto 0);
	signal pixel_bx2_reg : signed(8 downto 0);
	signal pixel_bx3_next : signed(8 downto 0);
	signal pixel_bx3_reg : signed(8 downto 0);
	signal pixel_bx4_next : signed(8 downto 0);
	signal pixel_bx4_reg : signed(8 downto 0);

	-- stage 5: X mult
	signal rx1_next : signed(17 downto 0);
	signal rx1_reg : signed(17 downto 0);
	signal rx2_next : signed(17 downto 0);
	signal rx2_reg : signed(17 downto 0);
	signal rx3_next : signed(17 downto 0);
	signal rx3_reg : signed(17 downto 0);
	signal rx4_next : signed(17 downto 0);
	signal rx4_reg : signed(17 downto 0);

	signal gx1_next : signed(17 downto 0);
	signal gx1_reg : signed(17 downto 0);
	signal gx2_next : signed(17 downto 0);
	signal gx2_reg : signed(17 downto 0);
	signal gx3_next : signed(17 downto 0);
	signal gx3_reg : signed(17 downto 0);
	signal gx4_next : signed(17 downto 0);
	signal gx4_reg : signed(17 downto 0);

	signal bx1_next : signed(17 downto 0);
	signal bx1_reg : signed(17 downto 0);
	signal bx2_next : signed(17 downto 0);
	signal bx2_reg : signed(17 downto 0);
	signal bx3_next : signed(17 downto 0);
	signal bx3_reg : signed(17 downto 0);
	signal bx4_next : signed(17 downto 0);
	signal bx4_reg : signed(17 downto 0);

	-- stage 6: Pixel output (sum)
	signal r_reg : std_logic_vector(7 downto 0);
	signal r_next : std_logic_vector(7 downto 0);
	signal g_reg : std_logic_vector(7 downto 0);
	signal g_next : std_logic_vector(7 downto 0);
	signal b_reg : std_logic_vector(7 downto 0);
	signal b_next : std_logic_vector(7 downto 0);

BEGIN
	process(clock,reset_n)
	begin
		if (reset_n='0') then
			param_xthreshold_reg <= (others=>'0');
			param_ythreshold_reg <= (others=>'0');
			param_xdelta_reg <= (others=>'0');
			param_ydeltaeach_reg <= (others=>'0');
			param_xaddrskip_reg <= "01";
			
			-- multi stage 1-5
			hsync_reg <= (others=>'0');
			vsync_reg <= (others=>'0');
			blank_reg <= (others=>'0');

			-- stage 1
			xacc_reg <= (others=>'0');
			yacc_reg <= (others=>'0');
			next_x_delay1_reg <= '0';

			-- stage 2
			coefx_reg.c1 <= (others=>'0');
			coefx_reg.c2 <= (others=>'0');
			coefx_reg.c3 <= (others=>'0');
			coefx_reg.c4 <= (others=>'0');
			coefy_reg.c1 <= (others=>'0');
			coefy_reg.c2 <= (others=>'0');
			coefy_reg.c3 <= (others=>'0');
			coefy_reg.c4 <= (others=>'0');
			next_x_delay2_reg <= '0';

			-- stage 3
			ry1_reg <= (others=>'0');
			ry2_reg <= (others=>'0');
			ry3_reg <= (others=>'0');
			ry4_reg <= (others=>'0');

			gy1_reg <= (others=>'0');
			gy2_reg <= (others=>'0');
			gy3_reg <= (others=>'0');
			gy4_reg <= (others=>'0');

			by1_reg <= (others=>'0');
			by2_reg <= (others=>'0');
			by3_reg <= (others=>'0');
			by4_reg <= (others=>'0');
			
			coefx3_reg.c1 <= (others=>'0');
			coefx3_reg.c2 <= (others=>'0');
			coefx3_reg.c3 <= (others=>'0');
			coefx3_reg.c4 <= (others=>'0');	
			next_x_delay3_reg <= '0';

			-- stage 4
			pixel_rx1_reg <= (others=>'0');
			pixel_gx1_reg <= (others=>'0');
			pixel_bx1_reg <= (others=>'0');

			pixel_rx2_reg <= (others=>'0');
			pixel_gx2_reg <= (others=>'0');
			pixel_bx2_reg <= (others=>'0');

			pixel_rx3_reg <= (others=>'0');
			pixel_gx3_reg <= (others=>'0');
			pixel_bx3_reg <= (others=>'0');

			pixel_rx4_reg <= (others=>'0');
			pixel_gx4_reg <= (others=>'0');
			pixel_bx4_reg <= (others=>'0');		
	
			coefx4_reg.c1 <= (others=>'0');
			coefx4_reg.c2 <= (others=>'0');
			coefx4_reg.c3 <= (others=>'0');
			coefx4_reg.c4 <= (others=>'0');	

			-- stage 5
			rx1_reg <= (others=>'0');
			rx2_reg <= (others=>'0');
			rx3_reg <= (others=>'0');
			rx4_reg <= (others=>'0');

			gx1_reg <= (others=>'0');
			gx2_reg <= (others=>'0');
			gx3_reg <= (others=>'0');
			gx4_reg <= (others=>'0');

			bx1_reg <= (others=>'0');
			bx2_reg <= (others=>'0');
			bx3_reg <= (others=>'0');
			bx4_reg <= (others=>'0');

			-- stage 6
			r_reg <= (others=>'0');
			g_reg <= (others=>'0');
			b_reg <= (others=>'0');
		elsif (clock'event and clock='1') then
			param_xthreshold_reg <= param_xthreshold_next;
			param_xdelta_reg <= param_xdelta_next;
			param_ythreshold_reg <= param_ythreshold_next;
			param_ydeltaeach_reg <= param_ydeltaeach_next;
			param_xaddrskip_reg <= param_xaddrskip_next;

			-- multi stage 1-5
			hsync_reg <= hsync_next;
			vsync_reg <= vsync_next;
			blank_reg <= blank_next;			
			
			-- stage 1
			xacc_reg <= xacc_next;
			yacc_reg <= yacc_next;
			next_x_delay1_reg <= next_x_delay1_next;

			-- stage 2
			coefx_reg <= coefx_next;
			coefy_reg <= coefy_next;
			next_x_delay2_reg <= next_x_delay2_next;

			-- stage 3
			ry1_reg <= ry1_next;
			ry2_reg <= ry2_next;
			ry3_reg <= ry3_next;
			ry4_reg <= ry4_next;

			gy1_reg <= gy1_next;
			gy2_reg <= gy2_next;
			gy3_reg <= gy3_next;
			gy4_reg <= gy4_next;

			by1_reg <= by1_next;
			by2_reg <= by2_next;
			by3_reg <= by3_next;
			by4_reg <= by4_next;
			
			coefx3_reg <= coefx3_next;			
			next_x_delay3_reg <= next_x_delay3_next;

			-- stage 4
			pixel_rx1_reg <= pixel_rx1_next;
			pixel_gx1_reg <= pixel_gx1_next;
			pixel_bx1_reg <= pixel_bx1_next;

			pixel_rx2_reg <= pixel_rx2_next;
			pixel_gx2_reg <= pixel_gx2_next;
			pixel_bx2_reg <= pixel_bx2_next;

			pixel_rx3_reg <= pixel_rx3_next;
			pixel_gx3_reg <= pixel_gx3_next;
			pixel_bx3_reg <= pixel_bx3_next;

			pixel_rx4_reg <= pixel_rx4_next;
			pixel_gx4_reg <= pixel_gx4_next;
			pixel_bx4_reg <= pixel_bx4_next;
			
			coefx4_reg <= coefx4_next;		

			-- stage 5
			rx1_reg <= rx1_next;
			rx2_reg <= rx2_next;
			rx3_reg <= rx3_next;
			rx4_reg <= rx4_next;

			gx1_reg <= gx1_next;
			gx2_reg <= gx2_next;
			gx3_reg <= gx3_next;
			gx4_reg <= gx4_next;

			bx1_reg <= bx1_next;
			bx2_reg <= bx2_next;
			bx3_reg <= bx3_next;
			bx4_reg <= bx4_next;

			-- stage 6
			r_reg <= r_next;
			g_reg <= g_next;
			b_reg <= b_next;
		end if;
	end process;
	
	-- temporary params, until i2c implemented
	-- 720p
--	param_xthreshold_next <= to_unsigned(699,10); -- these need to be inputs
--	param_xdelta_next <= to_unsigned(393,10);
--	param_ythreshold_next <= to_unsigned(400,9);
--	param_ydelta_next <= to_unsigned(166,9);
-- param_ydeltaeach_next <= to_unsigned(166,9);
--	param_xaddrskip_next <= "10";

	-- 1080i
--	param_xthreshold_next <= to_unsigned(400,11); -- these need to be inputs
--	param_xdelta_next <= to_unsigned(300,11);
--	param_ythreshold_next <= to_unsigned(786,11);
--	param_ydelta_next <= to_unsigned(218,11);
--	param_ydeltaeach_next <= to_unsigned(437,11); --interlace, need to skip a line
--	param_xaddrskip_next <= "01";


	param_xthreshold_next <= to_unsigned(1024,11); -- these need to be inputs
	param_xdelta_next <= to_unsigned(768,11);
	--param_xdelta_next <= to_unsigned(64,11);
	param_ythreshold_next <= to_unsigned(1024,11);
	--param_ydelta_next <= to_unsigned(284,11);
	param_ydeltaeach_next <= to_unsigned(569,11); --interlace, need to skip a line
	param_xaddrskip_next <= "01";
	
--  Delay sync in line with pipeline: multi stage 1-5
   process(hsync_reg,vsync_reg,blank_reg,hsync_in,vsync_in,blank_in)
	begin		
		hsync_next <= hsync_reg(5 downto 1)&hsync_in;
		vsync_next <= vsync_reg(5 downto 1)&vsync_in;
		blank_next <= blank_reg(5 downto 1)&blank_in;
	end process;

-- 	Compute accumulator - pipeline stage 1
	process(xacc_reg,param_xdelta_reg,param_xthreshold_reg,next_y_in)
	begin
		next_x <= '0';
		next_x_delay1_next <= '0';
		xacc_next <= xacc_reg+param_xdelta_reg;
		if ((xacc_reg+param_xdelta_reg)>=param_xthreshold_reg) then
			next_x <= '1'; -- when I ask for data, its on p1 in 2 cycles, i.e. pipeline stage 3
			next_x_delay1_next <= '1';
			xacc_next <= xacc_reg+param_xdelta_reg-param_xthreshold_reg;
		end if;

		if (next_y_in ='1') then 
			xacc_next <= (others=>'0');
		end if;
	end process;

	process(yacc_reg,param_ydeltaeach_reg,param_ythreshold_reg,next_y_in,next_frame_in,field2)
	begin
		yacc_next <= yacc_reg;
		next_y <= '0';

		if (next_y_in='1') then
			yacc_next <= yacc_reg+param_ydeltaeach_reg; 
			if ((yacc_reg+param_ydeltaeach_reg)>=param_ythreshold_reg) then
				next_y <= '1';
				yacc_next <= yacc_reg+param_ydeltaeach_reg-param_ythreshold_reg;
			end if;
		end if;

		if (next_frame_in='1') then
			yacc_next <= (others=>'0');
			if (field2='1') then --slightly lower on interlace field 2
				yacc_next(9 downto 0) <= param_ythreshold_reg(10 downto 1);
			end if;
		end if;
	end process;

--      Coef computation - pipeline stage 2
	process(
		xacc_reg,
		yacc_reg)
	variable xphase : std_logic_vector(3 downto 0);
	variable yphase : std_logic_vector(3 downto 0);
	begin
		coefx_next.c1 <= (others=>'0');
		coefx_next.c2 <= (others=>'0');
		coefx_next.c3 <= (others=>'0');
		coefx_next.c4 <= (others=>'0');
		coefy_next.c1 <= (others=>'0');
		coefy_next.c2 <= (others=>'0');
		coefy_next.c3 <= (others=>'0');
		coefy_next.c4 <= (others=>'0');

		xphase := std_logic_vector(xacc_reg(9 downto 6));
		yphase := std_logic_vector(yacc_reg(9 downto 6));

--		case xphase is
--		when "0000" =>
--			coefx_next <= x"7f000000";
--		when "0001" =>
--			coefx_next <= x"7f000000";
--		when "0010" =>
--			coefx_next <= x"7f000000";
--		when "0011" =>
--			coefx_next <= x"7f000000";
--		when "0100" =>
--			coefx_next <= x"7f000000";
--		when "0101" =>
--			coefx_next <= x"7f000000";
--		when "0110" =>
--			coefx_next <= x"7f000000";
--		when "0111" =>
--			coefx_next <= x"7f000000";
--		when "1000" =>
--		        coefx_next <= x"7f000000";
--		when "1001" =>
--		        coefx_next <= x"7f000000";
--		when "1010" =>
--		        coefx_next <= x"7f000000";
--		when "1011" =>
--		        coefx_next <= x"7f000000";
--		when "1100" =>
--		        coefx_next <= x"7f000000";
--		when "1101" =>
--		        coefx_next <= x"7f000000";
--		when "1110" =>
--		        coefx_next <= x"7f000000";
--		when "1111" =>
--			coefx_next <= x"7f000000";
--		when others=>
--			coefx_next <= (others=>'0');
--		end case;
--
--		case yphase is
--		when "0000" =>
--			coefy_next <= x"7f000000";
--		when "0001" =>
--			coefy_next <= x"7f000000";
--		when "0010" =>
--			coefy_next <= x"7f000000";
--		when "0011" =>
--			coefy_next <= x"7f000000";
--		when "0100" =>
--			coefy_next <= x"7f000000";
--		when "0101" =>
--			coefy_next <= x"7f000000";
--		when "0110" =>
--			coefy_next <= x"7f000000";
--		when "0111" =>
--			coefy_next <= x"7f000000";
--		when "1000" =>
--		        coefy_next <= x"7f000000";
--		when "1001" =>
--		        coefy_next <= x"7f000000";
--		when "1010" =>
--		        coefy_next <= x"7f000000";
--		when "1011" =>
--		        coefy_next <= x"7f000000";
--		when "1100" =>
--		        coefy_next <= x"7f000000";
--		when "1101" =>
--		        coefy_next <= x"7f000000";
--		when "1110" =>
--		        coefy_next <= x"7f000000";
--		when "1111" =>
--			coefy_next <= x"7f000000";
--		when others=>
--			coefy_next <= (others=>'0');
--		end case;
case xphase is 
when "0000" =>
	coefx_next.c1 <= to_signed(-8,9);
	coefx_next.c2 <= to_signed(147,9);
	coefx_next.c3 <= to_signed(-8,9);
	coefx_next.c4 <= to_signed(1,9);
when "0001" =>
	coefx_next.c1 <= to_signed(-6,9);
	coefx_next.c2 <= to_signed(148,9);
	coefx_next.c3 <= to_signed(-11,9);
	coefx_next.c4 <= to_signed(1,9);
when "0010" =>
	coefx_next.c1 <= to_signed(-3,9);
	coefx_next.c2 <= to_signed(147,9);
	coefx_next.c3 <= to_signed(-13,9);
	coefx_next.c4 <= to_signed(1,9);
when "0011" =>
	coefx_next.c1 <= to_signed(-1,9);
	coefx_next.c2 <= to_signed(145,9);
	coefx_next.c3 <= to_signed(-13,9);
	coefx_next.c4 <= to_signed(1,9);
when "0100" =>
	coefx_next.c1 <= to_signed(0,9);
	coefx_next.c2 <= to_signed(141,9);
	coefx_next.c3 <= to_signed(-10,9);
	coefx_next.c4 <= to_signed(1,9);
when "0101" =>
	coefx_next.c1 <= to_signed(1,9);
	coefx_next.c2 <= to_signed(133,9);
	coefx_next.c3 <= to_signed(-3,9);
	coefx_next.c4 <= to_signed(1,9);
when "0110" =>
	coefx_next.c1 <= to_signed(1,9);
	coefx_next.c2 <= to_signed(118,9);
	coefx_next.c3 <= to_signed(12,9);
	coefx_next.c4 <= to_signed(1,9);
when "0111" =>
	coefx_next.c1 <= to_signed(1,9);
	coefx_next.c2 <= to_signed(95,9);
	coefx_next.c3 <= to_signed(35,9);
	coefx_next.c4 <= to_signed(1,9);
when "1000" =>
	coefx_next.c1 <= to_signed(1,9);
	coefx_next.c2 <= to_signed(65,9);
	coefx_next.c3 <= to_signed(65,9);
	coefx_next.c4 <= to_signed(1,9);
when "1001" =>
	coefx_next.c1 <= to_signed(1,9);
	coefx_next.c2 <= to_signed(35,9);
	coefx_next.c3 <= to_signed(95,9);
	coefx_next.c4 <= to_signed(1,9);
when "1010" =>
	coefx_next.c1 <= to_signed(1,9);
	coefx_next.c2 <= to_signed(12,9);
	coefx_next.c3 <= to_signed(118,9);
	coefx_next.c4 <= to_signed(1,9);
when "1011" =>
	coefx_next.c1 <= to_signed(1,9);
	coefx_next.c2 <= to_signed(-3,9);
	coefx_next.c3 <= to_signed(133,9);
	coefx_next.c4 <= to_signed(1,9);
when "1100" =>
	coefx_next.c1 <= to_signed(1,9);
	coefx_next.c2 <= to_signed(-10,9);
	coefx_next.c3 <= to_signed(141,9);
	coefx_next.c4 <= to_signed(0,9);
when "1101" =>
	coefx_next.c1 <= to_signed(1,9);
	coefx_next.c2 <= to_signed(-13,9);
	coefx_next.c3 <= to_signed(145,9);
	coefx_next.c4 <= to_signed(-1,9);
when "1110" =>
	coefx_next.c1 <= to_signed(1,9);
	coefx_next.c2 <= to_signed(-13,9);
	coefx_next.c3 <= to_signed(147,9);
	coefx_next.c4 <= to_signed(-3,9);
when "1111" =>
	coefx_next.c1 <= to_signed(1,9);
	coefx_next.c2 <= to_signed(-11,9);
	coefx_next.c3 <= to_signed(148,9);
	coefx_next.c4 <= to_signed(-6,9);
when others => 
	coefx_next.c1 <= (others=>'0');
	coefx_next.c2 <= (others=>'0');
	coefx_next.c3 <= (others=>'0');
	coefx_next.c4 <= (others=>'0');
end case;
case yphase is 
when "0000" =>
	coefy_next.c1 <= to_signed(-8,9);
	coefy_next.c2 <= to_signed(147,9);
	coefy_next.c3 <= to_signed(-8,9);
	coefy_next.c4 <= to_signed(1,9);
when "0001" =>
	coefy_next.c1 <= to_signed(-6,9);
	coefy_next.c2 <= to_signed(148,9);
	coefy_next.c3 <= to_signed(-11,9);
	coefy_next.c4 <= to_signed(1,9);
when "0010" =>
	coefy_next.c1 <= to_signed(-3,9);
	coefy_next.c2 <= to_signed(147,9);
	coefy_next.c3 <= to_signed(-13,9);
	coefy_next.c4 <= to_signed(1,9);
when "0011" =>
	coefy_next.c1 <= to_signed(-1,9);
	coefy_next.c2 <= to_signed(145,9);
	coefy_next.c3 <= to_signed(-13,9);
	coefy_next.c4 <= to_signed(1,9);
when "0100" =>
	coefy_next.c1 <= to_signed(0,9);
	coefy_next.c2 <= to_signed(141,9);
	coefy_next.c3 <= to_signed(-10,9);
	coefy_next.c4 <= to_signed(1,9);
when "0101" =>
	coefy_next.c1 <= to_signed(1,9);
	coefy_next.c2 <= to_signed(133,9);
	coefy_next.c3 <= to_signed(-3,9);
	coefy_next.c4 <= to_signed(1,9);
when "0110" =>
	coefy_next.c1 <= to_signed(1,9);
	coefy_next.c2 <= to_signed(118,9);
	coefy_next.c3 <= to_signed(12,9);
	coefy_next.c4 <= to_signed(1,9);
when "0111" =>
	coefy_next.c1 <= to_signed(1,9);
	coefy_next.c2 <= to_signed(95,9);
	coefy_next.c3 <= to_signed(35,9);
	coefy_next.c4 <= to_signed(1,9);
when "1000" =>
	coefy_next.c1 <= to_signed(1,9);
	coefy_next.c2 <= to_signed(65,9);
	coefy_next.c3 <= to_signed(65,9);
	coefy_next.c4 <= to_signed(1,9);
when "1001" =>
	coefy_next.c1 <= to_signed(1,9);
	coefy_next.c2 <= to_signed(35,9);
	coefy_next.c3 <= to_signed(95,9);
	coefy_next.c4 <= to_signed(1,9);
when "1010" =>
	coefy_next.c1 <= to_signed(1,9);
	coefy_next.c2 <= to_signed(12,9);
	coefy_next.c3 <= to_signed(118,9);
	coefy_next.c4 <= to_signed(1,9);
when "1011" =>
	coefy_next.c1 <= to_signed(1,9);
	coefy_next.c2 <= to_signed(-3,9);
	coefy_next.c3 <= to_signed(133,9);
	coefy_next.c4 <= to_signed(1,9);
when "1100" =>
	coefy_next.c1 <= to_signed(1,9);
	coefy_next.c2 <= to_signed(-10,9);
	coefy_next.c3 <= to_signed(141,9);
	coefy_next.c4 <= to_signed(0,9);
when "1101" =>
	coefy_next.c1 <= to_signed(1,9);
	coefy_next.c2 <= to_signed(-13,9);
	coefy_next.c3 <= to_signed(145,9);
	coefy_next.c4 <= to_signed(-1,9);
when "1110" =>
	coefy_next.c1 <= to_signed(1,9);
	coefy_next.c2 <= to_signed(-13,9);
	coefy_next.c3 <= to_signed(147,9);
	coefy_next.c4 <= to_signed(-3,9);
when "1111" =>
	coefy_next.c1 <= to_signed(1,9);
	coefy_next.c2 <= to_signed(-11,9);
	coefy_next.c3 <= to_signed(148,9);
	coefy_next.c4 <= to_signed(-6,9);
when others => 
	coefy_next.c1 <= (others=>'0');
	coefy_next.c2 <= (others=>'0');
	coefy_next.c3 <= (others=>'0');
	coefy_next.c4 <= (others=>'0');
end case;


	end process;

	next_x_delay2_next <= next_x_delay1_reg;
	
--      YMult - pipeline stage 3
	process(pixels, coefy_reg)
		variable p1 : t_pixel;
		variable p2 : t_pixel;
		variable p3 : t_pixel;
		variable p4 : t_pixel;
	begin
		p1 := pixels(pixel4x4_idx(0,0));
		p2 := pixels(pixel4x4_idx(0,1));
		p3 := pixels(pixel4x4_idx(0,2));
		p4 := pixels(pixel4x4_idx(0,3));

		-- dsp blocks 9x9 multipliers
		-- 3 per block -> 4 blocks
		ry1_next <= signed('0'&p1.red)*coefy_reg.c1;
		ry2_next <= signed('0'&p2.red)*coefy_reg.c2;
		ry3_next <= signed('0'&p3.red)*coefy_reg.c3;
		ry4_next <= signed('0'&p4.red)*coefy_reg.c4;

		gy1_next <= signed('0'&p1.green)*coefy_reg.c1;
		gy2_next <= signed('0'&p2.green)*coefy_reg.c2;
		gy3_next <= signed('0'&p3.green)*coefy_reg.c3;
		gy4_next <= signed('0'&p4.green)*coefy_reg.c4;

		by1_next <= signed('0'&p1.blue)*coefy_reg.c1;
		by2_next <= signed('0'&p2.blue)*coefy_reg.c2;
		by3_next <= signed('0'&p3.blue)*coefy_reg.c3;
		by4_next <= signed('0'&p4.blue)*coefy_reg.c4;
	end process;
	
	next_x_delay3_next <= next_x_delay2_reg;
	coefx3_next <= coefx_reg;

--      X pixels - pipeline stage 4
	process(
		pixel_rx1_reg,pixel_rx2_reg,pixel_rx3_reg,pixel_rx4_reg,
		pixel_gx1_reg,pixel_gx2_reg,pixel_gx3_reg,pixel_gx4_reg,
		pixel_bx1_reg,pixel_bx2_reg,pixel_bx3_reg,pixel_bx4_reg,
		ry1_reg,ry2_reg,ry3_reg,ry4_reg,
		gy1_reg,gy2_reg,gy3_reg,gy4_reg,
		by1_reg,by2_reg,by3_reg,by4_reg,
		next_x_delay3_reg
		)
		variable ry_sum : signed (17 downto 0);
		variable gy_sum : signed (17 downto 0);
		variable by_sum : signed (17 downto 0);
	begin
		pixel_rx1_next <= pixel_rx1_reg;
		pixel_rx2_next <= pixel_rx2_reg;
		pixel_rx3_next <= pixel_rx3_reg;
		pixel_rx4_next <= pixel_rx4_reg;

		pixel_gx1_next <= pixel_gx1_reg;
		pixel_gx2_next <= pixel_gx2_reg;
		pixel_gx3_next <= pixel_gx3_reg;
		pixel_gx4_next <= pixel_gx4_reg;

		pixel_bx1_next <= pixel_bx1_reg;
		pixel_bx2_next <= pixel_bx2_reg;
		pixel_bx3_next <= pixel_bx3_reg;
		pixel_bx4_next <= pixel_bx4_reg;

		if (next_x_delay3_reg='1') then
--		   ry_sum := ry1_reg+ry2_reg+ry3_reg+ry4_reg;			
--			pixel_rx1_next <= ry_sum(17)&ry_sum(15 downto 8); 
--			pixel_rx2_next <= pixel_rx1_reg;
--			pixel_rx3_next <= pixel_rx2_reg;
--			pixel_rx4_next <= pixel_rx3_reg;
--
--			gy_sum := gy1_reg+gy2_reg+gy3_reg+gy4_reg;
--			pixel_gx1_next <= gy_sum(17)&gy_sum(15 downto 8);
--			pixel_gx2_next <= pixel_gx1_reg;
--			pixel_gx3_next <= pixel_gx2_reg;
--			pixel_gx4_next <= pixel_gx3_reg;
--
--			by_sum := by1_reg+by2_reg+by3_reg+by4_reg;
--			pixel_bx1_next <= by_sum(17)&by_sum(15 downto 8);
--			pixel_bx2_next <= pixel_bx1_reg;
--			pixel_bx3_next <= pixel_bx2_reg;
--			pixel_bx4_next <= pixel_bx3_reg;
			
		   ry_sum := ry1_reg+ry2_reg+ry3_reg+ry4_reg;			
			pixel_rx4_next <= ry_sum(17)&ry_sum(15 downto 8); 
			pixel_rx3_next <= pixel_rx4_reg;
			pixel_rx2_next <= pixel_rx3_reg;
			pixel_rx1_next <= pixel_rx2_reg;

			gy_sum := gy1_reg+gy2_reg+gy3_reg+gy4_reg;
			pixel_gx4_next <= gy_sum(17)&gy_sum(15 downto 8);
			pixel_gx3_next <= pixel_gx4_reg;
			pixel_gx2_next <= pixel_gx3_reg;
			pixel_gx1_next <= pixel_gx2_reg;

			by_sum := by1_reg+by2_reg+by3_reg+by4_reg;
			pixel_bx4_next <= by_sum(17)&by_sum(15 downto 8);
			pixel_bx3_next <= pixel_bx4_reg;
			pixel_bx2_next <= pixel_bx3_reg;
			pixel_bx1_next <= pixel_bx2_reg;			
		end if;
	end process;
	
	coefx4_next <= coefx3_reg;	

--      X mult - pipeline stage 5
	process(
		pixel_rx1_reg,pixel_rx2_reg,pixel_rx3_reg,pixel_rx4_reg,
		pixel_gx1_reg,pixel_gx2_reg,pixel_gx3_reg,pixel_gx4_reg,
		pixel_bx1_reg,pixel_bx2_reg,pixel_bx3_reg,pixel_bx4_reg,
	       	coefx4_reg)
	begin
		-- dsp blocks 9x9 multipliers
		-- 3 per block -> 4 blocks
		rx1_next <= pixel_rx1_reg*coefx4_reg.c1;
		rx2_next <= pixel_rx2_reg*coefx4_reg.c2;
		rx3_next <= pixel_rx3_reg*coefx4_reg.c3;
		rx4_next <= pixel_rx4_reg*coefx4_reg.c4;

		gx1_next <= pixel_gx1_reg*coefx4_reg.c1;
		gx2_next <= pixel_gx2_reg*coefx4_reg.c2;
		gx3_next <= pixel_gx3_reg*coefx4_reg.c3;
		gx4_next <= pixel_gx4_reg*coefx4_reg.c4;

		bx1_next <= pixel_bx1_reg*coefx4_reg.c1;
		bx2_next <= pixel_bx2_reg*coefx4_reg.c2;
		bx3_next <= pixel_bx3_reg*coefx4_reg.c3;
		bx4_next <= pixel_bx4_reg*coefx4_reg.c4;
	end process;


--      Pixel scaling computation - pipeline stage 6
	-- Compute output
	-- (p1*A1 + p2*A2 + p3*A3 + p4*A4)/65536
	process(
		rx1_reg,rx2_reg,rx3_reg,rx4_reg,
		gx1_reg,gx2_reg,gx3_reg,gx4_reg,
		bx1_reg,bx2_reg,bx3_reg,bx4_reg)
		variable sum_r : signed(17 downto 0);
		variable sum_g : signed(17 downto 0);
		variable sum_b : signed(17 downto 0);
	begin
		sum_r := (rx1_reg+rx2_reg)+(rx3_reg+rx4_reg);
		sum_g := (gx1_reg+gx2_reg)+(gx3_reg+gx4_reg);
		sum_b := (bx1_reg+bx2_reg)+(bx3_reg+bx4_reg);

		if (sum_r(17)='1') then
			sum_r := (others=>'0');
		elsif (sum_r(15) or sum_r(14))='1' then
			sum_r := to_signed(16383,18);
		end if;
		if (sum_g(17)='1') then
			sum_g := (others=>'0');
		elsif (sum_g(15) or sum_g(14))='1' then
			sum_g := to_signed(16383,18);
		end if;
		if (sum_b(17)='1') then
			sum_b := (others=>'0');
		elsif (sum_b(15) or sum_b(14))='1' then
			sum_b := to_signed(16383,18);
		end if;
		r_next <= std_logic_vector(sum_r(13 downto 6));
		g_next <= std_logic_vector(sum_g(13 downto 6));
		b_next <= std_logic_vector(sum_b(13 downto 6));
	end process;

	-- outputnext_x_size
	r<=r_reg;
	g<=g_reg;
	b<=b_reg;
	hsync<=hsync_reg(6); -- TODO: why 6 and not 5?
	vsync<=vsync_reg(6);
	blank<=blank_reg(6); 
	
	next_x_size <= std_logic_vector(param_xaddrskip_reg);

END vhdl;

--              h_pixels_across  <= 720 - 1;
--              h_sync_on <= 732 - 1;
--              h_sync_off <= 795 - 1;
--              h_end_count <= 864 - 1;
--              v_pixels_down <= 576 - 1;
--              v_sync_on <=  581 - 1;
--              v_sync_off <= 586 - 1;
--              v_end_count <=  625 - 1;

--                --PAL
--                h_pixels_across  <= 1280 - 1;
--                h_sync_on <= 1720 - 1;
--                h_sync_off <= 1760 - 1;
--                h_end_count <= 1980 - 1;
--                v_pixels_down <= 720 - 1;
--                v_sync_on <=  725 - 1;
--                v_sync_off <= 730 - 1;
--                v_end_count <=  750 - 1;



