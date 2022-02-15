
; Sierpinski Triangle, by ivop / Ivo van Poorten

; Graphics: 28 bytes, sound: 3 bytes, free: 1 byte

; Atari 800XL Rev.2 OS

; Lil' test.  Sierpinski !(xpos&ypos) and F#READY's plot routine

color   = $02fb
ypos    = $54
xpos    = $55   ; word

set_graphics_mode   = $ef9c
drawto              = $f9c2
plot                = $f1d8

	org $80

main
    lda #7                  ; or 6 (does not seem faster)
    jsr set_graphics_mode

loop
    lda xpos
;                sta $d201
    and ypos
                sta $d201
    bne nopixel

    tax         ; x is set to the same value everytime plot is called

nopixel
    stx color   ; set either the plot-returned value, or zero

draw
    jsr plot

    inc xpos    ; no compare, just "draw" outside the visible area
    bne loop

    inc ypos    ; no compare, just keep drawing in ROM
    bpl loop    ; but stop before hardware registers

    bmi main    ; resets xpos,ypos to 0,0
