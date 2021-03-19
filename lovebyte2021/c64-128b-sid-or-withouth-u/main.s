; ---------------------------------------------------------------------------

; Second sizecoding experiment on a C64

; SID or Without U

; by Ivo van Poorten <ivop@free.fr>
; mads -o:main.prg main.s
; x64 main.prg

; ---------------------------------------------------------------------------

SIDV1FREQLO = $d400         ; Note Frequency LSB
SIDV1FREQHI = $d401         ; And MSB

SIDV1PWLO   = $d402         ; Pulse Wave Duty Cycle
SIDV1PWHI   = $d403

SIDV1CTRL   = $d404 ; noise/ pulse/ saw/ triangle | test/ ringmod/ sync/ gate

SIDV1AD     = $d405         ; Attack Decay
SIDV1SR     = $d406         ; Sustain Release

SIDV2FREQLO = $d407
SIDV2FREQHI = $d408
SIDV2PWLO   = $d409
SIDV2PWHI   = $d40a
SIDV2CTRL   = $d40b
SIDV2AD     = $d40c
SIDV2SR     = $d40d

SIDV3FREQLO = $d40e
SIDV3FREQHI = $d40f
SIDV3PWLO   = $d410
SIDV3PWHI   = $d411
SIDV3CTRL   = $d412
SIDV3AD     = $d413
SIDV3SR     = $d414

SIDFCLO     = $d415
SIDFCHI     = $d416

SIDRESFILT  = $d417
SIDMODEVOL  = $d418     ; Mute3/ HiPass/ BandPass/ LowPass | Main Volume 0-15

; ---------------------------------------------------------------------------

    opt h-      ; no Atari XEX headers

; ---------------------------------------------------------------------------

some_page   = $f700

SNOTE   = 13
BAR     = 3
NPBAR   = 7         ; +1            Notes per bar

LOAD_ADDRESS    = $0801

; use LINENO as variables, copied for free to $39/$3a
; LINENO          = $3a39     ;)
LINENO      = ( (SNOTE * 256) + NPBAR )

_note_spd   = $3a
_npbar      = $39

; ---------------------------------------------------------------------------

; C64 Header

    dta a(LOAD_ADDRESS)

    org LOAD_ADDRESS
 
    dta a(_start), a(LINENO), $9e, '2059',0     ; BASIC SYS (2059)

_start                      ; $xx00 means end of BASIC program
    anx #$00                ; lax #$00, unstable, but A=X=0 should work

; ---------------------------------------------------------------------------

main
    sei

    lda #15
    sta SIDMODEVOL

    lsr             ; A = 7
    tax
    inx
    stx SIDV1AD     ; bass
    stx SIDV2AD     ; melody

            ; we keep SR at 0 so we can easily clear the gate bit

; ---------------------------------------------------------------------------

_reset_y

    ldy #BAR

loop
    sty $d020

    ldx #254
_wait_for_scanline_254
    cpx $d012
    bcs _wait_for_scanline_254
    
_wait_burn_enough_cycles
    dex
    bne _wait_burn_enough_cycles
                                        ; X=0
    lda basslo,y
    sta SIDV1FREQLO
    lda basshi,y
    sta SIDV1FREQHI

_next_note = *+1
    lda some_page
    and #3
    tax

    lda melodylo,x
    sta SIDV2FREQLO
    lda melodyhi,x
    sta SIDV2FREQHI

    lda #$21
    sta SIDV1CTRL
    sta SIDV2CTRL

    dec _note_spd
    bne loop

    asl SIDV1CTRL           ; C must be zero, reset gate bit
    asl SIDV2CTRL

    lda #SNOTE
    sta _note_spd

    inc _next_note

    dec _npbar
    bpl loop

    lda #7
    sta _npbar

    dey
    bpl loop

    bmi _reset_y

; ---------------------------------------------------------------------------

;       G1   B1   A1   D2
basslo
    dta $42, $1b, $a9, $e2

basshi
    dta $03, $04, $03, $04

; ---------------------------------------------------------------------------


;       D5   A4   G4   D4
melodylo
    dta $11, $45, $13, $89

melodyhi
    dta $27, $1d, $1a, $13


