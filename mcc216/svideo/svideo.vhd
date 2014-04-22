-- ===================================================================================
-- Package / Component definition
-- ===================================================================================

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

PACKAGE svideo_pkg IS
  COMPONENT svideo
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
    -- S-Video output
    y_out       : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    c_out       : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
    -- PAL(0)/NTSC(1) mode
    pal_ntsc    : IN  STD_LOGIC
  );
  END COMPONENT;

END PACKAGE;

-- ===================================================================================
-- Entity / Architecture definition
-- ===================================================================================

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
LIBRARY WORK;
USE WORK.SIN_COS_PKG.ALL;

ENTITY svideo IS
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
    -- S-Video output
    y_out       : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    c_out       : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
    -- PAL(0)/NTSC(1) mode
    pal_ntsc    : IN  STD_LOGIC
  );
END svideo;

ARCHITECTURE rtl OF svideo IS

  -- Color carrier phase (0 - 31)
  SIGNAL   col_ctr      : STD_LOGIC_VECTOR(4 DOWNTO 0);

  -------------------------
  -- RGB -> Y conversion --
  -------------------------
  -- 1st stage
  SIGNAL   comp_YR      : UNSIGNED(16 DOWNTO 0);
  SIGNAL   comp_YG      : UNSIGNED(16 DOWNTO 0);
  SIGNAL   comp_YB      : UNSIGNED(16 DOWNTO 0);
  SIGNAL   comp_Y2      : STD_LOGIC_VECTOR(16 DOWNTO 0);
  SIGNAL   comp_Y3      : STD_LOGIC_VECTOR(9 DOWNTO 0);
  SIGNAL   comp_Y4      : STD_LOGIC_VECTOR(9 DOWNTO 0);

  CONSTANT Y_LVL_SYNC   : STD_LOGIC_VECTOR(16 DOWNTO 0) := "00000000000000000";
  CONSTANT Y_LVL_BLANK  : STD_LOGIC_VECTOR(16 DOWNTO 0) := "01110011000000000";
  CONSTANT Y_LVL_PICT   : STD_LOGIC_VECTOR(16 DOWNTO 0) := "01110011000000000";

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
  SIGNAL   burst_dly    : STD_LOGIC;
  SIGNAL   csync_dly    : STD_LOGIC;
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
  BEGIN
    IF (areset_n = '0') THEN
      -- Color carrier phase
      col_ctr <= (OTHERS => '0');
      -- Y component
      comp_YR <= (OTHERS => '0');
      comp_YG <= (OTHERS => '0');
      comp_YB <= (OTHERS => '0');
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
      comp_YR <= "001010100" * unsigned(r_in);
      comp_YG <= "010100100" * unsigned(g_in);
      comp_YB <= "000100000" * unsigned(b_in);

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
      ELSIF (blank_dly = '1') THEN
        -- Blanking level
        comp_Y2 <= Y_LVL_BLANK;
      ELSE
        -- Picture level
        comp_Y2 <= std_logic_vector(comp_YR)
                 + std_logic_vector(comp_YG)
                 + std_logic_vector(comp_YB)
                 + Y_LVL_PICT;
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

      ------------------
      ------------------
      -- Fourth stage --
      ------------------
      ------------------
      
      -- Copy Y
      comp_Y4 <= comp_Y3;

      -----------------
      -----------------
      -- Fifth stage --
      -----------------
      -----------------

      -- Y/C signal
      luma <= comp_Y4;
      chroma <= comp_U + comp_V;

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
  -- High-speed DAC with dithering --
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
        luma_acc   <= luma_2 + ("00000000" & luma_acc(1 DOWNTO 0));
        chroma_acc <= chroma_2 + ("000000" & chroma_acc(1 DOWNTO 0));
      END IF;
    END IF;
  END PROCESS;
  -- Y/C outputs
  y_out <= luma_acc(9 DOWNTO 2);
  c_out <= chroma_acc(7 DOWNTO 2);

END rtl;
