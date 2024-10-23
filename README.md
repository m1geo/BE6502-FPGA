# BE6502-FPGA

## Intro
A 6502-based computer on an FPGA, based around Ben Eater's design using 'cores' by others.

I've long since followed the @beneater 6502 series along with several other YouTube homemade computer projects (@weirdboyjim and the jam-1). My main interest has always been what ties the hardware and software together, and how low level software and hardware interact. With Ben's recent videos on running Wozmon, MSBASIC and creating basic BIOS routines, I really _needed_ to follow along. So I set myself the challenge of doing so on an FPGA, rather than breadboard as a learning exercise for myself. I have some experience with Verilog - enough to be dangerous - but I'm not a professional, so there may (read: _will_) be bugs!

## Status

I have design running on a [Digilent Arty A7 35T](https://digilent.com/reference/programmable-logic/arty-a7/start) devboard running the modified Wozmon (modified again from Ben's version to suit my home-made hardware, see below). I have my UART running at 115200, and the 6502 core running at 50MHz using an MMCM to drop the 100 MHz board clock to 50 MHz. There's no reason for this, other than the fact that I thought the clock was 50 MHz, and then later realised it wasn't and it was easier to add the MMCM than recalculate the bit timings.

There's a simple Verilog testbench that just lets the platform boot up, and then sends an escape. There's no checking, but its easy to see in the waveform that the platform boots OK, acknowledges the UART interrupt, and correctly responds to the character from the circular buffer.

I wired up the dev-board's LEDs to port A, and the dev-board's switches to port B. These can be written and read and peform as you'd expect.

I plan to update this repository as Ben's videos progress. I'd like to get VGA output in the design, but I'm following Ben's videos as I have time.

## A few images

![Initial stages of the boot process](/images/vivado_sim_boot_process.jpg)

![UART data really is so much slower than the rest of the system!](/images/be6502_fpga_wozmon.jpg)

![MSBasic running with terminal output](/images/be6502_fpga_basic.jpg)

## Differences from Ben's Design

The main difference is in the UART. I couldn't find a good Verilog model of the 6551 ACIA that Ben uses, so I had to improvise. Using UART TX and RX cores from [Ben Marshall](https://github.com/ben-marshall/uart) I wrote a wrapper for the UART top that was as simple as possible. The baudrate is hard coded so no configuration is required. The cores themselves are parameterised, so it is easy to change the baudrate, but requires rebuilding the FPGA. There are no CMD or CTRL registers; just a DATA (rw) and STATUS (ro) register. Reading the status register clears the IRQ.

## Cores

* [65C02 CPU by Arlet Ottens](https://github.com/Arlet/verilog-65C02-microcode)
* [Verilog 65C22 by CompuSAR](https://github.com/CompuSAR/6522)
* Homebrew UART based on [Ben Marshall's UART](https://github.com/ben-marshall/uart)
* Homebrew ROM (32KB) and RAM (16KB) (need reworking to optimise synthesis time, but are functional)
* LFSR - not needed, but I wanted to have a source of 'random' on the CPU
* Timer - again, not needed, but I wanted to have the ability to monitor time.

# Support

This project comes without any support. Although I would like to help, I simply do not have the time to do so.

You can drop me a donation via PayPal if you have found the project useful: [PayPal Donation to M1GEO](https://www.paypal.com/paypalme/m1geo)

# Licence

This work was created as a learning platform for myself, and that alone. You're welcome to use it, hack it, etc., as you see fit.

I'm asserting no claims to the Cores mentioned above. They're included here for completeness, so anyone else can get started quickly, and they're commented with URLs in the code.
