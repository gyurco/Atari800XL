-- ===================================================================================
-- Package / Component definition
-- ===================================================================================

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

--PACKAGE svideo_pkg IS
--  COMPONENT svideo
--  PORT(
--    -- Power up reset
--    areset_n    : IN  STD_LOGIC;
--    -- Main clock (28.636363 MHz)
--    ecs_clk     : IN  STD_LOGIC;
--    -- DAC clock (114.545454 MHz)
--    dac_clk     : IN  STD_LOGIC;
--    -- RGB input
--    r_in        : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
--    g_in        : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
--    b_in        : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
--    -- Start of frame flag
--    sof         : IN  STD_LOGIC;
--    -- PAL burst phase
--    vpos_lsb    : IN  STD_LOGIC;
--    -- Burst/Synchro/Blanking inputs
--    blank       : IN  STD_LOGIC;
--    burst       : IN  STD_LOGIC;
--    csync_n     : IN  STD_LOGIC;
--    -- S-Video output
--    y_out       : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
--    c_out       : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
--    -- PAL(0)/NTSC(1) mode
--    pal_ntsc    : IN  STD_LOGIC
--  );
--  END COMPONENT;
--
--END PACKAGE;

-- ===================================================================================
-- Entity / Architecture definition
-- ===================================================================================

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
LIBRARY WORK;
USE WORK.SIN_COS_PKG.ALL;

ENTITY svideo_sync IS
  PORT(
    -- Power up reset
    areset_n    : IN  STD_LOGIC;
    -- Main clock (28.636363 MHz)
    ecs_clk     : IN  STD_LOGIC;
    -- DAC clock (114.545454 MHz)
    dac_clk     : IN  STD_LOGIC;
    -- RGB input
    r_in        : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
    g_in        : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
    b_in        : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
    -- Start of frame flag
    sof         : IN  STD_LOGIC;
    -- PAL burst phase
    vpos_lsb    : IN  STD_LOGIC;
    -- Burst/Synchro/Blanking inputs
    blank       : IN  STD_LOGIC;
    burst       : IN  STD_LOGIC;
    csync_n     : IN  STD_LOGIC;
    -- Composite or svideo input
    comp_n      : IN STD_LOGIC;
    -- S-Video output
    y_out       : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    c_out       : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
    -- sync
    sync_n_out : out std_logic;
    -- PAL(0)/NTSC(1) mode
    pal_ntsc    : IN  STD_LOGIC
  );
END svideo_sync;

ARCHITECTURE rtl OF svideo_sync IS

  -- Color carrier phase (0 - 31)
  SIGNAL   col_ctr      : STD_LOGIC_VECTOR(4 DOWNTO 0);

  -------------------------
  -- RGB -> Y conversion --
  -------------------------
  -- 1st stage
  SIGNAL   comp_YR_comp      : UNSIGNED(16 DOWNTO 0);
  SIGNAL   comp_YG_comp      : UNSIGNED(16 DOWNTO 0);
  SIGNAL   comp_YB_comp      : UNSIGNED(16 DOWNTO 0);
  SIGNAL   comp_YR_svideo      : UNSIGNED(16 DOWNTO 0);
  SIGNAL   comp_YG_svideo      : UNSIGNED(16 DOWNTO 0);
  SIGNAL   comp_YB_svideo      : UNSIGNED(16 DOWNTO 0);
  SIGNAL   comp_Y2      : STD_LOGIC_VECTOR(16 DOWNTO 0);
  SIGNAL   comp_Y3      : STD_LOGIC_VECTOR(9 DOWNTO 0);
  SIGNAL   comp_Y4      : STD_LOGIC_VECTOR(9 DOWNTO 0);

  CONSTANT Y_LVL_SYNC   : STD_LOGIC_VECTOR(16 DOWNTO 0) := "00000000000000000";
--  CONSTANT Y_LVL_BLANK_COMP    : STD_LOGIC_VECTOR(16 DOWNTO 0) := "00111000000000000";
--  CONSTANT Y_LVL_PICT_COMP     : STD_LOGIC_VECTOR(16 DOWNTO 0) := "00111000000000000";
  CONSTANT Y_LVL_BLANK_COMP    : STD_LOGIC_VECTOR(16 DOWNTO 0) := "00011000000000000";
  CONSTANT Y_LVL_PICT_COMP     : STD_LOGIC_VECTOR(16 DOWNTO 0) := "00011000000000000";
--  CONSTANT Y_LVL_BLANK_COMP    : STD_LOGIC_VECTOR(16 DOWNTO 0) := "00011111000000000";
--  CONSTANT Y_LVL_PICT_COMP     : STD_LOGIC_VECTOR(16 DOWNTO 0) := "00011111000000000";
--  CONSTANT Y_LVL_BLANK_COMP  : STD_LOGIC_VECTOR(16 DOWNTO 0) := "00000000000000000";
--  CONSTANT Y_LVL_PICT_COMP   : STD_LOGIC_VECTOR(16 DOWNTO 0) := "00000000000000000";
  CONSTANT Y_LVL_BLANK_SVIDEO  : STD_LOGIC_VECTOR(16 DOWNTO 0) := "00000000000000000";
  CONSTANT Y_LVL_PICT_SVIDEO   : STD_LOGIC_VECTOR(16 DOWNTO 0) := "00000000000000000";

  -------------------------
  -- RGB -> U conversion --
  -------------------------
  -- 1st stage
  SIGNAL   comp_UR      : UNSIGNED(16 DOWNTO 0);
  SIGNAL   comp_UG      : UNSIGNED(16 DOWNTO 0);
  SIGNAL   comp_UB      : UNSIGNED(16 DOWNTO 0);
  -- 2nd stage
  SIGNAL   comp_pU      : STD_LOGIC_VECTOR(17 DOWNTO 0);
  SIGNAL   comp_mU      : STD_LOGIC_VECTOR(17 DOWNTO 0);
  -- 3rd stage
  SIGNAL   sign_U       : STD_LOGIC;
  SIGNAL   ampl_U       : STD_LOGIC_VECTOR(7 DOWNTO 0);
  -- 4th stage
  SIGNAL   comp_U       : STD_LOGIC_VECTOR(8 DOWNTO 0);

--  CONSTANT pU_LVL_BURST : STD_LOGIC_VECTOR(17 DOWNTO 0) := "000100100000000000"; -- +15%
--  CONSTANT mU_LVL_BURST : STD_LOGIC_VECTOR(17 DOWNTO 0) := "111011100000000000"; -- -15%
--  CONSTANT pU_LVL_BURST : STD_LOGIC_VECTOR(17 DOWNTO 0) := "000110000000000000"; -- +20%
--  CONSTANT mU_LVL_BURST : STD_LOGIC_VECTOR(17 DOWNTO 0) := "111010000000000000"; -- -20%
  CONSTANT pU_LVL_BURST : STD_LOGIC_VECTOR(17 DOWNTO 0) := "000111111000000000"; -- +25%
  CONSTANT mU_LVL_BURST : STD_LOGIC_VECTOR(17 DOWNTO 0) := "111000000000000000"; -- -25%

  -------------------------
  -- RGB -> V conversion --
  -------------------------
  -- 1st stage
  SIGNAL   comp_VR      : UNSIGNED(16 DOWNTO 0);
  SIGNAL   comp_VG      : UNSIGNED(16 DOWNTO 0);
  SIGNAL   comp_VB      : UNSIGNED(16 DOWNTO 0);
  -- 2nd stage
  SIGNAL   comp_pV      : STD_LOGIC_VECTOR(17 DOWNTO 0);
  SIGNAL   comp_mV      : STD_LOGIC_VECTOR(17 DOWNTO 0);
  -- 3rd stage
  SIGNAL   sign_V       : STD_LOGIC;
  SIGNAL   ampl_V       : STD_LOGIC_VECTOR(7 DOWNTO 0);
  -- 4th stage
  SIGNAL   comp_V       : STD_LOGIC_VECTOR(8 DOWNTO 0);

  -----------------
  -- Y/C signals --
  -----------------
  SIGNAL   luma         : STD_LOGIC_VECTOR(9 DOWNTO 0);
  SIGNAL   luma_1       : STD_LOGIC_VECTOR(9 DOWNTO 0);
  SIGNAL   luma_2       : STD_LOGIC_VECTOR(9 DOWNTO 0);
  SIGNAL   luma_acc     : STD_LOGIC_VECTOR(9 DOWNTO 0);
  SIGNAL   chroma       : STD_LOGIC_VECTOR(8 DOWNTO 0);
  SIGNAL   chroma_1     : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL   chroma_2     : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL   chroma_acc   : STD_LOGIC_VECTOR(7 DOWNTO 0);
  
  -- Delayed input signals
  SIGNAL   blank_dly    : STD_LOGIC;
  SIGNAL   blank_dly2    : STD_LOGIC;
  SIGNAL   blank_dly3    : STD_LOGIC;
  SIGNAL   blank_dly4    : STD_LOGIC;
  SIGNAL   burst_dly    : STD_LOGIC;
  SIGNAL   burst_dly2    : STD_LOGIC;
  SIGNAL   burst_dly3    : STD_LOGIC;
  SIGNAL   burst_dly4    : STD_LOGIC;
  SIGNAL   csync_dly    : STD_LOGIC;
  SIGNAL   csync_dly2    : STD_LOGIC;
  SIGNAL   csync_dly3    : STD_LOGIC;
  SIGNAL   csync_dly4    : STD_LOGIC;
  SIGNAL   sof_dly      : STD_LOGIC_VECTOR(1 DOWNTO 0);

BEGIN

  PROCESS
  (
    areset_n,    -- Global reset
    ecs_clk,     -- Main clock
    csync_n,     -- Composite synchro (active low)
    blank,       -- Composite blanking
    burst,       -- Burst enable flag
    pal_ntsc,    -- PAL(0) / NTSC(1)
    sof          -- Start of frame flag
  )
    variable chroma_tmp : std_logic_vector(8 downto 0);
  BEGIN
    IF (areset_n = '0') THEN
      -- Color carrier phase
      col_ctr <= (OTHERS => '0');
      -- Y component
      comp_YR_svideo <= (OTHERS => '0');
      comp_YG_svideo <= (OTHERS => '0');
      comp_YB_svideo <= (OTHERS => '0');
      comp_YR_comp <= (OTHERS => '0');
      comp_YG_comp <= (OTHERS => '0');
      comp_YB_comp <= (OTHERS => '0');
      comp_Y2 <= (OTHERS => '0');
      comp_Y3 <= (OTHERS => '0');
      comp_Y4 <= (OTHERS => '0');
      -- U component
      comp_UR <= (OTHERS => '0');
      comp_UG <= (OTHERS => '0');
      comp_UB <= (OTHERS => '0');
      comp_pU <= (OTHERS => '0');
      comp_mU <= (OTHERS => '0');
      sign_U  <= '0';
      ampl_U  <= (OTHERS => '0');
      -- V component
      comp_VR <= (OTHERS => '0');
      comp_VG <= (OTHERS => '0');
      comp_VB <= (OTHERS => '0');
      comp_pV <= (OTHERS => '0');
      comp_mV <= (OTHERS => '0');
      sign_V  <= '0';
      ampl_V  <= (OTHERS => '0');
    ELSIF (rising_edge(ecs_clk)) THEN
      -----------------
      -----------------
      -- First stage --
      -----------------
      -----------------

      -- RGB -> Y conversion :
      ------------------------
      --     Y = (0.299*R + 0.587*G + 0.114*B) * 140 / 256
      --     Y =  0.164*R + 0.321*G + 0.062*B
      -- 512*Y =     84*R +   164*G +    32*B
      -- Adjust for sync: 512*Y = 153*R+300*G+58*B
      -- Adjust for sync - with 64 space for composite:
      --     Y = (0.299*R + 0.587*G + 0.114*B) * 192 / 256
      -- 512*Y = 114*R + 225*G + 43*B 
      -- Adjust for sync - with 32 space for composite:
      --     Y = (0.299*R + 0.587*G + 0.114*B) * 224 / 256
      -- 512*Y = 133*R + 262*G + 51*B 
      comp_YR_svideo <= "010011001" * unsigned(r_in);
      comp_YG_svideo <= "100101100" * unsigned(g_in);
      comp_YB_svideo <= "000111010" * unsigned(b_in);

      comp_YR_comp <= "010000101" * unsigned(r_in);
      comp_YG_comp <= "100000110" * unsigned(g_in);
      comp_YB_comp <= "000110011" * unsigned(b_in);

      -- RGB -> U conversion :
      ------------------------
      --     U = -0.147*R - 0.289*G + 0.436*B
      -- 512*U =    -75*R -   148*G +   223*B
      comp_UR <= "001001011" * unsigned(r_in);
      comp_UG <= "010010100" * unsigned(g_in);
      comp_UB <= "011011111" * unsigned(b_in);

      -- RGB -> V conversion :
      ------------------------
      --     V =  0.615*R - 0.515*G - 0.100*B
      -- 512*V =    315*R -   264*G -    51*B
      comp_VR <= "100111011" * unsigned(r_in);
      comp_VG <= "100001000" * unsigned(g_in);
      comp_VB <= "000110011" * unsigned(b_in);
      
      -- Delayed signals :
      --------------------
      csync_dly <= csync_n;          -- to 2nd stage
      csync_dly2 <= csync_dly;       -- to 3rd stage
      csync_dly3 <= csync_dly2;      -- to 4th stage
      csync_dly4 <= csync_dly3;      -- to 5th stage
      blank_dly <= blank;            -- to 2nd stage
      burst_dly <= burst;            -- to 2nd stage
      sof_dly   <= sof_dly(0) & sof; -- to 3rd stage

      ------------------
      ------------------
      -- Second stage --
      ------------------
      ------------------

      -- Compute Y
      IF (csync_dly = '0') THEN
        -- Synchro level
        comp_Y2 <= Y_LVL_SYNC;
      ELSIF (comp_n = '0') THEN
        IF (blank_dly = '1') THEN
          -- Blanking level
          comp_Y2 <= Y_LVL_BLANK_COMP;
        ELSE
          -- Picture level
          comp_Y2 <= std_logic_vector(comp_YR_comp)
                   + std_logic_vector(comp_YG_comp)
                   + std_logic_vector(comp_YB_comp)
                   + Y_LVL_PICT_COMP;
        END IF;
      ELSE
        IF (blank_dly = '1') THEN
          -- Blanking level
          comp_Y2 <= Y_LVL_BLANK_SVIDEO;
        ELSE
          -- Picture level
          comp_Y2 <= std_logic_vector(comp_YR_svideo)
                   + std_logic_vector(comp_YG_svideo)
                   + std_logic_vector(comp_YB_svideo)
                   + Y_LVL_PICT_SVIDEO;
        END IF;
      END IF;

      -- Compute U
      IF (burst_dly = '1') THEN
        comp_pU <= mU_LVL_BURST;
        comp_mU <= pU_LVL_BURST;
      ELSE
        comp_pU <= std_logic_vector('0' & comp_UB)
                 - std_logic_vector('0' & comp_UG)
                 - std_logic_vector('0' & comp_UR);
        comp_mU <= std_logic_vector('0' & comp_UR)
                 + std_logic_vector('0' & comp_UG)
                 - std_logic_vector('0' & comp_UB);
      END IF;

      -- Compute V
      IF (burst_dly = '1') THEN
        IF (pal_ntsc = '1') THEN
          -- NTSC burst
          comp_pV <= (OTHERS => '0');
          comp_mV <= (OTHERS => '0');
        ELSE
          -- PAL burst
          comp_pV <= pU_LVL_BURST;
          comp_mV <= mU_LVL_BURST;
        END IF;
      ELSE
        comp_pV <= std_logic_vector('0' & comp_VR)
                 - std_logic_vector('0' & comp_VG)
                 - std_logic_vector('0' & comp_VB);
        comp_mV <= std_logic_vector('0' & comp_VB)
                 + std_logic_vector('0' & comp_VG)
                 - std_logic_vector('0' & comp_VR);
      END IF;

      blank_dly2 <= blank_dly;            -- to 3rd stage
      burst_dly2 <= burst_dly;            -- to 3rd stage

      -----------------
      -----------------
      -- Third stage --
      -----------------
      -----------------
      
      -- Copy Y
      comp_Y3 <= comp_Y2(16 DOWNTO 7);

      -- Phase and amplitude for U,V
      sign_U <= comp_pU(17);
      sign_V <= comp_pV(17) XOR (vpos_lsb AND (NOT pal_ntsc));
      IF (comp_pU(17) = '1') THEN
        ampl_U <= comp_mU(16 DOWNTO 9);
      ELSE
        ampl_U <= comp_pU(16 DOWNTO 9);
      END IF;
      IF (comp_pV(17) = '1') THEN
        ampl_V <= comp_mV(16 DOWNTO 9);
      ELSE
        ampl_V <= comp_pV(16 DOWNTO 9);
      END IF;

      -- Color carrier phase
      IF (sof_dly(1) = '1') THEN
        col_ctr <= (OTHERS => '0');
      ELSE
        -- +4 for NTSC, +5 for PAL
        col_ctr <= col_ctr + ("0010" & (NOT pal_ntsc));
      END IF;

      blank_dly3 <= blank_dly2;            -- to 4th stage
      burst_dly3 <= burst_dly2;            -- to 4th stage

      ------------------
      ------------------
      -- Fourth stage --
      ------------------
      ------------------
      
      -- Copy Y
      comp_Y4 <= comp_Y3;
      blank_dly4 <= blank_dly3;            -- to 5th stage
      burst_dly4 <= burst_dly3;            -- to 5th stage

      -----------------
      -----------------
      -- Fifth stage --
      -----------------
      -----------------

      -- Y/C signal
      chroma_tmp := comp_U + comp_V;
      IF ((blank_dly4 = '1' and burst_dly4 = '0') or csync_dly4 = '0') then
        chroma_tmp := (others=>'0');
      END IF;
      IF (comp_n = '1') THEN
        luma <= comp_Y4;
        chroma <= chroma_tmp;
      else
        if (chroma_tmp(8)='1') then
          assert ((comp_Y4 > ('0' & not(chroma_tmp(8 DOWNTO 0))))) report "luma underflow! luma:"&integer'image(conv_integer(unsigned(comp_Y4)))&" chroma:"&integer'image(conv_integer(signed(chroma_tmp))) severity failure;
	elsif (chroma_tmp(8)='0') then
          assert ((not(comp_Y4) > ('0' & chroma_tmp(8 DOWNTO 0)))) report "luma overflow! luma:"&integer'image(conv_integer(unsigned(comp_Y4)))&" chroma:"&integer'image(conv_integer(signed(chroma_tmp))) severity failure;
        end if;
	luma <= comp_Y4 + (chroma_tmp(8) & chroma_tmp(8 DOWNTO 0));
        chroma <= chroma_tmp; -- TODO, remove me and make others=>0
      end if;

    END IF;

  END PROCESS;

  -----------------------------------
  -----------------------------------
  -- 4th stage : chroma modulation --
  -----------------------------------
  -----------------------------------

  tab_inst : sin_cos
  PORT MAP
  (
    clk                => ecs_clk,
    clk_ena            => '1',
    sin_ph(4)          => col_ctr(4) XOR sign_U,
    sin_ph(3 DOWNTO 0) => col_ctr(3 DOWNTO 0),
    sin_amp            => ampl_U,
    sin_out            => comp_U,
    cos_ph(4)          => col_ctr(4) XOR sign_V,
    cos_ph(3 DOWNTO 0) => col_ctr(3 DOWNTO 0),
    cos_amp            => ampl_V,
    cos_out            => comp_V
  );

  -----------------------------------
  -- high-speed DAC with dithering --
  -----------------------------------
  PROCESS
  (
    areset_n,   -- Global reset
    dac_clk,    -- DAC clock (114.545454 MHz)
    luma,       -- Luminance data
    chroma      -- Chrominance data
  )
  BEGIN
    IF (areset_n = '0') THEN
      luma_1     <= (OTHERS => '0');
      luma_2     <= (OTHERS => '0');
      luma_acc   <= (OTHERS => '0');
      chroma_1   <= (OTHERS => '0');
      chroma_2   <= (OTHERS => '0');
      chroma_acc <= (OTHERS => '0');
    ELSE
      IF (rising_edge(dac_clk)) THEN
        -- Clock domain crossing
        luma_1   <= luma;
        luma_2   <= luma_1;
        chroma_1 <= (NOT chroma(8)) & chroma(7 DOWNTO 1);
        chroma_2 <= chroma_1;
        -- First order delta-sigma
        luma_acc   <= luma_2; -- + ("00000000" & luma_acc(1 DOWNTO 0));
        chroma_acc <= chroma_2; -- + ("000000" & chroma_acc(1 DOWNTO 0));

      END IF;
    END IF;
  END PROCESS;

  -- Y/C outputs
  y_out <= luma_acc(9 DOWNTO 2);
  c_out <= chroma_acc(7 DOWNTO 2);

  -- delayed csync
  sync_n_out <= csync_dly4;

END rtl;
