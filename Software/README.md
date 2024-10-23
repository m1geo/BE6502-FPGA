# Building the Software & ROM images

This code was written to be built with [cc65](https://github.com/cc65/cc65), specifically the ca65 assembler, as with Ben's tutorials.

For an overview, see: [A simple BIOS for my breadboard computer](https://www.youtube.com/watch?v=0q6Ujn_zNH8&ab_channel=BenEater)

From the bin step, a further step is required to generate a `.mem` file that the FPGA tools will use. This is also added to the `make.sh` script in this repository.
