; biologie by ivop
; outline 2026, 256b compo

SDMCTL = $022f
SAVMSC = $58

set_graphics_mode = $ef9c
plot = $f1d8

ptr   = $f5
cntx  = $f7
xu16  = $f8
xu16h = $f9
yu16  = $fa
yu16h = $fb
cnt   = $fc
cnth  = $fd
tmp   = $fe
tmph  = $ff

ypos = $54
xpos = $55
color = $02fb

    org $0c00

restart:
    lda #7
    jsr set_graphics_mode

    lda #$a7
    sta $d201
    sta $d203
;    asl
;    sta $02c6

    lda #2
    sta cntx

    asl
    sta $02c4   ; a=4

    asl
    sta $02c5   ; a=8
    asl
    sta ptr+1   ; a=16 ($10)

    lda #15
    sta $02c6

    ldy #0
    sty yu16
    sty yu16h
    sty xu16

;    ldx #$10
;    stx ptr+1

    tya
    ldx #6*16
clear:
    sta (ptr),y
    iny
    bne clear
    inc ptr+1
    dex
    bne clear

; seed
;    lda $d20a
;    sta $0600
notzero:
    inc smc
smc=*+1
    lda mooi-1
endless:
    beq notzero
    sta xu16h

;    lda #2
;    sta cntx

loop:
    jsr step1           ; x += (y ^ 0x10) >> 2

    lda xu16            ; y -= x & 0x7fff
    sta tmp
    lda xu16h
    and #$7f
    sta tmph

    sbw yu16 tmp yu16

    jsr step1           ; x += (y ^ 0x10) >> 2

    ; step1 returns with A=xu16h

    clc                 ; x += 0x4000
    adc #$40
    sta xu16h

    lda yu16h           ; y -= 0x0800
    clc
    adc #$f8
    sta yu16h

; clip to screen

;    lda yu16h
    cmp #96
    bcs skip
    sta ypos

    lda xu16h
    and #$7f
    adc #16
    sta xpos

    jsr set_color

    jsr plot

skip:
    inc cnt
    bne loop

    lda cnth
    lsr
    lsr
    lsr
    and #15
    tax
    ldy notes,x
    sty $d200
    lsr
    lsr
    tax
    lda bass,x
    sta $d202

    inc cnth
    bne loop
    dec cntx
    bne loop

;    lda $0600
;    jmp *
    jmp restart

; returns with A=xu16h
step1:
    lda yu16h
    sta tmph
    lda yu16
    eor #$10

    lsr tmph
    ror
    lsr tmph
    ror

    clc
    adc xu16
    sta xu16
    lda xu16h
    adc tmph
    sta xu16h
    rts

; $1000-$6fff, scan lines page aligned is quicker
; 160x96 8-bit values

set_color:
    lda ypos
    clc
    adc #$10
    sta ptr+1
    ldy xpos
    lda (ptr),y
    clc
    adc #$10
    bcc store
    lda #$ff            ; saturate
store:
    sta (ptr),y
    sta tmp
    lda #0              ; top two bits is color
    asl tmp
    rol
    asl tmp
    rol
    sta color
    rts

mooi:
    dta $1f, $ef, $0b, $a7, $5c, $df, $53 ; $b2, $55

notes:
    dta 96,76,64,47     ; E G# B #
    dta 108,85,72,53    ; D F# A D
    dta 121,96,81,60    ; C E G C
    dta 128,102,85,64   ; B D# F#A B

; E D C B
bass:
    dta 193,217,243,255

