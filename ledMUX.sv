//Jonathan Perez & Ramy Elminyawi


module ledMux(input logic clk,   //ledMux module
              input logic reset, 
          //    input logic sck,
          //    input logic sdi,
              output logic sck2,
          //    output logic R0,
          //    output logic G0,
          //    output logic B0,
              output logic Latch,
        //   output logic Blank,
              output logic [2:0] row,                 
				  output logic [2:0] LEDS);
				  
//commented outputs will be added later				
				clkGen V(clk, reset, sck2EN, sck2);
				countShift B(sck2, reset, rowShift);
				LatchGen C(clk, reset, row, Latch);
				rowSelect U(rowShift, reset, row); 
				dispData A(clk, reset, Latch, sck2EN);  
				
				assign LEDS = row; //Debugging
				
endmodule



/*
The rowselect module takes in the rowShift signal and outputs which row is being driven
*/
module rowSelect(input logic rowShift,   // rowSelect module
					  input logic reset,
             	  output logic [2:0] row);
             	   
 //define variables            	
             logic [2:0] rowShiftCount = 4'b000;
//always_comb block determines which row the data is being put into	            
 	            always_ff @(posedge rowShift)
						begin
							if (reset)
								begin 
								rowShiftCount <= 4'b000; //reset rowShiftCount to 0
								end
							else
							begin 
							rowShiftCount <= rowShiftCount + 1'b1;  //increment RowShiftCount by 1
							end
						end
					  
           	      always_comb 
							begin
								if (reset)
									begin
										row = 4'b000;
									end
								else 
									begin							
 //selects row based off the value of rowShiftCount 
										case(rowShiftCount)        
											3'b000 : row[2:0] = 3'b000;       //row 0
											3'b001 : row[2:0] = 3'b001;       //row 1
											3'b010 : row[2:0] = 3'b010;       //row 2
											3'b011 : row[2:0] = 3'b011;       //row 3
											3'b100 : row[2:0] = 3'b100;       //row 4
											3'b101 : row[2:0] = 3'b101;       //row 5
											3'b110 : row[2:0] = 3'b110;  	    //row 6 
											3'b111 : row[2:0] = 3'b111;       //row 7 
										  default  : row[2:0] = 3'b000;      //default case goes to row 0
										endcase
									end
						end
endmodule

/*
This module uses a change in the row to drive the logic for the Latch signal
*/
module LatchGen(input logic clk,
					 input logic reset,
					 input logic [2:0] row,
					 output logic Latch);
					 
					 logic [2:0] prevrow;
					 logic [2:0] currow;
					 always_ff @(posedge clk, posedge reset)
						begin	 
							if(reset)
								begin
									Latch <= 1'b0;
									prevrow <= 3'b000;
									currow <= 3'b000;
								end
							else
								begin
									prevrow <= currow;
									currow <= row;
										if (currow == prevrow)
											begin
											Latch <= 1'b0;
											end
										else
											begin
												Latch <= 1'b1;
											end
							end
						end				
endmodule                 

/*
The clkGen module creates the CLK signal to the LED matix. The CLK signal pulses as long
as the sck2EN signal is high.
*/
module clkGen(input logic clk,  //clkGen module
              input logic reset,
              input logic sck2EN,
              output logic sck2);                   
// Define internal Variables
				  logic [3:0] sckCount = 4'd0;
              logic [3:0] sckMIN = 5'd2; 
              logic [3:0] sckMAX = 5'd7; 
				      	      
//Always_ff block to define sck signal to LED matrix				      
					always_ff@(posedge clk, posedge reset)
						begin
							if(reset)
								begin
								  sck2 <= 1'b0;
								  sckCount <= 4'b0000; 
								end
							else 
								begin
									if (sck2EN)
										begin
											sckCount[3:0] <= sckCount[3:0] + 1'b1; 
											if (sckCount > sckMIN && sckCount < sckMAX)
												begin
													sck2 <= 1'b1;	
												end
											else if(sckCount >= sckMAX)
												begin
													sckCount <= 4'b0000;
													sck2 <= 1'b0;
												end
											else
												begin
													sck2 <= 1'b0; 
												end
										end
									else
										begin
											sck2 <= 1'b0;
											sckCount <= 4'b0000;
										end
								end
						end
endmodule                    
	


/*
This module counts the number of pulses of sck2. Once the sck2 signal pulses 32
times Rowshift goes high.
*/	
module countShift(input logic sck2,
						input logic reset,
						output logic rowShift);
						
              logic [4:0] shiftCount = 5'b00000;
				  logic [4:0] shiftMax = 5'd31;
				  
				  always_ff @(negedge sck2 or posedge reset)
					begin
						if (reset)
							begin
								shiftCount <= 5'b00000;
								rowShift <= 1'b0;
							end
						else
							begin
								shiftCount[4:0] <= shiftCount[4:0] + 1;
								if (shiftCount == shiftMax)
									begin
									  shiftCount <= 0;
									  rowShift <= 1'b1;
									end
								else
									begin
										rowShift <= 1'b0;
									end
							end
					end
endmodule  

/*
This module sets the sck2EN signal low for a wait period. During this wait period
the RGB data is displayed on the LED Matrix
*/
module dispData(input logic clk,
					 input logic reset,
                input logic Latch,
                output logic sck2EN);             
                
               logic [25:0] stallCount = 26'd0;
               logic [25:0] stall = 26'd40_000_000; 
					//logic [9:0] stallCount = 10'b00_0000_0000;
					//	logic [9:0] stall = 10'd500;
						
                always_ff @(posedge clk, posedge reset)
                  begin 
							if (reset)
								begin
									sck2EN <= 1'b1;
								end
							else
								begin						
									if (Latch)
										begin
											sck2EN <= 1'b0;	
										end	
									if(~sck2EN)
										begin
											stallCount <= stallCount + 1'b1;
											if(stallCount == stall)
												begin
													stallCount <= 26'd0;
													//stallCount <= 10'b00_0000_0000;
													sck2EN <= 1'b1;
												end
										end
								end
						end
endmodule










// If the slave only need to received data from the master
// Slave reduces to a simple shift register given by following HDL: 

/*
module spi_slave_receive_only(input logic sck, //from master
										input logic sdi, //from master 
										output logic [7:0] LEDS,			//DEBUGGING
										output logic [9:0] Xpos, Ypos); // data received
										
		logic [31:0] q;
		always_ff @(posedge sck)
			begin
				q <={q[30:0], sdi}; //shift register
				
			 assign Xpos[9:0] = q[25:16];
			 assign Ypos[9:0] = q[9:0];
			 assign LEDS[7:0] = q[7:0];
endmodule
*/
