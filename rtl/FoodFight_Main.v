// Copyright (c) 2019 MiSTer-X

module MAIN
(
	input				cpuclk,

	input				reset,
	output			clk,
	output [22:0]	adr,
	output			as,
	output			rw,
	output			lds,
	output			uds,
	output [15:0]	od,

	input	  [2:0]	ipl,

	input				inp_dtack,
	input				inp_dv,
	input  [15:0]	inp_dt,

	input				vid_dtack,
	input				vid_dv,
	input  [15:0]	vid_dt,
	
	input				snd_dtack,
	input				snd_dv,
	input  [15:0]	snd_dt,
	

	input				DLCL,		// Downloaded ROM image
	input  [16:0]	DLAD,
	input   [7:0]	DLDT,
	input				DLEN
);
// Program ROM
wire [15:0] rom_dt;
wire			rom_dv;
wire			rom_dtack;
PROGROM prog( reset, clk, adr, as, rw, lds, uds, rom_dtack, rom_dv, rom_dt, DLCL,DLAD,DLDT,DLEN );

// Work RAM
wire [15:0] wrm_dt;
wire			wrm_dv;
wire			wrm_dtack;
WORKRAM wram( reset, clk, adr, as, rw, lds, uds, od, wrm_dtack, wrm_dv, wrm_dt );

// DataBus
wire	dtack =
			inp_dtack |
			vid_dtack |
			snd_dtack |
			wrm_dtack |
			rom_dtack ;

wire [15:0] din;
DSEL5x16 mcpudsel( din,
			inp_dv, inp_dt,
			vid_dv, vid_dt,
			snd_dv, snd_dt,
			wrm_dv, wrm_dt,
			rom_dv, rom_dt
);

// CPU core
MC68000W cpu
(
	.clk(cpuclk),
	.reset(reset),
	.din(din),
	.ipl(ipl),
	.dtack(dtack),
	.addr(adr),
	.dout(od),
	.as(as),
	.uds(uds),
	.lds(lds),
	.rw(rw)
);

assign clk = ~cpuclk;

endmodule


module DSEL5x16
(
	output [15:0] odt, 

	input en0, input [15:0] dt0,
	input en1, input [15:0] dt1,
	input en2, input [15:0] dt2,
	input en3, input [15:0] dt3,
	input en4, input [15:0] dt4
);

assign odt = en0 ? dt0 :
				 en1 ? dt1 :
				 en2 ? dt2 :
				 en3 ? dt3 :
				 en4 ? dt4 :
				 16'h0;

endmodule


module PROGROM
(
	input				reset,
	input				cl,
	input  [22:0]	ad,
	input				as,
	input				rw,
	input				lds,
	input				uds,
	output reg		dtack,
	output			dv,
	output [15:0]	dt,

	input				DLCL,		// Downloaded ROM image
	input  [16:0]	DLAD,
	input   [7:0]	DLDT,
	input				DLEN
);

// Address decoder
wire rom_cs = as & (ad[22:21]==2'b00) & (ad[15]==1'b0) & (lds|uds); 

// DTACK
always @(posedge cl) begin
	if (reset) dtack <= 0;
	else dtack <= rom_cs;
end

// ROMs
wire [15:0] r0dt,r1dt,r2dt,r3dt;
PRGxROM r0(cl,ad[12:0],r0dt, DLCL,DLAD,DLDT,DLEN & (DLAD[16:14]==3'b0_00));
PRGxROM r1(cl,ad[12:0],r1dt, DLCL,DLAD,DLDT,DLEN & (DLAD[16:14]==3'b0_01));
PRGxROM r2(cl,ad[12:0],r2dt, DLCL,DLAD,DLDT,DLEN & (DLAD[16:14]==3'b0_10));
PRGxROM r3(cl,ad[12:0],r3dt, DLCL,DLAD,DLDT,DLEN & (DLAD[16:14]==3'b0_11));

// CPU read data
assign dv = rom_cs & (~rw);
assign dt = (ad[14:13]==2'd0) ? r0dt :
				(ad[14:13]==2'd1) ? r1dt :
				(ad[14:13]==2'd2) ? r2dt :
										  r3dt ;

endmodule


module WORKRAM
(
	input				reset,
	input				cl,
	input  [22:0]	ad,
	input				as,
	input				rw,
	input				lds,
	input				uds,
	input	 [15:0]	od,

	output reg		dtack,
	output			dv,
	output [15:0]	id
);

// Address decoders
wire cs_m14 = as & (ad[22:21]==2'b00) & (ad[15:13]==3'b1_01);	// $014000-$014FFF
wire cs_m18 = as & (ad[22:21]==2'b00) & (ad[15:13]==3'b1_10);	// $018000-$018FFF

// DTACK
wire axs = (cs_m14 | cs_m18) & (uds|lds);
always @( posedge cl ) begin
	if (reset) dtack <= 0;
	else dtack <= axs;
end

// RAMs
wire [15:0] m14_dt, m18_dt;
RAM_W #(11) wm14( cl, ad[10:0], cs_m14, rw, lds, uds, od, m14_dt );
RAM_W #(11) wm18( cl, ad[10:0], cs_m18, rw, lds, uds, od, m18_dt );

// CPU read data
assign dv = axs & (~rw);
assign id = cs_m14 ? m14_dt :
			   cs_m18 ? m18_dt :
			   16'h0;

endmodule


module IRQGEN
(
	input  [8:0]	PV,
	input  [1:0]	IRQA,

	input				reset,
	input				clk,
	output [2:0]	IRQ
);

reg IRQ1,IRQ2;

reg [1:0] pIRQA;
reg [8:0] pPV;
always @(posedge clk or posedge reset) begin
	if (reset) begin
		pIRQA <= 0;
		pPV   <= 0;
		IRQ1  <= 0;
		IRQ2  <= 0;
	end
	else begin
		if ((pIRQA[0]^IRQA[0]) & ~IRQA[0]) IRQ1 <= 0;
		if ((pIRQA[1]^IRQA[1]) & ~IRQA[1]) IRQ2 <= 0;

		if (pPV!=PV) begin
			case (PV)
			0,64,128,192: IRQ1 <= IRQA[0];
			         224: IRQ2 <= IRQA[1];
			default:;
			endcase
		end

		pIRQA <= IRQA;
		pPV   <= PV;
	end
end

assign IRQ = {1'b0,IRQ2,IRQ1};

endmodule


//	MC68000-IP wrapper
module MC68000W
(
	input				clk,
	input				reset,
	input	 [15:0]	din,
	input				dtack,
	input	  [2:0]	ipl,
	output [22:0]	addr,
	output [15:0]	dout,
	output			as,
	output			uds,
	output			lds,
	output			rw
);

wire dd;

wire [31:0] _ad;
wire _uds, _lds, _rw, _as;

TG68 cpucore
(
	.clk(clk),
	.reset(~reset),
	.clkena_in(1'b1),
	.data_in(din),
	.IPL(~ipl),
	.dtack(~dtack),
	.addr(_ad),
	.data_out(dout),
	.as(_as),
	.uds(_uds),
	.lds(_lds),
	.rw(_rw),
	.drive_data(dd)
);
	
assign as	= ~_as;
assign rw   = ~_rw;
assign uds  = ~_uds;
assign lds  = ~_lds;

assign addr = _ad[23:1];

endmodule

