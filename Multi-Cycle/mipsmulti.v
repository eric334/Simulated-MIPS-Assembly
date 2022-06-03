//-------------------------------------------------------
// Multicycle MIPS processor
//------------------------------------------------

module mips(input        clk, reset,
            output [31:0] adr, writedata,
            output        memwrite,
            input [31:0] readdata);

  wire        zero, pcen, irwrite, regwrite,
               alusrca, iord, memtoreg, regdst;
  wire [1:0]  alusrcb, pcsrc;
  wire [2:0]  alucontrol;
  wire [5:0]  op, funct;

  controller c(clk, reset, op, funct, zero,
               pcen, memwrite, irwrite, regwrite,
               alusrca, iord, memtoreg, regdst, 
               alusrcb, pcsrc, alucontrol);
  datapath dp(clk, reset, 
              pcen, irwrite, regwrite,
              alusrca, iord, memtoreg, regdst,
              alusrcb, pcsrc, alucontrol,
              op, funct, zero,
              adr, writedata, readdata);
endmodule

// Todo: Implement controller module
module controller(input       clk, reset,
                  input [5:0] op, funct,
                  input       zero,
                  output       pcen, memwrite, irwrite, regwrite,
                  output       alusrca, iord, memtoreg, regdst,
                  output [1:0] alusrcb, pcsrc,
                  output [2:0] alucontrol);
	
	reg[2:0] ALUcontrol;
	reg[3:0] decodercontrol, nextcontrol;

	wire pcwrite;
	wire[1:0] aluop;
	wire branch;

	reg[14:0] controls;
	assign 	pcwrite = controls[14];
	assign 	memwrite = controls[13];
	assign 	irwrite = controls[12];
	assign 	regwrite = controls[11];
	assign 	alusrca = controls[10];
	assign 	branch = controls[9];
	assign 	iord = controls[8];
	assign 	memtoreg = controls[7];
	assign 	regdst = controls[6];
	assign 	alusrcb[1:0] = controls[5:4];
	assign 	pcsrc[1:0] = controls[3:2];
	assign 	aluop[1:0] = controls[1:0];

	assign pcen = pcwrite ||(branch && zero);

	assign alucontrol = ALUcontrol;

	initial begin
		decodercontrol <= 4'b0000;
	end

	always @ (posedge clk) begin
		decodercontrol <= nextcontrol;
		if(reset == 1) begin
			decodercontrol <= 4'b0000;
		end
	end

	always @(*) begin
		case(decodercontrol)
			4'b0000: begin // s0
				controls <= 15'b101000000010000; 
				nextcontrol <= 4'b0001;
			end
			4'b0001: begin // s1
				controls <= 15'b000000000110000;
				case(op)
					6'b000010: // jump
						nextcontrol <= 4'b1011;
					6'b001000: // addi
						nextcontrol <= 4'b1001;
					6'b000100: // beq
						nextcontrol <= 4'b1000;
					6'b000000: // rtype
						nextcontrol <= 4'b0110;
					6'b101011: // sw
						nextcontrol <= 4'b0010;
					6'b100011: // lw
						nextcontrol <= 4'b0010;
				endcase
			end
			4'b0010: begin // s2
				controls <= 15'b000010000100000;
					case(op)
						6'b101011: // sw
							nextcontrol <= 4'b0101;
						6'b100011: // lw
							nextcontrol <= 4'b0011;
					endcase
			end
			4'b0011: begin// s3
				controls <= 15'b000000100000000;
				nextcontrol <= 4'b0100;
			end
			4'b0100: begin// s4
				controls <= 15'b000100010000000;
				nextcontrol <= 4'b0000;
			end
			4'b0101: begin// s5
				controls <= 15'b010000100000000;
				nextcontrol <= 4'b0000;
			end
			4'b0110: begin// s6
				controls <= 15'b000010000000010;
				nextcontrol <= 4'b0111;
			end
			4'b0111: begin// s7
				controls <= 15'b000100001000000;
				nextcontrol <= 4'b0000;
			end
			4'b1000: begin// s8
				controls <= 15'b000011000000101;
				nextcontrol <= 4'b0000;
			end
			4'b1001: begin// s9
				controls <= 15'b000010000100000;
				nextcontrol <= 4'b1010;
			end
			4'b1010: begin// s10
				controls <= 15'b000100000000000;
				nextcontrol <= 4'b0000;
			end			
			4'b1011: begin// s11
				controls <= 15'b1000000000001000;
				nextcontrol <= 4'b0000;
			end
			default:
				controls <= 15'bxxxxxxxxxxxxxxx;
		endcase

		case (aluop)
			2'b00: ALUcontrol <= 3'b010; // add
			2'b01: ALUcontrol <= 3'b110; // sub
			2'b11: ALUcontrol <= 3'b001; // ori
			default: case(funct) // RTYPE
				6'b100000: ALUcontrol <= 3'b010; // ADD
				6'b100010: ALUcontrol <= 3'b110; // SUB
				6'b100100: ALUcontrol <= 3'b000; // AND
				6'b100101: ALUcontrol <= 3'b001; // OR
				6'b101010: ALUcontrol <= 3'b111; // SLT
				default: ALUcontrol <= 3'bxxx; // ???
			endcase
		endcase
	end
 
endmodule

// Todo: Implement datapath
module datapath(input        clk, reset,
                input        pcen, irwrite, regwrite,
                input        alusrca, iord, memtoreg, regdst,
                input [1:0]  alusrcb, pcsrc, 
                input [2:0]  alucontrol,
                output [5:0]  op, funct,
                output        zero,
                output [31:0] adr, writedata, 
                input [31:0] readdata);

	wire [31:0] Instr, Data, SrcA, SrcB, ALUResult, ImmExt, ImmExtShifted, ALUOut, PCJump, PCPrime, PC, ADR, WD3, RD1, RD2, A, B;
	wire [4:0] A1, A2, A3;
	wire ZERO;

	conswitch PCEN(clk, reset, pcen, PCPrime, PC);
	conswitch IRWRITE(clk, reset, irwrite, readdata, Instr);

	switch REGA(clk, reset, RD1, A);
	switch REGB(clk, reset, RD2, B);
	switch ALU(clk, reset, ALUResult, ALUOut);
	switch RDDATA(clk, reset, readdata, Data);

	mux2 IORD(iord, PC, ALUOut, ADR);
	mux2 MEMTOREG(memtoreg, ALUOut, Data, WD3);
	mux2 ALUSRCA(alusrca, PC, A, SrcA);
	
	mux2small REGDST(regdst, Instr[20:16], Instr[15:11], A3);

	mux3 PCSRC(pcsrc, ALUResult, ALUOut, PCJump, PCPrime);
	
	mux4 ALUSRCB(alusrcb, B, 4, ImmExt, ImmExtShifted, SrcB);

	ALU CALC(SrcA, SrcB, alucontrol, ALUResult, ZERO);

	registerfile REGISTER(clk, A1, A2, A3, regwrite, WD3, RD1, RD2);

	shift2 IMMEXT(ImmExt, ImmExtShifted);
	
	shift2small JUMP(Instr[25:0], PCJump[27:0]);

	signextend INSTR(Instr[15:0], ImmExt);

	assign writedata = B;
	assign adr = ADR;
	assign zero = ZERO;

	assign PCJump[31:28] = PC[31:28];

	assign A1 = Instr[25:21];
	assign A2 = Instr[20:16];

	assign op = Instr[31:26];
	assign funct = Instr[5:0];

endmodule

module registerfile(	input clk,
			input[4:0] a1, a2, a3,
			input we3, 
			input [31:0] wd3,
			output [31:0] rd1, rd2);
	
	reg[31:0] registers[31:0];

	assign rd1 = registers[a1];
	assign rd2 = registers[a2];

	//initialize the registers in the array
	integer i;	
	initial begin
		for (i=0; i<32; i=i+1) registers[i] <= 0;
	end

	always @ (posedge clk) begin
		if (we3 == 1)
			registers[a3] <= wd3;
	end

endmodule

module conswitch(	input clk, reset, en,
			input [31:0] d,
			output [31:0] q);
	reg[31:0] Q;

	assign q = Q;

	always @(posedge clk, posedge reset) begin
		if(reset == 1)
			Q <= 0;
		else if (en == 1)
			Q <= d;
	end
	
endmodule

module switch(	input clk, reset,
		input [31:0] d,
		output [31:0] q);
	reg[31:0] Q;

	assign q = Q;

	always @(posedge clk, posedge reset) begin
		if(reset == 1)
			Q <= 0;
		else
			Q <= d;
	end
	
endmodule

module mux2(	input s,
		input [31:0] a, b,
		output [31:0] q);

	reg[31:0] Q;
	assign q = Q;

	always @ * begin
		if(s == 0)
			Q <= a;
		else
			Q <= b;
	end	

endmodule

module mux2small(	input s,
			input [4:0] a, b,
			output [4:0] q);

	reg[4:0] Q;
	assign q = Q;

	always @ * begin
		if(s == 0)
			Q <= a;
		else
			Q <= b;
	end	

endmodule

module mux3(	input [1:0] s,
		input [31:0] a, b, c,
		output [31:0] q);

	reg[31:0] Q;
	assign q = Q;

	always @ * begin
		case(s)
			2'b00: Q <= a;
			2'b01: Q <= b;
			2'b10: Q <= c;
		endcase
	end	

endmodule

module mux4(	input [1:0] s,
		input [31:0] a, b, c, d,
		output [31:0] q);

	reg[31:0] Q;
	assign q = Q;

	always @ * begin
		case(s)
			2'b00: Q <= a;
			2'b01: Q <= b;
			2'b10: Q <= c;
			2'b11: Q <= d;
		endcase
	end	

endmodule

module shift2 (	input [31:0] a, 
		output [31:0] q);
	
	assign q = a << 2;
endmodule

module shift2small (	input [25:0] a, 
		output [31:0] q);
	
	assign q = a << 2;
endmodule

module adder (	input [31:0] a, b, 
		output [31:0] q);

	assign q = a + b ;
endmodule

module signextend(	input[15:0] a,
			output[31:0] q);

	assign q = {{16{a[15]}}, a};

endmodule
