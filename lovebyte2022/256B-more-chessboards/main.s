
; Cowbell? We need more chessboards!
; by Ivo van Poorten / ivop
; for Lovebyte 2022

color   = $02fb
ypos    = $54
xpos    = $55   ; word

set_graphics_mode   = $ef9c
drawto              = $f9c2
plot                = $f1d8

tmp = $30

	org $80

    lda #$48
    sta 106         ; RAMTOP

main
    lda #5
    jsr set_graphics_mode   ; also resets (xpos,ypos) to (0,0)

    sta 559

; 80x48

    
loop

; layer1

    lda #1
    sta color

        sta $d208           ; set 15kHz mode :)

    lda xpos
;    clc            ; none of the CLCs are needed
_xoffset = *+1
    adc #0
    and #$10
    sta tmp

    lda ypos
;    clc
;_yoffset = *+1
;    adc #0
    adc #$10
    and #$10
    eor tmp
    beq draw

; layer2

    inc color

    lda xpos
;    clc
_xoffset2 = *+1
    adc #0
    and #$08
    sta tmp

    lda ypos
;    clc
;_yoffset2 = *+1
;    adc #0
    adc #$08
    and #$08
    eor tmp
    beq draw

; layer 3

    inc color

    lda xpos
;    clc
_xoffset3 = *+1
    adc #0
    and #$04
    sta tmp

    lda ypos
;    clc
;_yoffset3 = *+1
;    adc #0
    adc #$04
    and #$04
    eor tmp
    beq draw

; layer 4 in theory, but we don't have more colors

    bne nodraw

draw
    jsr plot

nodraw
    inc xpos

    lda xpos
    cmp #80
    bne loop

    lda #0
    sta xpos

;    inc $02c8   ; indicator we are still doing something ;)

    inc ypos

;    bpl loop       ; meh, 36s precalc, 4 more bytes free

    lda ypos
    cmp #48
    bne loop        ; this is 15s precalc

    inc _xoffset        ; scroll layer 1
    inc _xoffset

;    inc _yoffset
;    inc _yoffset

    inc _xoffset2       ; scroll layer 2

;    inc _yoffset2

    lda _xoffset2
    and #1
    bne no3

    inc _xoffset3       ; scroll layer 3, too!!

;    inc _yoffset3

no3
    lda 106
    adc #$07            ; carry is always set here
    sta 106

    cmp #$c8
    bne main

; -----------------------------------

;    lda #32+2
;    sta 559             ; enable screen

    lda #$aa            ; $aa or $ae because of small/normal/wide screen later
    sta $d201
    sta $d203

    sta 559     ; enable screen, proper bits (DMA and normal) are set

outersoundloop
    ldy #15

_start_riff = *+1
    lda #$00            ; #$ax with x>0 to enable sound
    sta $d205

innersoundloop

    tya
    lsr
    lsr
    tax
    lda bass,x
    sta $d200
    sec                 ; w/o it wobbles too much imho
    sbc #1              ; modulate bass
    sta $d202

    lda riff,y
    sta $d204

    tya
    and #3
    ora #$80
_enable_hiss = *+1
    sta $d20c

animate

    ldx #2  ; or #1 and leave color 2 blueish, save one byte, and move faster

waitvb
    lsr $14
    bcc waitvb
    lda colors,x
    sta $02c4,x
    dex
    bpl wait vb

    lda $bb6d       ; straight into the last display list
;    sec            ; carry is always set after waitvb!
    sbc #$08
    cmp #$3b
    bne cont

    lda #$bb

cont
    sta $bb6d

    dec cnt
    bpl animate

;    inc $02c8      ; indicate we are doing something ;)

    lda #11
    sta cnt

    dey
    bpl innersoundloop

    lda #$a7                ; MUST be a7 because $d2a7 == $d207
    sta _start_riff

;    lda #7                 ; abuse repeats of pokey registers
    sta _enable_hiss

    bne outersoundloop

; ----------------------------------------------------------------------------

; Don't Fear The Reaper by Blue Öyster Cult
; Very Slow.
; Yeah, this are 64kHz NTSC frequencies played at 15kHz PAL :D
; Point is that the relative distances are okay and it sounds pretty nice ;)
; Sorry people with perfect pitch. It's about a semi-tone off.

bass        ; plays in reverse
  dta 162     ; G
  dta 182     ; F
  dta 162     ; G
  dta 144     ; A

riff        ; plays in reverse
    dta 19, 26, 31, 40
    dta 19, 26, 29, 45
    dta 19, 26, 31, 40
    dta 19, 17, 23, 35

;cnt
;    dta 7
;    dta 11
;    dta 15

; also saves three bytes!
;cnt = $05       ; value is $07
cnt = $17       ; value is $0b
;cnt = $2f       ; value is $0c

colors
    dta $0f, $07, $73       ; white, gray, blue

;    dta $bf, $27, $73      ; greenish, brownish, blue
;    dta $0f, $07, $75       ; white, gray, blue2





