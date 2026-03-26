
    org $80

    lda #0
    sta $d208
    beq gogogo

outer
    dec gogogo+1
    bpl gogogo

    lda #11
    sta gogogo+1
    lda #$d2            ; enable melody after 12 bars
    sta melreg

gogogo
    ldx #11

    lda basspat,x
    sta $d202

    lda crd1pat,x       ; arpeggio notes
    sta hiero
    lda crd2pat,x
    sta hiero2


    ldx #15

loop
    lda drumpat,x
    sta drumf
    clc
    adc #6
    sta drumc


melody = *+1
    lda $c200               ; here's the OS page we're going to play!
    and #7
    tay
    lda pentatonic,y
    sta $d206
    inc melody


    ldy #5

inner

drumf = *+1
    lda kickf,y
    sta $d200
drumc = *+1
    lda kickc,y
    sta $d201

    lda bassc,y
    sta $d203


    tya         ; chord arpeggio
    and #1
    beq do2pat

hiero = *+1
    lda #$0
    sta $d204
    bne continue

do2pat
hiero2 = *+1
    lda #$0
    sta $d204


continue
    txa
    and #2
    bne nocrd       ; half the time there is no chord (env has to end silent)
    lda crdc,y
    sta $d205
nocrd


    lda crdc,y      ; use crd envelope for melody, too
melreg=*+2
    sta $e207       ; $e207 == ROM (no sound); changed to $d207 after 12 bars


wait
    lda 20
wait2
    cmp 20
    beq wait2

    dey
    bpl inner

    dex
    bpl loop
    jmp outer


kickf   dta $00, $00, $ff, $f0, $e0, $40
kickc   dta $00, $00, $a8, $aa, $ac, $8e

snaref  dta $00, $00, $00, $00, $a0, $80
snarec  dta $84, $86, $88, $8a, $ac, $ae

hatclsf dta $00, $00, $00, $00, $00, $00
hatclsc dta $00, $00, $00, $00, $84, $88

drumpat
    dta <hatclsf,  <hatclsf, <hatclsf, <snaref
    dta <hatclsf,  <hatclsf, <hatclsf, <kickf
    dta <hatclsf,  <kickf,   <hatclsf, <snaref
    dta   <kickf,  <hatclsf, <hatclsf, <kickf

bassc   dta $c2, $c5, $c8, $ca, $cc, $ce

crdc    dta $a0, $a5, $a8, $aa, $ac, $ae

; 12 bar blues
basspat
    dta 131, 197, 146, 131
    dta 197, 197, 146, 146
    dta 197, 197, 197, 197

crd1pat
    dta  81, 121,  91,  81
    dta 121, 121,  91,  91
    dta 121, 121, 121, 121
crd2pat
    dta  53,  81,  60,  53
    dta  81,  81,  60,  60
    dta  81,  81,  81,  81

pentatonic
    dta 121, 108, 96, 81, 72
    dta 60, 53, 47
