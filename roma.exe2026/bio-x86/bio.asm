    org 0x0100

%ifdef dosbox
    les di,[bx]
%endif

%ifdef freedos
    push 0xa000
    pop es
%endif

bio_restart:
    mov ax,13h      ; vga 320x200
    int 10h

%ifdef dosbox
    mov dx,0x330
    mov si,midi
    rep outsb
    inc byte [note]
%endif

    mov dx,0x3c9    ; palette register, write 0 index to 0x3c8 not needed
    mov cx,255
pal:
    mov al,cl
    xor al,255      ; use inverted counter as value
    out dx,al       ; R = al
    shr al,1
    out dx,al       ; G = al >> 1
    shl al,2
    out dx,al       ; B = al << 1
    loop pal

bio_smc:
    mov bp,256*18           ; x initial value
    xor bx,bx               ; y initial value = 0

;    xor cx,cx               ; loop counter
    mov si,8                ; meta loop counter, si*65536

bio_loop:
    call step               ; x += (y^0x10)>>2

    mov ax,bp
    and ax,0x7fff
    sub bx,ax               ; y -= x&0x7fff

    call step               ; x += (y^0x10)>>2

    add bp,0x4000           ; x += 0x4000
    sub bx,0x0800           ; y -= 0x0800

    cmp bh,200
    jae short bio_loop      ; outside screen margin

    mov al,bh               ; al = y>>8
    xor ah,ah
    mov dx,320
    mul dx                  ; ax = 320*(y>>8)

    mov di,bp               ; di = x
    shr di,8                ; di = x>>8
    add di,ax               ; di = (x>>8)+320*(y>>8)
%ifdef dosbox
    add di,48               ; di += 48
%endif
%ifdef freedos
    add di,32               ; di += 32
%endif
    inc byte [es:di]        ; accumulate pixel

    loop bio_loop           ; dec cx, loop counter

    dec si
    jnz bio_loop            ; meta loop counter

sleep:
%ifdef dosbox
    mov cl,0x0010           ; cx:dx = time in ms, only set cx
%endif
%ifdef freedos
    mov cl,0x0040
%endif
    mov ah,86h
    int 15h

    inc byte [bio_smc+2]    ; increment initial x value
    jmp short bio_restart   ; and restart

step:
    mov ax,bx
    xor al,0x10
    shr ax,2
    add bp,ax       ; x += (y^0x10)>>2
    ret

%ifdef dosbox
midi:
;    db 0xc0, 13     ; instrument, ch. #0
;    db 0xc0, 96     ; instrument, ch. #0
    db 0xc0, 47     ; instrument, ch. #0
    db 0x90         ; noteon ch. #0
note:
    db 28
velocity:
    db 127
%endif
