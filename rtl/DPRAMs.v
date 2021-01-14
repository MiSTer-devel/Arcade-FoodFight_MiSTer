// Copyright (c) 2019 MiSTer-X

module LBuf1024
(
	input 				CL0,
	input  [9:0]		AD0,
	input  [7:0]		WD0,
	input					WE0,
	output [7:0]		RD0,

	input 				CL1,
	input	 [9:0]		AD1,
	input	 [7:0]		WD1,
	input					WE1,
	output [7:0]		RD1
);

DPRAM1024_8 r
(
	AD0, AD1,
	CL0, CL1,
	WD0, WD1,
	WE0, WE1,
	RD0, RD1
);

endmodule


module DPRAM #(AW=8,DW=8)
(
	input 					CL0,
	input [AW-1:0]			AD0,
	input [DW-1:0]			WD0,
	input						WE0,
	output reg [DW-1:0]	RD0,

	input 					CL1,
	input [AW-1:0]			AD1,
	input [DW-1:0]			WD1,
	input						WE1,
	output reg [DW-1:0]	RD1
);

reg [7:0] core[0:((2**AW)-1)];

always @(posedge CL0) begin
	if (WE0) core[AD0] <= WD0;
	else RD0 <= core[AD0];
end

always @(posedge CL1) begin
	if (WE1) core[AD1] <= WD1;
	else RD1 <= core[AD1];
end

endmodule


module DPRAMrw #(AW=8,DW=8)
(
	input 					CL0,
	input [AW-1:0]			AD0,
	output reg [DW-1:0]	RD0,

	input 					CL1,
	input [AW-1:0]			AD1,
	input [DW-1:0]			WD1,
	input						WE1,
	output reg [DW-1:0] 	RD1
);

reg [7:0] core[0:((2**AW)-1)];

always @(posedge CL0) RD0 <= core[AD0];
always @(posedge CL1) if (WE1) core[AD1] <= WD1; else RD1 <= core[AD1];

endmodule


module RAM_W #(AW=8)
(
	input					cl,
	input	 [(AW-1):0]	ad,
	input					cs,
	input					rw,
	input					lds,
	input					uds,
	input  [15:0]		id,
	output [15:0]		od
);

RAM_B #(AW) U( cl, ad, cs & uds, rw, id[15:8], od[15:8] );
RAM_B #(AW) L( cl, ad, cs & lds, rw, id[ 7:0], od[ 7:0] );

endmodule


module RAM_B #(AW=8)
(
	input					cl,
	input	 [(AW-1):0]	ad,
	input					en,
	input					wr,
	input   [7:0]		id,
	output reg [7:0]	od
);

reg [7:0] core [0:((2**AW)-1)];

always @( posedge cl ) begin
	if (en) begin
		if (wr) core[ad] <= id;
		else od <= core[ad];
	end
end

endmodule

