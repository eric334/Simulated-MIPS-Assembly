module tb();

	// external regs
	reg clock, reset; // maintenence regs
	
	// wires to connect our 3 modules
	wire MemWrite;
	wire [31:0] 	ALUOut,
			WriteData,
			ReadData,
			Instruction,
			PC;


top mips(clock, reset);

integer i;
initial
    begin
        clock = 0;
        reset = 0;
        #10;
        reset = 1;
        clock = 1;
        #10;
        reset = 0;
        clock = 0;
        #10;
        for(i=0;i<128;i=i+1)
            begin
                clock = 1;
                #10;
                clock = 0;
                #10;
            end
        $stop;
    end

endmodule