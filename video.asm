BORDCR  equ     $5c48

;--------------------------------------------------------------------
; Evaluates whether the lower limit has been reached.
; Input:  A  -> Upper limit (TTLLLLSSS).
;         HL -> Current position (010TTSSS LLLCCCCCCC).
; Output: Z  =  Reached.
;         NZ =  Not reached.
;
; Alters the value of the AF and BC registers.
;--------------------------------------------------------------------
CheckBottom:
        call checkVerticalLimit    ; Compare current position with limit
; If Z or NC has reached the ceiling, Z is set, otherwise NZ is set.
        ret c
checkBottom_bottom:
        xor a                      ; Active Z
        ret

;--------------------------------------------------------------------
; Evaluates whether the upper limit has been reached.
; Input:  A  -> Upper margin (TTLLLLSSS).
;         HL -> Current position (010TTSSS LLLCCCCCCC).
; Output: Z  =  Reached.
;         NZ =  Not reached.
;
; Alters the value of the AF and BC registers.
;--------------------------------------------------------------------
CheckTop:
        call checkVerticalLimit    ; Compare current position with limit
        ret                        ; checkVerticalLimit is enough

;--------------------------------------------------------------------
; Evaluates whether the vertical limit has been reached.
; Input: A  -> Vertical limit (TTLLLLSSS).
;        HL -> Current position (010TTSSS LLLCCCCCCC).
; Alters the value of the AF and BC registers.
;--------------------------------------------------------------------
checkVerticalLimit:
        ld   b, a                  ; B = A
        call GetPtrY               ; Y-coordinate (TTLLLSSSS)
                           ; of the current position
        cp   b                     ; A = B? B = value A = vertical limit
        ret

;--------------------------------------------------------------------
; Delete the ball.
; Alters the value of the AF, B and HL registers.
;--------------------------------------------------------------------
ClearBall:
        ld   hl, (ballPos)         ; HL = ball position
        ld   a, l                  ; A = row and column
        and  $1f                   ; A = column
        cp   $10                   ; Compare with centre display
        jr   c, clearBall_continue ; If carry, jump, is on left
        inc  l                     ; It is in right, increase column
clearBall_continue:
        ld   b, $06                ; Loop 6 scanlines
clearBall_loop:				
        ld   (hl), ZERO            ; Deletes byte pointed to by HL
        call NextScan              ; Next scanline
        djnz clearBall_loop        ; Until B = 0

        ret

;--------------------------------------------------------------------
; Clean screen, ink 7, background 0.
; Alters the value of the AF, BC, DE and HL registers.
;--------------------------------------------------------------------
Cls:
; Clean the pixels on the screen
        ld   hl, $4000             ; HL = start of VideoRAM
        ld   (hl), $00             ; Clears the pixels of that address
        ld   de, $4001             ; DE = next VideoRAM position
        ld   bc, $17ff             ; 6143 repetitions
        ldir                       ; Clears all pixels from VideoRAM

; Sets the ink to white and the background to black.
        ;ld   hl, $5800             ; HL = start of attribute area
        LD      A,$44
        inc     HL                 ; inc instead of ld HL above to save clock cycles, hl already at value we need
        ld      (hl),A              ; White ink and black background
        ld      (BORDCR),A
        
        ;ld   de, $5801             ; DE = next attribute position
        inc     DE                 ; same as HL inc instead of load to improve
        ld   bc, $2ff              ; 767 repetitions
        ldir                       ; Assigns the value to attributes

        ret

;--------------------------------------------------------------------
; Gets third, line and scanline of a memory location.
; Input:  HL -> Memory location.
; Output: A  -> Third, line and scanline obtained.
; Alters the value of the AF and E registers.
;--------------------------------------------------------------------
GetPtrY:
        ld   a, h                  ; A = H (third and scanline)
        and  $18                   ; A = third
        rlca
        rlca
        rlca                       ; Passes value of third to bits 6 and 7
        ld   e, a                  ; E = A
        ld   a, h                  ; A = H (third and scanline)
        and  $07                   ; A = scanline
        or   e                     ; A OR E = Tercio and scanline
        ld   e, a                  ; E = A = TT000SSS
        ld   a, l                  ; A = L (row and column)
        and  $e0                   ; A = line
        rrca		
        rrca                       ; Passes line value to bits 3 to 5
        or   e                     ; A OR E = TTLLLLSSS

        ret

;--------------------------------------------------------------------
; Gets the corresponding sprite to paint on the marker.
; Input:  A  -> score.
; Output: HL -> address of the sprite to be painted.
; Alters the value of the AF, BC and HL registers.
;--------------------------------------------------------------------
GetPointSprite:
        /* ld   hl, Zero              ; HL = address sprite 0
        ld   bc, $04               ; Sprite is 4 bytes away from 
                           ; the previous one
        inc  a                     ; Increment A, loop start != 0
getPointSprite_loop:
        dec  a                     ; Decreasing A
        ret  z                     ; A = 0, end of routine
        add  hl, bc                ; Add 4 to sprite address
        jr   getPointSprite_loop   ; Loop until A = 0	 */
        ld      HL,Zero
        add     A,A
        add     A,A
        LD      B,ZERO
        ld      C,A
        add     HL,BC
        ret
;------------------------------------------------------------------
; NextScan
; https://wiki.speccy.org/cursos/ensamblador/gfx2_direccionamiento
; Gets the memory location corresponding to the scanline.
; The next to the one indicated.
;     010T TSSS LLLC CCCC
; Input:  HL -> current scanline.
; Output: HL -> scanline next.
; Alters the value of the AF and HL registers.
;------------------------------------------------------------------
NextScan:
        inc  h                     ; Increment H to increase the scanline
        ld   a, h                  ; Load the value in A
        and  $07                   ; Keeps the bits of the scanline
        ret  nz                    ; If the value is not 0, end of routine  

; Calculate the following line
        ld   a, l                  ; Load the value in A
        add  a, $20                ; Add one to the line (%0010 0000)
        ld   l, a                  ; Load the value in L
        ret  c                     ; If there is a carry-over, it has changed
                           ; its position, the top is already adjusted 
                           ; from above. End of routine.

; If you get here, you haven't changed your mind and you have to adjust 
; as the first inc h increased it.
        ld   a, h                  ; Load the value in A
        sub  $08                   ; Subtract one third (%0000 1000)
        ld   h, a                  ; Load the value in H
        ret

; -----------------------------------------------------------------
; PreviousScan
; https://wiki.speccy.org/cursos/ensamblador/gfx2_direccionamiento
; Gets the memory location corresponding to the scanline.
; The following is the first time this has been done; prior 
; to that indicated.
;     010T TSSS LLLC CCCC
; Input:  HL -> current scanline.	    
; Output: HL -> previous scanline.
; Alters the value of the AF, BC and HL registers.
;------------------------------------------------------------------
PreviousScan:
        ld   a, h                  ; Load the value in A
        dec  h                     ; Decrements H to decrement the scanline
        and  $07                   ; Keeps the bits of the original scanline
        ret  nz                    ; If not at 0, end of routine

; Calculate the previous line
        ld   a, l                  ; Load the value of L into A
        sub  $20                   ; Subtract one line
        ld   l, a                  ; Load the value in L
        ret  c                     ; If there is carry-over, end of routine

; If you arrive here, you have moved to scanline 7 of the previous line
; and subtracted a third, which we add up again
        ld   a, h                  ; Load the value of H into A
        add  a, $08                ; Returns the third to the way it was
        ld   h, a                  ; Load the value in h
        ret

;--------------------------------------------------------------------
; Paint the ball.
; Alters the value of the AF, BC, DE and HL registers.
;--------------------------------------------------------------------
PrintBall:
        ld   b, $00                ; B = 0
        ld   a, (ballRotation)     ; A = ball rotation, what to paint?
        ld   c, a                  ; C = A
        cp   $00                   ; Compare with 0, see where it rotates to
        ld   a, $00                ; A = 0
        jp   p, printBall_right    ; If positive jumps, rotates to right

printBall_left:
; The rotation of the ball is to the left
        ld   hl, ballLeft          ; HL = address bytes ball
        sub  c                     ; A = A-C, ball rotation
        add  a, a                  ; A = A+A, ball = two bytes
        ld   c, a                  ; C = A
        sbc  hl, bc                ; HL = HL-BC (ball offset)
        jr   printBall_continue

printBall_right:
; Ball rotation is clockwise
        ld   hl, ballRight         ; HL = address bytes ball
        add  a, c                  ; A = A+C, ball rotation
        add  a, a                  ; A = A+A, ball = two bytes
        ld   c, a                  ; C = A
        add  hl, bc                ; HL = HL+BC (ball offset)

printBall_continue:
; The address of the ball definition is loaded in DE.
        ex   de, hl
        ld   hl, (ballPos)         ; HL = ball position

; Paint the first line in white
        ld   (hl), ZERO            ; Moves target to screen position
        inc  l                     ; L = next column
        ld   (hl), ZERO            ; Moves target to screen position
        dec  l                     ; L = previous column
        call NextScan              ; Next scanline

        ld   b, $04                ; Paint ball in next 4 scanlines
printBall_loop:
        ld   a, (de)               ; A = byte 1 definition ball
        ld   (hl), a               ; Load ball definition on screen
        inc  de                    ; DE = next byte definition ball
        inc  l                     ; L = next column
        ld   a, (de)               ; A = byte 2 definition ball
        ld   (hl), a               ; Load ball definition on screen
        dec  de                    ; DE = first byte definition ball
        dec  l                     ; L = previous column
        call NextScan              ; Next scanline
        djnz printBall_loop        ; Until B = 0

; Paint the last blank line
        ld   (hl), ZERO            ; Moves target to screen position
        inc  l                     ; L = next column
        ld   (hl), ZERO            ; Moves target to screen position

        ret

;--------------------------------------------------------------------
; Paint the edge of the field.
; Alters the value of AD, B, DE and HL registers.
;--------------------------------------------------------------------
PrintBorder:
        ld   hl, $4100             ; HL = third 0, line 0, scanline 1
        ld   de, $56e0             ; DE = third 2, line 7, scanline 6
        ld   b, $20                ; B = 32 to be painted
        ld   a, FILL               ; Load the byte to be painted into A

printBorder_loop:
        ld   (hl), a               ; Paints direction pointed by HL
        ld   (de), a               ; Paints address pointed by DE
        inc  l                     ; HL = next column
        inc  e                     ; DE = next column
        djnz printBorder_loop      ; Loop until B reaches 0
        ret

;--------------------------------------------------------------------
; Prints the centre line.
; Alters the value of the AF, B and HL registers.
;--------------------------------------------------------------------
PrintLine:
        ld   b, $18                ; Prints on all 24 lines of the screen
        ld   hl, $4010             ; Starts on line 0, column 16

printLine_loop:
        ld   (hl), ZERO            ; In the first scanline it prints blank
        inc  h                     ; Go to the next scanline

        push bc                    ; Preserves BC value for second loop
        ld   b, $06                ; Prints six times
printLine_loop2:
        ld   (hl), LINE            ; Print byte the line, $10, b00010000
        inc  h                     ; Go to the next scanline
        djnz printLine_loop2       ; Loop until B = 0
        pop  bc                    ; Retrieves value BC
        ld   (hl), ZERO            ; Print last byte of the line
        call NextScan              ; Goes to the next scanline
        djnz printLine_loop        ; Loop until B = 0 = 24 lines
        ret

;--------------------------------------------------------------------
; Repaint the centre line.
; Alters the value of the AF, BC and HL registers.
;--------------------------------------------------------------------
ReprintLine:
        ld   hl, (ballPos)         ; HL = ball position
        ld   a, l                  ; A = row and column
        and  $e0                   ; A = line
        or   $10                   ; A = row and column 16 ($10)
        ld   l, a                  ; HL = initial position repaint

        ld   b, $06                ; Repaints 6 scanlines
reprintLine_loop:
        ld   a, h                  ; A = third and scanline
        and  $07                   ; A = scanline
        ; If it is on scanline 0 or 7 it paints ZERO
        ; If you are on scanline 1 to 6 paint LINE
        cp   $01                   ; Scanline = 1?
        jr   c, reprintLine_loopCont     ; Scanline < 1, paint $00
        cp   $07                   ; Scanline = 7?
        jr   z, reprintLine_loopCont     ; Scanline = 7, paints ZERO

        ;ld   c, LINE               ; Scanline from 1 to 6, paint LINE
        
        ld   a, (hl)               ; A = pixels current position
        ;or   c                     ; A = A OR C (adds pixels from C)
        or      LINE
        ld   (hl), a               ; Paints current position result
reprintLine_loopCont:        
        call NextScan              ; Next Scanline
        djnz reprintLine_loop      ; Until B = 0

        ret

;--------------------------------------------------------------------
; Print the paddle.
; Input: HL -> paddle position.
;
; Alters the value of the B and HL registers.
;--------------------------------------------------------------------
PrintPaddle:
        ld   (hl), ZERO            ; Prints first byte of blank paddle
        call NextScan              ; Goes to the next scanline
        ld   b, $16                ; Paints visible byte of spade 22 times
printPaddle_loop:
        ld   (hl), C         ; Prints the paddle byte
        call NextScan              ; Goes to the next scanline

        djnz printPaddle_loop      ; Loop until B = 0

        ld   (hl), ZERO            ; Prints last byte of blank paddle

        ret

;--------------------------------------------------------------------
; Paint the scoreboard.
; Each number is 1 byte wide by 16 bytes high.
; Alters the value of the AF, BC, DE and HL registers.
;--------------------------------------------------------------------
PrintPoints:

        call    printPoint_1_print
        jr    printPoint_2_print

printPoint_1_print        
        
        ld   a, (p1points)         ; A = points player 1
        call GetPointSprite        ; Gets sprite to be painted in marker
                            ; Preserves the value of HL
        ; 1st digit of player 1
        ld   e, (hl)               ; HL = low part 1st digit address
                                ; E = (HL)
        inc  hl                    ; HL = high side address 1st digit
        ld   d, (hl)               ; D = (HL)
        push hl
        ld   hl, POINTS_P1         ; HL = memory address where to paint
                                ; points player 1
        call PrintPoint      ; Paint 1st digit marker player 1

        pop  hl                    ; Retrieves the value of HL
        ; 2nd digit of player 1
        ;inc  hl			
        inc  hl                    ; HL = low part 2nd digit address
        ld   e, (hl)               ; E = (HL)
        inc  hl                    ; HL = high side address 2nd digit
        ld   d, (hl)               ; D = (HL)
        ld   hl, POINTS_P1 + 1         ; HL = memory address where to paint
                                ; points player 1
        ;inc  l                     ; HL = address where to paint 2nd digit
        call PrintPoint     ; Paint 2nd digit marker player 1

        ret

printPoint_2_print
        ld   a, (p2points)         ; A = points player 2
        call GetPointSprite        ; Gets sprite to be painted in marker
        ; 1st digit of player 2
        ld   e, (hl)               ; HL = low part 1st digit address
                                ; E = (HL)
        inc  hl                    ; HL = high side address 1st digit
        ld   d, (hl)               ; D = (HL)             
        push hl                    ; Preserves value of HL

        ld   hl, POINTS_P2         ; HL = memory address where to paint
                                ; points player 2
        call PrintPoint      ; Paint 1st digit marker player 2

        pop  hl                    ; Retrieves the value of HL
        ; 2nd digit of player 2
        ;inc  hl			
        inc  hl                    ; HL = low part 2nd digit address
        ld   e, (hl)               ; E = (HL)
        inc  hl                    ; HL = high side address 2nd digit
        ld   d, (hl)               ; D = (HL)
        ld   hl, POINTS_P2 + 1        ; HL = memory address where to paint
                                ; points player 2
       ; inc  l                     ; HL = address where 2nd digit paints
        ; Paint the second digit of player 2's marker.

PrintPoint:
        ld   b, $10                ; Each digit: 1 byte x 16 (scanlines)
      ;  push de                    ; Preserves the value of DE
       ; push hl                    ; Preserves the value of HL
printPoint_printLoop:
        ld   a, (de)               ; A = byte to be painted
        ld   (hl), a               ; Paints the byte
        inc  de                    ; DE = next byte
        call NextScan              ; HL = next scanline
        djnz printPoint_printLoop  ; Until B = 0

       ; pop  hl                    ; Retrieves the value of HL
      ;  pop  de                    ; Retrieves the value of DE

        ret

;--------------------------------------------------------------------
; Repaint the scoreboard.
; Each number is 1 byte wide by 16 bytes high.
; Alters the value of the AF, BC, DE and HL registers.
;--------------------------------------------------------------------
ReprintPoints:
       ld       HL,(ballPos)
       call     GetPtrY
       cp       POINTS_Y_B
       ret      NC
       ld       A,L
       and      $1f
       cp       POINTS_X1_L
       ret      C
       jr       Z,printPoint_1_print
       cp       POINTS_X2_R
       jr       Z,reprintPoint_2_print
       ret      NC
reprintPoint_1
        cp      POINTS_X1_R
        jr      z,printPoint_1_print
        jr      c,printPoint_1_print
/* reprintPoint_1_print
        ld      A,(p1points)
        call    GetPointSprite
      ;  push    HL
        ld      E,(HL)
        inc     HL
        ld      D,(HL)
        push    HL
        ld      HL,POINTS_P1
        call    PrintPoint
        pop     hl
        ;inc     HL
        inc     HL
        ld      E,(HL)
        inc     HL
        ld      D,(HL)
        ld      HL,POINTS_P1 + 1
      ;  inc     L
        jr      PrintPoint
 */
reprintPoint_2
        cp      POINTS_X2_L
        ret     C
reprintPoint_2_print
        jr      printPoint_2_print
        /* ld      A,(p2points)
        call    GetPointSprite
        push    HL
        ld      E,(HL)
        inc     HL
        ld      D,(HL)
        ld      HL,POINTS_P2
        call    PrintPoints
        pop     hl
       ; inc     HL
        inc     HL
        ld      E,(HL)
        inc     HL
        ld      D,(HL)
        ld      HL,POINTS_P2 +1
       ; inc     L
        jp      PrintPoints    
 */