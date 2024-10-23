ISCNTC:
                JSR     MONRDKEY       ; Get next command item.
                BCC     not_cntc       ; If carry not set, then def not ctrlC
                CMP     #$3            ; Control+C is ASCII 'ETX' (end of text) 0x03
                BNE     not_cntc       ; If key not equal to ETX then isn't ctrlC
                JMP     is_cntc        ; Otherwise, it _is_ ctrlC
not_cntc:
                RTS        

is_cntc:
                NOP ; fall through into back into main basic code
