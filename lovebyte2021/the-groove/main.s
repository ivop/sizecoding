
; -------------------------------------------------------------------------

; THE GROOVE

; by ivop
; for lovebyte 2021

; -------------------------------------------------------------------------

; enclosed by ".proc" or ".local"
.macro m_assert_same_page
  .if :1 / $100 <> (:1 + .len :1 - 1) / $100
    .print ":1 *CROSSES* page boundary between ", :1, " - ", :1 + .len :1 - 1
  .else
    .print ":1 within page boundary between ", :1, " - ", :1 + .len :1 - 1
  .endif
.endm

; -------------------------------------------------------------------------

RTCLOK  = $0012

COLOR0  = $02c4
COLOR1  = $02c5
COLOR2  = $02c6
COLOR3  = $02c7
COLOR4  = $02c8

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

; -------------------------------------------------------------------------

VISUALS = 1             ; change color shadow registers

FAST    = 1

.if FAST
    INTRO_LENGTH    = 2         ; bars
    BARS_PER_BASS   = 2
    some_page       = $e400
    another_page    = $e400
.else
    INTRO_LENGTH    = 4         ; bars
    BARS_PER_BASS   = 4
    some_page       = $e4f0
    another_page    = $e400
.fi

; -------------------------------------------------------------------------

    org $58

; -------------------------------------------------------------------------

    lda #0             ; SIO leaves 3+4 connected
    sta AUDCTL         ; needed when we use more than two channels

    lda #$a3            ; chord volume
    sta AUDC2

; -------------------------------------------------------------------------
; MAIN
; -------------------------------------------------------------------------

main_loop_y

    ldy #15             ; index into sequence, counting down


_loop_sequence_and_restore_X

    ldx.w sequence,y

_loop_volume
    lda distortions,x

_distortion_mask = *+1
    and #$89                    ; start with noise only

_volume = *+1
    ora #7
    sta AUDC1

_frequency = *+1
    lda frequencies,x
    sta AUDF1

.if VISUALS
            sta COLOR2
.fi

_wait_vblank
    lsr RTCLOK+2
    bcc _wait_vblank
;    bcc _loop_volume           ; or something else for vibrato?


; Chord

; xxxxx  trashes X   xxxxxx
_chord_index = *+1
    ldx #3

_chord = *+1
    lda chord,x

_channel2_opcode                ; SMC
    ora AUDF2


    dec _chord_index
    bpl _no_chord_index_reset

    lda #3
    sta _chord_index

_no_chord_index_reset


; Lead 1

_lead_channel
    lda #$a0
_volume_lead = *+1
    ora #7
    sta AUDC3

_some_page_lsb = *+1
    lda some_page
    and #7
    tax
    lda lead_notes,x
_lead_channel_opcode            ; SMC
    ora AUDF3

; Lead 2

_second_lead_channel
    lda #$a0
    ora _volume
    sta AUDC4

_another_page_lsb = *+1
    lda another_page
    and #7
    tax
    lda lead_notes2,x
_second_lead_channel_opcode     ; SMC
    ora AUDF4

.if VISUALS
                sta 559
.fi

    dec _volume
    bpl _loop_sequence_and_restore_X    ; X was trashed


    lda #7
    sta _volume

    inc _another_page_lsb               ; every 16th note

    dec _volume_lead
    dec _volume_lead                    ; optional? if we need the extra bytes?
    bpl _no_reset_volume_lead

    lda #7
    sta _volume_lead

    inc _some_page_lsb                  ; every quarter note

_no_reset_volume_lead

.if VISUALS
                sty COLOR4
.fi

    dey
    bpl _loop_sequence_and_restore_X

; stuff on note level ^^^^
; ---------------------------------
; stuff on bar  level vvvv

    dec intro_counter
_trampoline_bne_main_loop_y
    bne main_loop_y
    inc intro_counter       ; once the intro is done, keep falling through

    lda #$ff                ; and allow all distortions
    sta _distortion_mask


    dec bar_counter
    bne _trampoline_bne_main_loop_y

    lda _frequency
    eor #FREQ_EOR_MASK               ; xxx possible opt??
    sta _frequency

    lda _chord
    eor #CHORD_EOR_MASK
    sta _chord

    lda #BARS_PER_BASS
    sta bar_counter

    dec chord_counter
    bne _trampoline_bne_main_loop_y
    inc chord_counter       ; once chords start, keep falling through

    lda #$8D                ; opcode STA ABS
    sta _channel2_opcode    ; enable chords


    dec lead_channel_counter
    bne _trampoline_bne_main_loop_y

    inc lead_channel_counter    ;   same fall-through trick

    sta _lead_channel_opcode            ; still STA ABS


    dec second_lead_channel_counter
    bne _trampoline_bne_main_loop_y

    sta _second_lead_channel_opcode     ; still STA ABS
 
    ; sta did not change P
    ; "abuse" beq on the bne trampoline

    beq _trampoline_bne_main_loop_y

;   jmp main_loop_y

; -------------------------------------------------------------------------

frequencies .local                    ; A pentatonic
    dta $13     ; snare
    dta $48     ; kick
    dta $e9     ; bass -- A     ; 12b
    dta $ce     ; bass -- B     ; 
    dta $3d     ; bass -- C#    ; 12a
    dta $33     ; bass -- E     ;
    dta $2d     ; bass -- F#    ;
    dta $25     ; bass -- a     ;
    .endl
    m_assert_same_page frequencies

frequencies2 .local                   ; D pentatonic
    dta $0f     ; snare                 ; slightly different, because we can
    dta $40     ; kick                  ; idem
    dta $ad     ; bass -- D     ; 12b
    dta $9b     ; bass -- E     ; 
    dta $2d     ; bass -- F#    ; 12a
    dta $25     ; bass -- A     ;
    dta $21     ; bass -- B     ;
    dta $1c     ; bass -- d     ;
    .endl
    m_assert_same_page frequencies2

; eor mask if both are on page zero / or same page
FREQ_EOR_MASK = frequencies ^ frequencies2

; -------------------------------------------------------------------------

chord .local                  ; A major, root position
    dta $48     ; A
    dta $39     ; C#
    dta $2f     ; E
    dta $23     ; a
    .endl
    m_assert_same_page chord

chord2 .local                 ; D major, 2nd inversion
    dta $48     ; A
    dta $35     ; D
    dta $2a     ; F#
    dta $23     ; a
    .endl
    m_assert_same_page chord2

; eor mask if both are on page zero / or same page
CHORD_EOR_MASK = chord ^chord2

; -------------------------------------------------------------------------

intro_counter
    dta INTRO_LENGTH

bar_counter
    dta BARS_PER_BASS +1    ; +1 because the 1st fall-through decreases it

chord_counter
    dta 2

lead_channel_counter
    dta 2+1

second_lead_channel_counter
    dta 2+1

; -------------------------------------------------------------------------

distortions .local        ;  include volumes for stacato instruments
    dta $88     ; snare
    dta $0c     ; kick
    dta $c0     ; bass -- I      1
    dta $c9     ; bass -- II     2
    dta $c9     ; bass -- III    3
    dta $c0     ; bass -- V      5
    dta $c8     ; bass -- VI     6
    dta $c8     ; bass -- VIII   8 (octave)
    .endl
    m_assert_same_page distortions

; -------------------------------------------------------------------------

; here's where the GROOVE happens in combination with the stacato instruments

sequence .local               ; in reverse, indexed  by Y
    dta  4, 5, 2, 0
    dta  5, 4, 3, 2
    dta  2, 6, 2, 0
    dta  2, 7, 2, 1
    .endl
    m_assert_same_page sequence

; -------------------------------------------------------------------------

lead_notes  = *
lead_notes2 = *+1           ; silent not in sync, one extra byte

notes .local
    dta $90         ; A
    dta $00         ; silent            ; $80         ; B
    dta $72         ; C#
    dta $00         ; silent            ; $60         ; E

    dta $55         ; F#
    dta $48         ; a
    dta $00         ; silent            ; $40         ; b
    dta $39         ; c#

;    dta $2f         ; e
;    dta $2a         ; f#
    dta $23         ; a             ; extra note on top!
;    dta $1f         ; b
 
    .endl
    m_assert_same_page notes

