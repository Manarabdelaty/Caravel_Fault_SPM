// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype none

`timescale 1 ns / 1 ps

`ifdef GL
    `include "gl/user_project/gl/user_proj_top.v"
    `include "gl/user_project/gl/user_project_wrapper.v"
`else
    `define USE_POWER_PINS
    `include "gl/user_project/gl/user_proj_top.v"
    `include "user_project_wrapper.v"
`endif

`include "caravel.v"
`include "spiflash.v"

`define SOC_SETUP_TIME 170_000

module chain_tb;
	reg clock;
    reg RSTB;
    reg CSB;
	reg power1, power2;
	reg power3, power4;

	wire gpio;
	wire [37:0] mprj_io;

    // JTAG Ports
    reg tms;
    reg tck;
    reg tdi;
    reg trst;

    wire tdo;

	assign mprj_io[0] = tck;
    assign mprj_io[1] = tms;
    assign mprj_io[2] = tdi;
    assign mprj_io[3] = (CSB == 1'b1) ? 1'b1 : 1'bz;
    assign mprj_io[5] = trst;
    assign tdo = mprj_io[4];
    
	// External clock is used by default.  Make this artificially fast for the
	// simulation.  Normally this would be a slow clock and the digital PLL
	// would be the fast clock.

	always #10 clock <= (clock === 1'b0);
	always #10 tck <= (tck === 1'b0);

    wire[470:0] serializable =
        471'b000000010101111101000011111101110100110110111111101111010100010101010011010101110111000110011110110100001110100011001110001010000001110110111011000101110101101001101111000110110000110011011010000100010000011000011111111000000100011000110111001001010100101001110000110111001000000010111100011100101100000111100100011100001001101000011010000000001011011001010101011011010011010100110111111011001010101000110011111011110011000111110111000110011001001001010010100101101000001;
    reg[470:0] serial;

    wire[7:0] tmsPattern = 8'b 01100110;
    wire[3:0] preload_chain = 4'b0011;

	initial begin
		clock = 0;
	end

	initial begin
		$dumpfile("chain.vcd");
		$dumpvars(0, chain_tb);

		// Repeat cycles of 1000 clock edges as needed to complete testbench
		repeat (60) begin
			repeat (1000) @(posedge clock);
			// $display("+1000 cycles");
		end
		$display("%c[1;31m",27);
		$display ("Monitor: Timeout, Test Chain (RTL) Failed");
		$display("%c[0m",27);
		$finish;
	end

    integer i;

	initial begin
        tms = 0 ;
        tck = 0 ;
        tdi = 0 ;
        trst = 0 ;
        RSTB <= 1'b0;
        CSB <= 1'b1;
        tms = 1;
        #2000;
		RSTB <= 1'b1;	    // Release reset    
        #(`SOC_SETUP_TIME); 
    	CSB = 1'b0;		// CSB can be released
        #20;
        trst = 1;   
        #20;

         /*
            Test PreloadChain Instruction
        */
        shiftIR(preload_chain);
        enterShiftDR();

        for (i = 0; i < 471; i = i + 1) begin
            tdi = serializable[i];
            #20;
        end
        for(i = 0; i< 471; i = i + 1) begin
            serial[i] = tdo;
            #20;
        end 

        if(serial !== serializable) begin
            $error("EXECUTING_PRELOAD_CHAIN_INST_FAILED");
            $finish;
        end
        exitDR();

        $display("SUCCESS_STRING");
        $finish;
    end

    task shiftIR;
        input[3:0] instruction;
        integer i;
        begin
            for (i = 0; i< 5; i = i + 1) begin
                tms = tmsPattern[i];
                #20;
            end

            // At shift-IR: shift new instruction on tdi line
            for (i = 0; i < 4; i = i + 1) begin
                tdi = instruction[i];
                if(i == 3) begin
                    tms = tmsPattern[5];     // exit-ir
                end
                #20;
            end

            tms = tmsPattern[6];     // update-ir 
            #20;
            tms = tmsPattern[7];     // run test-idle
            #60;
        end
    endtask

    task enterShiftDR;
        begin
            tms = 1;     // select DR
            #20;
            tms = 0;     // capture DR -- shift DR
            #40;
        end
    endtask

    task exitDR;
        begin
            tms = 1;     // Exit DR -- update DR
            #40;
            tms = 0;     // Run test-idle
            #20;
        end
    endtask

	initial begin		// Power-up sequence
		power1 <= 1'b0;
		power2 <= 1'b0;
		power3 <= 1'b0;
		power4 <= 1'b0;
		#100;
		power1 <= 1'b1;
		#100;
		power2 <= 1'b1;
		#100;
		power3 <= 1'b1;
		#100;
		power4 <= 1'b1;
	end

	wire flash_csb;
	wire flash_clk;
	wire flash_io0;
	wire flash_io1;

	wire VDD3V3 = power1;
	wire VDD1V8 = power2;
	wire USER_VDD3V3 = power3;
	wire USER_VDD1V8 = power4;
	wire VSS = 1'b0;

	caravel uut (
		.vddio	  (VDD3V3),
		.vssio	  (VSS),
		.vdda	  (VDD3V3),
		.vssa	  (VSS),
		.vccd	  (VDD1V8),
		.vssd	  (VSS),
		.vdda1    (USER_VDD3V3),
		.vdda2    (USER_VDD3V3),
		.vssa1	  (VSS),
		.vssa2	  (VSS),
		.vccd1	  (USER_VDD1V8),
		.vccd2	  (USER_VDD1V8),
		.vssd1	  (VSS),
		.vssd2	  (VSS),
		.clock	  (clock),
		.gpio     (gpio),
        .mprj_io  (mprj_io),
		.flash_csb(flash_csb),
		.flash_clk(flash_clk),
		.flash_io0(flash_io0),
		.flash_io1(flash_io1),
		.resetb	  (RSTB)
	);

	spiflash #(
		.FILENAME("chain.hex")
	) spiflash (
		.csb(flash_csb),
		.clk(flash_clk),
		.io0(flash_io0),
		.io1(flash_io1),
		.io2(),			// not used
		.io3()			// not used
	);

endmodule
`default_nettype wire
