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
	`include "sys/emu_ports.vh"
);

assign ADC_BUS  = 'Z;
assign USER_OUT = '1;
assign VGA_F1 = 0;
assign {UART_RTS, UART_TXD, UART_DTR} = 0;

assign LED_USER  = (vsd_sel & sd_act) | ioctl_download;
assign LED_DISK  = {1'b1, ~vsd_sel & sd_act};
assign LED_POWER = 0;
assign BUTTONS   = 0;
assign VGA_SCALER= 0;
assign VGA_DISABLE = 0;
assign HDMI_FREEZE = 0;
assign HDMI_BLACKOUT = 0;
assign HDMI_BOB_DEINT = 0;

wire [1:0] ar = status[33:32];
wire       vcrop_en = status[34];
reg        en270p;
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

`include "build_id.v" 
localparam CONF_STR = {
	"TSConf;;",
	"SC0,VHD,Mount virtual SD;",
	"-;",
	"o01,Aspect ratio,Original,Full Screen,[ARC1],[ARC2];",
	"O12,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%;",
	"-;",
	"d0o2,Vertical Crop,Disabled,270p(5x);",
	"o34,Scale,Normal,V-Integer,Narrower HV-Integer,Wider HV-Integer;",
	"-;",
	"O34,Stereo mix,None,25%,50%,100%;",
	"OST,General Sound,512KB,1MB,2MB;",
	"-;",
	"OU,CPU Type,NMOS,CMOS;",
	"O67,CPU Speed,3.5MHz,7MHz,14MHz;",
	"O8,CPU Cache,On,Off;",
	"O9A,#7FFD span,128K,128K Auto,1024K,512K;",
	"OLN,ZX Palette,Default,B.black,Light,Pale,Dark,Grayscale,Custom;",
	"OPR,INT Offset,1,2,3,4,5,6,7,0;",
	"-;",
	"OBD,F11 Reset,boot.$C,sys.rom,ROM;",
	"OEF,           bank,TR-DOS,Basic 48,Basic 128,SYS;",
	"OGI,Shift+F11 Reset,ROM,boot.$C,sys.rom;",
	"OJK,           bank,Basic 128,SYS,TR-DOS,Basic 48;",
	"-;",
	"R0,Reset and apply settings;",
	"J,Fire 1,Fire 2;",
	"V,v",`BUILD_DATE
};

wire [27:0] CMOSCfg;

// fix default values
assign CMOSCfg[5:0]  = 0;
assign CMOSCfg[7:6]  = status[7:6];
assign CMOSCfg[8]    = ~status[8];
assign CMOSCfg[10:9] = status[10:9] + 1'd1;
assign CMOSCfg[13:11]= (status[13:11] < 2) ? status[13:11] + 3'd3 : status[13:11] - 3'd2;
assign CMOSCfg[15:14]= status[15:14];
assign CMOSCfg[18:16]= (status[18:16]) ? status[18:16] + 3'd2 : 3'd0;
assign CMOSCfg[20:19]= status[20:19] + 2'd2;
assign CMOSCfg[23:21]= status[23:21];
assign CMOSCfg[24]   = 0;
assign CMOSCfg[27:25]= status[27:25] + 1'd1;


////////////////////   CLOCKS   ///////////////////
wire clk_sys;

pll pll
(
	.refclk(CLK_50M),
	.outclk_0(clk_sys),
	.outclk_1(CLK_VIDEO)
);

reg ce_28m;
always @(negedge clk_sys) begin
	reg [1:0] div;
	
	div <= div + 1'd1;
	if(div == 2) div <= 0;
	ce_28m <= !div;
end


//////////////////   HPS I/O   ///////////////////
wire  [5:0] joy_0;
wire  [5:0] joy_1;
wire [15:0] joya_0;
wire [15:0] joya_1;
wire  [1:0] buttons;
wire [63:0] status;
wire [24:0] ps2_mouse;
wire [10:0] ps2_key;

wire        forced_scandoubler;
wire [21:0] gamma_bus;

wire [31:0] sd_lba;
wire        sd_rd;
wire        sd_wr;
wire        sd_ack;
wire  [8:0] sd_buff_addr;
wire  [7:0] sd_buff_dout;
wire  [7:0] sd_buff_din;
wire        sd_buff_wr;
wire        img_mounted;
wire        img_readonly;
wire [63:0] img_size;
wire [64:0] RTC;

wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;
wire        ioctl_download;
wire  [7:0] ioctl_index;

hps_io #(.CONF_STR(CONF_STR)) hps_io
(
	.clk_sys(clk_sys),
	.HPS_BUS(HPS_BUS),

	.joystick_0(joy_0),
	.joystick_1(joy_1),
	.joystick_l_analog_0(joya_0),
	.joystick_l_analog_1(joya_1),

	.buttons(buttons),
	.status(status),
	.status_menumask({en270p}), 
	.forced_scandoubler(forced_scandoubler),
	.gamma_bus(gamma_bus),

	.RTC(RTC),

	.ps2_mouse(ps2_mouse),
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
	.ioctl_index(ioctl_index)
);


////////////////////  MAIN  //////////////////////
wire [7:0] R,G,B;
wire HBlank,VBlank;
wire VS, HS;
wire ce_vid;

wire reset;

tsconf tsconf
(
	.clk(clk_sys),
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

	.VGA_R(R),
	.VGA_G(G),
	.VGA_B(B),
	.VGA_HS(HS),
	.VGA_VS(VS),
	.VGA_HBLANK(HBlank),
	.VGA_VBLANK(VBlank),
	.VGA_CEPIX(ce_vid),

	.SD_SO(sdmiso),
	.SD_SI(sdmosi),
	.SD_CLK(sdclk),
	.SD_CS_N(sdss),

	.GS_ADDR(gs_mem_addr),
	.GS_DI(gs_mem_din),
	.GS_DO(gs_mem_dout | gs_mem_mask),
	.GS_RD(gs_mem_rd),
	.GS_WR(gs_mem_wr),
	.GS_WAIT(~gs_mem_ready), 	
	.SOUND_L(AUDIO_L),
	.SOUND_R(AUDIO_R),

	.COLD_RESET(RESET | status[0] | reset_img),
	.WARM_RESET(buttons[1]),
	.RESET_OUT(reset),
	.RTC(RTC),
	.OUT0(status[30]),

	.CMOSCfg(CMOSCfg),

	.PS2_KEY(ps2_key),
	.PS2_MOUSE(ps2_mouse),
	.joystick(joy_0[5:0] | joy_1[5:0]),

	.loader_addr(ioctl_addr[15:0]),
	.loader_data(ioctl_dout),
	.loader_wr(ioctl_wr && ioctl_download && !ioctl_index && !ioctl_addr[24:16])
);

assign DDRAM_CLK = clk_sys;

wire [20:0] gs_mem_addr;
wire  [7:0] gs_mem_dout;
wire  [7:0] gs_mem_din;
wire        gs_mem_rd;
wire        gs_mem_wr;
wire        gs_mem_ready;
reg   [7:0] gs_mem_mask;

always_comb begin
	gs_mem_mask = 0;
	case(status[29:28])
		0: if(gs_mem_addr[20:19]) gs_mem_mask = 8'hFF;
		1: if(gs_mem_addr[20])    gs_mem_mask = 8'hFF;
	 2,3:                        gs_mem_mask = 0;
	endcase
end

ddram ddram
(
	.*,
	.addr(gs_mem_addr),
	.dout(gs_mem_dout),
	.din(gs_mem_din),
	.we(gs_mem_wr),
	.rd(gs_mem_rd),
	.ready(gs_mem_ready)
);

assign AUDIO_S = 1;
assign AUDIO_MIX = status[4:3];

reg ce_pix;
always @(posedge CLK_VIDEO) begin
	reg old_ce;

	old_ce <= ce_vid;
	ce_pix <= ~old_ce & ce_vid;
end

reg VSync, HSync;
always @(posedge CLK_VIDEO) begin
	HSync <= HS;
	if(~HSync & HS) VSync <= VS;
end


wire [1:0] scale = status[2:1];
assign VGA_SL = {scale == 3, scale == 2};

video_mixer #(.GAMMA(1)) video_mixer
(
	.*,
	.scandoubler(scale || forced_scandoubler),
	.hq2x(scale==1),
	.freeze_sync(),
	.VGA_DE(vga_de)
);


//////////////////   SD   ///////////////////
wire sdclk;
wire sdmosi;
wire sdmiso = vsd_sel ? vsdmiso : SD_MISO;
wire sdss;

reg reset_img;
reg vsd_sel = 0;
always @(posedge clk_sys) begin
	integer to = 0;
	
	if(to) to <= to - 1;
	else reset_img <= 0;

	if(img_mounted) begin
		vsd_sel <= |img_size;
		reset_img <= 1;
		to <= 10000000;
	end
end

wire vsdmiso;
sd_card sd_card
(
	.*,
	.clk_spi(clk_sys),

	.sdhc(1),

	.sck(sdclk),
	.ss(~vsd_sel | sdss),
	.mosi(sdmosi),
	.miso(vsdmiso)
);

assign SD_CS   = vsd_sel | sdss;
assign SD_SCK  = sdclk & ~SD_CS;
assign SD_MOSI = sdmosi & ~SD_CS;

reg sd_act;

always @(posedge clk_sys) begin
	reg old_mosi, old_miso;
	integer timeout = 0;

	old_mosi <= sdmosi;
	old_miso <= sdmiso;

	sd_act <= 0;
	if(timeout < 1000000) begin
		timeout <= timeout + 1;
		sd_act <= 1;
	end

	if((old_mosi ^ sdmosi) || (old_miso ^ sdmiso)) timeout <= 0;
end

endmodule
