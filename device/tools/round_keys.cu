#include <stdio.h>
#include <stdlib.h>

// =========================================================================

//Round Keys
__device__ unsigned char key[16] = {
    0x00, 0x01, 0x02, 0x03,
    0x04, 0x05, 0x06, 0x07,
    0x08, 0x09, 0x0a, 0x0b,
    0x0c, 0x0d, 0x0e, 0x0f
};

/*
 * Key is added to the State using an XOR operation.
 */
__device__ void key_xor(unsigned char *state){

    for(int i=0;i < 16;i++) {
       state[i] = state[i]^key[i];
    }

}