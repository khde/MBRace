; mbrace.asm
    bits 16  ; real mode
    org 0x7c00  ; MBR in RAM


; https://www.fountainware.com/EXPL/bios_key_codes.htm
%define KEY_ESC 0x1
%define KEY_UP 0x48
%define KEY_DOWN 0x50
%define KEY_LEFT 0x4b
%define KEY_RIGHT 0x4d


section .bss
    sx resw 1
    sy resw 1


section .data
    x_offset db 20
    y_offset db 10
    vmem equ 0xb800


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
    dec word [sy]
_down:
    cmp ah, KEY_DOWN
    jne _left
    inc word [sy]
_left:
    cmp ah, KEY_LEFT
    jne _right
    dec word [sx]
_right:
    cmp ah, KEY_RIGHT
    jne _input_ret
    inc word [sx]
_input_ret:
    ret

logic:
    nop
    ret

draw:
    call clscr
    call draw_player
    
    ret

draw_player:
    mov di, [sx]
    mov si, [sy]
    mov dx, "#"
    call put_char
    
    mov di, [sx]
    mov si, [sy]
    mov dx, "#"
    call put_char
    
    mov di, [sx]
    mov si, [sy]
    mov dx, "#"
    call put_char
   
    mov di, [sx]
    mov si, [sy]
    mov dx, "#"
    call put_char
   
    
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
    mov ax, 24
    jmp _crow
    
_ccol:
    mov bx, 79
    dec ax
    jz _cout
_crow:
    mov di, bx
    mov si, ax
    mov dx, " "
    call put_char
    dec bx
    jnz _crow
    jz _ccol
    
_cout:
    
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
    
    mov ax, vmem  ; vga memory offset
    mov es, ax  ; move into segment register
    
    ; set player position
    mov word [sx], 40
    mov word [sy], 12
    
    jmp game_loop

game_loop:
    call input
    call logic
    call draw
    
    jmp game_loop
    
exit:
    ; Linux kernel acpi/apm poweroff routine
    ; blatantly copied
    mov ax, 0x1000
    mov ax, ss
    mov sp, 0xf000
    mov ax, 0x5307
    mov bx, 0x1
    mov cx, 0x3
    int 0x15
    
times 510-($-$$) db 0x4f  ; fill with zeros
db 0x55, 0xaa  ; boot signature
