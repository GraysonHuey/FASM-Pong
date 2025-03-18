format ELF64

section '.text' executable
public _start

; External functions from raylib library
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

_start:
    ; Initialize window with size 800x600 and title
    mov rdi, 800
    mov rsi, 600
    mov rdx, title
    call InitWindow

    ; Set game to run at 60 frames per second
    mov rdi, 60
    call SetTargetFPS

.titleScreen:
    ; Title screen rendering loop
    call BeginDrawing

    ; Set background color (dark purple)
    mov rdi, 0xFF630047
    call ClearBackground

    ; Draw game title
    mov rdi, title
    mov rsi, 315        ; x position
    mov rdx, 25         ; y position
    mov rcx, 32         ; font size
    mov r8, 0xFF6DD9677 ; blue color
    call DrawText

    ; Draw instructions
    mov rdi, subtitle
    mov rsi, 250
    mov rdx, 125
    mov rcx, 32
    mov r8, 0xFF6DD9677
    call DrawText
    call EndDrawing

    ; Check if window should close (X button)
    call WindowShouldClose
    cmp rax, 1
    je .over

    ; Check if Enter key is pressed to start game
    mov rdi, 257 ; Enter key
    call IsKeyDown
    cmp rax, 1
    je .gameLoop
    jmp .titleScreen

.gameLoop:
    ; Main game loop
    call WindowShouldClose
    test rax, rax
    jnz .over

    ; --- Handle paddle movement ---
    ; Check for Up key press
    mov rdi, 265 ; Up key
    call IsKeyDown
    cmp rax, 1
    jne .checkDown

    ; Move paddle up (if not at top edge)
    mov rax, [paddleY]
    cmp rax, 0
    je .checkDown
    sub rax, 5     ; Move paddle up by 5 pixels
    mov [paddleY], rax
    jmp .render

.checkDown:
    ; Check for Down key press
    mov rdi, 264 ; Down key
    call IsKeyDown
    cmp rax, 1
    jne .render

    ; Move paddle down (if not at bottom edge)
    mov rax, [paddleY]
    add rax, 5     ; Move paddle down by 5 pixels
    cmp rax, 450   ; Check bottom boundary (600 - paddle height)
    jge .render
    mov [paddleY], rax

.render:
    ; --- Render game elements ---
    call BeginDrawing

    ; Clear screen with background color
    mov rdi, 0xFF630047
    call ClearBackground

    ; Draw paddle (20x150 rectangle)
    mov rdi, 5           ; x position
    mov rsi, [paddleY]   ; y position
    mov rdx, 20          ; width
    mov rcx, 150         ; height
    mov r8, 0xFFB070B3   ; violet color
    call DrawRectangle

    ; Draw ball (15x15 square)
    mov rdi, [ballX]
    mov rsi, [ballY]
    mov rdx, 15
    mov rcx, 15
    mov r8, 0xFFB070B3 ; Keep in mind that Raylib colors are little endian (so use ABGR instead of RGBA)
    call DrawRectangle

    ; Draw score label
    mov rdi, scoreLabel
    mov rsi, 615
    mov rdx, 25
    mov rcx, 25
    mov r8, 0xFF6DD9677
    call DrawText

    ; Draw score counter
    mov rdi, scoreStr
    mov rsi, 700
    mov rdx, 25
    mov rcx, 25
    mov r8, 0xFF6DD9677
    call DrawText

    ; Draw difficulty label
    mov rdi, speedLabel
    mov rsi, 577
    mov rdx, 50
    mov rcx, 25
    mov r8, 0xFF6DD9677
    call DrawText

    ; Draw difficulty counter
    mov rax, [speed]
    mov rdi, speedStr
    call dec2str
    mov rdi, speedStr
    mov rsi, 700
    mov rdx, 50
    mov rcx, 25
    mov r8, 0xFF6DD9677
    call DrawText

    ; --- Ball collision logic ---
    ; Check right wall collision
    mov rax, [ballX]
    cmp rax, 785    ; Right boundary (800 - ball width)
    jge .invertXVel
    cmp rax, 0      ; Left boundary (game over condition)
    jle .lose
    jmp .checkYCollision

.invertXVel:
    ; Reverse ball x direction
    mov rax, [ballXVel]
    neg rax
    mov [ballXVel], rax

.checkYCollision:
    ; Check top/bottom wall collision
    mov rax, [ballY]
    cmp rax, 585    ; Bottom boundary (600 - ball height)
    jge .invertYVel
    cmp rax, 0      ; Top boundary
    jle .invertYVel
    jmp .checkPaddle

.invertYVel:
    ; Reverse ball y direction
    mov rax, [ballYVel]
    neg rax
    mov [ballYVel], rax
    jmp .checkPaddle

.checkPaddle:
    ; Check if ball is in paddle's x-range
    mov rax, [ballX]
    cmp rax, 5
    jl .updateBallPosition
    cmp rax, 25
    jg .updateBallPosition

    ; Check if ball is in paddle's y-range
    mov rax, [ballY]
    mov rbx, [paddleY]
    cmp rax, rbx
    jl .updateBallPosition
    add rbx, 150      ; Add paddle height
    cmp rax, rbx
    jg .updateBallPosition

    ; --- Ball hit paddle - angle determination ---
    mov rax, [ballY]
    mov rbx, [paddleY]
    add rbx, 75     ; Calculate middle of paddle (paddleY + 75)

    ; If ballY < middle of paddle, ball hit top half
    cmp rax, rbx
    jl .topHalfHit

    ; Ball hit bottom half - force downward velocity
    mov QWORD [ballYVel], 3
    jmp .paddleHitCommon

.topHalfHit:
    ; Force upward velocity
    mov QWORD [ballYVel], -3

.paddleHitCommon:
    ; Increment score and update display
    inc QWORD [score]
    mov rax, [score]
    mov rdi, scoreStr
    call dec2str

    ; Reverse X direction after paddle hit
    mov rax, [ballXVel]
    neg rax
    mov [ballXVel], rax

    ; --- Speed increase mechanism ---
    inc QWORD [bounces]
    mov rax, [bounces]
    mov rbx, [bouncesToSpeedUp] ; Increase speed every N bounces
    mov rdx, 0
    div rbx
    test rdx, rdx               ; Check if division remainder is zero
    jnz .updateBallPosition

    inc QWORD [speed]

    ; Increase X velocity based on direction
    mov rax, [ballXVel]
    cmp rax, 0
    jl .negativeXVel
    inc QWORD [ballXVel]  ; Increase positive velocity
    jmp .checkYVelSign

.negativeXVel:
    dec QWORD [ballXVel]  ; Increase negative velocity

.checkYVelSign:
    ; Increase Y velocity based on direction
    mov rax, [ballYVel]
    cmp rax, 0
    jl .negativeYVel
    inc QWORD [ballYVel]  ; Increase positive velocity
    jmp .updateBallPosition

.negativeYVel:
    dec QWORD [ballYVel]  ; Increase negative velocity

.updateBallPosition:
    ; Update ball position based on velocity
    mov rax, [ballX]
    add rax, [ballXVel]
    mov [ballX], rax

    mov rax, [ballY]
    add rax, [ballYVel]
    mov [ballY], rax

    call EndDrawing
    jmp .gameLoop

.lose:
    ; Game over screen - convert score for display
    mov rax, [score]
    mov rdi, finalScoreStr
    call dec2str

.loseLoop:
    ; Game over screen rendering loop
    call BeginDrawing

    ; Clear screen
    mov rdi, 0xFF630047
    call ClearBackground

    ; Draw "You lose!" message
    mov rdi, loseMsg
    mov rsi, 290
    mov rdx, 235
    mov rcx, 50
    mov r8, 0xFF6DD9677
    call DrawText

    ; Display final score
    mov rdi, scorePrefix
    mov rsi, 300
    mov rdx, 285
    mov rcx, 30
    mov r8, 0xFF6DD9677
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
    mov r8, 0xFF6DD9677
    call DrawText

    call EndDrawing

    ; Check for escape key (quit game)
    mov rdi, 256 ; Escape
    call IsKeyDown
    cmp rax, 1
    je .over

    ; Check for enter key (restart game)
    mov rdi, 257 ; Enter
    call IsKeyDown
    cmp rax, 1
    jne .loseLoop

    ; --- Reset game state for new game ---
    mov QWORD [ballX], 250
    mov QWORD [ballY], 250
    mov QWORD [ballXVel], 3
    mov QWORD [ballYVel], 3
    mov QWORD [paddleY], 150
    mov QWORD [bounces], 0
    mov QWORD [score], 0
    mov QWORd [speed], 1

    ; Reset score display
    mov rax, 0
    mov rdi, scoreStr
    call dec2str

    jmp .gameLoop

.over:
    ; Clean up and exit game
    call CloseWindow

    mov rax, 60
    mov rdi, 0
    syscall

; Function to convert decimal number to string representation
dec2str:
    push rbx
    push rcx
    push rdx

    ; Initialize buffer with zeros
    mov rbx, 10
    mov rcx, 5

.clear_buffer:
    mov BYTE [rdi + rcx - 1], '0'
    dec rcx
    jnz .clear_buffer

    ; Convert number to ASCII digits
    mov rcx, 5
    mov rbx, 10

.convert_loop:
    dec rcx
    xor rdx, rdx
    div rbx             ; Divide by 10, remainder in rdx
    add dl, '0'         ; Convert remainder to ASCII
    mov [rdi + rcx], dl ; Store digit
    test rax, rax       ; Check if quotient is zero
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

    scoreLabel: db "Score: ", 0      ; Label for current score
    scoreStr: db "00000", 0          ; Current score display buffer
    finalScoreStr: db "00000", 0     ; Final score display buffer

    speedLabel: db "Difficulty: ", 0 ; Label for current speed/difficulty
    speedStr: db "00000", 0          ; Current speed display buffer

    paddleY: dq 150                  ; Paddle Y position (X is fixed at left side)

    ballX: dq 250                    ; Ball X position
    ballY: dq 250                    ; Ball Y position
    ballXVel: dq 3                   ; Ball X velocity
    ballYVel: dq 3                   ; Ball Y velocity

    bounces: dq 0                    ; Counter for paddle hits
    bouncesToSpeedUp: dq 3           ; Increase speed every 3 bounces
    speed: dq 1                      ; Current speed
    score: dq 0                      ; Player score

section '.note.GNU-stack'
