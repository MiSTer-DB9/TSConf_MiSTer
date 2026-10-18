//============================================================================
//  TSConf for MiSTer
//
//  Port to MiSTer
//  Copyright (C) 2017-2019 Sorgelig
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//============================================================================

module emu
(
	//Master input clock
	input         CLK_50M,

	//Async reset from top-level module.
	//Can be used as initial reset.
	input         RESET,

	//Must be passed to hps_io module
	inout  [45:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        CLK_VIDEO,

	//Multiple resolutions are supported using different CE_PIXEL rates.
	//Must be based on CLK_VIDEO
	output        CE_PIXEL,

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	//if VIDEO_ARX[12] or VIDEO_ARY[12] is set then [11:0] contains scaled size instead of aspect ratio.
	output [12:0] VIDEO_ARX,
	output [12:0] VIDEO_ARY,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,
	output [1:0]  VGA_SL,
	output        VGA_SCALER, // Force VGA scaler
	output        VGA_DISABLE, // analog out is off

	input  [11:0] HDMI_WIDTH,
	input  [11:0] HDMI_HEIGHT,
	output        HDMI_FREEZE,
	output        HDMI_BLACKOUT,
	output        HDMI_BOB_DEINT,

`ifdef MISTER_FB
	// Use framebuffer in DDRAM
	// FB_FORMAT:
	//    [2:0] : 011=8bpp(palette) 100=16bpp 101=24bpp 110=32bpp
	//    [3]   : 0=16bits 565 1=16bits 1555
	//    [4]   : 0=RGB  1=BGR (for 16/24/32 modes)
	//
	// FB_STRIDE either 0 (rounded to 256 bytes) or multiple of pixel size (in bytes)
	output        FB_EN,
	output  [4:0] FB_FORMAT,
	output [11:0] FB_WIDTH,
	output [11:0] FB_HEIGHT,
	output [31:0] FB_BASE,
	output [13:0] FB_STRIDE,
	input         FB_VBL,
	input         FB_LL,
	output        FB_FORCE_BLANK,

`ifdef MISTER_FB_PALETTE
	// Palette control for 8bit modes.
	// Ignored for other video modes.
	output        FB_PAL_CLK,
	output  [7:0] FB_PAL_ADDR,
	output [23:0] FB_PAL_DOUT,
	input  [23:0] FB_PAL_DIN,
	output        FB_PAL_WR,
`endif
`endif

	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	// I/O board button press simulation (active high)
	// b[1]: user button
	// b[0]: osd button
	output  [1:0] BUTTONS,

	input         CLK_AUDIO, // 24.576 MHz
	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S,   // 1 - signed audio samples, 0 - unsigned
	output  [1:0] AUDIO_MIX, // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)

	//ADC
	inout   [3:0] ADC_BUS,

	//SD-SPI
	output        SD_SCK,
	output        SD_MOSI,
	input         SD_MISO,
	output        SD_CS,
	input         SD_CD,

	//High latency DDR3 RAM interface
	//Use for non-critical time purposes
	output        DDRAM_CLK,
	input         DDRAM_BUSY,
	output  [7:0] DDRAM_BURSTCNT,
	output [28:0] DDRAM_ADDR,
	input  [63:0] DDRAM_DOUT,
	input         DDRAM_DOUT_READY,
	output        DDRAM_RD,
	output [63:0] DDRAM_DIN,
	output  [7:0] DDRAM_BE,
	output        DDRAM_WE,

	//SDRAM interface with lower latency
	output        SDRAM_CLK,
	output        SDRAM_CKE,
	output [12:0] SDRAM_A,
	output  [1:0] SDRAM_BA,
	inout  [15:0] SDRAM_DQ,
	output        SDRAM_DQML,
	output        SDRAM_DQMH,
	output        SDRAM_nCS,
	output        SDRAM_nCAS,
	output        SDRAM_nRAS,
	output        SDRAM_nWE,

`ifdef MISTER_DUAL_SDRAM
	//Secondary SDRAM
	//Set all output SDRAM_* signals to Z ASAP if SDRAM2_EN is 0
	input         SDRAM2_EN,
	output        SDRAM2_CLK,
	output [12:0] SDRAM2_A,
	output  [1:0] SDRAM2_BA,
	inout  [15:0] SDRAM2_DQ,
	output        SDRAM2_nCS,
	output        SDRAM2_nCAS,
	output        SDRAM2_nRAS,
	output        SDRAM2_nWE,
`endif

	input         UART_CTS,
	output        UART_RTS,
	input         UART_RXD,
	output        UART_TXD,
	output        UART_DTR,
	input         UART_DSR,

	// Open-drain User port.
	// 0 - D+/RX
	// 1 - D-/TX
	// 2..6 - USR2..USR6
	// Set USER_OUT to 1 to read from USER_IN.
	// [MiSTer-DB9 BEGIN] - DB9/SNAC8 support: USER_OSD + per-pin push-pull mask, USER_IO widened to 8 bits
	output        USER_OSD,
	output  [7:0] USER_PP,
	input   [7:0] USER_IN,
	output  [7:0] USER_OUT,
	// [MiSTer-DB9 END]

	input         OSD_STATUS
);

assign ADC_BUS     = 'Z;
// [MiSTer-DB9 BEGIN] - DB9/SNAC8 support: USER_PP driven by wrapper; USER_OUT driven by joydb (USER_OUT_DRIVE) below
assign USER_PP = USER_PP_DRIVE;
// [MiSTer-DB9 END]
assign VGA_F1      = 0;
assign UART_RTS    = 0;
assign UART_DTR    = 0;
assign LED_POWER   = 0;
assign BUTTONS     = 0;
assign VGA_SCALER  = 0;
assign VGA_DISABLE = 0;
assign HDMI_FREEZE = 0;
assign HDMI_BLACKOUT = 0;
assign HDMI_BOB_DEINT = 0;

`ifdef MISTER_FB
assign FB_EN          = 0;
assign FB_FORMAT      = 0;
assign FB_WIDTH       = 0;
assign FB_HEIGHT      = 0;
assign FB_BASE        = 0;
assign FB_STRIDE      = 0;
assign FB_FORCE_BLANK = 0;
`ifdef MISTER_FB_PALETTE
assign FB_PAL_CLK  = 0;
assign FB_PAL_ADDR = 0;
assign FB_PAL_DOUT = 0;
assign FB_PAL_WR   = 0;
`endif
`endif

`ifdef MISTER_DUAL_SDRAM
assign SDRAM2_CLK  = 1'b0;
assign SDRAM2_A    = 'Z;
assign SDRAM2_BA   = 'Z;
assign SDRAM2_DQ   = 'Z;
assign SDRAM2_nCS  = 1'b1;
assign SDRAM2_nCAS = 1'b1;
assign SDRAM2_nRAS = 1'b1;
assign SDRAM2_nWE  = 1'b1;
`endif

`include "build_id.v"
localparam CONF_STR = {
	"TSConf;",
	"UART115200,MIDI;",
	"SC0,VHD,Mount SD image;",
	"-;",
	"OFH,Joystick 1,Kempston,Sinclair 1,Sinclair 2,Cursor,QAOPM;",
	"OIK,Joystick 2,Kempston,Sinclair 1,Sinclair 2,Cursor,QAOPM;",
	"OB,Swap mouse buttons,OFF,ON;",
	"-;",
	"P2,Video;",
	"P2o01,Aspect ratio,Original,Full Screen,[ARC1],[ARC2];",
	"P2O12,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%;",
	"d0P2o2,Vertical Crop,Disabled,270p(5x);",
	"P2o34,Scale,Normal,V-Integer,Narrower HV-Integer,Wider HV-Integer;",
	"P2-;",
	"P2OC,Vsync,48.8 Hz,60 Hz;",
	"P2OD,VDAC1,ON,OFF;",
	"O34,Stereo mix,None,25%,50%,100%;",
	"O5,PSG panning,ABC,ACB;",
	"O6,Audio Boost,On,Off;",
	"-;",
	"OE,CPU Type,CMOS,NMOS;",
	"P1,NVRAM;",
	"P1o56,CPU Speed (MHz),3.5,7,14;",
	"P1o7,CPU Cache,ON,OFF;",
	"P1o89,#7FFD span,128K,128K Auto,1024K,512K;",
	"P1oAC,Reset to,BD boot.$C,BD sys.rom,ROM #00,ROM #04,RAM #F8;",
	"P1oDE,Reset bank,TR-DOS,Basic 48,Basic 128,SYS;",
	"P1oFH,CS Reset to,BD boot.$C,BD sys.rom,ROM #00,ROM #04,RAM #F8;",
	"P1oIJ,CS Reset bank,TR-DOS,Basic 48,Basic 128,SYS;",
	"P1oKM,Boot Device,SD Z-controller,IDE Nemo Master,IDE Nemo Slave,RS-232,IDE Smuc Master,IDE Smuc Slave,SD2 Z-controller;",
	"P1oNP,ZX Palette,Default,B.black,Light,Pale,Dark,Grayscale,Custom;",
	"P1oQ,NGS Reset,OFF,ON;",
	"P1oR,FT8xx Reset,OFF,ON;",
	"P1oSU,INT Offset,1,2,3,4,5,6,7,0;",
	"P1-;",
	"P1T7,Apply;",
	"-;",
	// [MiSTer-DB9-Pro BEGIN] - Saturn-first joy_type (canonical bit notation)
	"O[127:126],UserIO Joystick,Off,Saturn,DB9MD,DB15;",
	"O[125],UserIO Players, 1 Player,2 Players;",
	// [MiSTer-DB9-Pro END]
	"R0,Reset;",
	"J,Fire 1,Fire 2,Fire 3,Fire 4;",
	"jn,A,B,X,Y;",
	"jp,B,A,Y,X;",
	"v,2;",
	"V,v",`BUILD_DATE
};

wire [127:0] status;
wire [1:0] scale = status[2:1];
wire [2:0] cfg_joystick1 = status[17:15];
wire [2:0] cfg_joystick2 = status[20:18];
wire cfg_mouse_swap = status[11];
wire cfg_60hz = ~status[12];
wire cfg_vdac = ~status[13];
wire cfg_out0 = ~status[14];
wire cfg_turbosound_acb = status[5];
wire cfg_audio_boost = ~status[6];

wire [1:0] ar = status[33:32];
wire vcrop_en = status[34];
reg en270p;
always @(posedge CLK_VIDEO) begin
	en270p <= ((HDMI_WIDTH == 1920) && (HDMI_HEIGHT == 1080) && !forced_scandoubler && !scale);
end

wire vga_de;
video_freak video_freak
(
	.*,
	.VGA_DE_IN(vga_de),
	.ARX((!ar) ? 12'd4 : (ar - 1'd1)),
	.ARY((!ar) ? 12'd3 : 12'd0),
	.CROP_SIZE((en270p & vcrop_en) ? 10'd270 : 10'd0),
	.CROP_OFF(0),
	.SCALE(status[36:35])
);

////////////////////   CLOCKS   ///////////////////
wire clk_sys;
pll pll
(
	.refclk(CLK_50M),
	.rst(1'b0),
	.outclk_0(clk_sys),
	.outclk_1(CLK_VIDEO)
);

reg ce_28m;
always @(negedge clk_sys) begin
	reg [1:0] div = 2'd2;
	div <= div + 1'd1;
	if(div == 2) div <= 0;
	ce_28m <= !div;
end

// Platform-specific gated clock for the TSConf core. ce_28m is registered on
// the falling edge of clk_sys, so it is stable throughout each selected pulse.
wire fclk;
cyclonev_clkena fclk_clkena
(
	.inclk (clk_sys),
	.ena   (ce_28m),
	.enaout(),
	.outclk(fclk)
);
defparam
	fclk_clkena.clock_type = "Global Clock",
	fclk_clkena.ena_register_mode = "none",
	fclk_clkena.ena_register_power_up = "low";

//////////////////   HPS I/O   ///////////////////
wire [31:0] joy_0;
wire [31:0] joy_1;
wire [1:0] buttons;
wire [7:0] uart_mode;
wire [24:0] ps2_mouse;
wire [15:0] ps2_mouse_ext;
wire [10:0] ps2_key;
wire forced_scandoubler;
wire [21:0] gamma_bus;

wire [31:0] sd_lba;
wire sd_rd;
wire sd_wr;
wire sd_ack;
wire [8:0] sd_buff_addr;
wire [7:0] sd_buff_dout;
wire [7:0] sd_buff_din;
wire sd_buff_wr;
wire img_mounted;
wire img_readonly;
wire [63:0] img_size;
wire [64:0] RTC;

wire ioctl_wr;
wire [26:0] ioctl_addr;
wire [7:0] ioctl_dout;
wire ioctl_download;
wire [15:0] ioctl_index;

// [MiSTer-DB9 BEGIN] - DB9/SNAC8 support: joydb wrapper
wire         CLK_JOY = CLK_50M;                 // Assign clock between 40-50Mhz
wire   [1:0] joy_type_raw    = status[127:126]; // 0=Off, 1=Saturn, 2=DB9MD, 3=DB15
wire         joy_2p          = status[125];
// SNAC cores: replace 1'b0 with the core's SNAC enable expression so SNAC
// preempts the joydb wrapper on shared USER_IO pins. Default 1'b0 is no-op.
wire         snac_active     = 1'b0;
// MT32-pi cores on primary USER_IO: replace 1'b0 with the core's MT32-active
// expression (e.g. `mt32_use` under `ifndef SECOND_MT32`, `~mt32_disable` for
// TRS-80's inverted polarity). Suppresses the OSD-open autodetect probe so it
// doesn't read the RPi's I2C master traffic as a ghost Saturn signature.
wire         mt32_primary_active = 1'b0;
wire   [1:0] joy_type        = snac_active ? 2'd0 : joy_type_raw;
wire         joy_db9md_en    = (joy_type == 2'd2);
wire         joy_db15_en     = (joy_type == 2'd3);
wire         joy_any_en      = |joy_type;
// [MiSTer-DB9 END]

// [MiSTer-DB9-Pro BEGIN] - Saturn key gate
wire         saturn_unlocked;                   // driven by hps_io UIO_DB9_KEY (0xFE)
// [MiSTer-DB9-Pro END]

// [MiSTer-DB9 BEGIN] - DB9/SNAC8 support: joydb wrapper wires + instance
wire   [7:0] USER_OUT_DRIVE;
wire   [7:0] USER_PP_DRIVE;
wire  [15:0] joydb_1, joydb_2;
wire         joydb_1ena, joydb_2ena;
wire  [15:0] joy_raw_payload;
// Programmable-remap matrix (joydb_remap inside joydb): clk_sys carries the
// 0xFD selector load (HPS-bus domain). joydb_*_mapped are the MiSTer-standard
// joystick words the core consumes at its joy0_USB merge point. db9_remap_*
// are driven by the hps_io instance (see the .db9_remap_* bindings there).
// Until a core consumes joydb_*_mapped (Layer B), the matrix stays at identity
// and synthesis prunes it -- binding these is dormant + fleet-safe.
wire  [15:0] joydb_1_mapped, joydb_2_mapped;
wire         db9_remap_cmd;
wire   [5:0] db9_remap_byte_cnt;
wire  [15:0] db9_remap_din;

// [MiSTer-DB9 BEGIN] - DB9 remap factory default (used until Main_MiSTer streams UIO 0xFD)
// Derived from CONF_STR J1, same rule as db9_map.cpp; lets the core work on a stock MiSTer binary.
// DB15:  Fire 1=A, Fire 2=B, Fire 3=C, Fire 4=D
// DB9MD: Fire 1=A, Fire 2=B, Fire 3=C, Fire 4=X
wire  [35:0] db9_remap_default_db15  = 36'hFFFFF7654;
wire  [35:0] db9_remap_default_db9md = 36'hFFFFF7654;
// [MiSTer-DB9 END]
joydb joydb (
  .clk             ( CLK_JOY         ),
  .clk_sys         ( clk_sys            ),
  .USER_IN         ( USER_IN         ),
  .OSD_STATUS          ( OSD_STATUS          ),
  .snac_active         ( snac_active         ),
  .mt32_primary_active ( mt32_primary_active ),
  .joy_type        ( joy_type        ),
  .joy_2p          ( joy_2p          ),
  .saturn_unlocked ( saturn_unlocked ),
  .USER_OUT_DRIVE  ( USER_OUT_DRIVE  ),
  .USER_PP_DRIVE   ( USER_PP_DRIVE   ),
  .USER_OSD        ( USER_OSD        ),
  .joydb_1         ( joydb_1         ),
  .joydb_2         ( joydb_2         ),
  .joydb_1ena      ( joydb_1ena      ),
  .joydb_2ena      ( joydb_2ena      ),
  .remap_cmd       ( db9_remap_cmd      ),
  .remap_byte_cnt  ( db9_remap_byte_cnt ),
  .remap_din       ( db9_remap_din      ),
  .remap_default_db15  ( db9_remap_default_db15  ),
  .remap_default_db9md ( db9_remap_default_db9md ),
  .joydb_1_mapped  ( joydb_1_mapped     ),
  .joydb_2_mapped  ( joydb_2_mapped     ),
  .joy_raw         ( joy_raw_payload )
);

assign USER_OUT = USER_OUT_DRIVE;
// [MiSTer-DB9 END]

// [MiSTer-DB9 BEGIN] - DB9/SNAC8 support: rename USB joystick wires
wire [31:0] joystick_0_USB, joystick_1_USB;
// [MiSTer-DB9 END]

hps_io #(.CONF_STR(CONF_STR)) hps_io
(
	.clk_sys(clk_sys),
	.HPS_BUS(HPS_BUS),

	.joystick_0(joystick_0_USB),
	.joystick_1(joystick_1_USB),
	.buttons(buttons),
	.status(status),
	.uart_mode(uart_mode),
	.status_menumask({15'd0,en270p}),
	.forced_scandoubler(forced_scandoubler),
	.gamma_bus(gamma_bus),

	.RTC(RTC),
	.ps2_mouse(ps2_mouse),
	.ps2_mouse_ext(ps2_mouse_ext),
	.ps2_key(ps2_key),

	.sd_lba('{sd_lba}),
	.sd_rd(sd_rd),
	.sd_wr(sd_wr),
	.sd_ack(sd_ack),
	.sd_buff_addr(sd_buff_addr),
	.sd_buff_dout(sd_buff_dout),
	.sd_buff_din('{sd_buff_din}),
	.sd_buff_wr(sd_buff_wr),
	.img_mounted(img_mounted),
	.img_readonly(img_readonly),
	.img_size(img_size),

	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),
	.ioctl_download(ioctl_download),
	.ioctl_index(ioctl_index),
	.ioctl_wait(1'b0),
	// [MiSTer-DB9 BEGIN] - DB9/SNAC8 support: joy_raw
	.joy_raw(joy_raw_payload),
	// programmable remap matrix selector load (UIO_DB9_MAP 0xFD)
	.db9_remap_cmd(db9_remap_cmd),
	.db9_remap_byte_cnt(db9_remap_byte_cnt),
	.db9_remap_din(db9_remap_din),
	// [MiSTer-DB9 END]
	// [MiSTer-DB9-Pro BEGIN] - Saturn key gate
	.saturn_unlocked(saturn_unlocked)
	// [MiSTer-DB9-Pro END]
);

// [MiSTer-DB9-Pro BEGIN] - DB controllers muted while OSD is open
// joydb_*_mapped is already in MiSTer-standard J1 order, identical to the USB
// joystick word, so it replaces the USB input as-is.
wire [31:0] joy_0_mux = joydb_1ena ? (OSD_STATUS ? 16'b0 : joydb_1_mapped) : joystick_0_USB;
wire [31:0] joy_1_mux = joydb_2ena ? (OSD_STATUS ? 16'b0 : joydb_2_mapped) : joydb_1ena ? joystick_0_USB : joystick_1_USB;
// Registered once on clk_sys: the T80 reads joy_0 combinationally in the
// gated 28 MHz fclk domain, and the joydb (CLK_JOY) select mux on that path
// failed setup by about 12 ns.
reg  [31:0] joy_0_q, joy_1_q;
always @(posedge clk_sys) begin
	joy_0_q <= joy_0_mux;
	joy_1_q <= joy_1_mux;
end
assign joy_0 = joy_0_q;
assign joy_1 = joy_1_q;
// [MiSTer-DB9-Pro END]

wire mouse_b0 = cfg_mouse_swap ? ps2_mouse[1] : ps2_mouse[0];
wire mouse_b1 = cfg_mouse_swap ? ps2_mouse[0] : ps2_mouse[1];
wire [28:0] core_mouse = {
	ps2_mouse[24], ps2_mouse_ext[3:0], ps2_mouse[23:8],
	ps2_mouse[7:2], mouse_b1, mouse_b0
};

//////////////////    NVRAM    ///////////////////
// NVRAM settings mirror the BIOS table at CMOS addresses B1-BC. The options
// whose BIOS defaults aren't zero are reordered in the OSD and converted back
// to the values expected by ts-bios.asm.
wire [25:0] nvram_cfg = status[62:37];

function automatic [2:0] nvram_boot_target;
	input [2:0] option;
	begin
		case(option)
			3'd0: nvram_boot_target = 3'd3; // BD boot.$C
			3'd1: nvram_boot_target = 3'd4; // BD sys.rom
			3'd2: nvram_boot_target = 3'd0; // ROM #00
			3'd3: nvram_boot_target = 3'd1; // ROM #04
			default: nvram_boot_target = 3'd2; // RAM #F8
		endcase
	end
endfunction

function automatic [7:0] nvram_cfg_value;
	input [7:0] address;
	input [25:0] cfg;
	begin
		case(address)
			8'hB1: nvram_cfg_value = {6'd0, cfg[1:0]};
			8'hB2: nvram_cfg_value = {5'd0, cfg[17:15]};
			8'hB3: nvram_cfg_value = {7'd0, ~cfg[2]};
			8'hB4: nvram_cfg_value = {5'd0, nvram_boot_target(cfg[7:5])};
			8'hB5: nvram_cfg_value = {6'd0, cfg[9:8]};
			8'hB6: nvram_cfg_value = {5'd0, nvram_boot_target(cfg[12:10])};
			8'hB7: nvram_cfg_value = {6'd0, cfg[14:13]};
			8'hB8: nvram_cfg_value = {6'd0, cfg[4:3] + 2'd1};
			8'hB9: nvram_cfg_value = {5'd0, cfg[20:18]};
			8'hBA: nvram_cfg_value = {7'd0, cfg[21]};
			8'hBB: nvram_cfg_value = {7'd0, cfg[22]};
			8'hBC: nvram_cfg_value = {5'd0, cfg[25:23] + 3'd1};
			default: nvram_cfg_value = 8'd0;
		endcase
	end
endfunction

wire [7:0] nvram_data_out;

localparam [2:0] NVRAM_IDLE     = 3'd0;
localparam [2:0] NVRAM_ADDRESS  = 3'd1;
localparam [2:0] NVRAM_DATA     = 3'd2;
localparam [2:0] NVRAM_CRC_BITS = 3'd3;
localparam [2:0] NVRAM_CRC_LOW  = 3'd4;
localparam [2:0] NVRAM_CRC_HIGH = 3'd5;

reg [2:0] nvram_state = NVRAM_IDLE;
reg [7:0] nvram_address = 8'hB1;
reg [15:0] nvram_crc = 16'hFFFF;
reg [2:0] nvram_crc_bit;
reg [25:0] nvram_cfg_latched;
reg old_status_reset = 1'b0;
reg nvram_initial_load_pending = 1'b1;

wire nvram_initial_load_trigger = nvram_initial_load_pending && old_status_reset && !status[0];
wire nvram_load_trigger = nvram_initial_load_trigger || status[7];
wire nvram_update_active = nvram_initial_load_pending || (nvram_state != NVRAM_IDLE) || nvram_load_trigger;
wire nvram_address_is_cfg = (nvram_address >= 8'hB1) && (nvram_address <= 8'hBC);
wire [7:0] nvram_config_data = nvram_cfg_value(nvram_address, nvram_cfg_latched);
wire [7:0] nvram_crc_data = nvram_address_is_cfg ? nvram_config_data : nvram_data_out;
wire nvram_cmos_wr = ((nvram_state == NVRAM_DATA) && nvram_address_is_cfg) ||
	(nvram_state == NVRAM_CRC_LOW) || (nvram_state == NVRAM_CRC_HIGH);
wire [7:0] nvram_cmos_data =
	(nvram_state == NVRAM_CRC_LOW) ? nvram_crc[7:0] :
	(nvram_state == NVRAM_CRC_HIGH) ? nvram_crc[15:8] :
	nvram_config_data;

// BIOS calculates CRC over B1-E5 (B0/FDDVirt is intentionally excluded) and
// stores it little-endian at E6-E7. Keep the core in reset while updating so
// BIOS never observes a partially written configuration.
always @(posedge clk_sys) begin
	old_status_reset <= status[0];
	if(nvram_initial_load_trigger) nvram_initial_load_pending <= 1'b0;

	case(nvram_state)
		NVRAM_IDLE: begin
			if(nvram_load_trigger) begin
				nvram_cfg_latched <= nvram_cfg;
				nvram_address <= 8'hB1;
				nvram_crc <= 16'hFFFF;
				nvram_state <= NVRAM_ADDRESS;
			end
		end

		NVRAM_ADDRESS: nvram_state <= NVRAM_DATA;

		NVRAM_DATA: begin
			nvram_crc <= nvram_crc ^ {nvram_crc_data, 8'd0};
			nvram_crc_bit <= 3'd0;
			nvram_state <= NVRAM_CRC_BITS;
		end

		NVRAM_CRC_BITS: begin
			nvram_crc <= nvram_crc[15] ?
				({nvram_crc[14:0], 1'b0} ^ 16'h1021) : {nvram_crc[14:0], 1'b0};
			if(nvram_crc_bit == 3'd7) begin
				if(nvram_address == 8'hE5) begin
					nvram_address <= 8'hE6;
					nvram_state <= NVRAM_CRC_LOW;
				end
				else begin
					nvram_address <= nvram_address + 1'd1;
					nvram_state <= NVRAM_ADDRESS;
				end
			end
			else nvram_crc_bit <= nvram_crc_bit + 1'd1;
		end

		NVRAM_CRC_LOW: begin
			nvram_address <= 8'hE7;
			nvram_state <= NVRAM_CRC_HIGH;
		end

		NVRAM_CRC_HIGH: begin
			nvram_state <= NVRAM_IDLE;
		end

		default: nvram_state <= NVRAM_IDLE;
	endcase
end

////////////////////  MAIN  //////////////////////
wire [7:0] R,G,B;
wire HBlank,VBlank;
wire VS,HS;
wire ce_vid;
wire hires;
wire signed [15:0] sound_l,sound_r;
wire midi_out,uart_out;
wire reset_out;

tsconf tsconf
(
	.clk(clk_sys),
	.fclk(fclk),
	.ce(ce_28m),

	.SDRAM_DQ(SDRAM_DQ),
	.SDRAM_A(SDRAM_A),
	.SDRAM_BA(SDRAM_BA),
	.SDRAM_DQML(SDRAM_DQML),
	.SDRAM_DQMH(SDRAM_DQMH),
	.SDRAM_nWE(SDRAM_nWE),
	.SDRAM_nCAS(SDRAM_nCAS),
	.SDRAM_nRAS(SDRAM_nRAS),
	.SDRAM_CKE(SDRAM_CKE),
	.SDRAM_nCS(SDRAM_nCS),
	.SDRAM_CLK(SDRAM_CLK),

	.VRED(R),
	.VGRN(G),
	.VBLU(B),
	.VHSYNC(HS),
	.VVSYNC(VS),
	.VGA_HBLANK(HBlank),
	.VGA_VBLANK(VBlank),
	.VGA_CEPIX(ce_vid),
	.VGA_HIRES(hires),

	.SD_SO(sdmiso),
	.SD_SI(sdmosi),
	.SD_CLK(sdclk),
	.SD_CS_N(sdss),
	.SD_CS2_N(sdss2),

	.SOUND_L(sound_l),
	.SOUND_R(sound_r),

	.RESET(RESET | status[0] | buttons[1] | reset_img | ioctl_download | nvram_update_active),
	.RESET_OUT(reset_out),
	.RTC(RTC),
	.TAPE_IN(UART_RXD),
	.MIDI_OUT(midi_out),
	.UART_RX(UART_RXD),
	.UART_TX(uart_out),

	.CFG_OUT0(cfg_out0),
	.CFG_60HZ(cfg_60hz),
	.CFG_SCANDOUBLER(1'b0),
	.CFG_VDAC(cfg_vdac),
	.CFG_JOYSTICK1(cfg_joystick1),
	.CFG_JOYSTICK2(cfg_joystick2),
	.CFG_TURBOSOUND_ACB(cfg_turbosound_acb),
	.CFG_AUDIO_BOOST(cfg_audio_boost),

	.PS2_KEY(ps2_key),
	.PS2_MOUSE(core_mouse),
	.JOYSTICK1(joy_0[7:0]),
	.JOYSTICK2(joy_1[7:0]),

	.loader_act(ioctl_download),
	.loader_addr(ioctl_addr[15:0]),
	.loader_do(ioctl_dout),
	.loader_wr(ioctl_wr),
	.loader_cs_rom_main(ioctl_index == 16'h0000),
	.loader_cs_rom_gs(ioctl_index == 16'h0040),

	.cmos_addr(nvram_address),
	.cmos_do(nvram_cmos_data),
	.cmos_di(nvram_data_out),
	.cmos_wr(nvram_cmos_wr)
);

assign AUDIO_L = sound_l;
assign AUDIO_R = sound_r;
assign AUDIO_S = 1'b1;
assign AUDIO_MIX = status[4:3];

assign UART_TXD = (uart_mode == 3) ? midi_out :
	                  (uart_mode == 1 || uart_mode == 2) ? uart_out : 1'b1;

assign DDRAM_CLK      = clk_sys;
assign DDRAM_BURSTCNT = 0;
assign DDRAM_ADDR     = 0;
assign DDRAM_RD       = 0;
assign DDRAM_DIN      = 0;
assign DDRAM_BE       = 0;
assign DDRAM_WE       = 0;

assign LED_USER = (vsd_sel & sd_act) | ioctl_download;
assign LED_DISK = {1'b1, ~vsd_sel & sd_act};

//////////////////   VIDEO   ///////////////////
reg [7:0] R_r,G_r,B_r;
reg HBlank_r,VBlank_r,HS_r,VS_r;
reg ce_vid_r;
always @(posedge CLK_VIDEO) begin
	R_r <= R;
	G_r <= G;
	B_r <= B;
	HBlank_r <= HBlank;
	VBlank_r <= VBlank;
	HS_r <= HS;
	VS_r <= VS;
	ce_vid_r <= ce_vid;
end

reg VSync,HSync;
always @(posedge CLK_VIDEO) begin
	HSync <= HS_r;
	if(~HSync & HS_r) VSync <= VS_r;
end

reg ce_pix_native = 0;
always @(posedge CLK_VIDEO) begin
	reg old_ce = 0;
	old_ce <= ce_vid_r;
	ce_pix_native <= ~old_ce & ce_vid_r;
end

reg ce_pix_fixed_14 = 0;
always @(posedge CLK_VIDEO) begin
	reg [1:0] ce_fixed_div = 3'd3;
	ce_fixed_div <= ce_fixed_div + 1'd1;
	ce_pix_fixed_14 <= !ce_fixed_div;
end

reg [1:0] hires_sync = 0;
reg seen_hires = 0;
reg ce_pix_force_14mhz = 0;
reg VSync_old = 0;

// scaler requires a constant pixel rate within a frame
always @(posedge CLK_VIDEO) begin
	hires_sync <= {hires_sync[0],hires};
	VSync_old <= VSync;

	if(~VSync_old & VSync) begin
		ce_pix_force_14mhz <= seen_hires;
		seen_hires <= hires_sync[1];
	end
	else if(hires_sync[1]) begin
		seen_hires <= 1;
	end
end

wire ce_pix = ce_pix_force_14mhz ? ce_pix_fixed_14 : ce_pix_native;

assign VGA_SL = {scale == 3,scale == 2};
video_mixer #(.GAMMA(1)) video_mixer
(
	.CLK_VIDEO(CLK_VIDEO),
	.CE_PIXEL(CE_PIXEL),
	.ce_pix(ce_pix),
	.scandoubler(scale || forced_scandoubler),
	.hq2x(scale == 1),
	.gamma_bus(gamma_bus),
	.R(R_r),
	.G(G_r),
	.B(B_r),
	.HSync(HSync),
	.VSync(VSync),
	.HBlank(HBlank_r),
	.VBlank(VBlank_r),
	.HDMI_FREEZE(HDMI_FREEZE),
	.freeze_sync(),
	.VGA_R(VGA_R),
	.VGA_G(VGA_G),
	.VGA_B(VGA_B),
	.VGA_VS(VGA_VS),
	.VGA_HS(VGA_HS),
	.VGA_DE(vga_de)
);

//////////////////   SD   ///////////////////
wire sdclk;
wire sdmosi;
wire sdss, sdss2;

reg reset_img;
reg vsd_sel = 0;
always @(posedge clk_sys) begin
	integer reset_timeout = 0;
	if(reset_timeout) reset_timeout <= reset_timeout - 1;
	else reset_img <= 0;

	if(img_mounted) begin
		vsd_sel <= |img_size;
		reset_img <= 1;
		reset_timeout <= 10000000;
	end
end

wire vsdmiso;
wire sdmiso = !vsd_sel ? SD_MISO :
	!sdss  ? vsdmiso :
	!sdss2 ? SD_MISO : 1'b1;

sd_card sd_card
(
	.*,
	.reset(reset_out),
	.clk_spi(clk_sys),
	.sdhc(1),
	.sck(sdclk),
	.ss(~vsd_sel | sdss),
	.mosi(sdmosi),
	.miso(vsdmiso)
);

assign SD_CS = vsd_sel ? sdss2 : sdss;
assign SD_SCK = sdclk & ~SD_CS;
assign SD_MOSI = sdmosi & ~SD_CS;

reg sd_act;
always @(posedge clk_sys) begin
	reg old_mosi,old_miso;
	integer activity_timeout = 0;
	old_mosi <= sdmosi;
	old_miso <= sdmiso;

	sd_act <= 0;
	if(activity_timeout < 1000000) begin
		activity_timeout <= activity_timeout + 1;
		sd_act <= 1;
	end
	if((old_mosi ^ sdmosi) || (old_miso ^ sdmiso)) activity_timeout <= 0;
end

endmodule
