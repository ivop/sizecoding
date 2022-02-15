
; -----------------------------------------------------------------------------

; ALTERNATIVE GR. 4 VERSION

; Array of chessboards. Hellmood tribute. By The Gatekeeper.

; Assume 800XL, 64kB, NO BASIC, rev.2 OS, 1st loaded block is also run address

; 2021-12-24 04:15 v1 127 bytes
; 2021-12-24 04:32 v2 124 bytes (merge init loops)
; 2021-12-24 17:05 v3 122 bytes (f#ready loop check instead of cpw)
; 2021-12-24 18:06 v4 120 bytes (split init again, assume zero at end)
; 2021-12-24 18:20 v5 119 bytes (carry is always set after waitvb loop)
; 2021-12-24 20:00 v6 117 bytes (no mwa, and abuse X being zero)
; 2021-12-25 20:46 v7 108 bytes (optimized copy2 loop)
; 2022-01-01 23:00 v8 126 bytes (added sound)

; -----------------------------------------------------------------------------

screen = $4000

    org $0080       ; how low can you go? if you use set_mode

    lda #4          ; graphics 4
    jsr $ef9c       ; set mode

    dec $022f       ; assume $22, decrease to $21 to set small screen

    lda #$ef        ; set color
    sta $02c4

; Now this is "valid"
; scrptr = $bb6c                  ; gr. 5
; scrptr = $af9c                  ; gr. 7

scrptr = $bd4c                  ; gr. 4

    ldx #63

copy2
    txa
    and #15         ; y always 0-15
    tay

    lda pat,y
    sta screen,x
    sta screen+64+1,x

    dex
    bpl copy2

    ldx #0
copy3

    lda screen,x
    sta screen+128,x
    sta screen+256,x
    sta screen+384,x
    dex
    bne copy3

    lda #$af            ; init sound, up to eleven, ehm, fifteen!
    sta $d201
    sta $d203

reset
;    lda #<screen            ; which is zero and X is still zero
;    sta scrptr
    stx scrptr              ; don't use X inside this loop
    lda #>screen
    sta scrptr+1

waitvb
    lsr $14
    bcc waitvb

;;;sound
    tya
;    eor #$ff
    and #$f0
    sta $d200       ; play "ladder"
    sty $d202       ; glide
    dey
;;;endsound

    lda scrptr
;    clc        ; not needed
    adc #7      ; adds 8 because carry is always set after bcc was not taken
    sta scrptr

    lda scrptr+1
    adc #0
    sta scrptr+1

;    lda scrptr+1           ; A is already scrptr+1
    cmp #>(screen+8*16)
    bne waitvb
    lda scrptr
    bpl waitvb              ; thanks f#ready
    bmi reset

pat
:4  dta %10101010, 0
:3  dta %01010101, 0
    dta %01010101       ; assume another zero after this

