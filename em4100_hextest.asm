;   OPEN RFID TAG - EM4100 TAG

#include "p12f683.inc"

	__CONFIG       _WDT_OFF & _BOD_OFF & _PWRTE_ON & _EC_OSC

TX	MACRO	DATA, NUM_BITS, PARITY_CHECK

	LOCAL i = NUM_BITS
	LOCAL tmp = DATA
	LOCAL parity = 0
	LOCAL mask = 0x01 << (NUM_BITS-1)

	WHILE i > 0

		IF (tmp & mask)
			CALL	_TX_manchester_one
			parity = !parity
		ELSE
			CALL	_TX_manchester_zero
		ENDIF

		tmp = tmp << 1

		i -=  1

	ENDW

	IF (PARITY_CHECK == 1)
		IF (parity)
			CALL _TX_manchester_one
		ELSE
			CALL _TX_manchester_zero
		ENDIF
	ENDIF

	ENDM

	ORG 0x00

_configuration

	BSF	STATUS,RP0 		; Bank 1

	CLRF	ANSEL 			; GPIOs as digital ports

	BCF	STATUS,RP0		; Bank 0

	MOVLW	07h 			; Turning off the analog comparators
	MOVWF	CMCON0

	CLRF	ADCON0              	; turn off A/D convertor

_main

	BSF	STATUS, RP0		; Bank 1

	; Transmits the header ('111111111')
	TX	0x1FF, 9, 0

	; Transmits the manufacturer ID (with parity bit)
	TX	0x0a, 4, 1
	TX	0x0b, 4, 1

	; Transmits the serial number (with parity bit)
	TX	0x0c, 4, 1
	TX	0x0c, 4, 1
	TX	0x0d, 4, 1
	TX	0x0d, 4, 1
	TX	0x0e, 4, 1
	TX	0x0e, 4, 1
	TX	0x0f, 4, 1
	TX	0x0f, 4, 1

	; Transmit the parity column (previously calculated) and the stop bit ('0')
	TX	b'00010', 5, 0

	bcf	STATUS, RP0		; Bank 0

	goto 	_main			; Repeat the transmition

_TX_manchester_one

	BSF 	TRISIO, GP4		; GP4 to High impedance. TX a zero
	NOP				; Waiting for 32 clocks (8 instructions)
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP

	BCF 	TRISIO, GP4		; GP4 to GND. TX a one
	NOP				; Waiting for 32 clocks (8 instructions)
	NOP
	NOP
	RETURN				; The RETURN and the next CALL
					; instructions count as 16 clocks (4*4)

_TX_manchester_zero

	BCF 	TRISIO, GP4		; GP4 to GND. TX a one
	NOP				; Waiting for 32 clocks (8 instructions)
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP


	BSF 	TRISIO, GP4		; GP4 to High impedance. TX a zero
	NOP				; Waiting for 32 clocks (8 instructions)
	NOP
	NOP
	RETURN				; The RETURN and the next CALL
					; instructions count as 16 clocks (4*4)

	END
