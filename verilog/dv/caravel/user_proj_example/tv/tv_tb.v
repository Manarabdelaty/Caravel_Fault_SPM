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

module tv_tb;
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

	always #12.5 clock <= (clock === 1'b0);
	always #20 tck <= (tck === 1'b0);

    integer i, error;

    reg [404:0] scanInSerial;
    reg [267:0] vectors [0:19];
    reg [404:0] gmOutput[0:19];

    wire[7:0] tmsPattern = 8'b 01100110;
    wire[3:0] preloadChain = 4'b 0011;

	initial begin
		clock = 0;
	end

	initial begin
		$dumpfile("tv.vcd");
		$dumpvars(0, tv_tb);

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

	initial begin
        tms = 0 ;
        tck = 0 ;
        tdi = 0 ;
        trst = 0 ;
        RSTB <= 1'b0;
        CSB <= 1'b1;
        tms = 1;
        $readmemb("user_proj_top.bin.vec.mem", vectors);
        $readmemb("user_proj_top.bin.out.mem", gmOutput);
        #2000;
		RSTB <= 1'b1;	    // Release reset    
        #(`SOC_SETUP_TIME); 
    	CSB = 1'b0;		// CSB can be released
        #40;
        trst = 1;        
        #40;
        test(vectors[0], gmOutput[0]) ;
        test(vectors[1], gmOutput[1]) ;
        test(vectors[2], gmOutput[2]) ;
        test(vectors[3], gmOutput[3]) ;
        test(vectors[4], gmOutput[4]) ;
        test(vectors[5], gmOutput[5]) ;
        test(vectors[6], gmOutput[6]) ;
        test(vectors[7], gmOutput[7]) ;
        test(vectors[8], gmOutput[8]) ;
        test(vectors[9], gmOutput[9]) ;
        test(vectors[10], gmOutput[10]) ;
        test(vectors[11], gmOutput[11]) ;
        test(vectors[12], gmOutput[12]) ;
        test(vectors[13], gmOutput[13]) ;
        test(vectors[14], gmOutput[14]) ;
        test(vectors[15], gmOutput[15]) ;
        test(vectors[16], gmOutput[16]) ;
        test(vectors[17], gmOutput[17]) ;
        test(vectors[18], gmOutput[18]) ;
        test(vectors[19], gmOutput[19]) ;

        $display("SUCCESS_STRING");
        $finish;
    end

    task test;
        input [267:0] vector;
        input [404:0] goldenOutput;
        begin
           
            // Preload Scan-Chain with TV

            shiftIR(preloadChain);
            enterShiftDR();

            for (i = 0; i < 268; i = i + 1) begin
                tdi = vector[i];
                if (i == 265) begin
                    tms = 1; // Exit-DR
                end
                if (i == 266) begin
                    tms = 0; // Pause-DR
                end
                if (i == 267) begin
                    tms = 1; // Exit2-DR
                end
                #40;
            end

            tms = 0; // Shift-DR
            #40;
            // Shift-out response
            error = 0;
            for (i = 0; i< 405;i = i + 1) begin
                tdi = 0;
                scanInSerial[i] = tdo;
                if (scanInSerial[i] !== goldenOutput[i]) begin
                    $display("Error simulating output response at bit number %0d                        Expected %0b, Got %0b", i, goldenOutput[i], scanInSerial[i]);
                    error = error + 1;
                end
                if(i == 404) begin
                    tms = 1; // Exit-DR
                end
                #40;
            end
            tms = 1; // update-DR
            #40;
            tms = 0; // run-test-idle
            #40;

            if(scanInSerial !== goldenOutput) begin
                $display("Simulating TV failed, number fo errors %0d : ", error);
                $error("SIMULATING_TV_FAILED");
                // $finish;
            end
        end
    endtask

       task shiftIR;
        input[3:0] instruction;
        integer i;
        begin
            for (i = 0; i< 5; i = i + 1) begin
                tms = tmsPattern[i];
                #40;
            end

            // At shift-IR: shift new instruction on tdi line
            for (i = 0; i < 4; i = i + 1) begin
                tdi = instruction[i];
                if(i == 3) begin
                    tms = tmsPattern[5];     // exit-ir
                end
                #40;
            end

            tms = tmsPattern[6];     // update-ir 
            #40;
            tms = tmsPattern[7];     // run test-idle
            #120;
        end
    endtask

    task enterShiftDR;
        begin
            tms = 1;     // select DR
            #40;
            tms = 0;     // capture DR -- shift DR
            #80;
        end
    endtask

    task exitDR;
        begin
            tms = 1;     // Exit DR -- update DR
            #80;
            tms = 0;     // Run test-idle
            #40;
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
		.FILENAME("tv.hex")
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
