; tafelkleed by ivop
; outline 2026 128b compo

SDMCTL = $022f
SAVMSC = $58

set_graphics_mode = $ef9c
plot = $f1d8

cnt   = $fc
cnth  = $fd
tmp   = $fe
tmph  = $ff

;ypos = $54
yu16h = $54
xpos = $55
color = $02fb

    org $7c

    inc color
restart:
    lda #8
    jsr set_graphics_mode

    lda #0
    sta $02c6
    sta yu16
    sta xu16
    sta xu16h

notzero:
    inc smc

smc = *+1
    lda mooi-1
    beq notzero
    sta yu16h

loop:

    lda yu16h      ; x += y >> 2
    sta tmph
    lda yu16: #0

    jsr lsr2

    clc
    adc xu16
    sta xu16
    lda xu16h
    adc tmph
    sta xu16h

    lda xu16h: #0      ; y -= x >> 2
    sta tmph
    lda xu16: #0

    jsr lsr2

    sta tmp

    lda yu16
    sec
    sbc tmp
    sta yu16
    lda yu16h
    sbc tmph
    sta yu16h

; clip to screen

    cmp #192
    bcs skip

    lda xu16h
    adc #32
    sta xpos
    lda #0
    adc #0
    sta xpos+1

    jsr plot

skip:
    inc cnt
    bne loop
    inc cnth
    bne loop

    beq restart

lsr2:
    lsr tmp+1
    ror
    lsr tmp+1
    ror
    rts

; not enough bytes for sound/music, so we have a list of nice looking
; patterns instead of $d20a (RANDOM)

mooi:
    dta 233,45,251,199,21,245,11,189,173,159,120,2,39,253,144
