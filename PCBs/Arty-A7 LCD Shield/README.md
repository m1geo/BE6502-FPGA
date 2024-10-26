# Arty-A7 LCD Shield

This folder contains a modified version of the standard Arduino LCD Shield to allow access to R/nW. By default, the Arduino board does not use this, and instead the software impliments a delay loop. However, to maintain compatibility with Ben's code, and to allow for varied CPU speeds, this board allows the code to poll the LCD status register to see if it is finished with previous commands.

The board is designed to be manufactured by JLCPCB (no affiliation, use who you want) as part of their 5 PCBs for $2 offer. A standard, cheap 2-layer board.

Gerbers, BoM and CPL are supplied, along with Schematic. I just soldered the few components on by hand.

Of course, you could just wire this all with jumpers in kin with the original concept! :)

# Some Renders

PCB Front:
![PCB Front|200](/PCBs/Arty-A7%20LCD%20Shield/Arty%20LCD%20Shield%20F.png)

PCB Rear:
![PCB Rear|200](/PCBs/Arty-A7%20LCD%20Shield/Arty%20LCD%20Shield%20R.png)