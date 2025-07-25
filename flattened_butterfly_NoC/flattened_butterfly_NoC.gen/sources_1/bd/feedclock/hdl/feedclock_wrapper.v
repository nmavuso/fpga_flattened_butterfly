//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2024 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2024.2 (lin64) Build 5239630 Fri Nov 08 22:34:34 MST 2024
//Date        : Fri Jul 25 16:05:52 2025
//Host        : eiffel-ubuntu running 64-bit Ubuntu 20.04.6 LTS
//Command     : generate_target feedclock_wrapper.bd
//Design      : feedclock_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module feedclock_wrapper
   (clk_in1,
    clk_out1,
    locked,
    reset);
  input clk_in1;
  output clk_out1;
  output locked;
  input reset;

  wire clk_in1;
  wire clk_out1;
  wire locked;
  wire reset;

  feedclock feedclock_i
       (.clk_in1(clk_in1),
        .clk_out1(clk_out1),
        .locked(locked),
        .reset(reset));
endmodule
