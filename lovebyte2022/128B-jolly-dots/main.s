
; Endless Dots - Jolly Dots
; 128B for Lovebyte 2022
; by Ivo van Poorten

; Always Random!

SAVMSC = $58

color   = $02fb
ypos    = $54
xpos    = $55   ; word

set_graphics_mode   = $ef9c
plot                = $f1d8

	org $80

main
    lda #5
    jsr set_graphics_mode   ; also resets (xpos,ypos) to (0,0)

    ldx #3          ; extra offset so X ends on zero. saves one byte
copycols
    lda colors-1,x
    sta $02c4-1,x
    dex
    bne copycols
    inx             ; X always 1

outerloop
    inc color

    lda color
    and #4
    beq noresetcolor

    stx color

noresetcolor
    lda $d20a
    and #$3f
    sta xpos
    lda $d20a
    and #$1f
    sta ypos

loop

_where = *+1
    lda #$bb                ; starts at $bb, dec with $08
    sta $bb6c+1
;    sta $d203
    sec
    sbc #8
    cmp #$3b                ; #$3b (16 frames) ; #$7b (8 frames)
    bne _noreset

    lda #$bb
_noreset
    sta _where
    sta SAVMSC+1

    jsr plot

                    ; INC ZP  = E6
                    ; DEC ZP  = C6
                    ; eor msk = 20

_xinstr
    inc xpos

    lda xpos
    sta $d201

    beq swapxinstr

    cmp #79
    bne no_swapxinstr

swapxinstr
    lda _xinstr
    eor #$20
    sta _xinstr

no_swapxinstr

_yinstr
    inc ypos

    lda ypos
    beq swapyinstr

    cmp #47
    bne no_swapyinstr

swapyinstr
    lda _yinstr
    eor #$20
    sta _yinstr

no_swapyinstr

waitvb
    lsr $14
    bcc waitvb

    dec cnt
    bne loop

    beq outerloop

cnt = $00       ; inits to 0, but doesn't matter anyway

colors
    dta $35, $9a, $0f

