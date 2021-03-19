
RTCLOK  = $12

SDMCTL  = $022f

CHBAS   = $02f4

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
AUDF2   = $d202
AUDC2   = $d203
AUDF3   = $d204
AUDC3   = $d205
AUDF4   = $d206
AUDC4   = $d207

DMACTL  = $d400
CHBASE  = $d409
WSYNC   = $d40a
VCOUNT  = $d40b

    org $50

    lda #$af
    sta AUDC1

loop
    sty $d017       ; characters luminance
    iny
    sty AUDF1

    lda RANDOM
    ora #32         ; always keep ANTIC DL DMA going
    sta DMACTL
    sta CHBASE

_sync
    sta WSYNC
    lsr
    bne _sync

    beq loop
