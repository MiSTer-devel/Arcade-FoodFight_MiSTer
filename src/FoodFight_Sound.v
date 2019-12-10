// Copyright (c) 2019 MiSTer-X

module SOUND
(
	output [15:0]	SOUT,
	input   [7:0]	DSW,

	input				rst,
	input				cl,
	input	 [22:0]	ad,
	input				as,
	input				rw,
	input				lds,
	input				uds,
	input  [15:0]	od,

	output 			dtack,
	output			dv,
	output [15:0]	id
);

// Address decoders
wire cs_pokey2 = lds & as & (ad[22:17] == 6'b1010_01);	// $A40000-$A4001F
wire cs_pokey1 = lds & as & (ad[22:17] == 6'b1010_10);	// $A80000-$A8001F
wire cs_pokey3 = lds & as & (ad[22:17] == 6'b1010_11);	// $AC0000-$AC001F
wire axs = (cs_pokey1|cs_pokey2|cs_pokey3);

// Bus cycle for "old 8-bit devices"
wire E;
BusCycle68k8B bc8(rst,cl,axs,E,dtack);

// Pokey x3
wire [7:0] rdt1,rdt2,rdt3;
wire [7:0] snd1,snd2,snd3;
PokeyW P1(.clk(E),.rst(rst),.ad(ad),.cs(cs_pokey1),.we(rw),.wd(od),.rd(rdt1),.snd(snd1),.p(DSW));
PokeyW P2(.clk(E),.rst(rst),.ad(ad),.cs(cs_pokey2),.we(rw),.wd(od),.rd(rdt2),.snd(snd2),.p(0));
PokeyW P3(.clk(E),.rst(rst),.ad(ad),.cs(cs_pokey3),.we(rw),.wd(od),.rd(rdt3),.snd(snd3),.p(0));

// CPU read data
assign dv = axs & (~rw);
assign id = cs_pokey1 ? {8'h0,rdt1} :
				cs_pokey2 ? {8'h0,rdt2} :
				cs_pokey3 ? {8'h0,rdt3} :
				16'h0;

// Sound Out
wire [9:0] snd = snd1+snd2+snd3;
assign SOUT = {snd,6'h0};

endmodule


module BusCycle68k8B
(
	input			rst,
	input			cl,
	input			axs,
	
	output		E,
	output reg	dtack
);

reg en = 0;
reg [3:0] dtkcnt = 0;

always @(posedge cl) begin
	if (rst) begin
		dtkcnt <= 0;
		en     <= 0;
		dtack  <= 0;
	end
	else begin
		if (~en) begin
			if (dtkcnt==0) en <= axs;
		end
		else begin
			if (dtack) begin
				if (~axs) begin
					dtack <= 0;
					en <= 0;
				end
			end
			else if (dtkcnt==8) dtack <= en;
		end
		dtkcnt <= (dtkcnt>=9) ? 0 : (dtkcnt+1);
	end
end
assign E = (dtkcnt>=6);

endmodule


// Pokey-IP wrapper
module PokeyW
(
	input				clk,

	input				rst,
	input  [3:0]	ad,
	input				cs,
	input				we,
	input  [7:0]	wd,
	output [7:0]	rd,

	output [7:0]	snd,

	input  [7:0]	p
);

wire [3:0] ch0,ch1,ch2,ch3;

pokey core (
	.RESET_N(~rst),
	.CLK(clk),
	.ADDR(ad),
	.DATA_IN(wd),
	.DATA_OUT(rd),
	.WR_EN(we & cs),
	.ENABLE_179(1'b1),
	.POT_IN(~p),
	
	.CHANNEL_0_OUT(ch0),
	.CHANNEL_1_OUT(ch1),
	.CHANNEL_2_OUT(ch2),
	.CHANNEL_3_OUT(ch3)
);

assign snd = ch0+ch1+ch2+ch3;

endmodule

