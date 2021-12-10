--
-- Multicore 2 / Multicore 2+
--
-- Copyright (c) 2017-2020 - Victor Trucco
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
        


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.std_logic_unsigned.ALL;

entity top is
    port (
        -- Clocks
        clock_50_i         : in    std_logic;

        -- Buttons
        btn_n_i            : in    std_logic_vector(4 downto 1);

        -- SRAM
        sram_addr_o        : out   std_logic_vector(20 downto 0)   := (others => '0');
        sram_data_io       : inout std_logic_vector(7 downto 0)    := (others => 'Z');
        sram_we_n_o        : out   std_logic                               := '1';
        sram_oe_n_o        : out   std_logic                               := '1';

        -- SDRAM
        SDRAM_A            : out std_logic_vector(12 downto 0);
        SDRAM_DQ           : inout std_logic_vector(15 downto 0);

        SDRAM_BA           : out std_logic_vector(1 downto 0);
        SDRAM_DQMH         : out std_logic;
        SDRAM_DQML         : out std_logic;    

        SDRAM_nRAS         : out std_logic;
        SDRAM_nCAS         : out std_logic;
        SDRAM_CKE          : out std_logic;
        SDRAM_CLK          : out std_logic;
        SDRAM_nCS          : out std_logic;
        SDRAM_nWE          : out std_logic;
    
        -- PS2
        ps2_clk_io         : inout std_logic                        := 'Z';
        ps2_data_io        : inout std_logic                        := 'Z';
        ps2_mouse_clk_io   : inout std_logic                        := 'Z';
        ps2_mouse_data_io  : inout std_logic                        := 'Z';

        -- SD Card
        sd_cs_n_o          : out   std_logic                        := 'Z';
        sd_sclk_o          : out   std_logic                        := 'Z';
        sd_mosi_o          : out   std_logic                        := 'Z';
        sd_miso_i          : in    std_logic;

        -- Joysticks
        joy_clock_o        : out   std_logic;
        joy_load_o         : out   std_logic;
        joy_data_i         : in    std_logic;
        joy_p7_o           : out   std_logic                        := '1';

        -- Audio
        AUDIO_L             : out   std_logic                       := '0';
        AUDIO_R             : out   std_logic                       := '0';
        ear_i               : in    std_logic;
        mic_o               : out   std_logic                       := '0';

        -- VGA
        VGA_R               : out   std_logic_vector(4 downto 0)    := (others => '0');
        VGA_G               : out   std_logic_vector(4 downto 0)    := (others => '0');
        VGA_B               : out   std_logic_vector(4 downto 0)    := (others => '0');
        VGA_HS              : out   std_logic                       := '1';
        VGA_VS              : out   std_logic                       := '1';

        LED                 : out   std_logic                       := '1';-- 0 is led on

        --STM32
        stm_rx_o            : out std_logic     := 'Z'; -- stm RX pin, so, is OUT on the slave
        stm_tx_i            : in  std_logic     := 'Z'; -- stm TX pin, so, is IN on the slave
        stm_rst_o           : out std_logic     := 'Z'; -- '0' to hold the microcontroller reset line, to free the SD card
        
        SPI_SCK             : inout std_logic   := 'Z';
        SPI_DO              : inout std_logic   := 'Z';
        SPI_DI              : inout std_logic   := 'Z';
        SPI_SS2             : inout std_logic   := 'Z';
        SPI_nWAIT           : out   std_logic   := '1';

        GPIO                : inout std_logic_vector(31 downto 0)   := (others => 'Z')
    );
end entity;

architecture Behavior of top is

    type config_array is array(natural range 15 downto 0) of std_logic_vector(7 downto 0);

    function to_slv(s: string) return std_logic_vector is 
        constant ss: string(1 to s'length) := s; 
        variable answer: std_logic_vector(1 to 8 * s'length); 
        variable p: integer; 
        variable c: integer; 
    begin 
        for i in ss'range loop
            p := 8 * i;
            c := character'pos(ss(i));
            answer(p - 7 to p) := std_logic_vector(to_unsigned(c,8)); 
        end loop; 
        return answer; 
    end function; 

    component vga is
    port
    (
        -- pixel clock
        pclk            : in std_logic;

        -- enable/disable scanlines
        scanlines   : in std_logic;
        
        -- output to VGA screen
        hs  : out std_logic;
        vs  : out std_logic;
        r   : out std_logic_vector(3 downto 0);
        g   : out std_logic_vector(3 downto 0);
        b   : out std_logic_vector(3 downto 0);
        blank : out std_logic
        
        --debug
        --joy_i : in std_logic_vector(11 downto 0)
    );
    end component;
    
    component osd_mc2 is
    generic
    (
        OSD_VISIBLE     : std_logic_vector(1 downto 0) := (others=>'0');
        OSD_X_OFFSET    : std_logic_vector(9 downto 0) := (others=>'0');
        OSD_Y_OFFSET    : std_logic_vector(9 downto 0) := (others=>'0');
        OSD_COLOR       : std_logic_vector(2 downto 0) := (others=>'0')
    );
    port
    (
        -- OSDs pixel clock, should be synchronous to cores pixel clock to
        -- avoid jitter.
        pclk        : in std_logic;

        -- SPI interface
        sck     : in std_logic;
        ss          : in std_logic;
        sdi     : in std_logic;
        sdo     : out std_logic;

        -- VGA signals coming from core
        red_in  : in std_logic_vector(4 downto 0);
        green_in : in std_logic_vector(4 downto 0);
        blue_in     : in std_logic_vector(4 downto 0);
        hs_in       : in std_logic;
        vs_in       : in std_logic;
        
        -- VGA signals going to video connector
        red_out : out std_logic_vector(4 downto 0);
        green_out: out std_logic_vector(4 downto 0);
        blue_out    : out std_logic_vector(4 downto 0);
        hs_out  : out std_logic;
        vs_out  : out std_logic;
        
        -- Data in
        data_in     : in std_logic_vector(7 downto 0);
        
        --data pump to sram
        pump_active_o   : out std_logic;
        sram_a_o            : out std_logic_vector(18 downto 0);
        sram_d_o            : out std_logic_vector(7 downto 0);
        sram_we_n_o     : out std_logic;
        config_buffer_o: out config_array
    
    );
    end component;
    
    component top_test_mc2p is
    port
    (
        auto_test_disabled  : in  std_logic;
        clk100              : in  std_logic;
        clk100n             : in  std_logic;
        clk25               : in  std_logic;
        pll_locked          : in  std_logic;
        
        sram_addr_o         : out std_logic_vector(20 downto 0);
        sram_data_io        : inout std_logic_vector(7 downto 0);
        sram_we_n_o         : out std_logic;
        sram_oe_n_o         : out std_logic;
            
        SDRAM_A             : out std_logic_vector(12 downto 0);
        SDRAM_BA            : out std_logic_vector(1 downto 0);
        SDRAM_DQ            : inout std_logic_vector(15 downto 0);
        SDRAM_DQMH          : out std_logic;
        SDRAM_DQML          : out std_logic;
        SDRAM_CKE           : out std_logic;
        SDRAM_nCS           : out std_logic;
        SDRAM_nWE           : out std_logic;
        SDRAM_nRAS          : out std_logic;
        SDRAM_nCAS          : out std_logic;
        SDRAM_CLK           : out std_logic;

        ps2_clk_io          : inout std_logic;
        ps2_data_io         : inout std_logic;
        ps2_mouse_clk_io    : inout std_logic;
        ps2_mouse_data_io   : inout std_logic;

        sd_cs_n_o           : out std_logic;
        sd_sclk_o           : out std_logic;
        sd_mosi_o           : out std_logic;
        sd_miso_i           : in  std_logic;

        joy1_up_i           : inout std_logic;
        joy1_down_i         : inout std_logic;
        joy1_left_i         : in  std_logic;
        joy1_right_i        : in  std_logic;
        joy1_p6_i           : in  std_logic;
        joy1_p9_i           : in  std_logic;
        joy2_up_i           : inout std_logic;
        joy2_down_i         : inout std_logic;
        joy2_left_i         : in  std_logic;
        joy2_right_i        : in  std_logic;
        joy2_p6_i           : in  std_logic;
        joy2_p9_i           : in  std_logic;
        joyX_p7_o           : out std_logic;

        AUDIO_L             : out std_logic;
        AUDIO_R             : out std_logic;

        VGA_R               : out std_logic_vector(4 downto 0);
        VGA_G               : out std_logic_vector(4 downto 0);
        VGA_B               : out std_logic_vector(4 downto 0);
        VGA_HS              : out std_logic;
        VGA_VS              : out std_logic;
        VGA_BLANK           : out std_logic;
        
        stm_rst_o           : out std_logic
    );
    end component;

    component joystick_serial is
    port
    (
        clk_i           : in  std_logic;
        clk_en          : in  std_logic;
        joy_data_i      : in  std_logic;
        joy_clk_o       : out  std_logic;
        joy_load_o      : out  std_logic;

        joy1_up_o       : out std_logic;
        joy1_down_o     : out std_logic;
        joy1_left_o     : out std_logic;
        joy1_right_o    : out std_logic;
        joy1_fire1_o    : out std_logic;
        joy1_fire2_o    : out std_logic;
        joy2_up_o       : out std_logic;
        joy2_down_o     : out std_logic;
        joy2_left_o     : out std_logic;
        joy2_right_o    : out std_logic;
        joy2_fire1_o    : out std_logic;
        joy2_fire2_o    : out std_logic
    );
    end component;

    -- clocks
    signal clk100               : std_logic;        
    signal clk100n              : std_logic;    
    signal pll_locked           : std_logic;    
    signal pixel_clock      : std_logic;        
    signal clk_dvi              : std_logic;        
    signal pMemClk              : std_logic;        
    signal clock_div_q      : unsigned(7 downto 0)              := (others => '0'); 
    
    -- Reset 
    signal reset_s              : std_logic;        -- Reset geral  
    signal power_on_s           : std_logic_vector(7 downto 0)  := (others => '1');
    signal btn_reset_s      : std_logic;
    
    -- Video
    signal video_r_s                : std_logic_vector(3 downto 0)  := (others => '0');
    signal video_g_s                : std_logic_vector(3 downto 0)  := (others => '0');
    signal video_b_s                : std_logic_vector(3 downto 0)  := (others => '0');
    signal video_hsync_n_s      : std_logic                             := '1';
    signal video_vsync_n_s      : std_logic                             := '1';
    
    signal osd_r_s              : std_logic_vector(3 downto 0)  := (others => '0');
    signal osd_g_s              : std_logic_vector(3 downto 0)  := (others => '0');
    signal osd_b_s              : std_logic_vector(3 downto 0)  := (others => '0');

    signal info_r_s             : std_logic_vector(3 downto 0)  := (others => '0');
    signal info_g_s             : std_logic_vector(3 downto 0)  := (others => '0');
    signal info_b_s             : std_logic_vector(3 downto 0)  := (others => '0');
    
    -- VGA
    signal vga_r_s              : std_logic_vector( 3 downto 0);
    signal vga_g_s              : std_logic_vector( 3 downto 0);
    signal vga_b_s              : std_logic_vector( 3 downto 0);
    signal vga_hsync_n_s        : std_logic;
    signal vga_vsync_n_s        : std_logic;
    signal vga_blank_s          : std_logic;

    -- HDMI
    signal tdms_r_s         : std_logic_vector( 9 downto 0);
    signal tdms_g_s         : std_logic_vector( 9 downto 0);
    signal tdms_b_s         : std_logic_vector( 9 downto 0);
    signal hdmi_p_s         : std_logic_vector( 3 downto 0);
    signal hdmi_n_s         : std_logic_vector( 3 downto 0);
    
    -- Keyboard
    signal keys_s           : std_logic_vector( 7 downto 0) := (others => '1'); 
    signal FKeys_s          : std_logic_vector(12 downto 1);
    
    -- joystick
    signal joy1_s           : std_logic_vector(15 downto 0) := (others => '1'); 
    signal joy2_s           : std_logic_vector(15 downto 0) := (others => '1'); 
    signal joyP7_s          : std_logic;

    signal joy1_in_s        : std_logic_vector(5 downto 0) := (others => '1'); 
    signal joy2_in_s        : std_logic_vector(5 downto 0) := (others => '1'); 
    
    -- config string
    constant STRLEN     : integer := 1;
--  constant CONF_STR       : std_logic_vector((STRLEN * 8)-1 downto 0) := to_slv("P,config.ini");
    constant CONF_STR       : std_logic_vector(7 downto 0) := X"00";
    
    signal config_buffer_s : config_array;
    
    -- keyboard
    signal kbd_intr      : std_logic;
    signal kbd_scancode  : std_logic_vector(7 downto 0);
    
    
    signal HDMI_R  : std_logic_vector(7 downto 0);
    signal HDMI_G  : std_logic_vector(7 downto 0);
    signal HDMI_B  : std_logic_vector(7 downto 0);
    signal HDMI_HS : std_logic;
    signal HDMI_VS : std_logic;
    signal HDMI_BL : std_logic;
                
    ----------------------------------
    
    -- auto test

    signal auto_test_disabled : std_logic := '1';
    signal btn_mode_s : std_logic;
    
    signal test_vga_r_s     : std_logic_vector(4 downto 0);
    signal test_vga_g_s     : std_logic_vector(4 downto 0);
    signal test_vga_b_s  : std_logic_vector(4 downto 0);
    signal test_vga_hs_s : std_logic;
    signal test_vga_vs_s : std_logic;
    signal test_vga_blank_s : std_logic;

    signal test_audiol_s : std_logic;
    signal test_audior_s : std_logic;
        
    signal test_joyp7_s : std_logic;
    signal menu_joyp7_s : std_logic;

        
begin   


    joystick_serial1 : joystick_serial 
    port map
    (
        clk_i           => pixel_clock,
        clk_en          => clock_div_q(1),
        joy_data_i      => joy_data_i,
        joy_clk_o       => joy_clock_o,
        joy_load_o      => joy_load_o,

        joy1_up_o       => joy1_in_s(0),
        joy1_down_o     => joy1_in_s(1),
        joy1_left_o     => joy1_in_s(2),
        joy1_right_o    => joy1_in_s(3),
        joy1_fire1_o    => joy1_in_s(4),
        joy1_fire2_o    => joy1_in_s(5),

        joy2_up_o       => joy2_in_s(0),
        joy2_down_o     => joy2_in_s(1),
        joy2_left_o     => joy2_in_s(2),
        joy2_right_o    => joy2_in_s(3),
        joy2_fire1_o    => joy2_in_s(4),
        joy2_fire2_o    => joy2_in_s(5)
    );
    

    btnscl: entity work.debounce
    generic map (
        counter_size    => 16
    )
    port map (
        clk_i               => pixel_clock,
        button_i            => btn_n_i(1) and btn_n_i(2) and btn_n_i(3),
        result_o            => btn_reset_s
    );
    

    process (pixel_clock)
    begin
        if rising_edge(pixel_clock) then
        
            if btn_reset_s = '0' then
                power_on_s <= (others=>'1');
            end if;
            
            if power_on_s /= x"00" then
                reset_s <= '1';
                stm_rst_o <= '0';
                power_on_s <= power_on_s - 1;
            else
                reset_s <= '0';
                stm_rst_o <= 'Z';
            end if;
            
        end if;
    end process;
  
    U00 : work.pll
      port map(
        inclk0   => clock_50_i,              
        c0       => pixel_clock,             -- 25.200Mhz
        c1       => clk_dvi,                 -- 126 MHz
        c2       => clk100,
        c3       => clk100n,
        locked   => pll_locked
      );

    --generate a black screen with proper sync VGA timing
    vga1 : vga 
    port map
    (
        pclk     => pixel_clock,

        scanlines => '0',
        
        hs      => video_hsync_n_s,
        vs      => video_vsync_n_s,
        r       => video_r_s,
        g       => video_g_s,
        b       => video_b_s,
        blank   => vga_blank_s
        
    );
      

    osd1 : osd_mc2 
    generic map
    (   
        --STRLEN => STRLEN,
        OSD_VISIBLE => "01",
        OSD_COLOR => "001", -- RGB
        OSD_X_OFFSET => "0000010010", -- 50
        OSD_Y_OFFSET => "0000001111"  -- 15
    )
    port map
    (
        pclk        => pixel_clock,

        -- spi for OSD
        sdi        => SPI_DI,
        sck        => SPI_SCK,
        ss         => SPI_SS2,
        sdo        => SPI_DO,
        
        red_in     => video_r_s & '0',
        green_in   => video_g_s & '0',
        blue_in    => video_b_s & '0',
        hs_in      => video_hsync_n_s,
        vs_in      => video_vsync_n_s,

        red_out(4 downto 1)    => osd_r_s,
        green_out(4 downto 1)  => osd_g_s,
        blue_out(4 downto 1)   => osd_b_s,
        hs_out     => vga_hsync_n_s,
        vs_out     => vga_vsync_n_s ,

        data_in     => keys_s,
    --  conf_str        => CONF_STR,
        
        config_buffer_o=> config_buffer_s
    );
   
    info1 : work.core_info 
    generic map
    (
        xOffset => 380,
        yOffset => 408
    )
    port map
    (
        clk_i   => pixel_clock,
        
        r_i         => osd_r_s,
        g_i         => osd_g_s,
        b_i         => osd_b_s,
        hSync_i     => vga_hsync_n_s,
        vSync_i     => vga_vsync_n_s ,

        r_o         => info_r_s,
        g_o         => info_g_s,
        b_o         => info_b_s,
        
        core_char1_s => "000001",  -- V 1.07 for the core
        core_char2_s => "000000",
        core_char3_s => "000111",

        stm_char1_s => unsigned(config_buffer_s(0)(5 downto 0)),    
        stm_char2_s => unsigned(config_buffer_s(1)(5 downto 0)),
        stm_char3_s => unsigned(config_buffer_s(2)(5 downto 0))
    );
    
    info2 : work.core_copyright
    generic map
    (
        xOffset => 320,
        yOffset => 420,
        Multicore2p => true
    )
    port map
    (
        clk_i       => pixel_clock,
        
        r_i         => info_r_s,
        g_i         => info_g_s,
        b_i         => info_b_s,
        hSync_i     => vga_hsync_n_s,
        vSync_i     => vga_vsync_n_s ,

        r_o         => vga_r_s,
        g_o         => vga_g_s,
        b_o         => vga_b_s
    );
              

    
--  kb: entity work.ps2keyb
--  port map (
--      enable_i            => '1',
--      clock_i         => pixel_clock,
--      clock_ps2_i     => clock_div_q(1),
--      reset_i         => reset_s,
--      --
--      ps2_clk_io      => ps2_clk_io,
--      ps2_data_io     => ps2_data_io,
--      --
--      keys_o          => keys_s,
--      functionkeys_o  => FKeys_s
--
--  );
--  

    -- Keyboard clock
    process(pixel_clock)
    begin
        if rising_edge(pixel_clock) then 
            clock_div_q <= clock_div_q + 1;
        end if;
    end process;
    
    -- get scancode from keyboard
    keyboard : entity work.io_ps2_keyboard
    port map (
      clk       => clock_div_q(1),
      clk_en    => clock_div_q(1),
      kbd_clk   => ps2_clk_io,
      kbd_dat   => ps2_data_io,
      interrupt => kbd_intr,
      scancode  => kbd_scancode
    );

    -- translate scancode to joystick
    joystick : entity work.kbd_joystick
    generic map 
    (
        osd_cmd     => "111",
        CLK_SPEED   => 6300
    )
    port map 
    (
        clk         => clock_div_q(1),
        kbdint      => kbd_intr,
        kbdscancode => std_logic_vector(kbd_scancode), 
        osd_o       => keys_s,
        osd_enable  => '1',

        -- 1,2,u,d,l,r   
        joystick_0  => joy1_in_s(4) & joy1_in_s(5) & joy1_in_s(0) & joy1_in_s(1) & joy1_in_s(2) & joy1_in_s(3),
        joystick_1  => joy2_in_s(4) & joy2_in_s(5) & joy2_in_s(0) & joy2_in_s(1) & joy2_in_s(2) & joy2_in_s(3),

        -- joystick_0 and joystick_1 should be swapped
        joyswap         => '0',

        -- player1 and player2 should get both joystick_0 and joystick_1
        oneplayer   => '1',

        -- tilt, coin4-1, start4-1
        controls   => open,

        -- fire12-1, up, down, left, right

        player1    => joy1_s,
        player2    => joy2_s,

        -- sega joystick
        sega_strobe => menu_joyp7_s 
    );


    
    ---------
        
        
    btnmode: entity work.debounce
    generic map (
        counter_size    => 16
    )
    port map (
        clk_i               => pixel_clock,
        button_i            => not btn_n_i(4),
        result_o            => btn_mode_s
    );
    
    process (btn_mode_s)
    begin
        if rising_edge(btn_mode_s) then
            auto_test_disabled <= not auto_test_disabled;
        end if;
    
    end process;
        
        process(pixel_clock)
        begin
            if auto_test_disabled = '1' then
                VGA_R       <= vga_r_s & '0';
                VGA_G       <= vga_g_s & '0';
                VGA_B       <= vga_b_s & '0';
                VGA_HS      <= vga_hsync_n_s;
                VGA_VS      <= vga_vsync_n_s;
                
                HDMI_R      <= vga_r_s & vga_r_s;
                HDMI_G      <= vga_g_s & vga_g_s;
                HDMI_B      <= vga_b_s & vga_b_s;
                HDMI_HS     <= vga_hsync_n_s;
                HDMI_VS     <= vga_vsync_n_s;
                HDMI_BL     <= vga_blank_s;
                
                AUDIO_L     <= '0';
                AUDIO_R     <= '0';
                stm_rst_o   <= 'Z';
                joy_p7_o    <= menu_joyp7_s;
            else
                VGA_R       <= test_vga_r_s;
                VGA_G       <= test_vga_g_s;
                VGA_B       <= test_vga_b_s;
                VGA_HS      <= test_vga_hs_s;
                VGA_VS      <= test_vga_vs_s;
                
                HDMI_R      <= test_vga_r_s & test_vga_r_s(4 downto 2);
                HDMI_G      <= test_vga_g_s & test_vga_g_s(4 downto 2);
                HDMI_B      <= test_vga_b_s & test_vga_b_s(4 downto 2);
                HDMI_HS     <= test_vga_hs_s;
                HDMI_VS     <= test_vga_vs_s;
                HDMI_BL     <= test_vga_blank_s;
            
                AUDIO_L     <= test_audiol_s;
                AUDIO_R     <= test_audior_s;
                stm_rst_o   <= '0';
                joy_p7_o    <= test_joyp7_s;
            end if;
        
        end process;
        
-----------------------------------------------------       
------------- AUTO TEST -----------------------------

    autotest : top_test_mc2p 
    port map
    (
        auto_test_disabled  => auto_test_disabled,
        clk100              => clk100,
        clk100n             => clk100n,
        clk25               => pixel_clock, 
        pll_locked          => pll_locked,

        sram_addr_o         => sram_addr_o,
        sram_data_io        => sram_data_io,
        sram_we_n_o         => sram_we_n_o,
        sram_oe_n_o         => sram_oe_n_o, 
                                
        SDRAM_A             => SDRAM_A,     
        SDRAM_BA            => SDRAM_BA,        
        SDRAM_DQ            => SDRAM_DQ,    
        SDRAM_DQMH          => SDRAM_DQMH,  
        SDRAM_DQML          => SDRAM_DQML,  
        SDRAM_CKE           => SDRAM_CKE,   
        SDRAM_nCS           => SDRAM_nCS,   
        SDRAM_nWE           => SDRAM_nWE,   
        SDRAM_nRAS          => SDRAM_nRAS,  
        SDRAM_nCAS          => SDRAM_nCAS,  
        SDRAM_CLK           => SDRAM_CLK,   

        ps2_clk_io          => ps2_clk_io,
        ps2_data_io         => ps2_data_io,
        ps2_mouse_clk_io    => ps2_mouse_clk_io,
        ps2_mouse_data_io   => ps2_mouse_data_io,

        sd_cs_n_o           => sd_cs_n_o,
        sd_sclk_o           => sd_sclk_o,
        sd_mosi_o           => sd_mosi_o,
        sd_miso_i           => sd_miso_i,

        joy1_up_i           => joy1_in_s(0),
        joy1_down_i         => joy1_in_s(1),
        joy1_left_i         => joy1_in_s(2),
        joy1_right_i        => joy1_in_s(3),
        joy1_p6_i           => joy1_in_s(4),
        joy1_p9_i           => joy1_in_s(5),
        joy2_up_i           => joy2_in_s(0),
        joy2_down_i         => joy2_in_s(1),
        joy2_left_i         => joy2_in_s(2),
        joy2_right_i        => joy2_in_s(3),
        joy2_p6_i           => joy2_in_s(4),
        joy2_p9_i           => joy2_in_s(5),
        joyX_p7_o           => test_joyp7_s,

        AUDIO_L             => test_audiol_s,
        AUDIO_R             => test_audior_s,

        VGA_R               => test_vga_r_s,
        VGA_G               => test_vga_g_s,
        VGA_B               => test_vga_b_s,
        VGA_HS              => test_vga_hs_s,
        VGA_VS              => test_vga_vs_s,
        VGA_BLANK           => test_vga_blank_s,
        stm_rst_o           => open
    );


        


end architecture;
