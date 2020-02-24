---------------------------------------------------------------------------
-- (c) 2019 mark watson
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

ENTITY crtc IS
PORT 
( 
	clk_pixel : in std_logic;
	reset_n : in std_logic;

	-- inputs
	resync_start_frame : in std_logic;

	-- outputs
	hsync : out std_logic;
	vsync : out std_logic;
	blank : out std_logic;

	inc_line  : out std_logic;
	inc_frame : out std_logic;
	
	field2 : out std_logic; -- field 2 is lower

	clock_select : out std_logic_vector(2 downto 0);
	
	video_id_code : out std_logic_vector(7 downto 0);
	scaler_select : out std_logic;

	-- to set up params
    scl_in           : in std_logic;
    sda_in           : in std_logic;
	 scl_wen          : out std_logic;
	 sda_wen          : out std_logic
);
END crtc;

--TODO: start_frame, clock_select and sda/scl

ARCHITECTURE vhdl OF crtc IS
	-- parameters
	signal param_h_syncLen_reg      : unsigned(11 downto 0);  --sync right at start
	signal param_h_preActiveLen_reg  : unsigned(11 downto 0);  --blank after sync
	signal param_h_activeLen_reg    : unsigned(11 downto 0); --then active
	signal param_h_postActiveLen_reg : unsigned(11 downto 0); --blank after active

	signal param_v_syncLen_reg      : unsigned(11 downto 0);  --sync right at start
	signal param_v_preActiveLen_reg  : unsigned(11 downto 0);  --blank after sync
	signal param_v_activeLen_reg    : unsigned(11 downto 0);  --then active
	signal param_v_postActiveLen_reg : unsigned(11 downto 0);  --blank after active

	signal param_interlace_reg : std_logic;
	signal param_interlaceDelayLen_reg : unsigned(11 downto 0); --delay sync by half a len

	signal param_video_id_code_reg : std_logic_vector(7 downto 0); -- CEA 864 id code
	signal param_scalar_select_reg : std_logic;
	
	signal param_clock_select_reg : std_logic_vector(2 downto 0); -- which clock to use
	
	signal param_active_reg : std_logic;
	
	signal params : std_logic_vector((13*12)-1 downto 0);

	-- state
	signal h_state_next: std_logic_vector(2 downto 0);
	signal h_state_reg : std_logic_vector(2 downto 0);
	signal v_state_next: std_logic_vector(3 downto 0);
	signal v_state_reg : std_logic_vector(3 downto 0);

	constant H_STATE_IDLE : std_logic_vector(2 downto 0) := "000";
	constant H_STATE_SYNC : std_logic_vector(2 downto 0) := "001";
	constant H_STATE_PREBLANK : std_logic_vector(2 downto 0) := "010";
	constant H_STATE_ACTIVE : std_logic_vector(2 downto 0) := "011";
	constant H_STATE_POSTBLANK : std_logic_vector(2 downto 0) := "100";

	constant V_STATE_IDLE : std_logic_vector(3 downto 0) := "0000";
	constant V_STATE_SYNC : std_logic_vector(3 downto 0) := "0001";
	constant V_STATE_PREBLANK : std_logic_vector(3 downto 0) := "0010";
	constant V_STATE_ACTIVE : std_logic_vector(3 downto 0) := "0011";
	constant V_STATE_POSTBLANK : std_logic_vector(3 downto 0) := "0100";
	constant V_STATE_PRESYNC_FIELD2 : std_logic_vector(3 downto 0) := "0101";
	constant V_STATE_SYNC_FIELD2 : std_logic_vector(3 downto 0) := "0110";
	constant V_STATE_POSTSYNC_FIELD2 : std_logic_vector(3 downto 0) := "0111";
	constant V_STATE_PREBLANK_FIELD2 : std_logic_vector(3 downto 0) := "1000";
	constant V_STATE_ACTIVE_FIELD2 : std_logic_vector(3 downto 0) := "1001";
	constant V_STATE_POSTBLANK_FIELD2 : std_logic_vector(3 downto 0) := "1010";

	signal h_delay_next : unsigned(11 downto 0);
	signal h_delay_reg : unsigned(11 downto 0);

	signal v_delay_next : unsigned(11 downto 0);
	signal v_delay_reg : unsigned(11 downto 0);
	signal v_delayh_next : unsigned(11 downto 0);
	signal v_delayh_reg : unsigned(11 downto 0);
	
	signal v_sync_inc : std_logic;
	
	signal resync : std_logic;
	
	signal h_blank_next : std_logic;
	signal h_sync_next : std_logic;
	signal v_blank_next : std_logic;
	signal v_sync_next : std_logic;
	signal blank_next : std_logic;

	signal h_blank_reg : std_logic;
	signal h_sync_reg : std_logic;
	signal v_blank_reg : std_logic;
	signal v_sync_reg : std_logic;	
	signal blank_reg : std_logic;
	
BEGIN
	--registers
	process(clk_pixel,reset_n)
	begin
		if (reset_n='0') then
			h_state_reg <= H_STATE_IDLE;
			v_state_reg <= V_STATE_IDLE;

			h_delay_reg <= (others=>'0');
			v_delay_reg <= (others=>'0');
			v_delayh_reg <= (others=>'0');
			
			h_blank_reg <= '1';
			h_sync_reg <= '0';
			v_blank_reg <= '1';
			v_sync_reg <= '0';
			blank_reg <= '1';
		elsif (clk_pixel='1' and clk_pixel'event) then
			h_state_reg <= h_state_next;
			v_state_reg <= v_state_next;

			h_delay_reg <= h_delay_next;
			v_delay_reg <= v_delay_next;
			v_delayh_reg <= v_delayh_next;
			
			h_blank_reg <= h_blank_next;
			h_sync_reg <= h_sync_next;
			v_blank_reg <= v_blank_next;
			v_sync_reg <= v_sync_next;
			blank_reg <= blank_next;
		end if;
	end process;
	
	-- parameters from i2c (todo)
--			-- 720p@50 (temp until we get crtc plumbed to firmware)
--		param_h_syncLen_next <= to_unsigned(40,12);
--		param_h_preActiveLen_next <= to_unsigned(220,12);
--		param_h_activeLen_next <= to_unsigned(1280,12);
--		param_h_postActiveLen_next <= to_unsigned(440,12);
--		param_v_syncLen_next <= to_unsigned(5,12);
--		param_v_preActiveLen_next <= to_unsigned(20,12);
--		param_v_activeLen_next <= to_unsigned(720,12);
--		param_v_postActiveLen_next <= to_unsigned(5,12);
--		param_interlace_next <= '0';
--		param_interlaceDelayLen_next <= (others=>'0');
--		param_clock_select_next <= (others=>'0');
		
			-- 1080i@50 (temp until we get crtc plumbed to firmware)
--		param_h_syncLen_next <= to_unsigned(44,12);
--		param_h_preActiveLen_next <= to_unsigned(148,12);
--		param_h_activeLen_next <= to_unsigned(1920,12);
--		param_h_postActiveLen_next <= to_unsigned(528,12);
--		param_v_syncLen_next <= to_unsigned(5,12);
--		param_v_preActiveLen_next <= to_unsigned(15,12);
--		param_v_activeLen_next <= to_unsigned(540,12);
--		param_v_postActiveLen_next <= to_unsigned(2,12);
--		param_interlace_next <= '1';
--		param_interlaceDelayLen_next <= to_unsigned(1320,12);
--		param_clock_select_next <= (others=>'0');		
--		param_active_next <= '1';

		
-- params set from i2c
	i2cregs : entity work.I2C_regs
	generic map (
		SLAVE_ADDR => "0000010",
		regs => 13,
		bits => 12
	)
	port map (
		scl_in => scl_in,
		sda_in => sda_in,
		scl_wen => scl_wen,
		sda_wen => sda_wen,
		
		clk => clk_pixel,
		rst => not(reset_n),
		
		reg => params			
	);
	param_h_syncLen_reg <= unsigned(params(1*12-1 downto 0*12));
	param_h_preActiveLen_reg <= unsigned(params(2*12-1 downto 1*12));
	param_h_activeLen_reg <= unsigned(params(3*12-1 downto 2*12));
	param_h_postActiveLen_reg <= unsigned(params(4*12-1 downto 3*12));
	param_v_syncLen_reg <= unsigned(params(5*12-1 downto 4*12));
	param_v_preActiveLen_reg <= unsigned(params(6*12-1 downto 5*12));
	param_v_activeLen_reg <= unsigned(params(7*12-1 downto 6*12));
	param_v_postActiveLen_reg <= unsigned(params(8*12-1 downto 7*12));
	param_interlace_reg <= params(8*12);
	param_interlaceDelayLen_reg <= unsigned(params(10*12-1 downto 9*12));
	param_video_id_code_reg <= params(10*12+8-1 downto 10*12);	
	param_scalar_select_reg <= params(10*12+9-1);
	param_clock_select_reg <= params(11*12+3-1 downto 11*12);
	param_active_reg <= params(12*12);
	
	-- state machine
		-- horizontal
	process(h_state_reg,h_delay_reg,h_blank_reg,h_sync_reg,
	   resync_start_frame,
		param_active_reg,
		param_h_syncLen_reg,
		param_h_preActiveLen_reg,
		param_h_activeLen_reg,
		param_h_postActiveLen_reg
	)
		variable delay_over : std_logic;
	begin
		h_state_next <= h_state_reg;
		h_delay_next <= h_delay_reg;
		h_blank_next <= h_blank_reg;
		h_sync_next <= h_sync_reg;
		
		v_sync_inc <= '0';
		inc_line <= '0';		

		h_delay_next <= h_delay_reg - 1;

		delay_over := '0';
		if (h_delay_reg="00000000001") then
			delay_over := '1';
		end if;

		case h_state_reg is
			when H_STATE_IDLE =>
				h_blank_next <= '1';
				h_sync_next <= '1';

				if (param_active_reg='1') then
					h_state_next <= H_STATE_ACTIVE;
					h_delay_next <= param_h_activeLen_reg;
					h_sync_next <= '0';
					h_blank_next <= '0';
				end if;
			when H_STATE_SYNC =>
				if (delay_over='1') then
					h_state_next <= H_STATE_PREBLANK;
					h_delay_next <= param_h_preActiveLen_reg;
					h_sync_next <= '0';
				end if;
			when H_STATE_PREBLANK =>
				if (delay_over='1') then
					h_state_next <= H_STATE_ACTIVE;
					h_delay_next <= param_h_activeLen_reg;
					h_blank_next <= '0';
					inc_line <= '1';
				end if;
			when H_STATE_ACTIVE =>
				if (delay_over='1') then
					h_state_next <= H_STATE_POSTBLANK;
					h_delay_next <= param_h_postActiveLen_reg;
					h_blank_next <= '1';					
				end if;
			when H_STATE_POSTBLANK =>
				if (delay_over='1') then
					h_state_next <= H_STATE_SYNC;
					h_delay_next <= param_h_syncLen_reg;
					h_sync_next <= '1';
					v_sync_inc <= '1';
				end if;
			when others =>
				h_state_next <= H_STATE_IDLE;
		end case;

		if (param_active_reg='0' or resync_start_frame='1') then
			h_state_next <= H_STATE_IDLE;
		end if;
	end process;

		-- vertical
	process(v_state_reg,v_delay_reg,v_delayh_reg,v_blank_reg,v_sync_reg,
		v_sync_inc,
		resync_start_frame,
		param_active_reg,
		param_v_syncLen_reg,
		param_v_preActiveLen_reg,
		param_v_activeLen_reg,
		param_v_postActiveLen_reg,
		param_interlace_reg,
		param_interlaceDelayLen_reg		
	)
		variable delay_over : std_logic;
		variable delayh_over : std_logic;
	begin
		v_state_next <= v_state_reg;
		v_delay_next <= v_delay_reg;
		v_delayh_next <= v_delayh_reg;
		v_blank_next <= v_blank_reg;
		v_sync_next <= v_sync_reg;		
		inc_frame <= '0';
		field2 <= '0';

		if (v_sync_inc = '1') then
			v_delay_next <= v_delay_reg - 1;
		end if;
		v_delayh_next <= v_delayh_reg - 1;

		delay_over := '0';
		if (v_delay_reg="0000000001" and v_sync_inc='1') then
			delay_over := '1';
		end if;
		delayh_over := '0';
		if (v_delayh_reg="00000000001") then
			delayh_over := '1';
		end if;

		case v_state_reg is
			when V_STATE_IDLE =>
				v_blank_next <= '1';
				v_sync_next <= '1';		

				if (param_active_reg='1') then
					v_state_next <= V_STATE_ACTIVE;
					v_delay_next <= param_v_activeLen_reg;
					v_sync_next <= '0';
					v_blank_next <= '0';		
					inc_frame <= '1';			
				end if;				
			when V_STATE_SYNC =>
				if (delay_over='1') then
					v_state_next <= V_STATE_PREBLANK;
					v_delay_next <= param_v_preActiveLen_reg;
					v_sync_next <= '0';
				end if;
			when V_STATE_PREBLANK =>
				if (delay_over='1') then
					v_state_next <= V_STATE_ACTIVE;
					v_delay_next <= param_v_activeLen_reg;
					v_blank_next <= '0';
					inc_frame <= '1';
				end if;
			when V_STATE_ACTIVE =>
				if (delay_over='1') then
					v_state_next <= V_STATE_POSTBLANK;
					v_delay_next <= param_v_postActiveLen_reg;
					v_blank_next <= '1';
				end if;
			when V_STATE_POSTBLANK =>
				if (delay_over='1') then
					if (param_interlace_reg='1') then
						v_state_next <= V_STATE_PRESYNC_FIELD2;
						v_delayh_next <= param_interlaceDelayLen_reg;
					else
						v_sync_next <= '1';
						v_state_next <= V_STATE_SYNC;
						v_delay_next <= param_v_syncLen_reg;
					end if;
				end if;
			when V_STATE_PRESYNC_FIELD2 =>
				if (delayh_over='1') then
					v_sync_next <= '1';
					v_state_next <= V_STATE_SYNC_FIELD2;
					v_delay_next <= param_v_syncLen_reg;					
				end if;
			when V_STATE_SYNC_FIELD2 =>
				if (delay_over='1') then
					v_state_next <= V_STATE_POSTSYNC_FIELD2;
					v_delayh_next <= param_interlaceDelayLen_reg;
				end if;
			when V_STATE_POSTSYNC_FIELD2 =>
				if (delayh_over='1') then
					v_sync_next <= '0';
					v_state_next <= V_STATE_PREBLANK_FIELD2;
					v_delay_next <= param_v_preActiveLen_reg+1;
				end if;				
			when V_STATE_PREBLANK_FIELD2 =>
				if (delay_over='1') then
					v_state_next <= V_STATE_ACTIVE_FIELD2;
					v_delay_next <= param_v_activeLen_reg;
					v_blank_next <= '0';
					inc_frame <= '1';
					field2 <= '1';					
				end if;
			when V_STATE_ACTIVE_FIELD2 =>
				if (delay_over='1') then
					v_state_next <= V_STATE_POSTBLANK_FIELD2;
					v_delay_next <= param_v_postActiveLen_reg;
					v_blank_next <= '1';
				end if;
			when V_STATE_POSTBLANK_FIELD2 =>
				if (delay_over='1') then
					v_sync_next <= '1';
					v_state_next <= V_STATE_SYNC;
					v_delay_next <= param_v_syncLen_reg;
				end if;
			when others =>
				v_state_next <= V_STATE_IDLE;
		end case;

		if (param_active_reg='0' or resync_start_frame='1') then
			v_state_next <= V_STATE_IDLE;
		end if;
	end process;
	
	blank_next <= h_blank_next or v_blank_next;
	
	-- outputs
	blank <= blank_reg;
	hsync <= h_sync_reg;
	vsync <= v_sync_reg;
	
	clock_select <= param_clock_select_reg(2 downto 0);
	video_id_code <= param_video_id_code_reg;
	scaler_select <= param_scalar_select_reg;

END vhdl;
