# Caravel_Fault_SPM

The repo contains SPM with DFT structure integratin with the Caravel chip. For the SPM/DFT insertion, refer to [Fault SPM](https://github.com/Manarabdelaty/Fault-SPM)

# Caravel Integration

### Verilog View

The SPM utilizes the caravel IO ports and logic analyzer probes. Refer to [user_project_wrapper.v](verilog/rtl/user_project_wrapper.v)

| Caravel-IO    | SPM           |  Mode
| ------------- | ------------- | -------------
|  io[0]        | tck           | Input
|  io[1]        | tms           | Input
|  io[2]        | tdi           | Input
|  io[4]        | tdo           | Output
|  io[5]        | trst          | Input

| Caravel-LA        | SPM            |  Mode
| ----------------- | ---------------| -------------
|  la_data[31:0]    | multiplicant   | Input
|  la_data[63:32]   | multiplier     | Input
|  la_data[64]      | start          | Input
|  la_data[65]      | product_select | Output
|  la_data[66]      | done           | Input
|  la_data[127:96]  | product        | Input

### GDS View

<p align=”center”>
<img src="doc/Screenshot%20from%202021-02-03%2011-51-36.png" width="40%" height="40%">
</p>
