# Xilinx USR_ACCESSE2 Parser

The [Xilinx AppNote XAPP497](https://docs.amd.com/v/u/en-US/xapp497_usr_access) details how to store a generation timestamp inside the FPGA programming file (.bit) at BitGen time, using the USR_ACCESSE2 field of the bitstream.

Inside the BE6502 project, four read-only 8-bit registers contain the 32-bit USR_ACCESSE2 word, which can be read out at offset 0x7020 (LSB) to 0x7023 (MSB).

Using Wozmon on the 6502, issuing `7020.7023` at the prompt will output these four registers. The script `usr_accesse2_parser.py` will parse these 4 bytes (or a 32b word) to reveal the encoded BitGen timestamp.

![USR_ACCESSE2](/Software/USR_ACCESSE2/usr_accesse2.png)