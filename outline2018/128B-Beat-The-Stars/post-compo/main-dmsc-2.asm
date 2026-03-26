
    org $80

; INIT

fillrandom
    lda $d20a
    pha
    tsx
    bne fillrandom

    stx $d40e       ; To use stack, we need to disable NMIs
    stx $d400

; ENDINIT

newframe

; BEAT

instr_idx = *+1
    ldx #3+kickenv

    lda 0,x
    sta $d201
    lda 8,x
    sta $d200

    dex
    lsr knt
    lsr knt
    bne noreset

    dec knt
pos=*+1
    ldy #6
    ldx song,y
    dey
    bpl noreset2

    ldy #7

noreset2
    sty pos

noreset
    stx instr_idx

; ENDBEAT

; STARS
    ldx #256-157
reloady
    ldy #4
    sty $d00d
next
    stx $d012
    txs
    pla
    sta $d000
    sta $d40a
    sta $d40a
    sty spd
spd=*+1
    adc #0
    pha
    inx
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
    dta <hatenv+3, <kickenv+3, <hatenv+3, <snareenv+3
    dta <hatenv+3, <hatenv+3,  <hatenv+3, <kickenv+3

knt
    dta "IVO"

