;   OPEN RFID TAG - EM4100 TAG

#include "p12f683.inc"

	__CONFIG       _WDT_OFF & _BOD_OFF & _PWRTE_ON & _EC_OSC

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

        LOCAL i = d'64'
        LOCAL tmp = b'1111111110001101001000110010100000000000000000011001100010101100'
        LOCAL mask = 0x01 << d'63'

        WHILE i > 0

                IF (tmp & mask)
                        CALL    _TX_manchester_one
                ELSE
                        CALL    _TX_manchester_zero
                ENDIF

                tmp <<= 1

                i -=  1

        ENDW

	BCF	STATUS, RP0		; Bank 0

	GOTO 	_main			; Repeat the transmition

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
