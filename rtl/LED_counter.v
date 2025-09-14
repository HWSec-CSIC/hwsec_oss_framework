`default_nettype none
`timescale 1 ns / 10 ps

////////////////////////////////////////////////////////////////////////////////////
// Company: IMSE-CNM CSIC
// Engineer: Pablo Navarro Torrero
// 
// Create Date: 03/07/2025
// Design Name: LED_counter.v
// Module Name: LED_counter
// Project Name: HWSEC OSS FRAMEWORK Tutorial
// Target Devices: iCE40-HX8K
// Tool Versions:
// Description: 
//		
//		8-bit LED counter 
//
// Additional Comment:
//
//      Target Frequency is 10 Hz (0.1s Period)
//      Clock Frequency is 12 MHz => CLK_DIV = 1,200,000
//
////////////////////////////////////////////////////////////////////////////////////

module LED_counter #(
                     parameter CLK_DIV = 20         //-- Clock Divisor 
                     )
                     (
                      input  wire        clk,       //-- Clock Signal
                      input  wire        rst_n,     //-- Active Low Reset
                      output reg [7:0]   leds       //-- LEDs
                      );
    

    
    reg [$clog2(CLK_DIV)-1:0] div_counter /*verilator public*/;     // Makes visible this signal during simulation

    always @(posedge clk) begin
        if (!rst_n) begin
            div_counter <= 0;
            leds        <= 0;
        end
        else if (div_counter == CLK_DIV - 1) begin
            div_counter <= 0;
            leds        <= leds + 1;
        end
        else begin
            div_counter <= div_counter + 1;
            leds        <= leds;
        end
    end
    
endmodule
