
RTCLOK  = $12

SDMCTL  = $022f

RANDOM  = $d20a

HPOSP0  = $d000
HPOSP1  = $d001

SIZEP0  = $d008
SIZEP1  = $d009

GRAFP0  = $d00d
GRAFP1  = $d00e

COLPM0  = $d012
COLPM1  = $d013

AUDF1   = $d200
AUDC1   = $d201

DMACTL  = $d400
WSYNC   = $d40a
VCOUNT  = $d40b

    org $50


_cnt = *+1          ; double as counter later
    ldy #$ff
    sty SIZEP0
    sty GRAFP0
    sty SIZEP1
    sty GRAFP1
    iny             ;  y=0
    sty SDMCTL


waitvb
    ldx VCOUNT
    bne waitvb
                    ; y=0  and  x=0


_starty = *+1
    ldy #$00
_startx = *+1
    ldx #$00

    stx AUDF1

loop
    sty COLPM0
    sty HPOSP0

    stx COLPM1
    stx HPOSP1

    stx WSYNC

    iny
    dex
    dec _cnt
    bne loop

    inc _starty
    inc _startx

_dist = *+1
    ldx #$cf
    stx AUDC1

    dec _dist

    bvc waitvb
