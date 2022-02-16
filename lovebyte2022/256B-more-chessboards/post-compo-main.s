
; POST-COMPO improvements!

; Atari 800XL with stock Rev 2 OS, no BASIC

; Cowbell? We need more chessboards!
; by Ivo van Poorten / ivop
; for Lovebyte 2022

color   = $02fb
ypos    = $54
xpos    = $55   ; word

set_graphics_mode   = $ef9c
plot                = $f1d8

; xoffsets in reverse (X = 2, 1, 0)
xoffsets  = 6               ; all three default to zero
_xoffset3 = xoffsets
_xoffset2 = xoffsets+1
_xoffset  = xoffsets+2

val = $03       ; doesn't interfer with OS set_graphics_mode
tmp = $30

	org $80

    lda #$48
    sta 106         ; RAMTOP

main
    lda #5
    jsr set_graphics_mode   ; also resets (xpos,ypos) to (0,0)

    asl 559

; 80x48

;    ldy #1
    sty $d208           ; set 15kHz mode :)


loop
    lda #$20            ; one lsr before it gets used: $10, $08,$04
    sta val

    sta color           ; only the 2 least significant bits are significant :)


; layer 1-3 merged!     (post-compo)

    ldx #2

next_layer
    inc color
    lsr val

    lda xpos
;    clc
    adc xoffsets,x
    and val
    sta tmp

    lda ypos
;clc
    adc val
    and val
    eor tmp
    beq draw

    dex
    bpl next_layer

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

    inc _xoffset2       ; scroll layer 2

    lda _xoffset2
    and #1
    bne no3

    inc _xoffset3       ; scroll layer 3, too!!

no3
    lda 106
    adc #$07            ; carry is always set here, adds 8
    sta 106

    cmp #$c8
    jne main

; -----------------------------------

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

; also saves three bytes!
;cnt = $05       ; value is $07
cnt = $17       ; value is $0b
;cnt = $2f       ; value is $0c

colors
    dta $0f, $07, $73       ; white, gray, blue

