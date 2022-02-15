
; ATARI INVASION MATH library

; Combining several algorithms for size and speed

; Cross-breeding by ivop 2022-01-xx

; v12 - introduce ENABLE_ZERO_PAGE_CODE_FIRST for sizecoding
; v11 - force caller to define locations of ZP and NON_ZP code
; v10 - export END_ of ZP and NON_ZP code
; v9 - fixed signed division, remainder follows sign of numerator!
; v8 - split test code, made it into an include file
; v7 - added alog8, 529 bytes with all functions enabled
; v6 - added sdiv16. a lot of code for sign corrections, but it works! 497B
; v5 - cleanup, made all subroutines .proc (local variables), better docs
;      changed .if to .ifdef for enabling functions
; v4 - added log8: 2-based log, A=log(A), total: 361 w/o test code
; v3 - sdiv8 with all sign corrections. not slow, but big! 342 bytes
; v2 - added sqrt16, udiv8 and udiv16 - 276 bytes w/o test code
; v1 - 159 bytes without test code

; remainders are least absolute remainders (so they can be negative)

; maybe: optional least positive remainder DEFine, to skip some code?

; if you enable SMUL8 or SMUL16, you need to enable the corresponding UMUL

; if you enable SDIV8 or SDIV16, you need to enable the corresponding UDIV

; defined by caller

;ORG_MATH_ZP     = $80
;ORG_MATH_NON_ZP = $2000

;.DEF ENABLE_UMUL8
;.DEF ENABLE_SMUL8
;.DEF ENABLE_UMUL16
;.DEF ENABLE_SMUL16
;.DEF ENABLE_SQRT16
;.DEF ENABLE_UDIV8
;.DEF ENABLE_SDIV8
;.DEF ENABLE_UDIV16
;.DEF ENABLE_SDIV16
;.DEF ENABLE_LOG8
;.DEF ENABLE_ALOG8

;.DEF ENABLE_ZERO_PAGE_CODE_FIRST       ; umul8 code

; ----------------------------------------------------------------------------

; Short manual :))

; mva #val1 FAC1
; mva #val2 FAC2
; jsr umul8
; A(msb) and X(lsb) = FAC1 * FAC2

; mva #val1 TERM1
; mva #val2 TERM2
; jsr smul8
; PROD = TERM1 * TERM2

; mwa #word1 multiplier
; mwa #word2 multiplicand
; jsr umul16
; product = multiplier * multiplicand

; mwa #word1 TERM1
; mwa #word2 TERM2
; jsr smul16
; product = TERM1 * TERM2

; mwa #word TERM1
; jsr sqrt16
; Y = sqrt16(TERM1)

; mva #val1 TERM1
; mva #val2 TERM2
; jsr udiv8
; TERM1 = TERM1/TERM2, remainder in A

; mwa #word1 TERM1  
; mwa #word2 TERM2
; jsr udiv16
; TERM1 = TERM1/TERM2, remainder in PROD

; mwa #word1 TERM1
; mwa #word2 TERM2
; jsr sdiv8
; TERM1 = TERM1/TERM2, remainder in A

; lda #val          ; input is 8.0
; jsr log8
; A=LOG(val)        ; result is 3.5 fixed point

; mwa #word1 TERM1
; mwa #word2 TERM2
; jsr sdiv16
; TERM1 = TERM1/TERM2, remainder in PROD

; lda #val          ; 3.5 fixed point
; jsr alog8
; A=ALOG(val)       ; result is 8.0

; ----------------------------------------------------------------------------

; Variables at the end of page zero     ; $f0-$ff (!)

TERM1           = $f0       ; 8 or 16-bits
TERM2           = $f2       ; 8 or 16--bits
PROD            = $f4       ; 16-bits
multiplier      = $f8       ; 16-bits
multiplicand    = $fa       ; 16-bits
product         = $fc       ; 32-bits
 
; save space for DIV8/16 routines

SAVE1   = $f8       ; 16-bits
SAVE2   = $fa       ; 16-bits

; ----------------------------------------------------------------------------

; WARNING: ALL zero page code is mirrored at the end of the file!!!

.ifdef ENABLE_ZERO_PAGE_CODE_FIRST

; This code needs to be on page zero

    org ORG_MATH_ZP

.ifdef ENABLE_UMUL8

FAC1 = umul8.FAC1
FAC2 = umul8.FAC2

; FAC1 and FAC2 are inlined!        FAC1 is clobbered, FAC2 is not!

; UMUL8         8*8=16 bits         FAC1 * FAC2 = MSB(A) LSB(X)

    .proc umul8
    lda #$00
    ldx #$08
    clc
mul_loop
    bcc skip_add
    clc
                    FAC2=*+1
    adc #0
skip_add
    ror
    ror FAC1
    dex
    bpl mul_loop
                    FAC1=*+1
    ldx #0
    rts

    .endp

.endif

END_ORG_MATH_ZP = *

.endif

; ----------------------------------------------------------------------------
; ----------------------------------------------------------------------------

; This code does not need to be on page zero

    org ORG_MATH_NON_ZP

.ifdef ENABLE_UMUL16

; UMUL16        16*16=32 bits   clobbers multiplier, but not multiplicand

umul16 
    lda #0
    sta product+2       ; clear upper bits of product
    sta product+3
    ldx #16             ; set binary count to 16 
shift_right
    lsr multiplier+1    ; divide multiplier by 2 
    ror multiplier
    bcc rotate_right
    lda product+2       ; get upper half of product and add multiplicand
    clc
    adc multiplicand
    sta product+2
    lda product+3 
    adc multiplicand+1
rotate_right
    ror                 ; rotate partial product 
    sta product+3 
    ror product+2
    ror product+1 
    ror product 
    dex
    bne shift_right
    rts

.endif

.ifdef ENABLE_SMUL8

smul8
    lda TERM1
    sta FAC1
    lda TERM2
    sta FAC2

    jsr umul8

    stx PROD
    sta PROD+1

    ; fix sign, see C=Hacking16 for details :))

    lda TERM1
    bpl skip1

    sec
    lda PROD+1
    sbc TERM2
    sta PROD+1

skip1

    lda TERM2
    bpl skip2

    sec
    lda PROD+1
    sbc TERM1
    sta PROD+1

skip2
    rts

.endif

; ----------------------------------------------------------------------------

.ifdef ENABLE_SMUL16

; use TERM1 and TERM2 as input. we need them unclobbered for sign correction

; product = TERM1 * TERM2       ; signed

    .proc smul16
    mwa TERM1 multiplier
    mwa TERM2 multiplicand
    jsr umul16

    lda TERM1+1
    bpl positive1

    sec
    lda product+2
    sbc TERM2
    sta product+2
    lda product+3
    sbc TERM2+1
    sta product+3

positive1
    lda TERM2+1
    bpl positive2

    sec
    lda product+2
    sbc TERM1
    sta product+2
    lda product+3
    sbc TERM1+1
    sta product+3

positive2
    rts

    .endp

.endif

; smul16 optimize hint: multiplicand is unclobbered, so define as
; product = TERM1 * multiplicand
; saves a mwa TERM2 multiplicand

; need to define aliases for a sort-of defined API ;)

; ----------------------------------------------------------------------------

.ifdef ENABLE_SQRT16

; from codebase64, source author unknown

; Y = sqrt(TERM1)       16 bits         Y is always rounded down

TLO = TERM2
THI = TERM2+1

MLO = TERM1
MHI = TERM1+1

    .proc sqrt16

    ldy #0      ; R = 0
    ldx #7
    clc         ; clear bit 16 of M

_loop
    tya
    ora _stab-1,X
    sta THI     ; (R ASL 8) | (D ASL 7)
    lda MHI
    bcs _skip0  ; M >= 65536? then T <= M is always true
    cmp THI
    bcc _skip1  ; T <= M
_skip0
    sbc THI
    sta MHI     ; M = M - T
    tya
    ora _stab,x
    tay         ; R = R OR D
_skip1
    asl MLO
    rol MHI     ; M = M ASL 1
    dex
    bne _loop

    ; last iteration
    bcs _skip2
    sty THI
    lda MLO
    cmp #$80
    lda MHI
    sbc THI
    bcc _skip3
_skip2
    iny         ; R = R OR D (D is 1 here)
_skip3
    rts

_stab
    dta $01, $02, $04, $08, $10, $20, $40, $80

    .endp

.endif

; ----------------------------------------------------------------------------

.ifdef ENABLE_UDIV8

; codebase64 -> by White Flame

; TERM1 = TERM1/TERM2
; remainder in A
; clobbers TERM1, but not TERM2

    .proc udiv8

_num        = TERM1
_denom      = TERM2

    lda #0
    ldx #7
    clc
_loopudiv8
    rol _num
    rol
    cmp _denom
    bcc _skipsbc
    sbc _denom
_skipsbc
    dex
    bpl _loopudiv8
    rol _num
    rts

    .endp

.fi

; ----------------------------------------------------------------------------

.ifdef ENABLE_UDIV16

; TERM1 = TERM1 / TERM2 , remainder in PROD

; clobbers TERM1, but not TERM2

    .proc udiv16

_divisor    = TERM2
_dividend   = TERM1
_remainder  = PROD
_result     = TERM1

    lda #0              ; preset remainder to 0
    sta _remainder
    sta _remainder+1
    ldx #16             ; repeat for each bit: ...

_divloop
    asl _dividend       ; dividend lb & hb*2, msb -> Carry
    rol _dividend+1
    rol _remainder      ; remainder lb & hb * 2 + msb from carry
    rol _remainder+1
    lda _remainder
    sec
    sbc _divisor        ; substract divisor to see if it fits in
    tay                 ; lb result -> Y, for we may need it later
    lda _remainder+1
    sbc _divisor+1
    bcc _skipdivloop    ; if carry=0 then divisor didn't fit in yet

    sta _remainder+1    ; else save substraction result as new remainder,
    sty _remainder
    inc _result         ; and INCrement result cause divisor fit in 1 times

_skipdivloop
    dex
    bne _divloop	

    rts

    .endp

.fi

; ----------------------------------------------------------------------------

.ifdef ENABLE_SDIV8

; TERM1 = TERM1/TERM2
; remainder in A

    .proc sdiv8

    ; TERM1=abs(TERM1) and TERM2=abs(TERM2), save originals in SAVE1 and SAVE2

    lda TERM1
    sta SAVE1
    bpl nothing1

    eor #$ff            ; swap sign
    clc
    adc #1
nothing1
    sta TERM1

    lda TERM2
    sta SAVE2
    bpl nothing2

    eor #$ff            ; swap sign
    clc
    adc #1
nothing2
    sta TERM2

    jsr udiv8

    ; TERM1 is result, SAVE1/2 are previous values

    tax             ; save remainder

    ; fix sign

    lda SAVE1
    bpl nosave1

    lda TERM1       ; fix sign
    eor #$ff
    sta TERM1
    inc TERM1

    txa              ; fix remainder
    eor #$ff
    tax
    inx

nosave1
    lda SAVE2
    bpl nosave2

    lda TERM1       ; fix sign (again)
    eor #$ff
    sta TERM1
    inc TERM1

;    txa              ; fix remainder
;    eor #$ff
;    tax
;    inx

nosave2
    txa             ; restore remainder
    rts

    .endp

.fi

; ----------------------------------------------------------------------------

.ifdef ENABLE_SDIV16

; TERM1 = TERM1 / TERM2 , remainder in PROD
; clobbers TERM1, but not TERM2

; sizecoding hint, sign inversion could be a subroutine

    .proc sdiv16

    ; TERM1=abs(TERM1) and TERM2=abs(TERM2), save originals in SAVE1 and SAVE2

    lda TERM1
    sta SAVE1
    lda TERM1+1
    sta SAVE1+1
    bpl nofix1

    eor #$ff            ; make positive
    sta TERM1+1
    lda TERM1
    eor #$ff
    sta TERM1

    inw TERM1

nofix1
    lda TERM2
    sta SAVE2
    lda TERM2+1
    sta SAVE2+1
    bpl nofix2

    eor #$ff            ; make positive
    sta TERM2+1
    lda TERM2
    eor #$ff
    sta TERM2

    inw TERM2

nofix2
    jsr udiv16

    ; fix sign of result (TERM1) and remainder (PROD)

    lda SAVE1+1
    bpl nofix3

    lda TERM1       ; invert sign
    eor #$ff
    sta TERM1
    lda TERM1+1
    eor #$ff
    sta TERM1+1

    inw TERM1

    lda PROD       ; invert sign of remainder
    eor #$ff
    sta PROD
    lda PROD+1
    eor #$ff
    sta PROD+1

    inw PROD

nofix3
    lda SAVE2+1
    bpl nofix4

    lda TERM1       ; invert sign
    eor #$ff
    sta TERM1
    lda TERM1+1
    eor #$ff
    sta TERM1+1

    inw TERM1

;    lda PROD       ; invert sign of remainder
;    eor #$ff
;    sta PROD
;    lda PROD+1
;    eor #$ff
;    sta PROD+1
;
;    inw PROD

nofix4
    rts
    .endp

.fi

; ----------------------------------------------------------------------------

.ifdef ENABLE_LOG8

; 2-based logarithm of A byte

; by Chromatix on 6502.org forum Dec 20 2020

; clobbers X    ; lower values of A are less accurate behind the point
                ; but only in the least significant bit

; A = LOG(A)    ; input is 8.0 fixed point, output is 3.5 fixed point

    .proc log8

    ldx #8
    sec
loop
    dex
    rol
    bcc loop

    stx TERM1
    lsr TERM1
    ror
    lsr TERM1
    ror
    lsr TERM1
    ror

    rts

    .endp
.fi

; ---------------------------------------------------------------------------

.ifdef ENABLE_ALOG8

; A = ALOG(A)   ; input is 3.5 fixed point, output is 8.0

; clobbers Y

; by GarthWilson on 6502.org 

    .proc alog8

    tay                ; (We'll need the input again later.)
    and #$1F           ; Look at only the fractional part; but
    ora #$20           ; it excludes the 1st '1', so add it.
    asl                ; Now scoot it to the left end to init.
    asl   
    sta SAVE1

    tya                ; Get the original input back again.
loop
    adc  #%00100000    ; (Note that C is already clear.)  Add
    bcs end            ; 1 to the exponent part until it carries.
    lsr SAVE1          ; As long as it doesn't carry, shift over
    jmp loop           ; and see if you can do it again.

end
    lda  SAVE1
    rts

    .endp

.fi

; ---------------------------------------------------------------------------

END_ORG_MATH_NON_ZP  = *

; ----------------------------------------------------------------------------

; WARNING: ALL zero page code is mirrored at beginning!!!

.ifndef ENABLE_ZERO_PAGE_CODE_FIRST

; This code needs to be on page zero

    org ORG_MATH_ZP

.ifdef ENABLE_UMUL8

FAC1 = umul8.FAC1
FAC2 = umul8.FAC2

; FAC1 and FAC2 are inlined!        FAC1 is clobbered, FAC2 is not!

; UMUL8         8*8=16 bits         FAC1 * FAC2 = MSB(A) LSB(X)

    .proc umul8
    lda #$00
    ldx #$08
    clc
mul_loop
    bcc skip_add
    clc
                    FAC2=*+1
    adc #0
skip_add
    ror
    ror FAC1
    dex
    bpl mul_loop
                    FAC1=*+1
    ldx #0
    rts

    .endp

.endif

END_ORG_MATH_ZP = *

.endif

