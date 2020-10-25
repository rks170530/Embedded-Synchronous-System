/* 
 *	File: Project.v
 *	Author: Raman Srivastava
 *	Modules:
 *			testSystem			- Testbench to demonstrate the functionality of the System by giving the
 *								  Processor a start signal every 2500 ticks.
 *			Aribiter			- A module that takes the Requests of the Processor, Memory, I/P and O/P
 *								  and provides the appropriate grant signals.
 *			Processor			- A module that when given a start signal, will ask the I/P to transfer 9 
 *								  values to the Memory, then load the memory values into its 9 registers,
 *								  add 9 values with seven 3:2 adders and one RC adder, and then store the	
 *								  sum back to the Memory, and then request the O/P to display that sum.
 *			Memory				- A module that checks the read/write bits of the System Bus, and 
 *								  either stores or loads from storage.
 *			InputUnit			- Module that loads from the TestData.txt file into a buffer to eventually
 *								  store into the Module module via the System Bus.
 *			OutputUnit			- Module that outputs to the command line by requesting specific data initial
 *								  the Memory module via the System Bus.
 *			ThreeByTwoAdder		- Takes three 11-bit values, adds them and outputs the 11-bit Sum and Carry 
 *								  results.
 *			RippleCarryAdder	- Takes the 11-bit Carry and Sum values, adds them and outputs the 12-bit
 *								  result.
 *			FullAdder			- Takes three 1-bit inputs and outputs the 1-bit Sum and Carry bits. 
 *			SystemClock			- Clock module that keeps the program synchronized with a cycle of 20. 
 */	
 
 /*
 *	Module: testSystem			- Testbench to demonstrate the functionality of the System by giving the
 *								  Processor a start signal every 2500 ticks.
 *
 *	Author: Raman Srivastava
 *	Ports: 	None
 *
 */ 
module testSystem;												// Establishes the name of the module and the ports.
	
	wire iSysClock;												// 1-bit wire for the Systm Clock.													
	wire [33:0] ioSysBus;										// 34-bit for the System Bus.
	
	wire readBit;												// 1-bit wire for the Read bit.
	wire writeBit;												// 1-bit wire for the Write bit.
	wire [15:0] addressBits;									// 16-bit wire for the Address bits.
	wire [15:0] dataBits;										// 16-bit wire for the Data bits.

	reg [3:0] iRequestLine;										// 4-bit Reg for the Request line.
	wire [3:0] oGrantLine;										// 4-bit Wire for the Grant line.
	
	reg [3:0] iGrantLine;										// 4-bit Reg for the Grant line.
	wire [3:0] oRequestLine;									// 4-bit Wire for the Request line.
		
	
	reg [33:0] testBus;											// 34-bit Reg to transfer values to the System Bus.
	
	reg iOPInterrupt;											// 1-bit Reg for the O/P Interrupt.
	reg iIPInterrupt;											// 1-bit Reg for the I/P Interrupt.
	wire oOPInterrupt;											// 1-bit Wire for the O/P Interrupt.
	wire oIPInterrupt;											// 1-bit Wire for the I/P Interrupt.
	
	reg iProcessStart;											// 1-bit Reg for starting the Processor to output the Sum of the 9 values.
	
	SystemClock testC(iSysClock);																							// Instantiate the Clock Module.
	Arbiter testA(oGrantLine, iRequestLine, iSysClock);																		// Instantiate the Arbiter Module.
	Processor testCPU(oRequestLine[3], ioSysBus, iGrantLine[3], iIPInterrupt, iOPInterrupt, iProcessStart, iSysClock);		// Instantiate the Processor Module.
	Memory testMem(oRequestLine[2], ioSysBus, iGrantLine[2], iSysClock);													// Instantiate the Memory Module.
	InputUnit testIP(oRequestLine[1], oIPInterrupt, ioSysBus, iGrantLine[1], iSysClock);									// Instantiate the I/P Module.
	OutputUnit testOP(oRequestLine[0], oOPInterrupt, ioSysBus, iGrantLine[0], iSysClock);									// Instantiate the O/P Module.
	
	assign ioSysBus = !(iGrantLine) ? testBus : 34'bz;			 	// Check if the GrantLine is 4'b0000, if so assign to the System Bus.	
	assign {readBit, writeBit, addressBits, dataBits} = ioSysBus;	// Assign the Read, Write, Address, and Data bits from the ioSysBus.
	
	always @(posedge iSysClock) begin							// Always block, as long as the Clock edge is positive. 
	
		iRequestLine = oRequestLine;							// Set iRequestLine to oRequestLine.
		iGrantLine = oGrantLine;								// Set iGrantLine to oGrantLine.
		iIPInterrupt = oIPInterrupt;							// Set iIPInterrupt to oIPInterrupt.
		iOPInterrupt = oOPInterrupt;							// Set iOPInterrupt to oOPInterrupt.
	end															// End of the Always Block. 
	
	initial begin												// Start of the initial block.
	
		iRequestLine = 4'b0000;									// Set the iRequestLine to 0000 initially.
				
		repeat (111) begin										// Iterate through block 9 times.							
			iProcessStart = 1'b1;								// Set iProcessStart to 1.
			#20 iProcessStart = 1'b0;							// After 20 ticks, set iProcessStart to 0.
			
			#2480 $display("");									// After 2480 ticks, display nothing for a new line.
		end														// End of the Repeat block.
		
		// $display($time, ", Request = %b, Grant = %b, R = %b, W = %b, A = %h, D = %h", iRequestLine, oGrantLine, ioSysBus[33], ioSysBus[32], ioSysBus[31:16], ioSysBus[15:0]);
		
		$finish;										
	end															// End of the initial block.

endmodule														// End of the module.

/*
 *	Aribiter					- A module that takes the Requests of the Processor, Memory, I/P and O/P
 *								  and provides the appropriate grant signals.
 *
 *	Author: Raman Srivastava
 *	Ports: 	
 *		sysGrantLine			O/P			A 4-bit input for the Grant Line.
 *		sysRequestLine			O/P			A 4-bit input for the Request Line.
 *		sysClock				I/P		    A 1-bit input the System Clock values.
 *
 */
module Arbiter(output [3:0] sysGrantLine, input [3:0] sysRequestLine,  input sysClock); // Establishes the name of the module and ports.

	reg [3:0] sysGrantLine;										// 4-bit Reg for setting the Grant Line.
	
	initial begin												// Start of the initial block.
	
		sysGrantLine = 4'b0000;									// Set the sysGrantLine to 0 intially.
	end															// End of the initial block.
	
	always @(posedge sysClock) begin							// Always block, as long as the Clock edge is positive.
	
		if (sysRequestLine == 4'b1000) begin					// Check if the sysRequestLine is 1000.
			
			sysGrantLine = 4'b1000;								// Set the sysGrantLine to 1000.
		end														// End of the If block.
		
		else if (sysRequestLine == 4'b0100) begin				// Check if the sysRequestLine is 0100.
			
			sysGrantLine = 4'b0100;								// Set the sysGrantLine to 0100.
		end														// End of the If block.
		
		else if (sysRequestLine == 4'b0010) begin				// Check if the sysRequestLine is 0010.
			
			sysGrantLine = 4'b0010;								// Set the sysGrantLine to 0010.
		end														// End of the If block.
		
		else if (sysRequestLine == 4'b0001) begin				// Set the sysGrantLine to 0001.
				
			sysGrantLine = 4'b0001;								// Set the sysGrantLine to 0001.
		end														// End of the If block.
		
		else begin												// Otherwise, if none of the above is true.
			
			sysGrantLine = 4'b0000;								// Set the sysGrantLine to 0000. 
		end														// End of the If block.
	end															// End of the ALways block.
	
endmodule

/*
 *	Processor					- A module that when given a start signal, will ask the I/P to transfer 9 
 *								  values to the Memory, then load the memory values into its 9 registers,
 *								  add 9 values with seven 3:2 adders and one RC adder, and then store the	
 *								  sum back to the Memory, and then request the O/P to display that sum.
 *
 *	Author: Raman Srivastava
 *	Ports: 	
 *		sysGrantLine			O/P			A 4-bit input for the Grant Line.
 *		sysBus					I/O			A 34-bit In/Out wire for the System Bus.		
 *		grantCheck				I/P			A 1-bit input for the Grant Line check.
 *      ipInterrupt				I/P			A 1-bit input for the I/P interrupt value.
 *		opInterrupt				I/P 		A 1-bit input for the O/P interrupt value.
 *		sysStart				I/P 		A 1-bit input for the System Start value.
 *		sysClock				I/P		    A 1-bit input the System Clock values.
 *
 */
module Processor(output sysRequest, inout [33:0] sysBus, input grantCheck, input ipInterrupt, input opInterrupt, input sysStart, input sysClock); 	// Establishes the name of the module and ports.

	wire sysReadBit;							// 1-bit Wire for the Read Bit.					
	wire sysWriteBit;							// 1-bit Wire for the Write Bit.	
	wire [15:0] sysAddress;						// 16-bit Wire for the Address Bits
	wire [15:0] sysData;						// 16-bit Wire for the Data Bits.
	wire [33:0] sysBus;							// 34-bit Wire for the System Bus.

	wire [10:0] carryVar [6:0];					// A 7 element 11-bit wire array for the Carry Values.
	wire [10:0] sumVar [6:0];					// A 7 element 11-bit wire array for the Sum Values.			
	wire [11:0] regResult;						// A 12-bit wire for storing the final result.
	
	reg writeMem;								// 1-bit Reg to check if the Processor has written to the Memory.
	reg	writeReg;								// 1-bit Reg to check if the Processor has handled the I/P interrupt and written to its 9 registers.
	reg addReg;									// 1-bit Reg to check if the Processor has added the 9 registers and produced the final result.
	reg outSum;									// 1-bit Reg to check if the Processor has written the final result to Memory and called the O/P module for Output.
	reg endProcess;								// 1-bit Reg to check if the Processor has handled the O/P interrupt and to reset everything.
	
	reg	sysRequest;								// 1-bit Reg for the Module Request.
	reg [15:0] outAddress;						// 16-bit Reg for the Output Address.
	reg [15:0] regAddress;						// 16-bit Reg for the address to load into its 9 registers.
	reg [3:0] regCount; 						// 4-bit Reg for counting the Register indexes.
	reg [10:0] inputReg [8:0];					// A 9 element 11-bit Reg array that contain the 9 registers.
	reg [33:0] sysSpace;						// Storage for the System Bus as a reg.	 
	
	initial begin								// Start of the inital block.
		
		regCount = 0;							// Set the regCount to 0 initially.
		regAddress = 0;							// Set the regAddress to 0 initially.
		outAddress = 16'h0200;					// Set the outAddress to 0200 hex initially.
		writeMem = 0;							// Set the writeMem to 0 initially.
		writeReg = 0;							// Set the writeReg to 0 initially.
		addReg = 0;								// Set the addReg to 0 initially.
		outSum = 0;								// Set the outSum to 0 initially.
		endProcess = 0;							// Set the endProcess to 0 initially.
		sysRequest = 0;							// Set the sysRequest to 0 initially.
		sysSpace = 0;							// Set the sysSpace to 0 initially.
	end											// End of the initial block.
	
	assign {sysReadBit, sysWriteBit, sysAddress, sysData} = sysBus;			// Store the read, write, address, and data values from the System Bus.
	assign sysBus = grantCheck ? sysSpace : 34'bz;							// If the Grant Line is 1, assign sysBus to the System Bus, otherwise impede values.
	
	ThreeByTwoAdder cpuAdder1(carryVar[0], sumVar[0], inputReg[0], inputReg[1], inputReg[2]);   // Use a 3:2 Adder to compute carryVar and sumVar 0 values from inputReg 0, 1, and 2. 
	ThreeByTwoAdder cpuAdder2(carryVar[1], sumVar[1], inputReg[3], inputReg[4], inputReg[5]);	// Use a 3:2 Adder to compute carryVar and sumVar 1 values from inputReg 3, 4, and 5.
	ThreeByTwoAdder cpuAdder3(carryVar[2], sumVar[2], inputReg[6], inputReg[7], inputReg[8]);	// Use a 3:2 Adder to compute carryVar and sumVar 2 values from inputReg 6, 7, and 8.
	
	ThreeByTwoAdder cpuAdder4(carryVar[3], sumVar[3], sumVar[0], sumVar[1], sumVar[2]);		 	// Use a 3:2 Adder to compute carryVar and sumVar 3 values from sumVar 0, 1 and 2.
	ThreeByTwoAdder cpuAdder5(carryVar[4], sumVar[4], carryVar[0], carryVar[1], carryVar[2]);   // Use a 3:2 Adder to compute carryVar and sumVar 4 values from carryVar 0, 1 and 2.

	ThreeByTwoAdder cpuAdder6(carryVar[5], sumVar[5], sumVar[3], sumVar[4], carryVar[3]);		// Use a 3:2 Adder to compute carryVar and sumVar 5 values from sumVar 3 and 4 along with carryVar 3.
	ThreeByTwoAdder cpuAdder7(carryVar[6], sumVar[6], sumVar[5], carryVar[5], carryVar[4]);	 	// Use a 3:2 Adder to compute carryVar and sumVar 6 values from carryVar 4 and 5 along with sumVar 5.
	
	RippleCarryAdder cpuAdder8(regResult, carryVar[6], sumVar[6]);								// Use a RC Adder to compute regResult from carryVar and sumVar 6.
	
	always@(posedge sysClock) begin													// Always block, as long as the Clock edge is positive. 	
		
		if (sysStart == 1) begin 													// Check if the sysStart is 1. 
			
			sysRequest = 1;															// Set sysRequest to 1.
			writeMem = 1;															// Set writeMem to 1.
		end																			// End of the If block.
	
		if ((grantCheck == 1) && (writeMem == 1)) begin								// Check if the grantCheck and writeMem are 1.
			
			writeMem = 0;															// Set writeMem to 0.
			sysSpace = {1'b0, 1'b1, 16'hff00, 16'h0100};							// Set sysSpace to call on the I/P Unit with Address FF00 hex.
			sysRequest = 0;															// Set sysRequest to 0.
		end																			// End of the If block.
		
		if (ipInterrupt == 1) begin													// Check if the ipInterrupt is 1.
			
			sysRequest = 1;															// Set the sysRequest to 1.
			
			if (grantCheck == 1) begin												// Check if grantCheck is 1.
	
				sysSpace = {1'b0, 1'b0, 16'h0000, 16'hff00};						// Set sysSpace to tell the I/P that the interrupt is handled with Data FF00 hex.
				writeReg = 1;														// Set writeReg to 1.
			end																		// End of the inner If block.
		end																			// End of the outer If block.
		
		if ((ipInterrupt == 0) && (writeReg == 1) && (grantCheck == 1)) begin		// Check if the ipInterrupt is 0 and the writeReg and grantCheck are 1.
			
			writeReg = 0;															// Set writeReg to 0.
			regAddress = 16'h0100;													// Set regAddress to 0100 hex.
			
			repeat (9) begin														// Iterate through the block 9 times.
				
				sysSpace = {1'b1, 1'b0, regAddress, 16'h0000};						// Set the sysSpace to ask the Memory for the Data value at the Address regAddress.
				sysRequest = 0;														// Set the sysRequest to 0.
			
				#120 sysRequest = 1;												// Wait 120 cycles for the Memory Unit to output to the System Bus, and then set sysRequest to 1.
			
				while (grantCheck != 1) begin										// While the grantCheck is not 1 yet.
				
					#1 sysSpace = sysBus;											// Wait 1 cycle, then set sysSpace to sysBus.
				end																	// End of the while block.
				
				inputReg[regCount] = sysData[10:0];									//  Set the rightmost 11 bits of the sysData to the inputReg at element regCount. 
				// $display($time, ", Reg[%b] = %b, D = %b", regCount, inputReg[regCount], sysData[10:0]);  // for Logic Proof.
				
				regCount = regCount + 1;											// Increment the regCount by 1.
				regAddress = regAddress + 2;										// Increment the regAddress by 2.
			end																		// End of the Repeat block.
			
			addReg = 1;																// Set addReg to 1.
		end																			// End of the If block.
		
		
		if ((grantCheck == 1) && (addReg == 1)) begin								// Check if the grantCheck and addReg is 1.
			
			addReg = 0;																// Set addReg to 0.
			
			#20 sysSpace = {1'b0, 1'b1, outAddress, 4'b0, regResult};				// After 20 ticks, set the sysSpace for the Memory to store the regResult Data value at Address outAddress.
			// $display($time, ", Writing result '%b' to Address '%h'.", sysSpace[15:0], sysSpace[31:16]);  // for Logic Proof.
			
			outSum = 1;																// Set the outSum to 1.
		end																			// End of the If block.
		
		if ((grantCheck == 1) && (outSum == 1)) begin								//  Check if the grantCheck and outSum is 1.
		
			outSum = 0;																// Set outSum to 0.
			#20 sysSpace = {1'b0, 1'b1, 16'hff80, outAddress};						// After 20 ticks, set the sysSpace to ask O/P to output from Address outAddress with Address set to FF80 hex.
			sysRequest = 0;															// Set sysRequest to 0.
		end																			// End of the If block.
		
		if (opInterrupt == 1) begin													// If the opInterrupt is 1.
			
			sysRequest = 1;															// Set the sysRequest to 1.
			sysSpace = sysBus;														// Set the sysSpace to the sysBus. 
		
			if (grantCheck == 1) begin												// Check if the grantCheck is 1.
	
				sysSpace = {1'b0, 1'b0, 16'h0000, 16'hff80};						// Set sysSpace to tell the O/P that the interrupt is handled with Data FF80 hex.
				endProcess = 1;														// Set the endProcess to 1.
			end																		// End of the inner If block.
		end																			// End of the outer If block.
		
		if ((grantCheck == 1) && (endProcess == 1)) begin							// Chekc if the grantCheck and endProcess is 1.
			
			#20 																	// Wait 20 ticks.
			// $display($time, ", Successfully handled the O/P interrupt. ");		// for Logic Proof.
			regCount = 0;															// Set the regCount to 0.
			regAddress = 0;															// Set the regAddress to 0.
			outAddress = outAddress + 2;											// Increment the outAddress by 2.
		
			writeMem = 0;															// Set the writeMem to 0.
			writeReg = 0;															// Set the writeReg to 0.
			addReg = 0;																// Set the addReg to 0.
			outSum = 0;																// Set the outSum to 0.
			endProcess = 0;															// Set the endProcess to 0.
			sysRequest = 0;															// Set the sysRequest to 0.
			sysSpace = 0;															// Set the sysSpace to 0.	
		end																			// End of the If block.
	end																				// End of the Always block.
	
endmodule																			// End of the module.

/*
 *	Module: Memory				- A module that checks the read/write bits of the System Bus, and 
 *								  either stores or loads from storage.
 *
 *	Author: Raman Srivastava
 *	Ports: 	
 *		sysRequest				O/P 		A 1-bit output for requesting the Grant Line.
 *		sysBus					I/O			A 34-bit In/Out wire for the System Bus.
 *		grantCheck				I/P			A 1-bit input for the Grant Line check.
 *		sysClock				I/P			A 1-bit input the System Clock values.
 *
 */
module Memory(output sysRequest, inout [33:0] sysBus, input grantCheck, input sysClock); 	// Establishes the name of the module and ports.			
									
	wire sysReadBit;							// 1-bit Wire for the Read Bit.					
	wire sysWriteBit;							// 1-bit Wire for the Write Bit.	
	wire [15:0] sysAddress;						// 16-bit Wire for the Address Bits
	wire [15:0] sysData;						// 16-bit Wire for the Data Bits.
	wire [33:0] sysBus;							// 34-bit Wire for the System Bus.						
	
	reg	sysRequest;								// 1-bit Reg for the Module Request.
	reg [15:0] sysStorage [32640:0];			// Actual Storage of the Memory.			
	reg [33:0] sysSpace;						// Storage for the System Bus as a reg.					

	initial begin								// Start of the initial blcok.
		
		sysRequest = 0;							// Set the sysRequest to 0 initially.
		sysSpace = 0;							// Set the sysSpace to 0 initially.
	end											// End of the initial block.
	
	assign {sysReadBit, sysWriteBit, sysAddress, sysData} = sysBus;			// Store the read, write, address, and data values from the System Bus.
	assign sysBus = grantCheck ? sysSpace : 34'bz;							// If the Grant Line is 1, assign sysBus to the System Bus, otherwise impede values.
			
	always @(posedge sysClock) begin													// Always block, as long as the Clock edge is positive. 															
		
		if ((sysReadBit == 0) && (sysWriteBit == 1) && (sysAddress < 65280)) begin		// Check if the Write bit is 1 and the Adress is less than FF00.							
		
			sysStorage[sysAddress/2] = sysData;											// Store the value to sysStorage if Write bit is 1.
			// $display($time, ", Stored Data '%h' into Storage Element '%h'.", sysData, sysAddress/2);	// for Logic Proof.
		end																				// End of the If block.																	
		
		if ((sysReadBit) && (sysWriteBit == 0) && (sysAddress < 65280)) begin			// Check if the Read bit is 1 and the Adress is less than FF00.					
					
			sysRequest = 1;																// Set the sysRequest to 1.
			sysSpace = sysBus;															// Set the sysSpace to the sysRequest.

			if (grantCheck == 1) begin													// Check if the grantCheck is 1.
				
				sysSpace = {1'b0, 1'b0, sysAddress, sysStorage[sysAddress/2]};			// Load the value to the sysSpace if the Read bit is 1.							
				// $display($time, ", Loaded Data '%h' from Storage Element '%h'.", sysStorage[sysAddress/2], sysAddress/2); // for Logic Proof.
				sysRequest = 0;															// Set the sysRequest to 0.
			end																			// End of the inner If block.
		end																				// End of the outer If block.																							
	end																					// End of the Always block.				

endmodule																				// End of the module.

/*
 *	Module: InputUnit			- Module that loads from the TestData.txt file into a buffer to eventually
 *								  store into the Module module via the System Bus.
 *
 *	Author: Raman Srivastava
 *	Ports: 	
 *		sysRequest				O/P 		A 1-bit output for requesting the Grant Line.
 *		sysInterrupt			O/P			A 1-bit output for the I/P interrupt.
 *		sysBus					I/O			A 34-bit In/Out wire for the System Bus.
 *		grantCheck				I/P			A 1-bit input for the Grant Line check.
 *		sysClock				I/P			A 1-bit input the System Clock values.
 *
 */
module InputUnit(output sysRequest, output sysInterrupt, inout [33:0] sysBus, input grantCheck, input sysClock);  // Establishes the name of the module and ports.		

	wire sysReadBit;							// 1-bit Wire for the Read Bit.					
	wire sysWriteBit;							// 1-bit Wire for the Write Bit.	
	wire [15:0] sysAddress;						// 16-bit Wire for the Address Bits
	wire [15:0] sysData;						// 16-bit Wire for the Data Bits.
	wire [33:0] sysBus;							// 34-bit Wire for the System Bus.							
	
	reg	sysRequest;								// 1-bit Reg for the Module Request.
	reg sysInterrupt;							// 1-bit Reg for the Interrupt value.
	reg writeMem;								// 1-bit Reg to check if the I/P is done writing to memory.
	reg [9:0] inputIndex; 						// 10-bit Reg for the internalBuffer element.
	reg [15:0] inputAddress;					// 16-bit Reg for storing the Input Address.
	reg [7:0] internalBuffer [0:1023];			// 1024 bit Array with each elment 8 bit to store the Data file.
	reg [33:0] sysSpace;						// 34-bit Reg for the System Bus assigner.				
	
	initial begin									// Start of the initial block.	
			
		sysRequest = 0;								// Set the sysRequest to 0 intially.
		sysInterrupt = 0;							// Set the sysInterrupt to 0 intially.
		writeMem = 0;								// Set the writeMem to 0 intially.
		sysSpace = 0;								// Set the sysSpace to 0 intially.
		inputIndex = 0;								// Set the inputIndex to 0 intially.
		$readmemb("TestData.txt", internalBuffer);	// Read from the TestData.txt file to the internalBuffer.
	end												// End of the initial block.										
	
	assign {sysReadBit, sysWriteBit, sysAddress, sysData} = sysBus;			// Store the read, write, address, and data values from the System Bus.
	assign sysBus = grantCheck ? sysSpace : 34'bz;							// If the Grant Line is 1, assign sysBus to the System Bus, otherwise impede values.
	
	always @(posedge sysClock) begin										// Always block, as long as the Clock edge is positive. 					
		
		if ((sysAddress == 16'hff00) && (sysInterrupt == 0)) begin			// Check if the sysAddress is FF00 and the sysInterrupt is 0.								
			
			// $display($time, ", Requesting access from the Input Unit since the Address is %h.", sysAddress);	// for Logic Proof.
			inputAddress = sysData;											// Load the inputAddress to the sysData value.
			writeMem = 1;													// Set the writeMem to 1.
			sysRequest = 1;													// Set the sysRequest to 1.
		end																	// End of the If block.												
			
		if ((grantCheck == 1) && (writeMem == 1)) begin						// Check if the Grant Line is 1 and the writeMem is 1.								
			
			repeat (9) begin												// Iterate through block 9 times.										
			
				if (sysRequest == 1) begin									// Check if the sysRequest is 1.					
					sysSpace = {1'b0, 1'b1, inputAddress, 8'b0, internalBuffer[inputIndex]}; 	// Load the inputAddress and the corresponding internalBuffer to the sysSpace.
					// $display($time, ", Writing, '%b' from the Buffer to the System Bus to address '%h'.", internalBuffer[inputIndex], inputAddress);	// for Logic Proof.
				
					#20 inputAddress = inputAddress + 2;					// After 20 cycles, increment inputAddress by 2.
						inputIndex = inputIndex + 1;						// Increment the inputIndex by 1.
				end															// End of the If block.
			end																// End of the repeat block.													
			
			sysSpace = {1'b0, 1'b0, 16'h0000, 16'h0000};					// Set the sysSpace to 0.
			sysRequest = 0;													// Set the sysRequest to 0.
			sysInterrupt = 1;												// Set the sysInterrupt to 1.
			writeMem = 0;													// Set the writeMem to 0.
			// $display($time, ", sysInterrupt = %b", sysInterrupt);		// for Logic Proof.
		end																	// End of the Always block.

		if (sysData == 16'hff00) begin										// Check if the sysData is FF00 hex.

			sysInterrupt = 0;												// Set the sysInterrupt to 0.
			inputAddress = 0;												// Set the sysInterrupt to 0.
		end																	// End of the If block.
	end																		// End of the Always block.
		
endmodule																	// End of the module.																	

/*
 *	Module: OutputUnit			- Module that outputs to the command line by requesting specific data initial
 *								  the Memory module via the System Bus.
 *
 *	Author: Raman Srivastava
 *	Ports: 	
 *		sysRequest				O/P 		A 1-bit output for requesting the Grant Line.
 *		sysInterrupt			O/P			A 1-bit output for the O/P interrupt.
 *		sysBus					I/O			A 34-bit In/Out wire for the System Bus.
 *		grantCheck				I/P			A 1-bit input for the Grant Line check.
 *		sysClock				I/P			A 1-bit input the System Clock values.
 *
 */
module OutputUnit(output sysRequest, output sysInterrupt, inout [33:0] sysBus, input grantCheck, input sysClock); 						// Establishes the name of the module and ports.
	
	wire sysReadBit;							// 1-bit Wire for the Read Bit.					
	wire sysWriteBit;							// 1-bit Wire for the Write Bit.	
	wire [15:0] sysAddress;						// 16-bit Wire for the Address Bits
	wire [15:0] sysData;						// 16-bit Wire for the Data Bits.
	wire [33:0] sysBus;							// 34-bit Wire for the System Bus.		
	
	reg	sysRequest;								// 1-bit Reg for the Module Request.							
	reg sysInterrupt;							// 1-bit Reg for the Interrupt Request.
	reg outputCheck;							// 1-bit Reg to check if O/P needs to output.
	reg outputDone;								// 1-bit Reg to check if the O/P has already outputted.
	reg [15:0] outputAddress;					// 16-bit Reg for storing the Output to Address.		
	reg [33:0] sysSpace;						// 34-bit Reg for the System Bus assigner.					
	
	initial begin								// Start of the initial block.						
			
		sysRequest = 0;							// Set the sysRequest to 0 initially.
		sysInterrupt = 0;						// Set the sysInterrupt to 0 initially.
		sysSpace = 0;							// Set the sysSpace to 0 initially.
		outputCheck = 0;						// Set the outputCheck to 0 initially.
		outputDone = 0;							// Set the outputDone to 0 initially.
	end											// End of the initial block.										
	
	assign {sysReadBit, sysWriteBit, sysAddress, sysData} = sysBus;			// Store the read, write, address, and data values from the System Bus.
	assign sysBus = grantCheck ? sysSpace : 34'bz;							// If the Grant Line is 1, assign sysBus to the System Bus, otherwise impede values.						

	always @(posedge sysClock) begin										// Always block, as long as the Clock edge is positive. 
		
		if (sysAddress == 16'hff80) begin									// Check if the System Bus' Address is FF80 hex.							
			
			// $display($time, ", Requesting print command from the Output Unit since the Address is %h.", sysAddress);	 // for Logic Proof.	
			outputAddress = sysData;										// Load the System Bus Data to the Output Address.
			sysRequest = 1;													// Set the sysRequest to 1.
			outputCheck = 0;												// Sets the outputCheck to 0.											
			outputDone = 0;													// Sets the outputDone to 0.
		end																	// End of the If block.
		
		if ((grantCheck == 1) && (outputDone == 0)) begin					// Check if the Grant Line is 1 and the outputDone is 0.
		
			if (sysRequest == 1) begin										// Check if the System Request is 1.
				
				sysSpace = {1'b1, 1'b0, outputAddress, 16'h0};				// Assign sysSpace with the outputAddress for the Memory to read from.
				// $display($time, ", Writing Address '%h' to the System Bus.", outputAddress);  // for Logic proof.
				sysRequest = 0;												// Set the sysRequest to 0.
				outputCheck = 1;											// Set the outputCheck to 1.
			end																// End of the inner If block.
		end																	// End of the outer If block.
		
		if ((sysReadBit == 0) && (sysWriteBit == 0) && (outputAddress == sysAddress) && (outputCheck == 1)) begin			// Check if the Read and Write Bit is, the outputCheck is 1, 
																															// and the outputAddress is the sysAddress.
			sysRequest = 1;													// Set the sysRequest to 1.
			sysSpace = sysBus;												// Set the syspace to sysBus.

			if ((grantCheck == 1) && (outputDone == 0)) begin				// Check if the grantCheck is 1 and outputDone is 0.
				
				#20 $display($time, ", Output: %h", sysData);				// Display the Output after 20 ticks.
				outputCheck = 0;											// Set the outputCheck to 0.
				outputDone = 1;												// Set the outputDone to 1.
				sysRequest = 0;												// Set the sysRequest to 0.
				sysInterrupt = 1;											// Set the sysInterrupt to 1.
			end																// End of the inner If block.
		end																	// End of the outer If block.
		
		if (sysData == 16'hff80) begin										// If the sysData is FF80 hex.
		
			sysInterrupt = 0;												// Set the sysInterrupt to 0.
			outputCheck = 0;												// Set the outputCheck to 0.
			outputDone = 0;													// Set the outputDone to 0.
		end																	// End of the If block.
	end																		// End of the Always block.
	
endmodule																	// End of the module.	

/*
 *	ThreeByTwoAdder				- Takes three 11-bit values, adds them and outputs the 11-bit Sum and Carry 
 *								  results.
 *
 *	Author: Raman Srivastava
 *	Ports: 	
 *		outputCarry				O/P		    An 11-bit output for Carry Bits.
 *		outputSum				O/P 		An 11-bit output for the Sum Bits.
 *		inputA					I/P			An 11-bit input for Variable A.
 *		inputB					I/P			An 11-bit input for Variable B.
 *		inputC	 				I/P			An 11-bit input for Variable C.
 *
 */
module ThreeByTwoAdder(outputCarry, outputSum, inputA, inputB, inputC);								// Establishes the name of the module and ports.
	
	input [10:0] inputA, inputB, inputC;															// Three 11-bit inputs to represent the 3 input variables.
	output [10:0] outputCarry, outputSum;															// Two 11-bit outputs to represent the Carry and Sum bits.
		
	FullAdder Bit0(outputCarry[1], outputSum[0], inputA[0], inputB[0], inputC[0]);					// Sets the Bit 1 and 0 for the Carry and Sum values by using a Full Adder.
	FullAdder Bit1(outputCarry[2], outputSum[1], inputA[1], inputB[1], inputC[1]);					// Sets the Bit 2 and 1 for the Carry and Sum values by using a Full Adder.
	FullAdder Bit2(outputCarry[3], outputSum[2], inputA[2], inputB[2], inputC[2]);					// Sets the Bit 3 and 2 for the Carry and Sum values by using a Full Adder.
	FullAdder Bit3(outputCarry[4], outputSum[3], inputA[3], inputB[3], inputC[3]);					// Sets the Bit 4 and 3 for the Carry and Sum values by using a Full Adder.
	FullAdder Bit4(outputCarry[5], outputSum[4], inputA[4], inputB[4], inputC[4]);					// Sets the Bit 5 and 4 for the Carry and Sum values by using a Full Adder.
	FullAdder Bit5(outputCarry[6], outputSum[5], inputA[5], inputB[5], inputC[5]);					// Sets the Bit 6 and 5 for the Carry and Sum values by using a Full Adder.
	FullAdder Bit6(outputCarry[7], outputSum[6], inputA[6], inputB[6], inputC[6]);					// Sets the Bit 7 and 6 for the Carry and Sum values by using a Full Adder.
	FullAdder Bit7(outputCarry[8], outputSum[7], inputA[7], inputB[7], inputC[7]);					// Sets the Bit 8 and 7 for the Carry and Sum values by using a Full Adder.
	FullAdder Bit8(outputCarry[9], outputSum[8], inputA[8], inputB[8], inputC[8]);					// Sets the Bit 9 and 8 for the Carry and Sum values by using a Full Adder.
	FullAdder Bit9(outputCarry[10], outputSum[9], inputA[9], inputB[9], inputC[9]);					// Sets the Bit 10 and 9 for the Carry and Sum values by using a Full Adder.
	
	FullAdder ZeroValues(outputCarry[0], outputSum[10], 1'b0, 1'b0, 1'b0);							// Sets the Bit 0 and 10 for the Carry and Sum values to be 0 using a Full Adder.
	
endmodule																							// End of the module.	

/*
 *	RippleCarryAdder			- Takes the 11-bit Carry and Sum values, adds them and outputs the 12-bit
 *								  result.
 *
 *	Author: Raman Srivastava
 *	Ports: 	
 *		outputResult			O/P		    A 12-bit output for Result Bits.
 *		inputCarry				I/P		    An 11-bit input for Carry Bits.
 *		inputSum				I/P 		An 11-bit input for the Sum Bits.
 *
 */
module RippleCarryAdder(outputResult, inputCarry, inputSum);											// Establishes the name of the module and ports.

	input [10:0] inputCarry, inputSum;																	// Two 11-bit inputs to represent the Carry and Sum bits.
	output [11:0] outputResult;																			// A 12-bit output to represent the Result bits.
	
	wire [10:0] tempCarry, tempSum;																		// Two 11-bit wires to temporarily store the new Sum and Carry bits.
	
	FullAdder RCAdderB0(tempCarry[0], tempSum[0], inputCarry[0], inputSum[0], 1'b0);					// Sets the Bit 0 for the Result value by using a Full Adder.
	FullAdder RCAdderB1(tempCarry[1], tempSum[1], inputCarry[1], inputSum[1], tempCarry[0]);			// Sets the Bit 1 for the Result value by using a Full Adder.
	FullAdder RCAdderB2(tempCarry[2], tempSum[2], inputCarry[2], inputSum[2], tempCarry[1]);			// Sets the Bit 2 for the Result value by using a Full Adder.
	FullAdder RCAdderB3(tempCarry[3], tempSum[3], inputCarry[3], inputSum[3], tempCarry[2]);			// Sets the Bit 3 for the Result value by using a Full Adder.
	FullAdder RCAdderB4(tempCarry[4], tempSum[4], inputCarry[4], inputSum[4], tempCarry[3]);			// Sets the Bit 4 for the Result value by using a Full Adder.
	FullAdder RCAdderB5(tempCarry[5], tempSum[5], inputCarry[5], inputSum[5], tempCarry[4]);			// Sets the Bit 5 for the Result value by using a Full Adder.
	FullAdder RCAdderB6(tempCarry[6], tempSum[6], inputCarry[6], inputSum[6], tempCarry[5]);			// Sets the Bit 6 for the Result value by using a Full Adder.
	FullAdder RCAdderB7(tempCarry[7], tempSum[7], inputCarry[7], inputSum[7], tempCarry[6]);			// Sets the Bit 7 for the Result value by using a Full Adder.
	FullAdder RCAdderB8(tempCarry[8], tempSum[8], inputCarry[8], inputSum[8], tempCarry[7]);			// Sets the Bit 8 for the Result value by using a Full Adder.
	FullAdder RCAdderB9(tempCarry[9], tempSum[9], inputCarry[9], inputSum[9], tempCarry[8]);			// Sets the Bit 9 for the Result value by using a Full Adder.
	FullAdder RCAdderB10(tempCarry[10], tempSum[10], inputCarry[10], inputSum[10], tempCarry[9]);		// Set the Bits 10 & 11 for the Result value by using a Full Adder.

	assign outputResult = {tempCarry[10], tempSum};														// Result is the most significant Carry bit, followed by the Sum Bits.

endmodule																								// End of the module.		

/*
 *	FullAdder					- A module that three 1- bit inputs, A, B, and a previous 
 *								  carry Cin input and outputs the value of A + B, as well 
 *								  as their carry bit.
 *
 *	Author: Raman Srivastava
 *	Ports: 	
 *		outputCout				O/P		    A 1-bit output for Carry Bit.
 *		outputS				    O/P 		A 1-bit output for the Sum Bit.
 *		inputA					I/P			A 1-bit input for Variable A.
 *		inputB					I/P			A 1-bit input for Variable B.
 *		inputCin 				I/P			A 1-bit input for the previous Carry Bit.
 *
 */
module FullAdder(outputCout, outputS, inputA, inputB, inputCin);	// Establishes the name of the module and ports.
    
    input inputA, inputB, inputCin;									// Three one-bit inputs to represent variables a, b, & cin.
    output outputCout, outputS;										// Two one-bit outputs to represent the Sum and Carry bit.
    
    wire andGate1, notA, notB, notQ1, andGateNANB, andGateQ2C;		// Wires to hold the values of the subfunction gates.
    wire notCin, notQ2, notQ3, notNotCin, andGateNNCinNQ2;
    wire gateQ1, gateQ2, gateQ3, outputCout, outputS;
    
    and  andGateA(andGate1, inputA, inputB);						// Wait 1 cycle, then set the value of (a & b) to andGate1. 
    not  notGateA(gateQ1, andGate1);								// Wait 1 cycle, then set the value of ~(a & b) to gateQ1.
    
    not  notGateB1(notQ1, gateQ1);									// Wait 1 cycle, then set the value of ~(Q1) to notQ1.
    not  notGateB2(notA, inputA);									// Wait 1 cycle, then set the value of ~a to notA.
    not  notGateB3(notB, inputB);									// Wait 1 cycle, then set the value of ~b to notB.
    and  andGateB(andGateNANB, notA, notB);							// Wait 1 cycle, then set the value of (~a & ~b) to andGateNANB.
    or  orGateB(gateQ2, notQ1, andGateNANB);						// Wait 1 cycle, then set the value of ~(Q1) | (~a && ~b) to gateQ2.
    
    and  andGateC(andGateQ2C, gateQ2, inputCin);					// Wait 1 cycle, then set the value of (Q2 && cin) to andGateQ2C.
    not  notGateC(gateQ3, andGateQ2C);								// Wait 1 cycle, then set the value of ~(Q2 && cin) to gateQ3.
    
    not  notGateD1(notQ3, gateQ3);									// Wait 1 cycle, then set the value of ~(Q3) to notQ3.
    not  notGateD2(notQ2, gateQ2);									// Wait 1 cycle, then set the value of ~Q2 to notQ2.
    not  notGateD3(notCin, inputCin);								// Wait 1 cycle, then set the value of ~cin to notCin.
    and  andGadeD(andGateNQ2NCin, notQ2, notCin);					// Wait 1 cycle, then set the value of (~Q2 && ~cin) to andGateNQ2NCin.
    or  orGateD(outputS, notQ3, andGateNQ2NCin);					// Wait 1 cycle, then set the value of ~(Q3) | (~Q2 && ~cin) to outputS.
    
    not  notGateE(notNotCin, notCin);								// Wait 1 cycle, then set the value of ~(~cin) to notNotCin.
    and  andGateE(andGateNNCinNQ2, notNotCin, notQ2);				// Wait 1 cycle, then set the value of (~(~cin) & ~Q2) to andGateNNCinNQ2.
    or  orGateE(outputCout, notQ1, andGateNNCinNQ2);				// Wait 1 cycle, then set the value of ~(Q1) | (~(~cin) & ~Q2) to outputCout.
    
endmodule															// End of the FullAdder module.															

/*
 *	Module: SystemClock			- Clock module that keeps the program synchronized with a cycle of 20. 
 *
 *	Author: Raman Srivastava
 *	Ports: 	
 *		sysClock				O/P			A 1-bit wire that outputs the Clock cycle values.
 *
 */
module SystemClock(output sysClock);			// Establishes the name of the module and the ports.
	
	reg sysTimer;								// Defines the sysTimer as a 1-bit register.

	initial begin								// Start of the initial block.
	
		sysTimer = 0;							// Sets sysTrack to 0 initially.
	end											// End of the initial block.
	
	assign sysClock = sysTimer;

	always begin								// Always block, as long as the Clock edge is positive.
	
		#10 sysTimer = ~sysTimer;				// Flips the cycle for positive to negative every 20 ticks 
												// and vice versa.
	end											// End of the Always block.
	
endmodule										// End of the module.
