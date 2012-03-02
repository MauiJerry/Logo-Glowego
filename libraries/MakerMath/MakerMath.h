/*
 *  MakerMath.h
 *  misc math functions for arduino
 *
 *  Created by Jerry Isdale on 1/15/12.
 *  no copyright. Based on work of others
 *
 */

int multiMap(int val, int* _in, int* _out, int sizearray);
float multiMapF(float val, float * _in, float * _out, int sizearray);

char fixCos(int angle);
char fixSin(int angle);

int makerMath_avg(int *array, int sizearray);
int makerMath_mode(int *array, int sizearray);
