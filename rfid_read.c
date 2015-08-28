/*  RFID Reader (EM41XX)
 *  Xeon Feb 2015
 *  gcc rfid_read.c -o rfid_read -ggdb -W -std=c99 -m64
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define KNRM  "\x1B[0m"
#define KRED  "\x1B[31m"
#define KYEL  "\x1B[33m"
#define KCYN  "\x1B[36m"
#define KWHT  "\x1B[37m"

#define DATA 10

#define HI_NIBBLE(b) (((b) >> 4) & 0xF)
#define LO_NIBBLE(b) ((b) & 0xF)

struct EM41XXpkt {
	int head[9]; //0x1FF
	int serial[5][8];
	int plh[5];
	int pll[5];
	int pc[4];
	int sbit[1]; //logical 0 stopbit
};

void binary(int *bits, int n){

	int b = 0;

	for (int c = 7; c >= 0; c--){

		if ((n >> c) & 0x1) bits[b++] = 1;
		else bits[b++] = 0;
	}
	return;
}

int main(int argc, char *argv[]){

	printf(KNRM"\nEM41XX ISO based RFID IC\n125kHz Carrier\
		\n2kbps ASK Manchester encoding\
		\n32-bit unique ID\
		\n64-bit data stream\n\n");

	struct EM41XXpkt em41xx;
	memset(&em41xx, 0, sizeof em41xx);

	char c = '\0', str[DATA];
	int i = 0, j = 0, n = 0, input[DATA], hex = 0, serial[5];
	memset(&str, 0, DATA);
	memset(&input, 0, DATA);

	// read input as hex
	printf("Scan RFID tag: "KRED);
	scanf("%s", str);

	for(i = 0; i < DATA; i++) {
		c = str[i];
		input[i] = strtol(&c, NULL, 16);
	};

	// display 8H10D format
	memmove(&str[0], &str[1], strlen(str));
	memmove(&str[0], &str[1], strlen(str));
	hex = strtol(str, NULL, 10);
	printf(KNRM"\n32 bit UID stored as 8H10D format: ");
	printf(KRED"0x%08X", hex);

	// merge 2 digits into single hi/lo bit output hex
	printf(KNRM"\nBYTES:\t"KCYN"   HEADER   "KYEL);
	for(i = 0; i < DATA; i+=2) {
                serial[j] = (input[i] << 4) | input[i+1];
		printf("0x%X  0x%X  ", HI_NIBBLE(serial[j]), LO_NIBBLE(serial[j]));
		j++;
        }

	// decimal to binary conversion
	for(i = 0; i < 9; i++) {
		em41xx.head[i] |= 0x01;
	}
	for(i = 0; i < 5; i++) {
		binary(em41xx.serial[i], serial[i]);
	}

	// calc parity bits
	for(j = 0; j < 5; j++){ //rows
		n = 0;
		for(i = 0; i < 4; i++) {
			n += em41xx.serial[j][i];
		}
		em41xx.plh[j] = n % 2;

		n = 0;
                for(; i < 8; i++) {
                        n += em41xx.serial[j][i];
                }
                em41xx.pll[j] = n % 2;
	}

	for(i = 0; i < 4; i++){ //cols
		n = 0;
                for(j = 0; j < 5; j++) {
			n += em41xx.serial[j][i];
		}
		for(j = 0; j < 5; j++) {
			n += em41xx.serial[j][i+4];
		}
		em41xx.pc[i] = n % 2;
	}

	// output bitstream
	printf(KNRM "\nBITSTREAM: " KCYN);
	for(i = 0; i < 9; i++) {
                printf("%d", em41xx.head[i]);
        }
	for(j = 0; j < 5; j++) {
		for(i = 0; i < 4; i++) {
        	        printf(KWHT"%d", em41xx.serial[j][i]);
        	}
		printf(KRED"%d"KWHT, em41xx.plh[j]);
		for(; i < 8; i++) {
                        printf("%d", em41xx.serial[j][i]);
                }
                printf(KRED"%d"KWHT, em41xx.pll[j]);
	}
	for(i = 0; i < 4; i++) {
                printf(KRED"%d", em41xx.pc[i]);
        }
	printf(KCYN"%d\n\n", em41xx.sbit[0]);

	// output 64bit parity table
        printf(KNRM"64 Bits Parity Table\n\n\t");
        for(i = 0; i < 9; i++) {
                printf(KCYN"%d", em41xx.head[i]);
        }
	printf("\n\t    ");
	for(j = 0; j < 5; j++) {
		for(i = 0; i < 4; i++) {
			printf(KWHT"%d", em41xx.serial[j][i]);
		}
		printf(KRED"%d\n\t    ", em41xx.plh[j]);
		for(; i < 8; i++) {
	                printf(KWHT"%d", em41xx.serial[j][i]);
	        }
        	printf(KRED"%d\n\t    ", em41xx.pll[j]);
	}
	for(i = 0; i < 4; i++) {
                printf(KRED"%d", em41xx.pc[i]);
        }
	printf(KCYN"%d\n\n", em41xx.sbit[0]);

	// instruction list
	printf(KNRM"TX Instructions for PIC Emulation\n\n");
	printf(KYEL"\tTX\t0x%X, 9, 0\n", 511);
	for(i = 0; i < 5; i++) {
		printf("\tTX\t0x%02X, 4, 1\n", HI_NIBBLE(serial[i]));
		printf("\tTX\t0x%02X, 4, 1\n", LO_NIBBLE(serial[i]));
	}
	printf("\tTX\tb'%d%d%d%d0', 5, 0", em41xx.pc[0], em41xx.pc[1], em41xx.pc[2], em41xx.pc[3]);

	printf(KNRM "\n\n");
	return 0;
}

/*
 * The EM41XX contains 64 bits divided in five groups of
 * information. 9 bits are used for the header, 10 row parity
 * bits, 4 column parity bits, 40 data bits, and 1 stop bit
 * set to logic 0.
 *
 * The header is composed of the 9 first bits which are all
 * mask programmed to "1". Due to the data and parity
 * organisation, this sequence cannot be reproduced in the
 * data string. The header is followed by 10 groups of 4 data
 * bits allowing 100 billion combinations and 1 even row
 * parity bit. Then, the last group consists of 4 event column
 * parity bits without row parity bit. Lastly, a stop bit which is
 * written to "0"
 * Bits 10-40 are customer specific identification.
 * These 64 bits are outputted serially in order to control the
 * modulator. When the 64 bits data string is outputted, the
 * output sequence is repeated continuously until power goes
 * off.
 */
