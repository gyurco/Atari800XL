LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
use work.pixels.all;

ENTITY multiscale IS  
  GENERIC(
    enable_area : integer := 1;
	 enable_polyphasic : integer := 1
  );
  PORT(
    clock   : IN     STD_LOGIC;                             --system clock
    reset_n : IN     STD_LOGIC;                             --asynchronous reset

	 scaler_select : IN STD_LOGIC; -- 0==areascale/1==polyphasic
	 
    -- need to know:
    -- block of 4 pixels (x,y:x+1,y:x,y+1:x+1,y+1)
    -- relative scale ratios
    --p1 : in std_logic_vector(23 downto 0); --RGB
    --p2 : in std_logic_vector(23 downto 0); --RGB
    --p3 : in std_logic_vector(23 downto 0); --RGB
    --p4 : in std_logic_vector(23 downto 0); --RGB
	 
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
END multiscale;

ARCHITECTURE vhdl OF multiscale IS

		signal poly_red_next : std_logic_vector(7 downto 0);
		signal poly_green_next : std_logic_vector(7 downto 0);
		signal poly_blue_next : std_logic_vector(7 downto 0);
		signal poly_hsync_next : std_logic;
		signal poly_vsync_next : std_logic;
		signal poly_blank_next : std_logic;
		signal poly_next_x : STD_LOGIC;
		signal poly_next_x_size : std_logic_vector(1 downto 0);
		signal poly_next_y : STD_LOGIC;	 			

		signal area_red_next : std_logic_vector(7 downto 0);
		signal area_green_next : std_logic_vector(7 downto 0);
		signal area_blue_next : std_logic_vector(7 downto 0);
		signal area_hsync_next : std_logic;
		signal area_vsync_next : std_logic;
		signal area_blank_next : std_logic;				
		signal area_next_x : STD_LOGIC;
		signal area_next_x_size : std_logic_vector(1 downto 0);
		signal area_next_y : STD_LOGIC;	 		
		
BEGIN
	
gen_polyphasic_on : if enable_polyphasic=1 generate

polyphasicscale_impl : entity work.polyphasicscale
	port map 
	(
		CLOCK => CLOCK,
		RESET_N => reset_n,

		pixels => pixels,
		next_y_in => next_y_in,      --reset_x
		next_frame_in => next_frame_in, --reset y
		next_x => poly_next_x,
		next_y => poly_next_y,
		next_x_size => poly_next_x_size,
		field2 => field2, -- field 2 is half lower
		
		hsync_in => hsync_in,
		vsync_in => vsync_in,
		blank_in => blank_in,

		r => poly_red_next,
		g => poly_green_next,
		b => poly_blue_next,
		hsync => poly_hsync_next,
		vsync => poly_vsync_next,
		blank => poly_blank_next,
				
		sda => sda,
		scl => scl		
	);
end generate gen_polyphasic_on;	
	
gen_area_on : if enable_area=1 generate	
areascale_impl : entity work.areascale
	port map 
	(
		CLOCK => CLOCK,
		RESET_N => reset_n,

		pixels => pixel_to2x2(pixels),
		next_y_in => next_y_in,      --reset_x
		next_frame_in => next_frame_in, --reset y
		next_x => area_next_x,
		next_y => area_next_y,
		next_x_size => area_next_x_size,
		field2 => field2, -- field 2 is half lower
		
		hsync_in => hsync_in,
		vsync_in => vsync_in,
		blank_in => blank_in,

		r => area_red_next,
		g => area_green_next,
		b => area_blue_next,
		hsync => area_hsync_next,
		vsync => area_vsync_next,
		blank => area_blank_next,
		
		sda => sda,
		scl => scl
	);
end generate gen_area_on;	
	
gen_select_on : if enable_area=1 and enable_polyphasic=1 generate	
	process(scaler_select,
		area_red_next,area_green_next,area_blue_next,
		area_hsync_next,area_vsync_next,area_blank_next,
		area_next_x,area_next_y,area_next_x_size,
		poly_red_next,poly_green_next,poly_blue_next,
		poly_hsync_next,poly_vsync_next,poly_blank_next,
		poly_next_x,poly_next_y,poly_next_x_size)		
	begin
		if (scaler_select='0') then
			r <= area_red_next;
			g <= area_green_next;
			b <= area_blue_next;
			hsync <= area_hsync_next;
			vsync <= area_vsync_next;
			blank <= area_blank_next;		
			
			next_x <= area_next_x;
			next_y <= area_next_y;
			next_x_size <= area_next_x_size;		
		else
			r <= poly_red_next;
			g <= poly_green_next;
			b <= poly_blue_next;
			hsync <= poly_hsync_next;
			vsync <= poly_vsync_next;
			blank <= poly_blank_next;		
			
			next_x <= poly_next_x;
			next_y <= poly_next_y;
			next_x_size <= poly_next_x_size;				
		end if;
	end process;
end generate gen_select_on;

gen_fixed_area : if enable_area=1 and enable_polyphasic=0 generate	
			r <= area_red_next;
			g <= area_green_next;
			b <= area_blue_next;
			hsync <= area_hsync_next;
			vsync <= area_vsync_next;
			blank <= area_blank_next;		
			
			next_x <= area_next_x;
			next_y <= area_next_y;
			next_x_size <= area_next_x_size;		
end generate gen_fixed_area;

gen_fixed_poly : if enable_area=0 and enable_polyphasic=1 generate	
			r <= poly_red_next;
			g <= poly_green_next;
			b <= poly_blue_next;
			hsync <= poly_hsync_next;
			vsync <= poly_vsync_next;
			blank <= poly_blank_next;		
			
			next_x <= poly_next_x;
			next_y <= poly_next_y;
			next_x_size <= poly_next_x_size;		
end generate gen_fixed_poly;

gen_none : if enable_area=0 and enable_polyphasic=0 generate	
	-- TODO: nearest neighbour?	
end generate gen_none;

END vhdl;
