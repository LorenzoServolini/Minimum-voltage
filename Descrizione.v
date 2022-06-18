module ABC(
	soc, dav_, min,
	rfd, eoc1, x1, eoc2, x2, eoc3, x3, clock, reset_
);

output soc, dav_;
output [7:0] min;

input [7:0] x1, x2, x3;
input eoc1, eoc2, eoc3, rfd, clock, reset_;

reg			SOC; 			assign soc = SOC;
reg			DAV_;			assign dav_ = DAV_;
reg [7:0] 	MIN;			assign min = MIN;
reg [2:0]	STAR; parameter S0=0, S1=1, S2=2, S3=3;

wire [7:0] minimo_i;
MINIMO_3 minimo(x1, x2, x3, minimo_i);

always @(reset_ == 0) #1
begin
	SOC <= 0;
	DAV_ <= 1;
	STAR <= S0;
end

always @(posedge clock) if(reset_ == 1) #3
	casex(STAR)
		S0: 
			begin
				SOC <= 1;
				STAR <= ({eoc1, eoc2, eoc3} == 3'B000) ? S1 : S0;
			end
		S1:
			begin
				SOC <= 0;
				MIN <= minimo_i;
				STAR <= ({eoc1, eoc2, eoc3} == 3'B111) ? S2 : S1;
			end
		S2:
			begin
				DAV_ <= 0;
				STAR <= (rfd == 0) ? S3 : S2;
			end
		S3: 
			begin
				DAV_ <= 1;
				STAR <= (rfd == 1) ? S0 : S3;
			end
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