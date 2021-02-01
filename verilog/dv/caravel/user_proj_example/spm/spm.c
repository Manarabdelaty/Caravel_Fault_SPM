/*
 * SPDX-FileCopyrightText: 2020 Efabless Corporation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * SPDX-License-Identifier: Apache-2.0
 */

#include "../../defs.h"

/*
	SPM Functional Test:
		- Configures JTAG I/Os to be pulled by default to zero/one
		- Starts SPM multiplication through logic analyzer probes
*/

void main()
{
	/* 
	IO Control Registers
	| DM     | VTRIP | SLOW  | AN_POL | AN_SEL | AN_EN | MOD_SEL | INP_DIS | HOLDH | OEB_N | MGMT_EN |
	| 3-bits | 1-bit | 1-bit | 1-bit  | 1-bit  | 1-bit | 1-bit   | 1-bit   | 1-bit | 1-bit | 1-bit   |

	Output: 0000_0110_0000_1110  (0x1808) = GPIO_MODE_USER_STD_OUTPUT
	| DM     | VTRIP | SLOW  | AN_POL | AN_SEL | AN_EN | MOD_SEL | INP_DIS | HOLDH | OEB_N | MGMT_EN |
	| 110    | 0     | 0     | 0      | 0      | 0     | 0       | 1       | 0     | 0     | 0       |
	
	 
	Input: 0000_0001_0000_1111 (0x0402) = GPIO_MODE_USER_STD_INPUT_NOPULL
	| DM     | VTRIP | SLOW  | AN_POL | AN_SEL | AN_EN | MOD_SEL | INP_DIS | HOLDH | OEB_N | MGMT_EN |
	| 001    | 0     | 0     | 0      | 0      | 0     | 0       | 0       | 0     | 1     | 0       |

	*/

	// Configure JTAG ports
	reg_mprj_io_0 =  GPIO_MODE_USER_STD_INPUT_NOPULL; 	// tck
	reg_mprj_io_1 =  GPIO_MODE_USER_STD_INPUT_NOPULL;   // tms
	reg_mprj_io_2 =  GPIO_MODE_USER_STD_INPUT_NOPULL; 	// tdi
	reg_mprj_io_3 =  GPIO_MODE_USER_STD_INPUT_NOPULL; 	// trst
	reg_mprj_io_4 =  GPIO_MODE_USER_STD_BIDIRECTIONAL;  // tdo
	
	reg_mprj_io_31 = GPIO_MODE_MGMT_STD_OUTPUT;
	reg_mprj_io_30 = GPIO_MODE_MGMT_STD_OUTPUT;
	reg_mprj_io_29 = GPIO_MODE_MGMT_STD_OUTPUT;
	reg_mprj_io_28 = GPIO_MODE_MGMT_STD_OUTPUT;
	reg_mprj_io_27 = GPIO_MODE_MGMT_STD_OUTPUT;
	reg_mprj_io_26 = GPIO_MODE_MGMT_STD_OUTPUT;
	reg_mprj_io_25 = GPIO_MODE_MGMT_STD_OUTPUT;
	reg_mprj_io_24 = GPIO_MODE_MGMT_STD_OUTPUT;
	reg_mprj_io_23 = GPIO_MODE_MGMT_STD_OUTPUT;
	reg_mprj_io_22 = GPIO_MODE_MGMT_STD_OUTPUT;
	reg_mprj_io_21 = GPIO_MODE_MGMT_STD_OUTPUT;
	reg_mprj_io_20 = GPIO_MODE_MGMT_STD_OUTPUT;
	reg_mprj_io_19 = GPIO_MODE_MGMT_STD_OUTPUT;
	reg_mprj_io_18 = GPIO_MODE_MGMT_STD_OUTPUT;
	reg_mprj_io_17 = GPIO_MODE_MGMT_STD_OUTPUT;
	reg_mprj_io_16 = GPIO_MODE_MGMT_STD_OUTPUT;

	/* Apply configuration */
	reg_mprj_xfer = 1;
	while (reg_mprj_xfer == 1);

	// Configure LA probes [31:0], [63:32],[64] as inputs to the cpu 
	// Configure LA probe [65], [127:96] as output from the cpu
	reg_la0_ena = 0xFFFFFFFF;    // [31:0]
	reg_la1_ena = 0xFFFFFFFF;    // [63:32]
	reg_la2_ena = 0x00000001;    // [95:64]
	reg_la3_ena = 0x00000000;    // [127:96]

	// Write mc & mp 
	reg_la0_data = 4;  // mc
	reg_la1_data = 6;  // mp

	// Start Multiplication
	reg_la2_data = 1;

	// Configure LA[0] as output
	reg_la0_ena = 0x00000000;

	// Wait on done signal
	while((reg_la0_data & 0x00000001) != 1);

	// Configure [64] as output
	reg_la2_ena = 0x00000001;

	// read multiplication value
	int long prod =  ((reg_la3_data << 32) | reg_la2_data); 
	
	if (prod != 25) {
		reg_mprj_datal = 0xAB410000;
	} else {
		reg_mprj_datal = 0xAB400000;
	}
}

