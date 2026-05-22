; billie, sierpzoom from hellmood's memories
; by ivop, for outline 2026

SDMCTL = $022f

;;SAVMSC = $58

coltab = $0600
fade = $0f00

set_graphics_mode   = $ef9c

;    org $80
    org $74         ; lower will corrupt because of OS graphics call

    bvc main

YLOOP:
init_dx_lsb = *+1
    lda #0
    sta dl
init_dx_msb = *+1
    lda #0
    sta dh

    lda #-32
    sta xpos

    ldx #64     ; loop 64 times, saves load/cmp xpos, but just as many bytes

XLOOP:

pre_bh = *+1
    lda #0
    clc
xpos = *+1
    adc #0
    sta bh

ypos = *+1
    lda #0
    sec
    sbc dh
bh = *+1
    and #0
    and #$fc

;    tax
    sta al

; plot
mask = *+1
    lda #%10000000
    bne okido

    inc ptr
    tya                 ; clear next 8 pixels
    sta (ptr),y

    lda #%10000000
    sta mask

okido:
al = *+1
    and coltab          ; is page aligned, indexed by al, al != 0 ? 0 : 0xff
    ora (ptr),y
    sta (ptr),y

    lsr mask

; end plot

skip_plot:

dl = *+1
    lda #0
    clc
    adc cx
    sta dl

dh = *+1
    lda #0
    adc cx+1
    sta dh

    inc xpos

    dex
    bne XLOOP

pre_bl = *+1
    lda #0
    clc
    adc cx
    sta pre_bl
    lda pre_bh
    adc cx+1
    sta pre_bh

    lda ptr
    cmp #$ff
    bne nomsb

    inc ptr+1       ; mask = 0, so lsb will be increased before plot

nomsb:
    inc ypos
    lda ypos
    cmp #48         ; gr. 4
    bne YLOOP

    rts

bp = $20
cx = $21
ptr = $23

    .print "size of YLOOP = ", *-YLOOP
    .print "end of YLOOP = ", *

; "music" on page zero, lda zp,x is 1 byte shorter

bass:
;    dta 0x89,0xb6,0x98,0x89,0x98,0xb6,0xcb,0xb6 ; billie jean, buzzy
;    dta 0x5a,0xb6,0x98,0x89,0x98,0xb6,0xcb,0xb6 ; billie jean, buzzy, low start
    dta 0x5a,0x3c,0x33,0x2d,0x33,0x3c,0x43,0x3c ; billie jean, gritty

;    dta $e6, $7a, $71, $a1, $98, $bf, $cb, $f2 ; funky semitones, gritty
;    dta $4c, $28, $25, $34, $33, $3f, $43, $51 ; funky semitones, buzzy
drum:
    dta 64,0,12,96,128,0,12,0
;    dta 64,0,16,64,64,0,16,0

; hummmmm, audctl=5, audf1=fe, audc1=a8, audf3=ff, auddc3=a0-af

main:
    lda #4
    jsr set_graphics_mode

    dec SDMCTL          ; narrow playfield

    ; we assume fresh boot, OS zeroes memory

    ldy #$ff
    sty coltab      ; for quick al != 0 ? 0 : 0xff

    iny             ; Y = 0 for the duration of the program

    ; cx = 0xbe00, init_dx = -cx<<6 = 0x(d0)8000    bp -64..63
    ; cx = 0xbc00, init_dx = -cx<<6 = 0x(d1)0000    bp -127..127
restart:
    sty cx
    sty init_dx_lsb
    lda #$be
    sta cx+1
    lda #$80
    sta init_dx_msb

    sty bp

BPLOOP:
.local color
    lda bp
    cmp #10
    bcc store_col
    eor #$7f
    cmp #10
    bcc store_col

    asl
    and #$f0
    ora #10
store_col:
    sta $02c4

    lda bp
    and #15
    lsr
    tax
    lda drum,x
    sta $d200
    lda bass,x
    sta $d202
    lda bp
    and #1
    asl
    asl
    ora #$80
    sta $d201
    asl
    ora #$c0
    sta $d203

.endl

    lda #$7f
    sta ptr

    lda $bd48+5     ; get msb of scrmem
    sta ptr+1
    eor #4          ; adjust and page flip
    sta $bd48+5

    sty mask        ; force inc of ptr and clear of scrmem

    lda cx
    sta pre_bl
    lda cx+1
    sta pre_bh

    sty ypos

    jsr YLOOP

    ; cx += 8
    lda cx
    ;clc            ; ypos >= 48, so C=1 when YLOOP exits
    adc #7
    sta cx
    bcc nomsb2
    inc cx+1
nomsb2:

    ; init_dx += 512
    inc init_dx_msb
    inc init_dx_msb

    inc bp
    bpl BPLOOP
    bmi restart

    .print "size of restart/bploop: ", *-restart

    .print "size of main: ", *-main

