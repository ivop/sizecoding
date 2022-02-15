
; We're going down!
; 128B entry for Lovebyte 2022
; by Ivo van Poorten

RAMTOP  = 106

color   = $02fb
ypos    = $54
xpos    = $55   ; word

set_graphics_mode   = $ef9c
plot                = $f1d8

	org $80

main
    lda #5
    jsr set_graphics_mode

    asl 559             ; screen off during pre-calc

loop
    lda #2
    sta color

;    clc                ; always clear
_xoffset = *+1
    lda #15
    and #15             ; slanted checkerboards for "free"
    adc xpos
    adc ypos            ; unslant :)) and add x-axis movement
    and #16
    beq draw

    inc color

;    clc                 ; always clear
_xoffset2 = *+1
    lda #7
    and #7              ; slanted checkerboards for "free"
    adc xpos
    and #8
    bne nodraw

draw
    jsr plot

nodraw
    inc xpos
    lda xpos
    cmp #80
    bne loop

;    lda  #0
;    sta xpos
    sty xpos            ; Y is always 0

    dec _xoffset        ; slanted!
    dec _xoffset2       ;
                        ; no checks or bitwise ANDs, they are done in the loop

    inc ypos
    lda ypos
    cmp #48
    bne loop

    dec _xoffset        ; adjust for next frame
    dec _xoffset
    dec _xoffset2

    lda RAMTOP
;    sec                ; carry is always set
    sbc #8
    sta RAMTOP

    dec numframes
    bpl main

    lsr 559             ; enable screen

animate
    and #$af            ; $a7
    sta $d201

    ldx #2              ; animation speed
waitvb
    lsr $14
    bcc waitvb
    dex
    bpl waitvb

    lda $436d
;    clc                ; carry is always set, so add 7 + 1
    adc #7
    sta $436d

    cmp #$c3
    bne animate

    lda #$43
    sta $436d

    sty $d200
    iny                 ; Going down!?!? ;)

    jmp animate

numframes
    dta 15

