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
extrn snprintf
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
    mov rcx, 32
    mov r8, 0xFFFFFFFF
    call DrawText

    mov rdi, subtitle
    mov rsi, 250
    mov rdx, 125
    mov rcx, 32
    mov r8, 0xFFFFFFFF
    call DrawText
    call EndDrawing

    call WindowShouldClose
    cmp rax, 1
    je .over
    mov rdi, 257 ; Enter key
    call IsKeyDown
    cmp rax, 1
    je .gameLoop
    jmp .titleScreen

.gameLoop:
    call WindowShouldClose
    test rax, rax
    jnz .over

    ; Handle paddle movement
    mov rdi, 265 ; Up key
    call IsKeyDown
    cmp rax, 1
    jne .checkDown

    mov rax, [paddleY]
    cmp rax, 0
    je .checkDown
    sub rax, 5
    mov [paddleY], rax
    jmp .render

.checkDown:
    mov rdi, 264 ; Down key
    call IsKeyDown
    cmp rax, 1
    jne .render

    mov rax, [paddleY]
    add rax, 5
    cmp rax, 450
    jge .render
    mov [paddleY], rax

.render:
    call BeginDrawing

    mov rdi, 0x09423E32
    call ClearBackground

    ; Draw paddle
    mov rdi, 5
    mov rsi, [paddleY]
    mov rdx, 20
    mov rcx, 150
    mov r8, 0xFFFFFFFF
    call DrawRectangle

    ; Draw ball
    mov rdi, [ballX]
    mov rsi, [ballY]
    mov rdx, 15
    mov rcx, 15
    mov r8, 0xFFFFFFFF
    call DrawRectangle

    ; Draw score
    mov rdi, scoreStr
    mov rsi, 700
    mov rdx, 25
    mov rcx, 25
    mov r8, 0xFFFFFFFF
    call DrawText

    ; Ball collision logic
    mov rax, [ballX]
    cmp rax, 785
    jge .invertXVel
    cmp rax, 0
    jle .lose
    jmp .checkYCollision

.invertXVel:
    mov rax, [ballXVel]
    neg rax
    mov [ballXVel], rax

.checkYCollision:
    mov rax, [ballY]
    cmp rax, 585
    jge .invertYVel
    cmp rax, 0
    jle .invertYVel
    jmp .checkPaddle

.invertYVel:
    mov rax, [ballYVel]
    neg rax
    mov [ballYVel], rax
    jmp .checkPaddle

.checkPaddle:
    mov rax, [ballX]
    cmp rax, 5
    jl .updateBallPosition
    cmp rax, 25
    jg .updateBallPosition

    mov rax, [ballY]
    mov rbx, [paddleY]
    cmp rax, rbx
    jl .updateBallPosition
    add rbx, 150
    cmp rax, rbx
    jg .updateBallPosition

    ; Ball hit paddle - determine which half
    mov rax, [ballY]
    mov rbx, [paddleY]
    add rbx, 75     ; Calculate middle of paddle (paddleY + 75)

    ; If ballY < middle of paddle, ball hit top half
    cmp rax, rbx
    jl .topHalfHit

    ; Ball hit bottom half
    mov QWORD [ballYVel], 3  ; Force downward velocity
    jmp .paddleHitCommon

.topHalfHit:
    mov QWORD [ballYVel], -3 ; Force upward velocity

.paddleHitCommon:
    ; Increment score and reverse X velocity
    inc QWORD [score]
    mov rax, [score]
    mov rdi, scoreStr
    call dec2str

    ; Reverse X direction
    mov rax, [ballXVel]
    neg rax
    mov [ballXVel], rax

    ; Handle speed increase
    inc QWORD [bounces]
    mov rax, [bounces]
    mov rbx, [bouncesToSpeedUp]
    mov rdx, 0
    div rbx
    test rdx, rdx
    jnz .updateBallPosition

    ; Increase speed after certain number of bounces
    mov rax, [ballXVel]
    cmp rax, 0       ; Check if velocity is positive or negative
    jl .negativeXVel
    inc QWORD [ballXVel]
    jmp .checkYVelSign

.negativeXVel:
    dec QWORD [ballXVel]

.checkYVelSign:
    mov rax, [ballYVel]
    cmp rax, 0
    jl .negativeYVel
    inc QWORD [ballYVel]
    jmp .updateBallPosition

.negativeYVel:
    dec QWORD [ballYVel]

.updateBallPosition:
    mov rax, [ballX]
    add rax, [ballXVel]
    mov [ballX], rax

    mov rax, [ballY]
    add rax, [ballYVel]
    mov [ballY], rax

    call EndDrawing
    jmp .gameLoop

.lose:
    ; Convert score to string for display on lose screen
    mov rax, [score]
    mov rdi, finalScoreStr
    call dec2str

.loseLoop:
    call BeginDrawing

    ; Clear the screen completely
    mov rdi, 0x09423E32
    call ClearBackground

    ; Display "You lose!" message
    mov rdi, loseMsg
    mov rsi, 290
    mov rdx, 235
    mov rcx, 50
    mov r8, 0xFFFFFFFF
    call DrawText

    ; Display final score
    mov rdi, scorePrefix
    mov rsi, 300
    mov rdx, 285
    mov rcx, 30
    mov r8, 0xFFFFFFFF
    call DrawText

    mov rdi, finalScoreStr
    mov rsi, 410
    mov rdx, 285
    mov rcx, 30
    mov r8, 0xFFFFFFFF
    call DrawText

    ; Display replay instructions
    mov rdi, replay
    mov rsi, 125
    mov rdx, 335
    mov rcx, 25
    mov r8, 0xFFFFFFFF
    call DrawText

    call EndDrawing

    ; Check for escape key (quit)
    mov rdi, 256 ; Escape
    call IsKeyDown
    cmp rax, 1
    je .over

    ; Check for enter key (restart)
    mov rdi, 257 ; Enter
    call IsKeyDown
    cmp rax, 1
    jne .loseLoop

    ; Reset game state
    mov QWORD [ballX], 250
    mov QWORD [ballY], 250
    mov QWORD [ballXVel], 3
    mov QWORD [ballYVel], 3
    mov QWORD [paddleY], 150
    mov QWORD [bounces], 0
    mov QWORD [score], 0

    ; Reset score display
    mov rax, 0
    mov rdi, scoreStr
    call dec2str

    jmp .gameLoop

.over:
    call CloseWindow
    mov rdi, 0
    call _exit

dec2str:
    push rbx
    push rcx
    push rdx

    mov rbx, 10
    mov rcx, 5

.clear_buffer:
    mov BYTE [rdi + rcx - 1], '0'
    dec rcx
    jnz .clear_buffer

    mov rcx, 5
    mov rbx, 10

.convert_loop:
    dec rcx
    xor rdx, rdx
    div rbx
    add dl, '0'
    mov [rdi + rcx], dl
    test rax, rax
    jnz .convert_loop

    pop rdx
    pop rcx
    pop rbx
    ret

section '.data' writeable
    title: db "FASM Pong", 0
    subtitle: db "Press enter to start!", 0
    loseMsg: db "You lose!", 0
    scorePrefix: db "Score: ", 0
    replay: db "Press enter to play again or escape to quit", 0

    scoreStr: db "00000", 0
    finalScoreStr: db "00000", 0

    paddleY: dq 150

    ballX: dq 250
    ballY: dq 250
    ballXVel: dq 3
    ballYVel: dq 3

    bounces: dq 0
    bouncesToSpeedUp: dq 3
    score: dq 0

section '.note.GNU-stack'
