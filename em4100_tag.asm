;   OPEN RFID TAG - EM4100 TAG

#include "p12f683.inc"

	__CONFIG       _WDT_OFF & _BOD_OFF & _PWRTE_ON & _EC_OSC

		;    MACRO:     TX
		;    Desc.:     Transmits data to the reader
		;    Params.:   DATA -> data to transmit
		;               NUM_BITS -> number of bits to transmit
		;               PARITY_CHECK -> calculates the parity bit

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

		;    Function:  _configuration
		;    Desc.:     Configures the microcontroller
		;    Notes:     If you want to port the firmware to another 12F or 16F micro,
		;               you have to change only this function. Be sure that you
		;               configure the IO ports as digital inputs.

_configuration

	BSF	STATUS,RP0 		; Bank 1

	CLRF	ANSEL 			; GPIOs as digital ports

	BCF	STATUS,RP0		; Bank 0

	MOVLW	07h 			; Turning off the analog comparators
	MOVWF	CMCON0

	CLRF	ADCON0              	; turn off A/D convertor

		;    Function:  _main
		;    Desc.:     Main program loop. Transmits the data.
		;    Notes:     The firmware emulates an EM4100 tag with the next memory map
		;
		;               111111111 			<- Header
		;               00011 00011                     <- Manufacturer ID
		;               00011 00011 00011 00011         <- Serial number
		;               00011 00011 00011 00011
		;               11110                           <- parity column and stop bit

_main

	BSF	STATUS, RP0		; Bank 1

	; Transmits the header ('111111111')
	TX	 0x1FF, 9, 0


	; Transmits the manufacturer ID (with parity bit)
	TX	0x01, 4, 1
	TX	0x01, 4, 1

	; Transmits the serial number (with parity bit)
	TX	0x01, 4, 1
	TX	0x01, 4, 1
	TX	0x01, 4, 1
	TX	0x01, 4, 1
	TX	0x01, 4, 1
	TX	0x01, 4, 1
	TX	0x01, 4, 1
	TX	0x01, 4, 1

	; Transmit the parity column (previously calculated) and the stop bit ('0')
	TX	b'11110', 5, 0

	bcf	STATUS, RP0		; Bank 0

	goto 	_main			; Repeat the transmition

		;    Function:  _TX_manchester_one
		;    Desc.:     Transmit a '1'
		;    Function:  _TX_manchester_zero
                ;    Desc.:     Transmit a '0'
		;    Notes:     Manchester encoding at 64 clocks per bit is used.
		;               To change the data rate, just add or remove NOP instructions
		;               Using a Biphase encoding would require more complex changes.
		;               However, you can transmit a biphase encoded memory map if you
		;               encode the raw data transmited as Manchester.

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
