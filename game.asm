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
extrn DrawCircle
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
    jne .again

    mov rax, [paddleY]
    add rax, 5
    cmp rax, 450
    je .again
    mov [paddleY], rax
    xor rax, rax
    jmp .again

.again:
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

; Currently we crash with exit code 1 if the player loses. TODO: Implement lose screen
.lose:
    call CloseWindow
    mov rdi, 1
    call _exit

.over:
    call CloseWindow
    mov rdi, 0
    call _exit

section '.data' writeable
    title: db "FASM Pong", 0

    paddleY: dq 50

    ballX: dq 250
    ballY: dq 250
    ballXVel: dq 2
    ballYVel: dq 2

section '.note.GNU-stack'
