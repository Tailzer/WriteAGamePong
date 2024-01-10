
                include BasicLib.asm
                include game.asm
                include controls.asm
                include sprite.asm
                include video.asm
                include sound.asm

                device	zxspectrum48
                ORG	23755

line_useval = 1   ;; Last line will be RANDOMIZE USR VAL "32768"

basic
	LINE : db clear,val,'"23980"'	: LEND
	LINE : db load,'"pong"', code	: LEND
	LINE : db rand,usr : NUM start	: LEND
basend
               
                org  23981

;--------------------------------------------------------------------
; Programme entry
;--------------------------------------------------------------------
MAIN
start   ld   a, $00               ; A = 0
        out  ($fe), a              ; Black border

        call Cls                   ; Clear screen
        call PrintLine             ; Print centre line
        call PrintBorder           ; Print field border
        call PrintPoints
        call WaitStart
        ld   a, ZERO
        ld   (p1points), a
        ld   (p2points), a
        call PrintPoints
        ld      HL,BALLPOS_INI
        ld      (ballPos),HL
        ld      HL,PADDLE1POS_INI
        LD      (paddle1pos),HL
        ld      HL,PADDLE2POS_INI
        ld      (paddle2pos),HL
        ld      A,$03
        call    PlaySound
Loop:
        
        ld   a, (ballSetting)
        rrca
        rrca
        ;rrca ;removed as part of optimisation
        rrca
        and  $07
        ld   b, a
        ld   a, (countLoopBall)    ; A = countLoopsBall	
        inc  a                     ; It increases it
        ld   (countLoopBall), a    ; Load to memory
        cp   b                     ; Counter = 2?
        jr   nz, loop_paddle       ; Counter != 2, skip
        call MoveBall              ; Move ball
        ld   a, ZERO               ; A = 0
        ld   (countLoopBall), a    ; Counter = 0

loop_paddle:
        ld   a, (countLoopPaddle)  ; A = count number of paddle turns
        inc  a                     ; It increases it
        ld   (countLoopPaddle), a  ; Load to memory
        cp   $02                   ; Counter = 2?
        jr   nz, loop_continue     ; Counter != 2, skip
        call ScanKeys              ; Scan for keystrokes
        call MovePaddle            ; Move paddles
        ld   a, ZERO               ; A = 0
        ld   (countLoopPaddle), a  ; Counter = 0

loop_continue:
        call CheckBallCross        ; Checks for collision between ball
                           ; and paddles
        call PrintBall             ; Paint ball
        call ReprintLine           ; Reprint line
        call ReprintPoints
        ld   hl, (paddle1pos)      ; HL = paddle 1 position
        ld      C,PADDLE1
        call PrintPaddle           ; Paint paddle 1
        ld   hl, (paddle2pos)      ; HL = paddle 2 position
        ld      C,PADDLE2
        call PrintPaddle           ; Paint paddle 2
        ld   a, (p1points)
        cp   $0f
        jp   z, MAIN
        ld   a, (p2points)
        cp   $0f
        jp   z, MAIN
        jr  Loop                   ; Infinite loop
codend
        

countLoopBall:   db $00    ; Count turns ball
countLoopPaddle: db $00    ; Count turns paddles
p1points:        db $00
p2points:        db $00

        DEFINE	tape	Simple-loader.tap

	EMPTYTAP tape
	SAVETAP  tape , BASIC , "basic" , basic , basend-basic , 10
        SAVETAP  tape , CODE , "pong" , start , codend-start
