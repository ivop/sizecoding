; The Road To Bach - One Page
;
; BWV Anh 114, composed by Christian Petzold
;
; by Ivo van Poorten    2017,2021
;
; For timing critical loop or ranges enclosed by ".PROC" or ".LOCAL"
.macro m_assert_same_page
  .if :1 / $100 <> (:1 + .len :1 - 1) / $100
    .print ":1 *CROSSES* page boundary between ", :1, " - ", :1 + .len :1 - 1
  .else
    .print ":1 within page boundary between ", :1, " - ", :1 + .len :1 - 1
  .endif
.endm

RTCLOK  = $0012

PCOLR0  = $02c0
PCOLR1  = $02c1
PCOLR2  = $02c2
PCOLR3  = $02c3

HPOSM0  = $d004
HPOSM1  = $d005
HPOSM2  = $d006
HPOSM3  = $d007

SIZEM   = $d00c

GRAFM   = $d011

AUDF1   = $d200
AUDC1   = $d201
AUDF2   = $d202
AUDC2   = $d203
AUDF3   = $d204
AUDC3   = $d205
AUDF4   = $d206
AUDC4   = $d207
AUDCTL  = $d208

RANDOM  = $d20a

WSYNC   = $d40a
VCOUNT  = $d40b

    ; $4e is the lowest possible org

    ; keep adjusting until everything is in its own page :)

    org $4e + 26

    ldx #0
    stx AUDCTL  ; needed because the OS leaves 3+4 linked after loading from
                ; disk. what would happen with a cas file? two tone mode? :)

    stx 559     ; turn off screen

    dex
    stx SIZEM   ; $ff all players quad size

    stx PCOLR2
    stx PCOLR3

    ; left hand. right hand is set automatically later.
    ldx #$a2
    stx AUDC3
    ldx #$a4
    stx AUDC1
    stx PCOLR0

    inx
    stx GRAFM       ; $a5, each missile has a bit set

repeat
    ldy #96
    sty PCOLR1

loop

lsbmusic = *+1
    lda.w music

    pha

    lsr
    lsr
    lsr
    lsr
    tax
    lda lefthand,x
    sta AUDF1
    sta HPOSM0
    lsr
    sta AUDF3               ; fake sawtooth

    pla

    and #$0f
    tax
    stx rh_value

    lda righthand,x
    sta AUDF2
    sta HPOSM1
    lsr
    sta AUDF4               ; fake sawtooth


    ldx #9              ; or 10?
wait
    lda VCOUNT
    sta HPOSM3
    asl
    sta HPOSM2
    sta WSYNC

    lsr RTCLOK+2
    bcc wait

rh_value = *+1
    lda #0
    beq skip

    txa
    ora #$a0
    sta AUDC2
    txa
    lsr
    ora #$a0
    sta AUDC4

skip
    dex
    bpl wait


    inc lsbmusic
    dey
    bne loop

    sty lsbmusic        ; y == 0
    beq repeat

lefthand .local
;               $00  $10  $20  $30  $40  $50  $60  $70  $80  $90  $a0  $b0
;                 G    A    B    D,   E   F#    G    A    B    C   C#    D
            dta   0, 144, 128, 217, 193, 172, 162, 144, 128, 121, 114, 108
         .endl
    m_assert_same_page lefthand

righthand .local
;               $00  $01  $02  $03  $04  $05  $06  $07  $08  $09  $0a  $0b $0c
;               sil    G    A    B    C   C#    D    E   F#    G    A    B  F#
            dta   0,  81,  72,  64,  60,  57,  53,  47,  42,  40,  35,  31, 85
         .endl
    m_assert_same_page righthand

; note pairs, page 1 of BWV Anh 114.
music .local
    dta $66, $60, $61, $62, $73, $74
    dta $86, $80, $81, $80, $81, $80
    dta $97, $90, $94, $96, $97, $98
    dta $89, $80, $81, $80, $81, $80

    dta $74, $70, $76, $74, $53, $52
    dta $63, $60, $64, $63, $92, $91
    dta $bc, $b0, $81, $82, $63, $61
    dta $b2, $b0, $30, $90, $80, $70

    dta $86, $80, $81, $82, $73, $74
    dta $66, $60, $81, $80, $61, $60
    dta $97, $90, $94, $96, $97, $98
    dta $89, $80, $91, $80, $71, $60

    dta $74, $70, $76, $74, $53, $52
    dta $63, $60, $64, $63, $82, $81
    dta $92, $90, $b3, $b2, $31, $3c
    dta $61, $60, $60, $60, $00, $00
    .endl
    m_assert_same_page music

