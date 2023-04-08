; mbrace.asm
    bits 16  ; real mode
    org 0x7c00  ; MBR in RAM


; https://www.fountainware.com/EXPL/bios_key_codes.htm
%define KEY_ESC 0x1
%define KEY_UP 0x48
%define KEY_DOWN 0x50
%define KEY_LEFT 0x4b
%define KEY_RIGHT 0x4d


section .text
    jmp start


input:
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
    jne _left
    cmp [ps], word 0x3
    je _left
    add word [py], 6
    inc word [ps]
_left:
    cmp ah, KEY_LEFT
    jne _right
    dec word [px]
_right:
    cmp ah, KEY_RIGHT
    jne _input_ret
    inc word [px]
_input_ret:
    ret


logic:
    nop
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
    
    ;xor  di, di
    ;mov  cx, 80 * 25
    ;mov  ax, 0x720      ; WhiteOnBlack space character
    ;cld
    ;rep stosw
    ret


start:
    ; set video mode
    mov ah, 0x0
    mov al, 0x2  ; 80x25? Text mode
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
    
    ; player
    mov word [ps], 0x1
    mov word [px], 0x6
    mov word [py], 0x3
    
    ; enemy
    mov word [e1x], 60 
    mov word [e1y], 10
    
    mov word [e2x], 40
    mov word [e2y], 18
    
game_loop:
    call input
    call logic
    call draw
    
    jmp game_loop
    
exit:
    ; Linux kernel acpi/apm poweroff code
    ; blatantly copied
    mov ax, 0x1000
    mov ax, ss
    mov sp, 0xf000
    mov ax, 0x5307
    mov bx, 0x1
    mov cx, 0x3
    int 0x15


;;;;;;;;;;;;;;;;;;
    ; player position
    ps dw 0x0
    px dw 0x0
    py dw 0x0
    
    ; enemy
    e1x dw 0x0
    e1y dw 0x0
    
    e2x dw 0x0
    e2y dw 0x0
    
    ; box
    boxx dw 5
    boxy dw 3
    boxw dw 60
    boxh dw 15
    
    ; car 12x5
car:
    db 0x20, 0x20, 0x20, 0x20, 0x5f, 0x5f, 0x5f, 0x5f, 0x20, 0x20, 0x20, 0x20
    db 0x20, 0x20, 0x20, 0x2f, 0x20, 0x20, 0x20, 0x20, 0x5c, 0x20, 0x20, 0x20
    db 0x5f, 0x5f, 0x2f, 0x5f, 0x5f, 0x5f, 0x5f, 0x5f, 0x5f, 0x5c, 0x5f, 0x5f
    db 0x7c, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x7c
    db 0x3d, 0x28, 0x4f, 0x29, 0x20, 0x2d, 0x2d, 0x20, 0x28, 0x4f, 0x29, 0x3d


times 510-($-$$) db 0x4f  ; fill with zeros
db 0x55, 0xaa  ; boot signature
