/*  lc_tank calc
 *  Xeon Feb 2015
 *  gcc lc_tank.c -o lc_tank -ggdb -Wall -std=c99 -m64 -lm
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

#define M_PI 3.14159265358979323846

int main(int argc, char *argv[]){

	double c = 27e-12, l = 0.2e-6;

	printf("\nInductance: %.3fuH", l*1e6);
	printf("\nCapacitance: %.3fnF", c*1e9);
	printf("\nFrequency: %.6fMHz\n\n", 1/(2e6*M_PI*sqrt(l*c)));

	return 0;
}
