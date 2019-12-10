//===============================================
//	 FPGA Food Fight
//
//  					Copyright (c) 2019 MiSTer-X
//===============================================
module FPGA_FoodFight
(
	input				MCLK,
   input				RESET,

	input	  [7:0]	AX0,
	input	  [7:0]	AY0,
	input	  [7:0]	AX1,
	input	  [7:0]	AY1,
	input	  [7:0]	DIN,

	input   [8:0]	PH,
	input   [8:0]	PV,
	output 			PCLK,
	output [11:0]	POUT,

	output [15:0]  SOUT,
	

	input				ROMCL,	// Downloaded ROM image
	input  [16:0]	ROMAD,
	input   [7:0]	ROMDT,
	input				ROMEN
);

wire  [7:0] DSW = 8'b00000000;

wire VCLKx8,VCLKx4,VCLKx2,VCLK;
CLKGEN clkgen (MCLK,VCLKx8,VCLKx4,VCLKx2,VCLK);

wire			rst_68K, cl_68K, as_68K, rw_68K, lds_68K, uds_68K;
wire  [2:0]	ipl_68k;
wire [22:0]	ad_68K;
wire [15:0]	od_68K;

wire			inp_dv, inp_dtack;
wire [15:0]	inp_dt;

wire			vid_dv, vid_dtack;
wire [15:0]	vid_dt;

wire			snd_dv, snd_dtack;
wire [15:0]	snd_dt;

wire  [7:0] DOUT;

IODEV iodev (
	AX0,AY0, AX1,AY1, DIN,
	DOUT,
	rst_68K,cl_68K,ad_68K,as_68K,rw_68K,lds_68K,uds_68K,od_68K,
	inp_dtack, inp_dv, inp_dt,

	ROMCL, ROMAD, ROMDT, ROMEN
);

IRQGEN igen (
	PV, DOUT[3:2],
	rst_68K,cl_68K,ipl_68k
);

VIDEO video (
	VCLKx8,VCLKx4,VCLK,
	PH,PV,PCLK,POUT,
	rst_68K,cl_68K,ad_68K,as_68K,rw_68K,lds_68K,uds_68K,od_68K,
	vid_dtack,vid_dv,vid_dt,

	ROMCL, ROMAD, ROMDT, ROMEN
);

SOUND sound (
	SOUT, DSW,
	rst_68K,cl_68K,ad_68K,as_68K,rw_68K,lds_68K,uds_68K,od_68K,
	snd_dtack,snd_dv,snd_dt
);

MAIN main (
	VCLK,
	rst_68K,cl_68K,ad_68K,as_68K,rw_68K,lds_68K,uds_68K,od_68K,
	ipl_68k,
	inp_dtack,inp_dv,inp_dt,
	vid_dtack,vid_dv,vid_dt,
	snd_dtack,snd_dv,snd_dt,

	ROMCL, ROMAD, ROMDT, ROMEN
);

assign rst_68K = RESET;

endmodule


module CLKGEN
(
	input		MCLK,
	
	output 	CLKr,
	output 	CLK0,
	output 	CLK1,
	output 	CLK2,

	output	CLK15
);

reg [15:0] clkdiv;
always @(posedge MCLK) clkdiv <= clkdiv+1;

assign CLKr = MCLK;
assign {CLK2,CLK1,CLK0} = clkdiv[2:0];
assign CLK15 = clkdiv[15];

endmodule


