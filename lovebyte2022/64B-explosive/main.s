
; 64B   Explosive Pathfinder!
;
; by ivop, for Lovebyte 2022

color   = $02fb
ypos    = $54
xpos    = $55   ; word

yprev   = $5a
xprev   = $5b   ; word

iter    = $fd
nval    = $fe   ; word

set_graphics_mode   = $ef9c
drawto              = $f9c2
plot                = $f1d8

	org $80

main
    lda #7
    jsr set_graphics_mode

WIDTH=160
HEIGHT=96

start
    lda #WIDTH/2
    sta xpos
    sta xprev
    lda #HEIGHT-1
    sta ypos
    sta yprev

    lda #47
    sta iter

;    jsr plot

loop
    dec ypos
    dec ypos

;    lda $d20a
;    and #1
;    bne increment

    ror $d20a
    bcs increment

:3    dec xpos
    bvc dodraw

increment
:3    inc xpos

dodraw
    jsr drawto

    dec iter
    bne loop

    lda $d20a
    sta color

    sta $d201

    bvc start

