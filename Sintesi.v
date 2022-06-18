module ABC(
	soc, dav_, min,
	rfd, eoc1, x1, eoc2, x2, eoc3, x3, clock, reset_
);

output soc, dav_;
output [7:0] min;

input [7:0] x1, x2, x3;
input eoc1, eoc2, eoc3, rfd, clock, reset_;

wire b4,b3,b2,b1,b0;
wire c2,c1,c0;

Parte_Operativa PO(soc, dav_, min, c2, c1, c0, rfd, eoc1, x1, eoc2, x2, eoc3, x3, clock, reset_, b4, b3, b2, b1, b0);
Parte_Controllo PC(b4, b3, b2, b1, b0, clock, reset_, c2, c1, c0);
endmodule

module Parte_Operativa(
	soc, dav_, min, c2, c1, c0,
	rfd, eoc1, x1, eoc2, x2, eoc3, x3, clock, reset_, b4, b3, b2, b1, b0
);

output soc, dav_, c2, c1, c0;
output [7:0] min;

input [7:0] x1, x2, x3;
input eoc1, eoc2, eoc3, rfd, clock, reset_, b4, b3, b2, b1, b0;

reg			SOC; 			assign soc = SOC;
reg			DAV_;			assign dav_ = DAV_;
reg [7:0] 	MIN;			assign min = MIN;

wire [7:0] minimo_i;
MINIMO_3 minimo(x1, x2, x3, minimo_i);

assign c0 = ({eoc1, eoc2, eoc3} == 3'B000) ? 1 : 0;
assign c1 = ({eoc1, eoc2, eoc3} == 3'B111) ? 1 : 0;
assign c2 = ~rfd;

// Registro SOC
always @(reset_ == 0) #1 SOC <= 0;
always @(posedge clock) if(reset_ == 1) #3
	casex({b1,b0})
		'B00: SOC <= 1;
		'B01: SOC <= 0;
		'B1?: SOC <= SOC;
	endcase

// Registro DAV_
always @(reset_ == 0) #1 DAV_ <= 1;
always @(posedge clock) if(reset_ == 1) #3
	casex({b3, b2})
		'B1?: DAV_ <= DAV_;
		'B00: DAV_ <= 0;
		'B01: DAV_ <= 1;
	endcase

// Registro MIN
always @(posedge clock) if(reset_ == 1) #3
	casex(b4)
		1: MIN <= MIN;
		0: MIN <= minimo_i;
	endcase
endmodule

module Parte_Controllo(
	b4, b3, b2, b1, b0,
	clock, reset_, c2, c1, c0
);

output b4, b3, b2, b1, b0;
input clock, reset_, c2, c1, c0;

reg [2:0]	STAR;
parameter S0='B00, S1='B01, S2='B10, S3='B11;

assign {b4,b3,b2,b1,b0} = 	(STAR == S0) ? 5'B11X00 :
							(STAR == S1) ? 5'B01X01 :
							(STAR == S2) ? 5'B1001X :
							/*   S3   */   5'B1011X;

always @(reset_ == 0) #1 STAR <= S0;
always @(posedge clock) if(reset_ == 1) #3
	casex(STAR)
		S0: STAR <= (c0 == 1) ? S1 : S0;
		S1: STAR <= (c1 == 1) ? S2 : S1;
		S2: STAR <= (c2 == 1) ? S3 : S2;
		S3: STAR <= (c2 == 1) ? S3 : S0;
	endcase
endmodule

// Rete composta da due sottrattori che guidano altrettanti multiplexer a due vie
// i quali selezionano il minimo tra gli operandi delle rispettive sottrazioni
module MINIMO_3(
	a, b, c,
	min
);
	input 	[7:0] a, b, c;
	output 	[7:0] min;

	wire [7:0] min_a_b;
	MINIMO_2 m1(a, b, min_a_b);

	wire [7:0] min_a_b_c;
	MINIMO_2 m2(min_a_b, c, min_a_b_c);

	assign min = min_a_b_c;
endmodule

module MINIMO_2(
	a, b,
	min
);
	input 	[7:0] a, b;
	output 	[7:0] min;

	wire b_out;
	sottrattore #( .N(8) ) s(
		.x(a), .y(b), .b_in(1'B0),
		.b_out(b_out)
	);

	assign min = b_out ? a : b;
endmodule

/********************************************************************************************
*	ROM PARTE CONTROLLO																		*
*																							*
*	Stato	CodificaStato	b4 b3 b2 b1 b0 	Ceff	NextMicroAddressT	NextMicroAddressF	*
*	S0		00				1  1  -  0  0	00		01					00					*
*	S1		01				0  1  -  0  1	01		10					01					*
*	S2		10				1  0  0  1  -	10		11					10					*
*	S3		11				1  0  1  1  -	10		11					00					*
********************************************************************************************/