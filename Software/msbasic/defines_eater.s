; configuration
CONFIG_2A := 1

CONFIG_SCRTCH_ORDER := 2

; zero page
ZP_START0 = $00 ; added for input buffer pointers
ZP_START1 = $02
ZP_START2 = $0C
ZP_START3 = $62
ZP_START4 = $6D

; extra/override ZP variables
USR				:= GORESTART ; XXX

; constants
SPACE_FOR_GOSUB := $3E
STACK_TOP		:= $FA
WIDTH			  := 40
WIDTH2			:= 30
RAMSTART2		:= $0400

; magic memory locations
ENTROPY = $7000 ; lfsr (not used)


