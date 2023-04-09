; mbrace.asm

    bits 16  ; real mode
    org 0x7c00  ; MBR in RAM

%define KEY_ESC 0x1
%define KEY_UP 0x48
%define KEY_DOWN 0x50


section .text
    jmp start

input:
    ; check if key is pressed
    mov ah, 0x1
    int 0x16
    jz _input_ret
    
    ; read key press
    mov ah, 0x0
    int 0x16
    
    ; check which key was pressed
    cmp ah, KEY_ESC
    jne _up
    jmp exit
_up:
    cmp ah, KEY_UP
    jne _down
    cmp [ps], word  0x1
    je _down
    sub word [py], 6
    dec word [ps]
_down:
    cmp ah, KEY_DOWN
    jne _input_ret
    cmp [ps], word 0x3
    je _input_ret

    add word [py], 6
    inc word [ps]
_input_ret:
    ret


logic:
    ; new position for enemy 1
    dec word [e1x]
    cmp word [e1x], 0
    jnz _srs1
    mov word [e1x], eoffset
    
    add [e1y], word 0x5
    cmp [e1y], word 20
    jnge _srs1
    mov [e1y], word 0x3
_srs1:

    ; new position for enemy 2
    dec word [e2x]
    cmp word [e2x], 0x0
    jnz _srs2
    mov word [e2x], eoffset
    
    sub [e2y], word 0x5
    cmp [e2y], word 0x0
    jnle _srs2
    mov [e2y], word 19
_srs2:
    
    ; check collision
    mov ax, [e1x]
    mov bx, [e1y]
    mov cx, 0x2
_collp:
    mov di, [px]  ; right
    add di, 0xc
    cmp di, ax
    js _nocol
    mov di, [py]  ; top
    add di, 0x5
    cmp di, bx
    js _nocol
    mov di, [py]  ; bottom
    cmp bx, di
    js _nocol
    jmp start
_nocol:
    mov ax, [e2x]
    mov bx, [e2y]
    
    dec cx
    jnz _collp
    
    ret


draw:
    call clscr
    
    mov di, [px]
    mov si, [py]
    call draw_car
    
    mov di, [e1x]
    mov si, [e1y]
    call draw_car
    
    mov di, [e2x]
    mov si, [e2y]
    call draw_car
    
    ret


;  di: x
;  si: y
draw_car:
    push di
    push si
    
    xor ax, ax  ; rows
    mov bx, car  ; char
    xor cx, cx  ; columns
    
    jmp _carr
    
_carc:
    xor ax, ax
    sub di, 0xc
_carr:
    ; char
    mov dx, [bx]  ; only works with bx
    call put_char
    
    inc ax
    inc bx
    inc di
    cmp ax, 0xc
    jne _carr
    
    inc cx
    inc si
    cmp cx, 5
    jne _carc
    
    pop si
    pop di
    ret

   
;  di: x
;  si: y
;  dx: char
put_char:
    push di
    push si
    push ax
    
    imul si, 160
    sal di, 1
    add di, si
    
    mov ah, byte 0x7  ; attributes
    mov al, dl  ; char
    
    mov word [es:di], ax
    
    pop ax
    pop si
    pop di
    ret


clscr:
    xor di, di
    mov ax, 80 * 25 * 2
_clloop:
    mov word [es:di], 0x720
    inc di
    inc di
    cmp di, ax
    jne _clloop

    ret


start:
    ; set video mode
    mov ah, 0x0
    mov al, 0x2  ; 80x25 text mode
    int 0x10
    
    ; set color of bg
    mov ah, 0xb
    mov bh, 0x0
    mov bl, 0x9
    int 0x10
    
    ; hide cursor
    mov ah, 0x1
    mov cx, 0x2607 ; 5th bit of ch
    int 0x10
    
    mov ax, 0xb800  ; vga memory offset
    mov es, ax  ; move into segment register
    
    ; player position
    mov word [ps], 0x1
    mov word [px], 0x6
    mov word [py], 0x3
    
    ; enemy position
    mov word [e1x], 60 
    mov word [e1y], 6
    
    mov word [e2x], 25
    mov word [e2y], 15


game_loop:
    call input
    call logic
    call draw
    
    ; wait
    xor ax, ax
    mov ah, 0x86  ; number for waiting
    mov cx, 0  ; time to wait
    int 0x15
    
    jmp game_loop


exit:
    ; Linux kernel acpi or apm poweroff code
    ; blatantly copied
    mov ax, 0x1000
    mov ax, ss
    mov sp, 0xf000
    mov ax, 0x5307
    mov bx, 0x1
    mov cx, 0x3
    int 0x15


    ; player position
    ps dw 0x0
    px dw 0x0
    py dw 0x0
    
    ; enemy 1
    e1x dw 0x0
    e1y dw 0x0
    
    ; enemy2
    e2x dw 0x0
    e2y dw 0x0
    
    ; x-respawn point for enemies
    eoffset equ 65
    
    ; box
    boxx db 5
    boxy db 3
    boxw db 60
    boxh db 15
    
    ; car 12x5
car:
    db 0x20, 0x20, 0x20, 0x20, 0x5f, 0x5f, 0x5f, 0x5f, 0x20, 0x20, 0x20, 0x20
    db 0x20, 0x20, 0x20, 0x2f, 0x20, 0x20, 0x20, 0x20, 0x5c, 0x20, 0x20, 0x20
    db 0x5f, 0x5f, 0x2f, 0x5f, 0x5f, 0x5f, 0x5f, 0x5f, 0x5f, 0x5c, 0x5f, 0x5f
    db 0x7c, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x7c
    db 0x3d, 0x28, 0x4f, 0x29, 0x20, 0x2d, 0x2d, 0x20, 0x28, 0x4f, 0x29, 0x3d


times 510-($-$$) db 0x4f  ; fill with zeros
db 0x55, 0xaa  ; boot signature
