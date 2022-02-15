
shift_count = $22       ; inits to $03
timer       = $41       ; also ints to $03

color   = $02fb
ypos    = $54
xpos    = $55   ; word

set_graphics_mode   = $ef9c

    org $80
;   org $2000

main
    lda #5                  ; mode 5        80*48 = 3840 pixels!
    jsr set_graphics_mode

    lda #$21            ; small screen + DMA    tip by F#READY :)
    sta 559

    ldx #>VBI
    ldy #<VBI
    lda #7
    jsr $e45c           ; SETVBV

    ldx #3
setcolors
    lda colors-1,x          ; offset -1 so X ends up 0
    sta $02c4-1,x
    dex
    bne setcolors

; X = 0         ; stx is our stz

    ldy #3

; Y = 3         ; sty is store 3

; --------------------------------

mainloop
    lda #$a0
    sta _shift_address
    sta _shift_address2
_start_address = *+1
    lda #$b3                    ; start drawing invissible screen memory
    sta _shift_address+1
    sta _shift_address2+1

loop
; Layer 1

    lda #1
    sta color

        sta $d208           ; set 15kHz mode

    clc                 ; necessary for first pixel (0,0)
_xoffset = *+1
    lda #15
    and #15             ; slanted checkerboards for "free"
    adc xpos
    adc ypos            ; unslant :)
    adc ypos            ; slant to the other side
    and #16
    beq draw

; Layer 2

    inc color

;    clc
_xoffset2 = *+1
    lda #7
    and #7              ; slanted checkerboards for "free"
    adc xpos
    and #8
    beq draw

; Layer 3

    inc color

;    clc
    lda xpos
;_xoffset3 = *+1
;    adc #7
    and #7
    and ypos                ; hidden sierpinski :)
    bne draw

; Layer 4

    inc color               ; always draw a pixel, including BAK

draw

    ror color               ; unroll for speed in inner loop!
_shift_address = *+1
    rol $bba0

    ror color
_shift_address2 = *+1       ; need to adjust two addresses though
    rol $bba0

    dec shift_count
    bpl no_adjust           ; still in the same screen memory byte

    inc _shift_address
    inc _shift_address2
    bne nomsb

    inc _shift_address+1
    inc _shift_address2+1

nomsb

    sty shift_count         ; Y is always 3, which means 4 shifts

no_adjust
    inc xpos
    lda xpos
;    cmp #80
    cmp #64
    bne loop

    lda  #0
    sta xpos

    dec _xoffset        ; slanted!
    dec _xoffset2
;    inc _xoffset3

    inc ypos
    lda ypos
    cmp #49             ; one extra for effect
    bne loop

    stx ypos            ; X should be 0

; adjust for next frame ?
    dec _xoffset
;    dec _xoffset
;    dec _xoffset2

    lda _start_address      ; swap draw and visible address
    sta $bb6d
    eor #$08
    sta _start_address

    jmp mainloop

colors
;    dta $77, $7f, $73       ; still got the blues
;    dta $97, $9f, $93       ; darker blues
;    dta $a7, $af, $a3       ; GREEN
    dta $a7, $af, $b3       ; GREEN
;    dta $a5, $7f, $93       ; ATRACT mode palette

VBI

_bass_index = *+1
    ldx #7

    lda bass,x
;    nop            lsr or asl
    tax
    stx $d200
    inx
    stx $d202

_volume = *+1
    lda #$0f
    and #$0f
    bne no_16

    dec timer
    bpl no_16

_drum_freq = *+1

;    lda #0                  ; "Mantronix" hiss
;    eor #3

    lda #$f3
    eor #$f0                ; low rumble or "snares"

    sta _drum_freq
    sta $d204

    ldx #3
    stx timer

    dec _bass_index
    bpl no_16

    ldx #7
    stx _bass_index

    ldx #$8d            ; STA opcode
    stx _drum_instruction

;    inx
;    inx
;    stx 77              ; ATRACT, start changing palette
;    stx 78              ; DRKMAK

no_16
    ora #$a0
    sta $d201
    sta $d203

   and #$87
_drum_instruction
   lda $d205            ; becomes STA later

    dec _volume

    jmp $e462               ; XITVBV

bass
    ; in reverse  <-----  Hello by Lionel Richie ;) Or Still Got The Blues...
    ;   A    A    E    Bb   F    C    G    D
    dta 144, 144, 193, 136, 182, 121, 162, 108

