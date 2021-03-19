; ---------------------------------------------------------------------------

; My very first C64 program

; by Ivo van Poorten <ivop@free.fr>
; mads -o:main.prg main.s
; x64sc -autostartprgmode 1 -autostart main.prg

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

; Program parameters

SPEED   = 15
NOTES   = 8

some_page   = $f020

; ---------------------------------------------------------------------------

    opt h-      ; no Atari XEX headers

; ---------------------------------------------------------------------------

LOAD_ADDRESS    = $0801

; use LINENO as variables, copied for free to $39/$3a
LINENO          = SPEED + (256 * (NOTES-1))

_speed_counter  = $39
_note_counter   = $3a

; ---------------------------------------------------------------------------

; C64 Header

    dta a(LOAD_ADDRESS)

    org LOAD_ADDRESS
 
    dta a(_start), a(LINENO), $9e, '2059',0     ; BASIC SYS (2059)

_start                      ; $xx00 means end of BASIC program
    anx #$00               ; lax #$00, unstable, but A=X=0 should work

; ---------------------------------------------------------------------------

main
    sei

    lda #<irq
    sta $314
    lda #>irq
    sta $315

;    stx $d011       ; X=0, VIC-II screen off
    stx $d012

    lda #$7f
    sta $dc0d

    inx             ; X=1
    stx $d01a
    stx $d019       ; ACK IRQs

    lda #15
    sta SIDMODEVOL

    ldx #$09
    stx SIDV1AD
;    stx SIDV3AD

    dex
    stx SIDV2AD
    stx SIDV3AD

;    lda #$00           ; zero is default
;    sta SIDV1SR
;    sta SIDV2SR
;    sta SIDV3SR

    cli

; ---------------------------------------------------------------------------

    bne *
;    jmp *

; ---------------------------------------------------------------------------

irq
    lda #$01
    sta $d019      ; ACK IRQ

_some_page_offset = *+1
    lda some_page
    and #7
    tax

    lda lead_notes_lo,x
    sta SIDV3FREQLO
    lda lead_notes_hi,x
    sta SIDV3FREQHI

    ldx _note_counter

    stx $d020               ; Border Color

_freqlotab_ref =  *+1
    lda freqlotab,x
    sta SIDV1FREQLO
_freqhitab_ref =  *+1
    lda freqhitab,x
    sta SIDV1FREQHI

    lda drums,x
_enable_drum = *        ; SMC, changes to STA abs
    eor SIDV2FREQHI

    lda #$21
    sta SIDV1CTRL       ; set gate bit
    lda #$81
    sta SIDV2CTRL
    lda #$11
_enable_melody = *      ; SMC, changes to STA abs
    eor SIDV3CTRL

    dec _speed_counter
    bpl _notes_done

    lda #SPEED
    sta _speed_counter

    inc _some_page_offset

;    lda #0              ; clear gate bits 
;    sta SIDV1CTRL
;    sta SIDV2CTRL
;    sta SIDV3CTRL

    clc
    asl SIDV1CTRL       ; clear gate bits
    asl SIDV2CTRL
    asl SIDV3CTRL

    dec _note_counter
    bpl _notes_done

    lda #NOTES-1
    sta _note_counter

    dec _chord_counter
    bne _notes_done

    lda #2
    sta _chord_counter

    lda _freqlotab_ref          ; switch from C to F and back again
    eor #freqlotab_mask
    sta _freqlotab_ref
    lda _freqhitab_ref
    eor #freqhitab_mask
    sta _freqhitab_ref

    sta $d021                   ; Screen Color

    dec _drum_start_counter     ; keeps counting after STA abs is done
    bne _no_drum_start

    lda #$8d            ; STA abs
    sta _enable_drum

_no_drum_start
    dec _melody_start_counter   ; keeps...etc...
    bne _exit_irq

    lda #$8d            ; STA abs
    sta _enable_melody

_notes_done

_exit_irq
    jmp $ea81           ; exit IRQ

; ---------------------------------------------------------------------------

_chord_counter
    dta 2
_drum_start_counter
    dta 2
_melody_start_counter
    dta 4

; ---------------------------------------------------------------------------

; BASS
; played in reverse
;       A#2  G2   F2   G2   A#2  C3   C2   C1
freqlotab
    dta $c1, $85, $cf, $85, $c1, $b4, $5a, $2d
freqhitab
    dta $07, $06, $05, $06, $07, $08, $04, $02


; xx overlap with freqlotab2       index 0-7
lead_notes_lo
    ;   C5   D5   F5   A#5
    dta $ce, $11, $76, $04

;       D#3  C3   A#2  C3   D#3  F3   F2   F1
freqlotab2
    dta $59, $b4, $c1, $b4, $59, $9d, $cf, $e7


; xx overlap with freqhitab2       index 0-7
lead_notes_hi
    ;   C5   D5   F5   A#5
    dta $22, $27, $2e, $3e

freqhitab2
    dta $0a, $08, $07, $08, $0a, $0b, $05, $02

freqlotab_mask = freqlotab ^ freqlotab2
freqhitab_mask = freqhitab ^ freqhitab2

; ---------------------------------------------------------------------------

; DRUMS
; played in reverse
drums
    dta $ff, $10, $ff, $1, $ff, $20, $ff, $1

; ---------------------------------------------------------------------------

