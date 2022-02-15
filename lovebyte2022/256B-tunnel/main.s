
; GR. 10 TUNNEL by ivop Lovebyte 2022 entry

; 2022-01-13 final version? :)

COLOR   = $2fb

ypos    = $54
xpos    = $55       ; and $56
yprev   = $5a
xprev   = $5b       ; and $5c

; OS functions, 800XL OS Rev.2
set_graphics_mode   = $ef9c
drawto              = $f9c2

counter   = $fe
fourtimes = $ff

; ----------------------------------------------

	org $2000
	
main
	lda #10
	jsr set_graphics_mode

    ; now A=00 X=0A Y=01

;    lda #0
    sta 559             ; disable screen DMA

    sta $d208           ; AUDCTL, reset SIO settings

MAKEITSO = 16       ; 16 pixels is square and fastest. perhaps 12 or 14?

;;;;;;;

outerloop

loop
    lda #3
    sta fourtimes

;;;

innerloop
_color = *+1
    lda #0          ; first drawto is zero (black), resets to one
    sta COLOR

;-    sta $d201       ; pre-calc sea shore sound!

xstartpos = *+1
    lda #0+MAKEITSO
    sta xpos
ystartpos = *+1
    lda #0
    sta ypos

    jsr drawto

xend = *+1
    lda #79-MAKEITSO
    sta xpos
    jsr drawto

yend = *+1
    lda #191
    sta ypos
    jsr drawto

    lda xstartpos
    sta xpos
    jsr drawto

    lda ystartpos
    sta ypos
    jsr drawto

    dec yend
    inc ystartpos

    dec fourtimes
    bpl innerloop

;;;

    inc xstartpos
    dec xend

    inc _color
    lda _color
    cmp #9
    bne loop

;; A=09 X=01 Y=01
;    lda #1
    stx _color

    dec outertimes
    bne outerloop

;;;;;;;;;

;    lda #$5a
;    sta $d204

    lda #$a7        ; melody volume
    sta $d201

;    ldy #7  ; can be eliminated in favour of 2 bytes, but different groove
;            ; perhaps dey or iny for another groove

    dey     ; better groove than iny, and now it's 256 bytes w/o intro hiss 

reset_colors

    ldx #7
set_colors
source_colors = *+1
    lda monotunnel,x
    sta $02c1,x
    dex
    bpl set_colors

    lda #32+2
    sta 559             ; enable screen DMA again, and again, and ....

;;;

mainloop

    lda melodynotes,y
_enable_melody = *+1
    sta $d20c           ; $d20c is unused by pokey, becomes $d200 later

;;
    ldx #7
waitvb
    lsr $14
    bcc waitvb
    dex
    bpl waitvb

    lda notes,y
    sta $d206
    lda dist,y
    sta $d207
    dey
    bpl cont
    ldy #7
cont
;;

rotate_colors
    ldx #7
rotloop
    lda $02c1,x
    sta $02c2,x
    dex
    bpl rotloop
    lda $02c9           ; don't use Y to save the color, same amount of bytes
    sta $02c1

    sta $d203           ; hiss and bleep, syncs with drum and bass line!

;    dec counter        ; slow change of colors
;    dec counter

    lda counter            ; quicker change of colors, but more code
;    sec                    ; carry is still set after waitvb
    sbc #4
    sta counter

    bne mainloop

;;;

    lda source_colors
;    sec                ; carry is still set after waitvb
    sbc #8

    cmp #<cols-8
    bne noloop

    ; X=FF
    inx
    stx _enable_melody      ; enable $d200

    lda #<monotunnel        ; reset tunnel loop
noloop
    sta source_colors

    bvc reset_colors

;;;;;;;;;;;;;;;

outertimes
    dta 3

melodynotes
;    dta $5a                ; shuffle some more for an interesting melody
    dta $47,$3b ,$32
    dta $2c, $23,$1d ,$18
    dta $5a

; notes and dist are played in reverse!

notes
    dta $00, $71, $00, $17
    dta $47, $8f, $47, $8f
dist
    dta $c0, $cf, $c0, $8f
    dta $cf, $cf, $cf, $cf

; palettes are selected in reverse, too.

cols
colorfultunnel
    dta $2e, $4c, $6a, $88
    dta $a6, $c4, $e3, $f2

tunnel
    dta $0e, $0c, $0a, $08
    dta $06, $04, $03, $02

monowithred
    dta 8, 8, 8, 8
    dta 0, $34, $34, 0

monotunnel
    dta 8, 8, 8, 8
;    dta 0, 0, 0, 0 ; assume zeroes

