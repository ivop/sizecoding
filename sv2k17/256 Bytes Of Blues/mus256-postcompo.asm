
; ivop      (2nd place sv2k17 version)
;
; jac!      (improve entry of outer, lsr instead of and #1,
;            bit abs trick, relocate to use lda ZP,x , lsr:rcc 20 trick)
; irgendwer (overlapping tables)
; ivop      (carry always set after loop)
; dmsc      (reorder tables for 4 more bytes overlap
;            even better entry of outer, swap of x and y in inner loops
;            eor trick for both notes of arpeggio,
;            read crdc (envelope) only once)
; ivop      (remove crd1pat and calculate the values
;            merge basspat and crd2pat with one extra indirection
;            overlap bluespat and drumpat)
; dmsc      (use last part of snare as hat-closed instrument)
; ivop      (merge bassc and crdc)
; dmsc      (reorder writing to bass control, simpler *3/2)
; irgendwer (merged drums and blues pattern into one table)
; dmsc      (reorder chord tables, use table for chord again, now it's shorter)
; jac!      (inc $d208 reads $ff and writes $00)
; irgendwer (moved blues pattern to page boundary for index free access)
; dmsc      (invert drums pattern to reuse last tree zeroes in the hat-closed instrument)
; jac!      (reuse Y=0 to activate melody frequency register instead of control register)
; dmsc      (move drums frequency table to zeropage, optimize CLC/ADC to EOR if possible)
; irgendwer (changed self modifying arpeggio code to stack operations)

;For timing critical loop or ranges enclosed by ".PROC" or ".LOCAL"
.macro m_assert_same_page
  .if :1 / $100 <> (:1 + .len :1 - 1) / $100
    .error ":1 crosses page boundary between ", :1, " - ", :1 + .len :1 - 1
  .else
    .print ":1 within page boundary between ", :1, " - ", :1 + .len :1 - 1
  .endif
.endm


voice1f = $d202
voice1c = $d203
voice2f = $d204
voice2c = $d205
voice3f = $d206
voice3c = $d207
voice4f = $d20a     ; silent
voice4c = $d201

    org $4e + 25    ; offset is there to have tables not cross page boundaries

    inc $d208

outer
    inc currentblues
    bne readblues
    sty melreg      ; here A=$E0 X=$FF Y=$00 P=$33
    lda #<bluespat
    sta currentblues

readblues
currentblues = *+1
    lda bluespat-1  ; start at one before starting blues, first iteration increments
    and #%11
    tax
    lda bass,x
    sta voice2f


    lda chord2,x    ; the other arpeggio note is NOTE*3/2
    pha
    eor chord,x
    sta chiero

    ldy #256-16     ; count from -16 to 0
loop
    lda drumspat + 16 - 256, y
    lsr
    lsr
    sta drumc

    .if ((hatclsc^hatclsf) ^ hatclsf == hatclsc) && ((hatclsc^hatclsf) ^ kickf == kickc) && ((hatclsc^hatclsf) ^ snaref == snarec)
                    ; optimize, can use EOR instead of CLC+ADC:
      eor #.LO(hatclsc^hatclsf)
    .else
      clc           ; Must clear carry again
      adc #(hatclsf-hatclsc)
    .endif
    sta drumf


melody = *+1
    lda $c200       ; here's the OS page we're going to play!
    and #7
    tax
    lda pentatonic,x
melreg=*+1
    sta voice4f     ; first $d20a, changed to $d200 after 12 bars
    inc melody

    ldx #5

inner

drumf = *+1
    lda kickf,x
    sta voice1f

drumc = *+1
    lda kickc,x
    sta voice1c

    pla
    sta voice3f
chiero = *+1
    eor #$00        ; interchange note for next in chord
    pha

    tya
    lsr
    lsr             ; carry set, no chord
    lda bassc,x
    sta voice2c
    ora #$20        ; $Cx | $20 = $Ex, which is also clean notes
    bcc nocrd       ; half the time there is no chord (env has to end silent)
    sta voice3c
nocrd
    sta voice4c     ; use same envelope for melody, too

    lsr:rcc 20

    dex
    bpl inner

    iny
    bne loop
    pla
    bne outer

bass .local
    dta 131, 146, 197
    .endl
    m_assert_same_page bass

chord_and_penta .local
.def :chord
    dta 53, 60  ; 81 from below
.def :chord2
    dta 81, 91  ; 121 from below
.def :pentatonic
    dta 121, 108, 96, 81, 72
    dta 60, 53, 47

    .endl chord_and_penta
    m_assert_same_page chord_and_penta

bassc   .local
    dta $c0, $c5, $c8, $ca, $cc, $ce
    .endl
    m_assert_same_page bassc


        ; Table with drums frequency values
hatclsf = *-3
          ; $??, $??, $??, $00, $00, $00
snaref  dta $00, $00, $00, $00, $a0, $80
kickf   dta $00, $00, $ff, $f0, $e0, $40


drumspat = *            ; Drums pattern starts here
bluespat = * + 1        ; Blues pattern is in the same table, starting in the second position

     dta .LO(kickc) << 2     , .LO(hatclsc) << 2 | 2, .LO(hatclsc) << 2 | 2, .LO(kickc) << 2   | 2
     dta .LO(snarec) << 2 | 2, .LO(hatclsc) << 2 | 1, .LO(kickc) << 2   | 1, .LO(hatclsc) << 2 | 2
     dta .LO(kickc) << 2  | 2, .LO(hatclsc) << 2 | 0, .LO(hatclsc) << 2 | 1, .LO(hatclsc) << 2 | 2
     dta .LO(snarec) << 2 | 0

        .error * <> $100        ; The end of the blues pattern is in the roll to the next page!

   ; The next tree values are  $00, $00, $00 -> use from table bellow!
   ; dta .LO(drums.hatclsc) << 2    , .LO(drums.hatclsc) << 2    , .LO(drums.hatclsc) << 2

; ensure hatclsc is always $0100 so its LSB is $00

        ; Table with drums control values
hatclsc dta $00, $00, $00 ; , $84, $86, $88
snarec  dta $84, $86, $88, $8a, $ac, $ae
kickc   dta $00, $00, $a8, $aa, $ac, $8e

; ensure that difference between control/frequency values is constant
    .error (hatclsc - hatclsf) <> (snarec - snaref)
    .error (hatclsc - hatclsf) <> (kickc - kickf)
