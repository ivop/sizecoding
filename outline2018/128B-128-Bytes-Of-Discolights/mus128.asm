
COLOR2 = $02c6
COLOR4 = $02c8

HPOSP0 = $d000
HPOSP1 = $d001
GRAFP0 = $d00d
GRAFP1 = $d00e
PCOLR0 = $02c0
PCOLR1 = $02c1

    org $80

outer
    ldx #15                 ; 16 ticks (notes)
    stx $d204               ; also $0f distortion for drums

loop
    lda drumnbass,x

    sta GRAFP1
    sta HPOSP1
    sta PCOLR1

    and #1
    asl
    asl
    asl                     ; 0 or 8
    sta  $d205              ; play drum note

    sta COLOR4

    lda drumnbass,x
    lsr
    sta $d200               ; play bass note

    sta COLOR2

    inc *+3                 ; next byte of ROM or whatever page we are playing
    lda $f000               ; (page zero saves one byte but melody sucks)
    and #7                  ; 3 least significant bits
    tay                     ; index in pentatonic table

    lda pentatonic,y
    sta $d202               ; play!

    sta GRAFP0
    sta HPOSP0
    sta PCOLR0

    ldy #15                 ; each tick has 8 subticks for volume envelopes
                            ; y is decreased by two every inner loop 

inner
    tya
    ora #$c0
    sta $d201               ; bass distortion $c0
    ora #$20                ; clean $e0
    sta $d203

    lsr:rcc 20              ; wait until new frame starts

;    lda #0
    sta $d205               ; silence the drum after 1 subtick

    dey:dey:bpl inner       ; next subtick
    dex:bpl loop            ; next tick
    bmi outer               ; completely start over

; pattern is played backwards!

drumnbass
    dta 97<<1|1, 97<<1|1, 85<<1|0, 85<<1|1
    dta 97<<1|0, 97<<1|0, 85<<1|0, 85<<1|0
    dta 63<<1|0, 63<<1|0, 63<<1|0, 63<<1|1
    dta 63<<1|0, 63<<1|0, 63<<1|0,127<<1|0

pentatonic
    dta 121, 108, 96, 81, 72, 60, 53, 47

