; Ben Eater 6502 Based System based on the accompanying YouTube series
; https://www.youtube.com/watch?v=mpIFag8zSWo
; 
; FPGA by George Smart, M1GEO.
; https://github.com/m1geo/BE6502-FPGA
;
; This file containts customisations specific to this FPGA implimentation.

.setcpu "65C02"
.debuginfo

.zeropage
                .org ZP_START0          ; Read/Write points for input circular buffer
READ_PTR:       .res 1
WRITE_PTR:      .res 1

.segment "INPUT_BUFFER"
INPUT_BUFFER:   .res $100

.segment "BIOS"

ACIA_DATA   = $5000                     ; Data register (read/write byte from UART)
ACIA_STAT   = $5001                     ; Status register: {x, x, x, 4:uart_tx_busy, x, x, 1:uart_rx_break, 0:uart_rx_valid};

splashtext1: .asciiz "Ben Eater 6502 Computer on FPGA by George Smart M1GEO (23-Oct-2024)"
splashtext2: .asciiz "See https://github.com/m1geo/BE6502-FPGA for details.";

LOAD:
                RTS

SAVE:
                RTS

; Read character from UART to the A-register
; On return, carry flag set indicates if key was pressed. If true, key in A-reg.
; Modifies: Flags(carry), A-reg
MONRDKEY:
CHRIN:
                PHX                     ; Save X
                JSR     BUFFER_SIZE     ; Check how many RXed bytes there are.
                BEQ     @buff_empty     ; Jump out if no key
                JSR     READ_BUFFER     ; Load character -> A
                JSR     CHROUT          ; Echo character
                PLX                     ; Restore X (if char)
                SEC                     ; Set carry flag
                RTS                     ; Return from subroutine
@buff_empty:
                PLX                     ; Restore X (if no char)
                CLC                     ; Clear carry flag
                RTS                     ; Return from subroutine

; Output character from A-register to the UART
; Modifies: Flags(carry)
MONCOUT:
CHROUT:
                PHA                     ; Save A to stack
                STA     ACIA_DATA       ; Output character.
@txdelay:       LDA     ACIA_STAT       ; Read UART status flag
                AND     #$10            ; UART busy? Mask for bit5
                BNE     @txdelay        ; Loop until UART not busy.
                PLA                     ; Restore A from stack
                RTS                     ; Return from subroutine

; Init Circular Buffer
; Modifies: Flags, A-reg
INIT_BUFFER:                            ; Set both PTR equal for empty buffer
                LDA     #0              ; Reset buffer counters to zero (don't read, as FPGA Simulation will see 8'hXX)
                STA     READ_PTR        ; Read READ_PTR
                STA     WRITE_PTR       ; Write to WRITE_PTR
                RTS                     ; Return

; Write char to buffer (from A-reg)
; Modifies: Flags, X-reg
WRITE_BUFFER:
                LDX     WRITE_PTR
                STA     INPUT_BUFFER,x
                INC     WRITE_PTR
                RTS
                
; Read next character and return in A-reg
; Modifies: Flags, A-reg, X-reg
READ_BUFFER:
                LDX     READ_PTR
                LDA     INPUT_BUFFER,x
                INC     READ_PTR
                RTS

; Return in A how many bytes are in the buffer
; Modifies: Flags, A-reg
BUFFER_SIZE:
                LDA     WRITE_PTR
                SEC                     ; Set carry bit
                SBC     READ_PTR        ; Subtract with carry (wraps with circ buffer)
                RTS

; Interrupt Request Handler
IRQ_HANDLER:
                PHA                     ; Save A to stack
                PHX                     ; Save X to stack
                LDA     ACIA_STAT       ; Check status (and ACK UART IRQ)
                AND     #$01            ; Check if Key was pressed
                BEQ     @not_uart_data  ; Jump out if no key
                LDA     ACIA_DATA       ; Read UART data byte
                JSR     WRITE_BUFFER    ; Write UART data to circ buffer
@not_uart_data:
                PLX                     ; Restore X from stack
                PLA                     ; Restore A from stack
                RTI                     ; Return from interrupt

NMI_HANDLER:
                RTI

.include "wozmon.s"

.segment "RESETVEC"
.word   NMI_HANDLER                     ; NMI vector
.word   RESET                           ; RESET vector
.word   IRQ_HANDLER                     ; IRQ vector
