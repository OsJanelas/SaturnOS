[org 0x7c00]

start:
    xor ax, ax
    mov ds, ax
    mov es, ax
    
    mov si, msg_welcome
    call print_string

shell_loop:
    mov si, prompt
    call print_string
    call read_command
    
    ; Comparar comando "gfx"
    mov si, buffer
    mov di, cmd_gfx
    call strcmp
    jc launch_gui

    jmp shell_loop

; --- Funções de Texto ---
print_string:
    lodsb
    or al, al
    jz .done
    mov ah, 0x0e
    int 0x10
    jmp print_string
.done: ret

read_command:
    mov di, buffer
.loop:
    mov ah, 0
    int 0x16
    cmp al, 13 ; Enter
    je .done
    mov ah, 0x0e
    int 0x10
    stosb
    jmp .loop
.done:
    mov al, 0
    stosb
    mov al, 10 ; Nova linha após o enter
    mov ah, 0x0e
    int 0x10
    ret

; --- CORREÇÃO DA STRCMP (Linhas 58-63) ---
strcmp:
.loop:
    mov al, [si]
    mov bl, [di]
    cmp al, bl
    jne .not_equal    ; Se forem diferentes, sai
    cmp al, 0         ; Se chegou no fim da string (e são iguais)
    je .return_equal
    inc si
    inc di
    jmp .loop
.not_equal:
    clc               ; Limpa Carry Flag (Falso)
    ret
.return_equal:
    stc               ; Define Carry Flag (Verdadeiro)
    ret

; --- MODO GRÁFICO (GUI) ---
launch_gui:
    mov ax, 0x0013    ; Modo VGA 320x200
    int 0x10
    push 0xA000
    pop es

draw_wallpaper:
    xor di, di
    xor dx, dx        ; Y = 0
.loop_y:
    xor cx, cx        ; X = 0
.loop_x:
    ; SEU ALGORITMO DE PAPEL DE PAREDE
    mov ax, cx
    mov bx, ax
    and bx, dx
    jnz .draw_black
    
    mov al, dl
    add al, [color_offset]
    mov [es:di], al
    jmp .next_pixel
.draw_black:
    mov byte [es:di], 0
.next_pixel:
    inc di
    inc cx
    cmp cx, 320
    jne .loop_x
    inc dx
    cmp dx, 200
    jne .loop_y

gui_input:
    mov ah, 0
    int 0x16
    cmp al, 'm'
    je show_menu
    cmp al, 'b'
    je launch_gui
    cmp al, 'c'
    je start          ; Volta pro Shell
    jmp gui_input

show_menu:
    ; Simulação de Menu: Desenha uma linha branca no topo
    mov di, 0
    mov al, 15        ; Branco
    mov cx, 320
    rep stosb
    jmp gui_input

; --- Dados ---
msg_welcome  db '# v0.5 - #', 13, 10, 0
prompt       db '> ', 0
cmd_gfx      db 'gfx', 0
color_offset db 10
buffer       times 64 db 0

times 510-($-$$) db 0
dw 0xAA55