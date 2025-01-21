format ELF64

section '.text' executable
public _start

extrn SetTargetFPS
extrn InitWindow
extrn CloseWindow
extrn WindowShouldClose
extrn BeginDrawing
extrn EndDrawing
extrn DrawRectangle
extrn DrawText
extrn ClearBackground
extrn IsKeyDown
extrn _exit

_start:
    mov rdi, 800
    mov rsi, 600
    mov rdx, title
    call InitWindow

    mov rdi, 60
    call SetTargetFPS

.titleScreen:
    call BeginDrawing

    mov rdi, 0x09423E32
    call ClearBackground

    mov rdi, title
    mov rsi, 315
    mov rdx, 25
    mov rcx, 24
    mov r8, 0xFFFFFFFF
    call DrawText

    mov rdi, subtitleText
    mov rsi, 315
    mov rcx, 20
    mov r8, 0xFFFFFFFF
    call DrawText
    call EndDrawing

    call WindowShouldClose
    cmp rax, 1
    je .over
    mov rdi, 257 ; Enter key
    call IsKeyDown
    cmp rax, 1
    je .game
    jmp .titleScreen

.checkUp:
    mov rdi, 265
    call IsKeyDown
    cmp rax, 1
    jne .checkDown

    mov rax, [paddleY]
    cmp rax, 0
    je .checkDown
    sub rax, 5
    mov [paddleY], rax
    xor rax, rax

.checkDown:
    mov rdi, 264
    call IsKeyDown
    cmp rax, 1
    jne .game

    mov rax, [paddleY]
    add rax, 5
    cmp rax, 450
    je .game
    mov [paddleY], rax
    xor rax, rax
    jmp .game

.game:
    call WindowShouldClose
    test rax, rax
    jnz .over
    call BeginDrawing

    mov rdi, 0x09423E32
    call ClearBackground

    mov rdi, 5
    mov rsi, [paddleY]
    mov rdx, 20
    mov rcx, 150
    mov r8, 0xFFFFFFFF
    call DrawRectangle

    mov rdi, [ballX]
    mov rsi, [ballY]
    mov rdx, 15
    mov rcx, 15
    mov r8, 0xFFFFFFFF
    call DrawRectangle
    jmp .checkX

.checkX:
    mov rax, [ballX]
    cmp rax, 785
    jge .invertXVel
    cmp rax, 0
    jle .lose
    jmp .checkY

.checkY:
    mov rax, [ballY]
    cmp rax, 585
    jge .invertYVel
    cmp rax, 0
    jle .invertYVel
    jmp .checkPaddle

.invertXVel:
    mov rax, [ballXVel]
    neg rax
    mov [ballXVel], rax
    jmp .checkY

.invertYVel:
    mov rax, [ballYVel]
    neg rax
    mov [ballYVel], rax
    jmp .checkPaddle

.checkPaddle:
    mov rax, [ballX]
    cmp rax, 5
    jl .move
    cmp rax, 25
    jg .move

    mov rax, [ballY]
    mov rbx, [paddleY]
    cmp rax, rbx
    jl .move
    add rbx, 150
    cmp rax, rbx
    jg .move

    mov rax, [ballXVel]
    neg rax
    mov [ballXVel], rax
    inc QWORD [bounces]
    jmp .addSpeed

.addSpeed:
    mov rax, [bounces]
    mov rbx, 5
    div rax
    cmp rdx, 0
    jne .move
    inc QWORD [ballXVel]
    inc QWORD [ballYVel]
    jmp .move

.move:
    mov rax, [ballX]
    add rax, [ballXVel]
    mov [ballX], rax

    mov rax, [ballY]
    add rax, [ballYVel]
    mov [ballY], rax
    jmp .doneMove

.doneMove:
    call EndDrawing
    jmp .checkUp

.lose:
    mov rdi, 0x09423E32
    call ClearBackground

    mov rdi, loseMsg
    mov rsi, 290
    mov rdx, 275
    mov rcx, 50
    mov r8, 0xFFFFFFFF
    call DrawText
    call EndDrawing

    jmp .sleep5sec

.sleep5sec:
    mov DWORD [tv_sec], 5
    mov DWORD [tv_nsec], 0
    mov rax, 35
    mov rdi, timeval
    mov rsi, timeval
    syscall

    jmp .over

.over:
    call CloseWindow
    mov rdi, 0
    call _exit

section '.data' writeable
    title: db "FASM Pong", 0
    subtitleText: db "Press enter to start!", 0
    loseMsg: db "You lost!", 0

    paddleY: dq 150

    ballX: dq 250
    ballY: dq 250
    ballXVel: dq 1
    ballYVel: dq 1

    bounces: dq 0

    timeval:
      tv_sec: dd 0
      tv_nsec: dd 0

section '.note.GNU-stack'
