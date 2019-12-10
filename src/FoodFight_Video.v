// Copyright (c) 2019 MiSTer-X

//`define DEBUGDISP

module VIDEO
(
	input				VCLKx8,
	input				VCLKx4,
	input				VCLK,

	input   [8:0]	HPOSi,
	input	  [8:0]	VPOS,
	output			PCLK,
	output [11:0]	POUT,
	
	input				reset,
	input				cl,
	input	 [22:0]	ad,
	input				as,
	input				rw,
	input				lds,
	input				uds,
	input  [15:0]	od,
	output 			dtack,
	output			dv,
	output [15:0]	id,


	input				DLCL,		// Downloaded ROM image
	input  [16:0]	DLAD,
	input   [7:0]	DLDT,
	input				DLEN
);

wire  [8:0] HPOS = HPOSi+1;


// Video RAMs
wire			BGVCL;
wire  [9:0]	BGVAD;
wire [15:0]	BGVDT;

wire			SPACL;
wire  [7:0] SPAAD;
wire [15:0] SPADT;

wire			PALCL;
wire  [7:0] PALAD;
wire  [7:0] PALDT;

VIDEORAMS vrams(
	BGVCL,BGVAD,BGVDT,
	SPACL,SPAAD,SPADT,
	PALCL,PALAD,PALDT,
	reset,cl,ad,as,rw,lds,uds,od,dtack,dv,id
);

// BG Scanline Generator
wire			BGCCL;
wire [12:0]	BGCAD;
wire  [7:0]	BGCDT;
BGCHROM bgch(BGCCL,BGCAD,BGCDT, DLCL,DLAD,DLDT,DLEN);

wire  [7:0]	BGCOL;
BG bgr(
	VCLKx4,VCLK,
	HPOS,VPOS,
	BGVCL,BGVAD,BGVDT,
	BGCCL,BGCAD,BGCDT,
	BGCOL
);

// Sprite Scanline Generator
wire			SPCCL;
wire [12:0] SPCAD;
wire [15:0] SPCDT;
SPCHROM spch(SPCCL,SPCAD,SPCDT, DLCL,DLAD,DLDT,DLEN);

wire  [7:0] SPCOL;
SPRITE spr(
	VCLKx8,VCLKx4,VCLK,
	HPOS,VPOS,
	SPACL,SPAAD,SPADT,
	SPCCL,SPCAD,SPCDT,
	SPCOL
);

// CPU-Bus display (for debug)
`ifdef DEBUGDISP
wire [0:31] DBGF = {{23{1'b1}},1'b0, 2'b11, 1'b0,  2'b11 , 1'b0,  1'b1, 1'b0 };
wire [0:31] DBGO = {    ad,    1'b0, as,rw, 1'b0, lds,uds, 1'b0, dtack, 1'b0 };
wire			DBGD;
wire  [2:0] DBGC;
DBGDISP bdsp(VCLK,HPOS,VPOS, DBGF,DBGO,1'b1, DBGD,DBGC);
`else
wire			DBGD = 0;
wire  [2:0] DBGC = 0;
`endif

// Color mixer
CMIX cmix(
	VCLK,
	DBGD,DBGC,
	BGCOL,SPCOL,
	PALCL,PALAD,PALDT,
	PCLK,POUT
);

endmodule


module VIDEORAMS
(
	input				BGVCL,
	input   [9:0]	BGVAD,
	output [15:0]	BGVDT,
	
	input				SPACL,
	input   [7:0]	SPAAD,
	output [15:0]	SPADT,

	input				PALCL,
	input   [7:0]	PALAD,
	output  [7:0]	PALDT,

	input				reset,
	input				cl,
	input	 [22:0]	ad,
	input				as,
	input				rw,
	input				lds,
	input				uds,
	input  [15:0]	od,

	output reg		dtack,
	output			dv,
	output [15:0]	id
);

// Address decoders
wire cs_spa = as & (ad[22:21] == 2'b00     ) & (ad[15:13] == 3'b1_11);	// $01C000-$01C0FF
wire cs_bgv = as & (ad[22:17] == 6'b1000_00) & (ad[10]    == 1'b0); 		// $800000-$8007FF
wire cs_pal = as & (ad[22:17] == 6'b1001_01) & (ad[15:13] == 3'b1_00);	// $950000-$9501FF

// DTACK
wire axs = (cs_bgv|cs_spa|cs_pal) & (uds|lds);
always @(posedge cl) begin
	if (reset) dtack <= 0;
	else dtack <= axs;
end

// VRAMs
wire  [1:0] ds = {uds,lds};
wire [15:0] id_spa,id_bgv,id_pal;
SPARAM spar(SPACL,SPAAD,SPADT,cl,ad[6:0],cs_spa & rw,ds,id_spa,od);
BGVRAM bgvr(BGVCL,BGVAD,BGVDT,cl,ad[9:0],cs_bgv & rw,ds,id_bgv,od);
PALRAM palt(PALCL,PALAD,PALDT,cl,ad[7:0],cs_pal & rw,ds,id_pal,od);

// CPU read data
assign dv = axs & (~rw);
assign id = cs_bgv ? id_bgv :
				cs_spa ? id_spa :
				cs_pal ? id_pal :
				0;

endmodule


module BGVRAM
(
	input				CLV,
	input   [9:0]	ADV,
	output [15:0]	DTV,
	
	input				CL,
	input   [9:0]	AD,
	input				WE,
	input	  [1:0]	DS,
	output [15:0]	OD,
	input  [15:0]	ID
);

DPRAMrw #(10,8) e(CLV,ADV,DTV[15:8],CL,AD,ID[15:8],WE & DS[1],OD[15:8]);
DPRAMrw #(10,8) o(CLV,ADV,DTV[ 7:0],CL,AD,ID[ 7:0],WE & DS[0],OD[ 7:0]);

endmodule


module SPARAM
(
	input				CLV,
	input   [6:0]	ADV,
	output [15:0]	DTV,
	
	input				CL,
	input   [9:0]	AD,
	input				WE,
	input	  [1:0]	DS,
	output [15:0]	OD,
	input  [15:0]	ID
);
	
DPRAMrw #(7,8) e(CLV,ADV,DTV[15:8],CL,AD,ID[15:8],WE & DS[1],OD[15:8]);
DPRAMrw #(7,8) o(CLV,ADV,DTV[ 7:0],CL,AD,ID[ 7:0],WE & DS[0],OD[ 7:0]);

endmodule


module PALRAM
(
	input				CLV,
	input   [7:0]	ADV,
	output  [7:0]	DTV,
	
	input				CL,
	input   [8:0]	AD,
	input				WE,
	input	  [1:0]	DS,
	output [15:0]	OD,
	input  [15:0]	ID
);

wire [7:0] dmy;
DPRAMrw #(8,8) e(CLV,ADV,dmy,CL,AD,ID[15:8],WE & DS[1],OD[15:8]);
DPRAMrw #(8,8) o(CLV,ADV,DTV,CL,AD,ID[ 7:0],WE & DS[0],OD[ 7:0]);

endmodule


module BG
(
	input				VCLKx4,
	input				VCLK,

	input   [8:0]	HPOS,
	input   [8:0]	VPOS,

	output			BGVCL,
	output  [9:0]	BGVAD,
	input  [15:0]	BGVDT,

	output			BGCCL,
	output [12:0]	BGCAD,
	input   [7:0]	BGCDT,

	output reg [7:0] BGCOL
);

wire  [8:0] BGHP  = HPOS-8;
wire  [8:0] BGVP  = VPOS;

assign 		BGVCL = VCLKx4;
assign		BGVAD = {BGHP[7:3],BGVP[7:3]};

wire  [8:0] BGCNO = {BGVDT[15],BGVDT[7:0]};
wire  [5:0] BGPNO = {BGVDT[13:8]};

assign		BGCCL = VCLKx4;
assign		BGCAD = {BGCNO,~BGHP[2],BGVP[2:0]};

wire  [7:0] BGCSH = BGCDT << BGHP[1:0];
wire  [1:0] BGCPX ={BGCSH[7],BGCSH[3]};
always @(posedge VCLK) BGCOL <= {BGPNO,BGCPX};

endmodule


module CMIX
(
	input				VCLK,

	input				DCEN,
	input  [2:0]	DRGB,

	input  [7:0]	BGCOL,
	input  [7:0]	SPCOL,

	output			PALCL,
	output [7:0]	PALAD,
	input  [7:0]	PALDT,

	output			PCLK,
	output [11:0]	POUT
);

wire	 BGOPQ = (BGCOL[1:0]!=0);
wire	 SPOPQ = (SPCOL[1:0]!=0);
wire	 SPBGL =  SPCOL[7] & BGOPQ;

assign PALCL = ~VCLK;
assign PALAD = SPBGL ? BGCOL : SPOPQ ? {1'b0,SPCOL[6:0]} : BGCOL;

wire [11:0] COL0 = {PALDT[7:6],2'b00,PALDT[5:3],1'b0,PALDT[2:0],1'b0};
wire [11:0] COL1 = {{4{DRGB[2]}},{4{DRGB[1]}},{4{DRGB[0]}}};

function [3:0] TRANSP;
input [3:0] C0,C1;
	TRANSP = (C0*3+C1)/4;
endfunction

wire [11:0] COLT = {
	TRANSP(COL0[11:8],COL1[11:8]),
	TRANSP(COL0[ 7:4],COL1[ 7:4]),
	TRANSP(COL0[ 3:0],COL1[ 3:0])
};

// Pixel output
assign PCLK = VCLK;
assign POUT = DCEN ? COLT : COL0;

endmodule


`ifdef DEBUGDISP
module DBGDISP
(
	input					VCLK,
	input  [8:0]		HPOS,
	input	 [8:0]		VPOS,

	input [0:31]		DBGF,
	input [0:31]		DBGO,
	input					DBGDSP,

	output reg			DBGD,
	output reg [2:0]	DBGC
);

reg  [0:31] DBGS;
wire  [4:0] DBGH = HPOS[7:3];

always @(posedge VCLK) begin
	if (VPOS==224) DBGD <= DBGDSP;
	if (HPOS==511) DBGS <= DBGO;
	DBGC <= (HPOS[2:0]==7) ? 0 :
				DBGF[DBGH] ? (DBGS[DBGH] ? 3'b101 : 3'b010) :
				0;
end

endmodule
`endif
