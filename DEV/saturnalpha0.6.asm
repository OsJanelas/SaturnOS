[bits 16]
[org 0x7c00]

start:
    xor ax, ax
    mov ds, ax
    mov es, ax

shell:
    mov si, msg_boot
    call print_string
.wait_boot:
    mov di, buffer
    call read_line
    mov si, buffer
    mov di, cmd_ok
    call compare_strings
    jne .wait_boot

load_gui:
    mov ax, 0x0013      ; VGA 320x200
    int 0x10
    
render_fractal:         ; Substituiu o draw_aurora original
    mov ax, 0xA000
    mov es, ax
    xor di, di          ; Offset do pixel (0 a 63999)

.loop_fractal:
    ; Calcular X e Y a partir de DI
    mov ax, di
    xor dx, dx
    mov cx, 320
    div cx              ; AX = Y (linha), DX = X (coluna)

    ; --- Lógica que você solicitou ---
    mov bx, ax          ; BX = Y
    and bx, dx          ; Operação bitwise entre X e Y
    
    jnz .draw_black     ; Se o resultado não for zero, pinta de preto

    mov al, dl          ; Usa a coordenada X como cor base
    add al, byte [color_offset] ; Adiciona o offset para criar animação/variação
    mov [es:di], al
    jmp .next_pixel

.draw_black:
    mov byte [es:di], 0

.next_pixel:
    inc di
    cmp di, 64000       ; Fim da tela (320*200)
    jne .loop_fractal

    inc byte [color_offset] ; Muda a cor para a próxima "frame" ou interação

    ; Desenha os elementos da UI por cima do fractal
    call draw_taskbar
    call draw_folder

gui_loop:
    mov ah, 0
    int 0x16            
    cmp al, 'm'         ; Menu Iniciar
    je .show_menu
    cmp al, 'n'         ; Bloco de Notas
    je .show_notes
    cmp al, 'c'         ; CMD
    je .show_cmd
    cmp al, 'b'         ; Back / Refresh Fractal
    je render_fractal
    jmp gui_loop

.show_menu:
    call draw_start_menu
    jmp gui_loop
.show_notes:
    call draw_notepad
    jmp gui_loop
.show_cmd:
    call draw_cmd_window
    jmp gui_loop

; --- ELEMENTOS DA INTERFACE ---
draw_taskbar:
    mov di, 320*182
    mov al, 44          ; Cor da barra
    mov cx, 320*18
    push es
    mov ax, 0xA000
    mov es, ax
    rep stosb
    pop es
    
    mov dx, 0x1701      ; Cursor na barra
    mov ah, 2
    xor bh, bh
    int 0x10
    mov si, btn_start
    call print_string
    ret

draw_folder:
    mov bx, 25
.l: mov ax, 320
    mul bx
    add ax, 25
    mov di, ax
    mov al, 7
    mov cx, 15
    mov dx, 0xA000
    mov es, dx
    rep stosb
    inc bx
    cmp bx, 38
    jne .l
    mov dx, 0x0503
    mov ah, 2
    int 0x10
    mov si, txt_system
    call print_string
    ret

; [As outras funções de desenho draw_start_menu, draw_notepad, etc. seguem a mesma lógica]
; [Apenas certifique-se de definir ES como 0xA000 antes de usar STOSB na memória de vídeo]

draw_start_menu:
    mov bx, 100
.l: mov ax, 320
    mul bx
    mov di, ax
    mov al, 7
    mov cx, 80
    mov dx, 0xA000
    mov es, dx
    rep stosb
    inc bx
    cmp bx, 182
    jne .l
    mov dx, 0x0D01
    mov ah, 2
    int 0x10
    mov si, menu_items
    call print_string
    ret

draw_notepad:
    mov bx, 40
.l: mov ax, 320
    mul bx
    add ax, 60
    mov di, ax
    mov al, 15
    mov cx, 200
    mov dx, 0xA000
    mov es, dx
    rep stosb
    inc bx
    cmp bx, 140
    jne .l
    mov dx, 0x0608
    mov ah, 2
    int 0x10
    mov si, txt_note
    call print_string
    ret

draw_cmd_window:
    mov bx, 50
.l: mov ax, 320
    mul bx
    add ax, 100
    mov di, ax
    mov al, 0
    mov cx, 120
    mov dx, 0xA000
    mov es, dx
    rep stosb
    inc bx
    cmp bx, 110
    jne .l
    mov dx, 0x070D
    mov ah, 2
    int 0x10
    mov si, txt_cmd
    call print_string
    ret

; --- FUNÇÕES DE SISTEMA ---
compare_strings:
.l: mov al, [si]
    mov bl, [di]
    cmp al, bl
    jne .not_eq
    or al, al
    jz .eq
    inc si
    inc di
    jmp .l
.not_eq: ret
.eq: add sp, 2
    jmp load_gui

print_string:
    mov ah, 0x0e
.l: lodsb
    or al, al
    jz .d
    int 0x10
    jmp .l
.d: ret

read_line:
    xor cx, cx
.l: mov ah, 0
    int 0x16
    cmp al, 0x0D
    je .d
    mov ah, 0x0e
    int 0x10
    stosb
    jmp .l
.d: mov al, 0
    stosb
    ret

; --- DADOS ---
color_offset db 0       ; Variável para o efeito do fractal
msg_boot     db 'So... the gui is going to change', 13, 10, 'Type gfx for open GUI: ', 0
cmd_ok       db 'gfx', 0
btn_start    db 'start', 0
menu_items   db ' User', 0
txt_system   db 'System', 0
txt_note     db 'Notepad', 0
txt_cmd      db 'Sat', 0
buffer       times 16 db 0

times 510-($-$$) db 0
dw 0xaa55