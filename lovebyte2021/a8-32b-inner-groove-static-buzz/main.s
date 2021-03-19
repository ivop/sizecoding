
    org $50

;    ldx #$af
;    stx $d201
;    inx

    ldx #0
    stx 559

loop
    lda $d20a
;    lda $d40b
    asl
    sta $d000
    sta $d00d
    sta $d012

    lda $00,x           ; page zero is not constant! and it saves a byte
    and #$1f
    sta $d201           ; play sample ;)

    stx $d008
;    sta $d01a

;    stx $d000
;    stx $d00d
;    stx $d012

;    stx $d200
    dex
 
    jmp loop
