; Ben Eater 6502 Based System based on the accompanying YouTube series
; https://www.youtube.com/watch?v=mpIFag8zSWo
; 
; FPGA by George Smart, M1GEO.
; https://github.com/m1geo/BE6502-FPGA
;
; This file containts customisations specific to this FPGA implimentation.

.setcpu "65C02"
.segment "WOZMON"

XAML  = $24                            ; Last "opened" location Low
XAMH  = $25                            ; Last "opened" location High
STL   = $26                            ; Store address Low
STH   = $27                            ; Store address High
L     = $28                            ; Hex value parsing Low
H     = $29                            ; Hex value parsing High
YSAV  = $2A                            ; Used to see if hex value is given
MODE  = $2B                            ; $00=XAM, $7F=STOR, $AE=BLOCK XAM
IN    = $0200                          ; Input buffer

RESET:
                CLD                    ; Clear decimal arithmetic mode
                JSR     INIT_BUFFER    ; Set up circular buffer
                CLI                    ; Clear interrupt disable (enable them)
                LDA     #$0D           ; Send CR
                JSR     CHROUT
                LDA     #$0A           ; Send LF
                JSR     CHROUT
                LDX     #0             ; Load 0->X
SND_SPLASH1:     
                LDA     splashtext1,x  ; Splash Line 1
                BEQ     SPLASH_DONE1   ; If A==0 (string term) jump to done
                JSR     CHROUT         ; Send char using bios CHROUT
                INX                    ; Inc X for next char
                JMP     SND_SPLASH1    ; Loop until string terminator
SPLASH_DONE1:
                LDA     #$0D           ; Send CR
                JSR     CHROUT
                LDA     #$0A           ; Send LF
                JSR     CHROUT
                LDX     #0             ; Load 0->X
SND_SPLASH2:     
                LDA     splashtext2,x  ; Splash Line 2
                BEQ     SPLASH_DONE2   ; If A==0 (string term) jump to done
                JSR     CHROUT         ; Send char using bios CHROUT
                INX                    ; Inc X for next char
                JMP     SND_SPLASH2    ; Loop until string terminator
SPLASH_DONE2:
                LDA     #$0D           ; Send CR
                JSR     CHROUT
                LDA     #$0A           ; Send LF
                JSR     CHROUT
                LDA     #$1B           ; Begin Wozmon with escape.
                LDY     #$8B           ; Hack to not take BPL NEXTCHAR.

NOTCR:
                CMP     #$08           ; Backspace key?
                BEQ     BACKSPACE      ; Yes.
                CMP     #$1B           ; ESC?
                BEQ     ESCAPE         ; Yes.
                INY                    ; Advance text index.
                BPL     NEXTCHAR       ; Auto ESC if line longer than 127.

ESCAPE:
                LDA     #$5C           ; "\".
                JSR     CHROUT         ; Output it.

GETLINE:
                LDA     #$0D           ; Send CR
                JSR     CHROUT
                LDA     #$0A           ; Send LF
                JSR     CHROUT

                LDY     #$01           ; Initialize text index.
BACKSPACE:      DEY                    ; Back up text index.
                BMI     GETLINE        ; Beyond start of line, reinitialize.

NEXTCHAR:
                JSR     CHRIN          ; Call character in routine
                BCC     NEXTCHAR       ; If buffer empty, loop
                STA     IN,Y           ; Add to text buffer.
                CMP     #$0D           ; CR?
                BNE     NOTCR          ; No.

                LDY     #$FF           ; Reset text index.
                LDA     #$00           ; For XAM mode.
                TAX                    ; X=0.
SETBLOCK:
                ASL
SETSTOR:
                ASL                    ; Leaves $7B if setting STOR mode.
                STA     MODE           ; $00 = XAM, $74 = STOR, $B8 = BLOK XAM.
BLSKIP:
                INY                    ; Advance text index.
NEXTITEM:
                LDA     IN,Y           ; Get character.
                CMP     #$0D           ; CR?
                BEQ     GETLINE        ; Yes, done this line.
                CMP     #$2E           ; "."?
                BCC     BLSKIP         ; Skip delimiter.
                BEQ     SETBLOCK       ; Set BLOCK XAM mode.
                CMP     #$3A           ; ":"?
                BEQ     SETSTOR        ; Yes, set STOR mode.
                CMP     #$52           ; "R"?
                BEQ     RUNPROG        ; Yes, run user program.
                STX     L              ; $00 -> L.
                STX     H              ;    and H.
                STY     YSAV           ; Save Y for comparison

NEXTHEX:
                LDA     IN,Y           ; Get character for hex test.
                EOR     #$30           ; Map digits to $0-9.
                CMP     #$0A           ; Digit?
                BCC     DIG            ; Yes.
                ADC     #$88           ; Map letter "A"-"F" to $FA-FF.
                CMP     #$FA           ; Hex letter?
                BCC     NOTHEX         ; No, character not hex.
DIG:
                ASL
                ASL                    ; Hex digit to MSD of A.
                ASL
                ASL

                LDX     #$04           ; Shift count.
HEXSHIFT:
                ASL                    ; Hex digit left, MSB to carry.
                ROL     L              ; Rotate into LSD.
                ROL     H              ; Rotate into MSD's.
                DEX                    ; Done 4 shifts?
                BNE     HEXSHIFT       ; No, loop.
                INY                    ; Advance text index.
                BNE     NEXTHEX        ; Always taken. Check next character for hex.

NOTHEX:
                CPY     YSAV           ; Check if L, H empty (no hex digits).
                BEQ     ESCAPE         ; Yes, generate ESC sequence.

                BIT     MODE           ; Test MODE byte.
                BVC     NOTSTOR        ; B6=0 is STOR, 1 is XAM and BLOCK XAM.

                LDA     L              ; LSD's of hex data.
                STA     (STL,X)        ; Store current 'store index'.
                INC     STL            ; Increment store index.
                BNE     NEXTITEM       ; Get next item (no carry).
                INC     STH            ; Add carry to 'store index' high order.
TONEXTITEM:     JMP     NEXTITEM       ; Get next command item.

RUNPROG:
                JMP     (XAML)         ; Run at current XAM index.

NOTSTOR:
                BMI     XAMNEXT        ; B7 = 0 for XAM, 1 for BLOCK XAM.

                LDX     #$02           ; Byte count.
SETADR:         LDA     L-1,X          ; Copy hex data to
                STA     STL-1,X        ;  'store index'.
                STA     XAML-1,X       ; And to 'XAM index'.
                DEX                    ; Next of 2 bytes.
                BNE     SETADR         ; Loop unless X = 0.

NXTPRNT:
                BNE     PRDATA         ; NE means no address to print.
                LDA     #$0D           ; CR
                JSR     CHROUT         ; Output it.
                LDA     #$0A           ; LF
                JSR     CHROUT         ; Output it.
                LDA     XAMH           ; 'Examine index' high-order byte.
                JSR     PRBYTE         ; Output it in hex format.
                LDA     XAML           ; Low-order 'examine index' byte.
                JSR     PRBYTE         ; Output it in hex format.
                LDA     #$3A           ; ":".
                JSR     CHROUT         ; Output it.

PRDATA:
                LDA     #$20           ; Blank.
                JSR     CHROUT         ; Output it.
                LDA     (XAML,X)       ; Get data byte at 'examine index'.
                JSR     PRBYTE         ; Output it in hex format.
XAMNEXT:        STX     MODE           ; 0 -> MODE (XAM mode).
                LDA     XAML
                CMP     L              ; Compare 'examine index' to hex data.
                LDA     XAMH
                SBC     H
                BCS     TONEXTITEM     ; Not less, so no more data to output.

                INC     XAML
                BNE     MOD8CHK        ; Increment 'examine index'.
                INC     XAMH

MOD8CHK:
                LDA     XAML           ; Check low-order 'examine index' byte
                AND     #$07           ; For MOD 8 = 0
                BPL     NXTPRNT        ; Always taken.

PRBYTE:
                PHA                    ; Save A for LSD.
                LSR
                LSR
                LSR                    ; MSD to LSD position.
                LSR
                JSR     PRHEX          ; Output hex digit.
                PLA                    ; Restore A.

PRHEX:
                AND     #$0F           ; Mask LSD for hex print.
                ORA     #$30           ; Add "0".
                CMP     #$3A           ; Digit?
                BCC     ECHO           ; Yes, output it.
                ADC     #$06           ; Add offset for letter.
                JMP     CHROUT

ECHO:                                  ; [GSCHANGED]
                STA     ACIA_DATA      ; Output character.
                PHA                    ; Save A.
TXDELAY:        LDA     ACIA_STAT      ; Read UART status flag
                AND     #$10           ; Mask out bit5
                BNE     TXDELAY        ; Until UART not busy.
                PLA                    ; Restore A.
                RTS                    ; Return.
