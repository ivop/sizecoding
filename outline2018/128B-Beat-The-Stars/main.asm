
    org $80

; INIT
    ldx #$9c        ; no playfield + enough random numbers
    stx $022f

fillrandom
    lda $d20a
    sta $0600,x
    dex
    bne fillrandom

    inx
    stx $d00d
;    dec $d00d      ; 1 byte less, but stars are stripes ;)

; ENDINIT

newframe

; BEAT

instr_idx = *+1
    ldx #3

env=*+1
    lda kickenv,x
    sta $d201

freq=*+1
    lda kickfreq,x
    sta $d200
    dec instr_idx
    bpl noreset

    lda #3
    sta instr_idx

pos=*+1
    ldx #6
    lda song,x
    sta env
    clc
    adc #8
    sta freq
    dec pos
    bpl noreset

    lda #7
    sta pos

; ENDBEAT

; STARS

noreset
    ldx #0
reloady
    ldy #4
next
    stx $d012
    lda $0600,x
    sta $d000
    sta $d40a
    sta $d40a
    tya
    adc $0600,x
    sta $0600,x
    inx
    cpx #154
    beq newframe

    dey
    bne next
    beq reloady

; ENDSTARS

hatenv
    dta $00, $00
snareenv
    dta $82, $84, $a7, $0a
kickenv
    dta $c4, $a7, $a9, $0a

hatfreq
snarefreq
    dta $03, $04, $95, $13
kickfreq
    dta $bf, $ef, $df, $0c

song
    dta <hatenv, <kickenv, <hatenv, <snareenv
    dta <hatenv, <hatenv,  <hatenv, <kickenv

    dta "IVO"

