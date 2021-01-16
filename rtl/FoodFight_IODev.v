// Copyright (c) 2019 MiSTer-X

module IODEV
(
	input	 [7:0]		AX0,
	input	 [7:0]		AY0,
	input	 [7:0]		AX1,
	input	 [7:0]		AY1,
	input  [7:0]		DIN,

	output reg [7:0]	DOUT = 0,

	input					reset,
	input					cl,
	input  [22:0]		ad,
	input					as,
	input					rw,
	input					lds,
	input					uds,
	input	 [15:0]		od,

	output reg			dtack,
	output				dv,
	output [15:0]		id,
	
	
	input					DLCL,		// Downloaded ROM image
	input  [16:0]		DLAD,
	input   [7:0]		DLDT,
	input					DLEN
);

// Address decoders
wire cs_nvr = as & (ad[22:17] == 6'b1001_00);								// $900000-$9001FF (NVRAM)
wire cs_adc = as & (ad[22:17] == 6'b1001_01) & (ad[15:13]==3'b0_00);	// $940000-$940001 (ADC value)
wire cs_adq = as & (ad[22:17] == 6'b1001_01) & (ad[15:13]==3'b0_01);	// $944000-$944007 (ADC start)
wire cs_dio = as & (ad[22:17] == 6'b1001_01) & (ad[15:13]==3'b0_10);	// $948000-$948001 (Digital I/O)
wire cs_nvc = as & (ad[22:17] == 6'b1001_01) & (ad[15:13]==3'b1_01);	// $954000-$954001 (NVRAM Recall)
wire cs_wdt = as & (ad[22:17] == 6'b1001_01) & (ad[15:13]==3'b1_10);	// $958000-$958001 (Watch-dog Timer)

wire cs_dm0 = as & (ad[22:17] == 6'b1001_01) & (ad[15:13]==3'b0_11);	// $94C000-$94C001 (unknown)
wire cs_dm1 = as & (ad[22:19] == 4'b1111);									// $F00000-$FFFFFF (unknown)

// DTACK
wire axs = ( cs_nvr | cs_adc | cs_adq | cs_dio | cs_nvc | cs_wdt | cs_dm0 | cs_dm1 ) & (uds|lds);
always @( posedge cl ) begin
	if (reset) dtack <= 0;
	else dtack <= axs;
end

// NVRAM
wire [3:0] nvr_dt;
NVRAM nvram(cl,ad[7:0],cs_nvr & lds,rw,od[3:0],nvr_dt, DLCL,DLAD,DLDT,DLEN);

// Digital Output
always @( posedge cl ) begin
	if (reset) DOUT <= 0;
	else if (cs_dio & rw & lds) DOUT <= od[7:0];
end

// Digital Input
reg  [7:0] din_dt;
always @( posedge cl ) begin
	if (cs_dio & (~rw) & lds) din_dt <= DIN;
end

// Analog Input
reg [1:0] adcs = 0;
always @( posedge cl ) begin
	if (reset) adcs <= 0;
	else if (cs_adq & rw & lds) adcs <= ad[1:0];
end
wire [7:0] adc_dt = (adcs==2'b00) ? AY1 :
						  (adcs==2'b01) ? AY0 : 
						  (adcs==2'b10) ? AX1 : 
												AX0 ;

// CPU read data
assign dv = axs & (~rw);
assign id = cs_dio ? {  8'hFF,din_dt} :
				cs_adc ? {  8'h00,adc_dt} :
				cs_nvr ? {12'hFFF,nvr_dt} :
			   16'hFFFF;

endmodule

