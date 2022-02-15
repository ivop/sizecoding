
; w/o header, 16 bytes

; Assume 800XL, 64kB, NO BASIC, rev.2 OS, 1st loaded block is also run address

; Name???

; by Ivo van Poorten, 2022-01-05 19:51

    org $80

    lda #3
    jsr $ef9c   ; set gr. mode
loop
    lda $14
    sta $be70,x
    sta $d201
    dex
    bvc loop
