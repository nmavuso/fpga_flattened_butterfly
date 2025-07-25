# FPGA Flattened Butterfly
This repo demonstrates a light-weight flattened butterfly Network on a Chip (NoC) on a 7-series FPGA. It is fully connected for structure and involves simplified hashing Processing Elements.

This code is demonstrated on a simple XC7A35T FPGA and was designed to meet the 20,000 available LUTs. The XC7A35T device has a limit of 56 I/O ports, which makes it infeasible for full functionality. Pipelining and ingress & egress can further be added to allow connecting with a PCIE.  

High-speed interfaces, such as a Serial/Deserializer (SERDES), can be added for more efficiency in communication. 

This design is a shadow demo of a more robust ULTRASCALE+ implementation. 

The selected device has an onboard oscillator of 12Mhz. I use a Mixed-Clock Module (MMCM) to generate a 100 MHz clock. You need the clocking IP to be compatible with the xc7a35tcpg236-1 device. 

**Prerequisites:**

```Vivado 2024.2```

```xc7a35tcpg236-1 device licence``` 


<img width="2490" height="1415" alt="Screenshot from 2025-07-25 16-50-48" src="https://github.com/user-attachments/assets/433129e5-158a-4661-9f4c-845e0cb9debc" />
