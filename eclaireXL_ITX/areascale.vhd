LIBRARY ieee;
USE ieee.std_logic_1164.all;
--USE ieee.std_logic_arith.all;
--USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.all;
use work.pixels.all;

--TODO: scanlines!!
--out_colour(7 downto 4) <= out_colour_raw(7 downto 4);
--out_colour(3 downto 0) <= out_colour_raw(3 downto 0) when (not(out_scanlines) or vcnt(0))='1' else '0'&out_colour_raw(3 downto 1);

ENTITY areascale IS
  PORT(
    clock   : IN     STD_LOGIC;                             --system clock
    reset_n : IN     STD_LOGIC;                             --asynchronous reset

    -- need to know:
    -- block of 4 pixels (x,y:x+1,y:x,y+1:x+1,y+1)
    -- relative scale ratios
    --p1 : in std_logic_vector(23 downto 0); --RGB
    --p2 : in std_logic_vector(23 downto 0); --RGB
    --p3 : in std_logic_vector(23 downto 0); --RGB
    --p4 : in std_logic_vector(23 downto 0); --RGB
	 
	 pixels : in t_Pixel2x2;

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
END areascale;

-- customscalex:568 customscaley:256 xdelta:640 ydelta:102 TA:65536
ARCHITECTURE vhdl OF areascale IS
	signal param_xthreshold_next : unsigned(10 downto 0);
	signal param_xthreshold_reg : unsigned(10 downto 0);
	signal param_ythreshold_next : unsigned(10 downto 0);
	signal param_ythreshold_reg : unsigned(10 downto 0);
	signal param_xdelta_next : unsigned(10 downto 0);
	signal param_xdelta_reg : unsigned(10 downto 0);
	signal param_ydelta_next : unsigned(10 downto 0);
	signal param_ydelta_reg : unsigned(10 downto 0);
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
	
	-- stage 2 : Area calc 
	signal dl_next : unsigned(8 downto 0);
	signal dl_reg : unsigned(8 downto 0);
	signal dlO_next : unsigned(8 downto 0);
	signal dlO_reg : unsigned(8 downto 0);
	signal dt_next : unsigned(8 downto 0);
	signal dt_reg : unsigned(8 downto 0);
	signal dtO_next : unsigned(8 downto 0);
	signal dtO_reg : unsigned(8 downto 0);	

	-- stage 3 : Area calc mult
	signal A1_next : unsigned(17 downto 0);
	signal A1_reg : unsigned(17 downto 0);
	signal A2_next : unsigned(17 downto 0);
	signal A2_reg : unsigned(17 downto 0);
	signal A3_next : unsigned(17 downto 0);
	signal A3_reg : unsigned(17 downto 0);
	signal A4_next : unsigned(17 downto 0);
	signal A4_reg : unsigned(17 downto 0);

	signal p1_s3_reg : t_Pixel;
	signal p2_s3_reg : t_Pixel;
	signal p3_s3_reg : t_Pixel;
	signal p4_s3_reg : t_Pixel;
	signal p1_s3_next : t_Pixel;
	signal p2_s3_next : t_Pixel;
	signal p3_s3_next : t_Pixel;
	signal p4_s3_next : t_Pixel;

	-- stage 4: Pixel scaling
	signal f1_r_reg : unsigned(35 downto 0);
	signal f2_r_reg : unsigned(35 downto 0);
	signal f3_r_reg : unsigned(35 downto 0);
	signal f4_r_reg : unsigned(35 downto 0);

	signal f1_g_reg : unsigned(35 downto 0);
	signal f2_g_reg : unsigned(35 downto 0);
	signal f3_g_reg : unsigned(35 downto 0);
	signal f4_g_reg : unsigned(35 downto 0);

	signal f1_b_reg : unsigned(35 downto 0);
	signal f2_b_reg : unsigned(35 downto 0);
	signal f3_b_reg : unsigned(35 downto 0);
	signal f4_b_reg : unsigned(35 downto 0);

	signal f1_r_next : unsigned(35 downto 0);
	signal f2_r_next : unsigned(35 downto 0);
	signal f3_r_next : unsigned(35 downto 0);
	signal f4_r_next : unsigned(35 downto 0);

	signal f1_g_next : unsigned(35 downto 0);
	signal f2_g_next : unsigned(35 downto 0);
	signal f3_g_next : unsigned(35 downto 0);
	signal f4_g_next : unsigned(35 downto 0);

	signal f1_b_next : unsigned(35 downto 0);
	signal f2_b_next : unsigned(35 downto 0);
	signal f3_b_next : unsigned(35 downto 0);
	signal f4_b_next : unsigned(35 downto 0);

	-- stage 5: Pixel output
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
			param_ydelta_reg <= (others=>'0');
			param_ydeltaeach_reg <= (others=>'0');
			param_xaddrskip_reg <= "01";
			
			-- multi stage 1-5
			hsync_reg <= (others=>'0');
			vsync_reg <= (others=>'0');
			blank_reg <= (others=>'0');

			-- stage 1
			xacc_reg <= (others=>'0');
			yacc_reg <= (others=>'0');

			-- stage 2
			dt_reg <= (others=>'0');
			dl_reg <= (others=>'0');
			dtO_reg <= (others=>'0');
			dlO_reg <= (others=>'0');

			-- stage 3
			A1_reg <= (others=>'0');
			A2_reg <= (others=>'0');
			A3_reg <= (others=>'0');
			A4_reg <= (others=>'0');

			p1_s3_reg <= (others=>(others=>'0'));
			p2_s3_reg <= (others=>(others=>'0'));
			p3_s3_reg <= (others=>(others=>'0'));
			p4_s3_reg <= (others=>(others=>'0'));

			-- stage 4
			f1_r_reg <= (others=>'0');
			f2_r_reg <= (others=>'0');
			f3_r_reg <= (others=>'0');
			f4_r_reg <= (others=>'0');

			f1_g_reg <= (others=>'0');
			f2_g_reg <= (others=>'0');
			f3_g_reg <= (others=>'0');
			f4_g_reg <= (others=>'0');

			f1_b_reg <= (others=>'0');
			f2_b_reg <= (others=>'0');
			f3_b_reg <= (others=>'0');
			f4_b_reg <= (others=>'0');

			-- stage 5
			r_reg <= (others=>'0');
			g_reg <= (others=>'0');
			b_reg <= (others=>'0');
		elsif (clock'event and clock='1') then
			param_xthreshold_reg <= param_xthreshold_next;
			param_xdelta_reg <= param_xdelta_next;
			param_ythreshold_reg <= param_ythreshold_next;
			param_ydelta_reg <= param_ydelta_next;
			param_ydeltaeach_reg <= param_ydeltaeach_next;
			param_xaddrskip_reg <= param_xaddrskip_next;

			-- multi stage 1-5
			hsync_reg <= hsync_next;
			vsync_reg <= vsync_next;
			blank_reg <= blank_next;			
			
			-- stage 1
			xacc_reg <= xacc_next;
			yacc_reg <= yacc_next;

			-- stage 2
			dt_reg <= dt_next;
			dl_reg <= dl_next;
			dtO_reg <= dtO_next;
			dlO_reg <= dlO_next;

			-- stage 3
			A1_reg <= A1_next;
			A2_reg <= A2_next;
			A3_reg <= A3_next;
			A4_reg <= A4_next;

			p1_s3_reg <= p1_s3_next;
			p2_s3_reg <= p2_s3_next;
			p3_s3_reg <= p3_s3_next;
			p4_s3_reg <= p4_s3_next;

			-- stage 4
			f1_r_reg <= f1_r_next;
			f2_r_reg <= f2_r_next;
			f3_r_reg <= f3_r_next;
			f4_r_reg <= f4_r_next;

			f1_g_reg <= f1_g_next;
			f2_g_reg <= f2_g_next;
			f3_g_reg <= f3_g_next;
			f4_g_reg <= f4_g_next;

			f1_b_reg <= f1_b_next;
			f2_b_reg <= f2_b_next;
			f3_b_reg <= f3_b_next;
			f4_b_reg <= f4_b_next;

			-- stage 5
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
	param_xthreshold_next <= to_unsigned(400,11); -- these need to be inputs
	param_xdelta_next <= to_unsigned(300,11);
	param_ythreshold_next <= to_unsigned(786,11);
	param_ydelta_next <= to_unsigned(218,11);
	param_ydeltaeach_next <= to_unsigned(437,11); --interlace, need to skip a line
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
		xacc_next <= xacc_reg+param_xdelta_reg;
		if ((xacc_reg+param_xdelta_reg)>=param_xthreshold_reg) then
			next_x <= '1'; -- when I ask for data, its on p1 in 2 cycles, i.e. pipeline stage 3
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

--      Area computation - pipeline stage 2
--      dl = min(customscalex-xacc_i,xdelta);
--      dt = min(customscaley-yacc_i,ydelta);
--      
--      dlO = (xdelta-dl);
--      dtO = (ydelta-dt);
--      
--      A1 = dl*dt;   %M1
--      A2 = dlO*dt;  %M2
--      A3 = dl*dtO;  %M3
--      A4 = TA-A3-A2-A1; %Save 1!
	process(
		param_xthreshold_reg,xacc_reg,param_xdelta_reg,
		param_ythreshold_reg,yacc_reg,param_ydelta_reg)
		variable dl : unsigned(10 downto 0);
		variable dt : unsigned(10 downto 0);

		variable dlO : unsigned(10 downto 0);
		variable dtO : unsigned(10 downto 0);
	begin
		dl := param_xthreshold_reg-xacc_reg(10 downto 0);
		if (dl>param_xdelta_reg) then
			dl := param_xdelta_reg;
		end if;

		dt := param_ythreshold_reg-yacc_reg(10 downto 0);
		if (dt>param_ydelta_reg) then
			dt := param_ydelta_reg;
		end if;

		dlO:= param_xdelta_reg-dl;
		dtO:= param_ydelta_reg-dt;

		dt_next <= dt(8 downto 0);
		dl_next <= dl(8 downto 0);
		dtO_next <= dtO(8 downto 0);
		dlO_next <= dlO(8 downto 0);
	end process;

--      Area computation - pipeline stage 3
	process(dl_reg,dlO_reg,dt_reg,dtO_reg)
	begin
		-- dsp blocks 9x9 multipliers
		-- 3 per block
		A1_next <= dl_reg*dt_reg;
		A2_next <= dlO_reg*dt_reg;
		A3_next <= dl_reg*dtO_reg;
		A4_next <= dlO_reg*dtO_reg; --can save this one (leaving for now)

		--A1 <= to_unsigned(0,18);
		--A2 <= to_unsigned(0,18);
		--A3 <= to_unsigned(0,18);
		--A4 <= to_unsigned(65535,18);
	end process;

	-- delay pixel data
	process(pixels)
	begin
		p1_s3_next <= pixels(pixel2x2_idx(0,0));
		p2_s3_next <= pixels(pixel2x2_idx(1,0));
		p3_s3_next <= pixels(pixel2x2_idx(0,1));
		p4_s3_next <= pixels(pixel2x2_idx(1,1));
	end process;

--      Pixel scaling computation - pipeline stage 4
	-- Compute output
	-- (p1*A1 + p2*A2 + p3*A3 + p4*A4)/65536
	process(A1_reg,A2_reg,A3_reg,A4_reg,p1_s3_reg,p2_s3_reg,p3_s3_reg,p4_s3_reg)
	begin
		-- dsp blocks 18x18 multipliers
		-- 2 per block
		f1_r_next <= unsigned("0000000000"&p1_s3_reg.red)*A1_reg;
		f2_r_next <= unsigned("0000000000"&p2_s3_reg.red)*A2_reg;
		f3_r_next <= unsigned("0000000000"&p3_s3_reg.red)*A3_reg;
		f4_r_next <= unsigned("0000000000"&p4_s3_reg.red)*A4_reg;

		f1_g_next <= unsigned("0000000000"&p1_s3_reg.green)*A1_reg;
		f2_g_next <= unsigned("0000000000"&p2_s3_reg.green)*A2_reg;
		f3_g_next <= unsigned("0000000000"&p3_s3_reg.green)*A3_reg;
		f4_g_next <= unsigned("0000000000"&p4_s3_reg.green)*A4_reg;

		f1_b_next <= unsigned("0000000000"&p1_s3_reg.blue)*A1_reg;
		f2_b_next <= unsigned("0000000000"&p2_s3_reg.blue)*A2_reg;
		f3_b_next <= unsigned("0000000000"&p3_s3_reg.blue)*A3_reg;
		f4_b_next <= unsigned("0000000000"&p4_s3_reg.blue)*A4_reg;
	end process;

--      Pixel scaling computation - pipeline stage 5
	-- Compute output
	-- (p1*A1 + p2*A2 + p3*A3 + p4*A4)/65536
	process(
		f1_r_reg,f2_r_reg,f3_r_reg,f4_r_reg,
		f1_g_reg,f2_g_reg,f3_g_reg,f4_g_reg,
		f1_b_reg,f2_b_reg,f3_b_reg,f4_b_reg)
		variable sum_r : unsigned(9 downto 0);
		variable sum_g : unsigned(9 downto 0);
		variable sum_b : unsigned(9 downto 0);
	begin
		sum_r := (f1_r_reg(23 downto 14)+f2_r_reg(23 downto 14))+(f3_r_reg(23 downto 14)+f4_r_reg(23 downto 14));
		sum_g := (f1_g_reg(23 downto 14)+f2_g_reg(23 downto 14))+(f3_g_reg(23 downto 14)+f4_g_reg(23 downto 14));
		sum_b := (f1_b_reg(23 downto 14)+f2_b_reg(23 downto 14))+(f3_b_reg(23 downto 14)+f4_b_reg(23 downto 14));

		r_next <= std_logic_vector(sum_r(9 downto 2));
		g_next <= std_logic_vector(sum_g(9 downto 2));
		b_next <= std_logic_vector(sum_b(9 downto 2));
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


