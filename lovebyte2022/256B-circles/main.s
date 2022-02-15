; Zooming Circles
; needs mathlib.s
; by ivop for Lovebyte 2022

; v5 - 256 bytes: 230 gfx, 26 bytes sound
; v4 - 230 bytes, keep drawing! ;)
; v3 - 233 bytes, invert SBC and ADC, rely on clear carry bit
; v2 - 235 bytes, save first PROD on stack

color   = $02fb
ypos    = $54
xpos    = $55   ; word

set_graphics_mode   = $ef9c
drawto              = $f9c2
plot                = $f1d8

	org $3000

main
    lda #10
    jsr set_graphics_mode

WIDTH=80
HEIGHT=192

loop
    lda xpos
    clc                 ; first clc is mandatory :/
    adc #-WIDTH/2
    sta TERM1
    sta TERM2
    jsr smul8           ; x^2

    lda PROD+1
    pha
    lda PROD
    pha                 ; save for later

    lda ypos
    lsr                 ; for gr. 10, square "pixels"
    lsr                 ; for gr. 10

;    clc                ; always clear
    adc #-HEIGHT/8

    sta TERM1
    sta TERM2
    jsr smul8           ; y^2

    pla                 ; restore, add current PROD and store in TERM1
;    clc                ; carry is always clear, or it doesn't matter ;)
    adc PROD
    sta TERM1
    pla
    adc PROD+1
    sta TERM1+1         ; x^2 + y^2

    jsr sqrt16          ; sqrt(x^2 + y^2)

    tya
    and #7
    tay
    iny                 ; color 1-8 (0 is background)
    sty color

draw
    jsr plot

    inc xpos    ; compare, do not just draw on the next line(s)
    lda xpos
        sta $d203       ; noise $#@$#!@$
    cmp #WIDTH
    bne loop

    lda #0
    sta xpos

    inc ypos    ; no compare, just keep drawing in ROM
;    lda ypos
;    cmp #HEIGHT
    bne loop

    lda #$a7        ; enable dist A
    sta $d201

reset_y
    ldy #3

animate

    sty $d203           ; beat ;)

    lda notes,y
    sta $d200

rotate_colors
    ldx #7
rotloop
    lda $02c1,x
    sta $02c2,x
    dex
    bpl rotloop
    lda $02c9           ; don't use Y to save the color, same amount of bytes
    sta $02c1

    ldx #5              ; speed ; compromise for gfx/snd
waitvb
    lsr $14
    bcc waitvb
    dex
    bpl waitvb

    dey
    bpl animate

    bmi reset_y

;    bmi animate

; INCLUDE mathlib last, depending on where your code goes, you want ZP code
; defined later, so the non-ZP blocks merge
; And we don't need a run address anymore :)

.DEF ENABLE_UMUL8
.DEF ENABLE_SMUL8
;.DEF ENABLE_UMUL16
;.DEF ENABLE_SMUL16
.DEF ENABLE_SQRT16
;.DEF ENABLE_UDIV8
;.DEF ENABLE_SDIV8
;.DEF ENABLE_UDIV16
;.DEF ENABLE_SDIV16
;.DEF ENABLE_LOG8
;.DEF ENABLE_ALOG8

ORG_MATH_ZP = $80
ORG_MATH_NON_ZP = *         ; merge with current code block

;.DEF ENABLE_ZERO_PAGE_CODE_FIRST       ; don't define, so ZP block is last

    icl "mathlib.s"

; Put notes on page zero

    org END_ORG_MATH_ZP

; F sharp !

;notes   = $e400

notes
; F sharp major
    dta $a0, $7f, $6b
    dta $50

;    dta $50, $3f, $35
;    dta $27, $1f

; shuffled
;    dta $a0, $6b, $35, $3f
;    dta $1f, $27, $50, $7f



