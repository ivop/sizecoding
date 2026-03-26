
    org $80

; INIT

fillrandom
knt=*+2         ; For the envelope counter, reused the $D2
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
    ldx #kickenv-hatenv

    lda hatenv+3,x
    sta $d201
    lda hatfreq+3,x
    sta $d200

    dex
    lsr knt
    lsr knt
    bne noreset

    dec knt
pos=*+1
    ldy #7
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
    ldx #256-157       ; PAL stars speed
;    ldx #256-132       ; NTSC stars speed
;    ldx $D40B           ; Works in PAL or NTSC, but stars don't move vertically!
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

song
    dta <kickenv-hatenv, <hatenv-hatenv, <kickenv-hatenv, <hatenv-hatenv
    dta <snareenv-hatenv, <hatenv-hatenv, <hatenv-hatenv,  <hatenv-hatenv

hatenv=*-2      ; Two previous bytes are 0, last values of hat envelope = silent
snareenv
    dta $82, $84, $a7, $0a
kickenv
    dta $c4, $a7, $a9, $0a

hatfreq=*-2     ; Two previous bytes are any value, as envelope is silent
snarefreq
    dta $03, $04, $95, $13
kickfreq
    dta $bf, $ef, $df, $0c

signature
    dta "IVO"

