// single-cycle MIPS processor
// instantiates a controller and a datapath module

module mips(input          clk, reset,
            output  [31:0] pc,
            input   [31:0] instr,
            output         memwrite,
            output  [31:0] aluout, writedata,
            input   [31:0] readdata);

  wire        memtoreg, branch,
               pcsrc, zero,
               alusrc, regdst, regwrite, jump;
  wire [2:0]  alucontrol;

  controller c(instr[31:26], instr[5:0], zero,
               memtoreg, memwrite, pcsrc,
               alusrc, regdst, regwrite, jump,
               alucontrol);
  datapath dp(clk, reset, memtoreg, pcsrc,
              alusrc, regdst, regwrite, jump,
              alucontrol,
              zero, pc, instr,
              aluout, writedata, readdata);
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
		if(s == 1)
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
		if(s == 1)
			Q <= a;
		else
			Q <= b;
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

module datapath(	input          clk, reset,
                	input          memtoreg, pcsrc,
               	 	input          alusrc, regdst,
               	 	input          regwrite, jump,
                	input   [2:0]  alucontrol,
                	output         zero,
                	output  [31:0] pc,
                	input   [31:0] instr,
                	output  [31:0] aluout, writedata,
                	input   [31:0] readdata);
	
	//list of all internal wires in the circuit
	wire [4:0] WriteReg;
	wire [31:0] SrcA, SrcB, Result, InstrShifted, ImmExt, PCBranch, BranchBridge, PCPlus4, PCJump, PCBridge, PCPrime;

	assign PCJump[27:0] = InstrShifted;
	assign PCJump[31:28] = PCPlus4[31:28];

	//the array of registers central to the circuit
	registerfile primary(clk, instr[25:21], instr[20:16], WriteReg, regwrite, Result, SrcA, writedata);
	
	//the primary alu of the circuit
	ALU calc(SrcA, SrcB, alucontrol, aluout, zero);

	//the two shifter modules i nthe circuit
	shift2small instr_shift(instr[25:0], InstrShifted);
	shift2 branch_shift(ImmExt, BranchBridge);
	
	//adders
	adder plus4(pc, 4, PCPlus4);
	adder brancher(BranchBridge, PCPlus4, PCBranch);

	//all of the multiplexers in the ciruit labeld by their toggle wire
	mux2 PCSRC(pcsrc, PCBranch, PCPlus4, PCBridge);
	mux2 JUMP(jump, PCJump, PCBridge, PCPrime);
	mux2small REGDST(regdst, instr[15:11], instr[20:16], WriteReg);
	mux2 ALUSRC(alusrc, ImmExt, writedata, SrcB);
	mux2 MEMTOREG(memtoreg, readdata, aluout, Result);

	//sign extender
	signextend IMMEXT(instr[15:0], ImmExt);

	// flip flop
	switch flipflop(clk, reset, PCPrime, pc);

endmodule

module controller(input   [5:0] op, funct,
                  input         zero,
                  output        memtoreg, memwrite,
                  output        pcsrc, alusrc,
                  output        regdst, regwrite,
                  output        jump,
                  output  [2:0] alucontrol);

	reg[2:0] ALUcontrol;

	wire[1:0] aluop;
	wire branch;
// VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV UPDATED TO IMPLEMENT BNE VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
	wire bne;

	reg[9:0] controls;

// VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV UPDATED TO IMPLEMENT BNE VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
	assign 	bne = controls[9];
	assign 	regwrite = controls[8];
	assign	regdst = controls[7];
	assign	alusrc = controls[6];
	assign	branch = controls[5];
	assign	memwrite = controls[4];
	assign	memtoreg = controls[3];
	assign	jump = controls[2];
	assign	aluop = controls[1:0];

	assign pcsrc = zero & branch;
// VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV UPDATED TO IMPLEMENT BNE VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
	assign pcsrc = !zero & bne;
	assign alucontrol = ALUcontrol;

	always @(*) begin
		case(op)
			6'b000000: controls <= 10'b0110000010; //Rtyp
			6'b100011: controls <= 10'b0101001000; //LW
			6'b101011: controls <= 10'b0001010000; //SW
			6'b000100: controls <= 10'b0000100001; //BEQ
			6'b001000: controls <= 10'b0101000000; //ADDI
			6'b000010: controls <= 10'b0000000100; //J
// VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV UPDATED TO IMPLEMENT ORI VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
			6'b001101: controls <= 10'b0101000011; //ORI
// VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV UPDATED TO IMPLEMENT BNE VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
			6'b000101: controls <= 10'b1000000001; //BNE
			default: controls <= 10'bxxxxxxxxxx; //???
		endcase

		case (aluop)
			2'b00: ALUcontrol <= 3'b010; // add
			2'b01: ALUcontrol <= 3'b110; // sub
// VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV UPDATED TO IMPLEMENT ORI VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
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
