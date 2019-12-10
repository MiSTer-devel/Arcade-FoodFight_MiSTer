// Copyright (c) 2019 MiSTer-X

module SPRITE
(
	input					VCLKx8,
	input					VCLKx4,
	input					VCLK,

	input	  [8:0]		HPOS,
	input	  [8:0]		VPOS,

	output				SPACL,
	output  [7:0]		SPAAD,
	input  [15:0]		SPADT,

	output				SPCCL,
	output [12:0]		SPCAD,
	input  [15:0]		SPCDT,

	output reg  [7:0]	SPCOL
);

wire  [8:0] SPHP  = HPOS;
wire  [8:0] SPVP  = VPOS+2;

// Sequencer
`define LOOP		(PH)
`define NEXT		(PH+1)

reg  [15:0] D0,D1;

wire  [7:0] SX = D1[15:8];
wire	[7:0] SY = D1[7:0];
wire  [7:0] CN = D0[7:0];
wire  [4:0] PN = D0[12:8];
wire			FH = D0[15];
wire			FV = D0[14];
wire        BH = D0[13];

wire	[8:0] YM = SY+SPVP[7:0];
wire	[8:0] YM_= (SPADT[7:0])+SPVP[7:0];
wire			HT = (YM_[7:4]==4'b1111);

reg	[6:0] NO;
reg   [4:0] LP;
wire  [3:0] LX = LP[3:0]^{4{FH}};
wire  [3:0] LY = YM[3:0]^{4{FV}};

reg   [2:0] PH = 0;
always @(posedge VCLKx4) begin
	if (SPHP==380) PH <= 0;
	else case(PH)
		0: begin NO <= 16; LP <= 0; PH <= (SPHP==0) ? `NEXT:`LOOP; end
		1: begin D1 <= SPADT; NO <= HT ? NO : (NO+1); PH <= HT ? (PH+1) : ((NO==63) ? 0 :`LOOP); end
		2: begin D0 <= SPADT; PH <= `NEXT; end
		3: begin LP <= 5'b10000; PH <=`NEXT; end
		4: begin LP <= LP+1; PH <= (LP==5'b11111) ? `NEXT:`LOOP; end 
		5: begin NO <= NO+1; PH <= (NO==63) ? 0 : 1; end
		default: PH <= 0;
	endcase
end
assign SPACL = ~VCLKx4;
assign SPAAD = {NO,(PH==1)? 1'b1 : 1'b0};

// Renderer
assign SPCCL = ~VCLKx8;
assign SPCAD = {CN,~LX[3],LY};
wire [15:0] CSH = SPCDT << LX[2:0];
wire  [7:0]	PIX = {BH,PN,CSH[15],CSH[7]};
wire  [8:0] PWP = SX+(LX^{4{FH}})-1;
wire 			PWE = (PIX[1:0]!=0) & LP[4];

// Line Buffer
wire			wsid = SPVP[0];
wire [9:0]	wadr = {wsid,{1'b0,PWP[7:0]}};
reg  [9:0]	rad0,rad1=1;
wire [7:0]	opix,dum;
LBuf1024 lbuf(
  ~VCLKx4,wadr,PIX,PWE,dum,
	VCLKx4,rad0,8'h0,(rad0==rad1),opix
);
always @(posedge VCLK) rad0 <= {~wsid,SPHP};
always @(negedge VCLK) begin
	SPCOL <= opix;
	rad1  <= rad0;
end

endmodule

