;sound.asm
;sound routines

;Point

C_3	equ	$0d07
C_3_FQ	equ	$0082 / $10

; Paddle

C_4	equ	$066e
C_4_FQ	equ	$105 / $10

; Border

C_5	equ	$0326
C_5_FQ	equ	$020b /$10

BEEPER	equ	$03b5

PlaySound
	push	DE
	push	HL
	;cp	$01
	dec	A
	jr	Z, playSound_point
	;cp	$02
	dec	A
	jr	Z, playSound_paddle
	ld	HL,C_5
	ld	de,C_5_FQ
	jr beep

playSound_point
	ld	HL,C_3
	ld	de,C_3_FQ
	jr	beep

playSound_paddle
	ld	HL,C_4
	ld	de,C_4_FQ

beep
	push	AF
	push	BC
	push	IX
	call	BEEPER
	pop	IX
	pop	BC
	pop	AF
	pop	HL
	pop	DE

	ret

