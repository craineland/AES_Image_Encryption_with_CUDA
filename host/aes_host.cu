// System Imports
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <cuda.h>

// Project Imports
#include "tools/sbox.c"
#include "tools/helper_functions.c"
#include "tools/round_keys_serial.c"
#include "tools/bitmap.c"

/*
 * Serial implementation of Advanced Encryption Standard (AES)
 * Based on "aes.c" by Dani Huertas
 *
 * Encryption/Decryption process simplified with integrated
 * byte substitution and additive key rounds
 *
 * @author      Camden Landis (craine)
 * @version     05.12.2021
 *              DD.MM.YYYY
 */
// =========================================================================


// Number of columns (32-bit words) comprising the State. 
// For this standard, num. of col. = 4.
static int col_num = 4;


/*
 * Transformation in the Cipher that processes the State by cyclically 
 * shifting the last three rows of the State by different offsets. 
 */
void shift_rows(unsigned char *state) {
    unsigned char i, j, k, state_update;
    for (i = 1; i < 4; i++) {
        k = 0;
        while (k < i) {
            state_update = state[col_num*i + 0];
            
            for (j = 1; j < col_num; j++) {
                state[col_num*i + j-1] = state[col_num*i + j];
            }

            state[col_num*i + col_num-1] = state_update;
            k++;
        }
    }
}


/*
 * Transformation in the Inverse Cipher that is the  
 * cryptographic inverse of shift_rows().
 */
void inverse_shift_rows(unsigned char *state) {
    unsigned char i, j, k, state_update;
    for (i = 1; i < 4; i++) {
        k = 0;
        while (k < i) {
            state_update = state[col_num*i + col_num-1];
            
            for (j = col_num-1; j > 0; j--) {
                state[col_num*i + j] = state[col_num*i + j-1];
            }

            state[col_num*i + 0] = state_update;
            k++;
        }
    }
}


/*
 * Transformation in the Cipher that takes all of the columns of the 
 * State and mixes their data (independently of one another) to 
 * produce new columns.
 */
void mix_columns(unsigned char *state) {

    unsigned char a[] = {0x02, 0x01, 0x01, 0x03}; // a(x) = {02} + {01}x + {01}x2 + {03}x3
    unsigned char i, j, col[4], result[4];

    for (j = 0; j < col_num; j++) {
        for (i = 0; i < 4; i++) {
            col[i] = state[col_num*i+j];
        }

        coef_mult(a, col, result);

        for (i = 0; i < 4; i++) {
            state[col_num*i+j] = result[i];
        }
    }
}


/*
 * Transformation in the Inverse Cipher that is the 
 * cryptographic inverse of mix_columns().
 */
void inverse_mix_columns(unsigned char *state) {

    unsigned char a[] = {0x0e, 0x09, 0x0d, 0x0b}; // a(x) = {0e} + {09}x + {0d}x2 + {0b}x3
    unsigned char i, j, col[4], result[4];

    for (j = 0; j < col_num; j++) {
        for (i = 0; i < 4; i++) {
            col[i] = state[col_num*i+j];
        }

        coef_mult(a, col, result);

        for (i = 0; i < 4; i++) {
            state[col_num*i+j] = result[i];
        }
    }
}


/*
 * Performs the simplified AES encryption operation
 */
void aes_encrypt(unsigned char *image, int size, int key) {
    
    int i = 0;
    // byte substitution
    for (i = 0 ;i < size; i++)
        // index translation from SBOX
        image[i] = sbox[image[i]];

    // shift rows
    for (i = 0; i < size; i += 16)
        shift_rows(image + i);

    // mix columns
    for (i = 0; i < size; i += 16)
        mix_columns(image + i); 

    // Add round key
    for (i = 0; i < size; i += 16)
       key_xor(image + i);

}


/*
 * Performs the simplified AES decryption operation
 */
void aes_decrypt(unsigned char *image, int size, int key) {
    
    int i = 0;
    // add round key
    for (i = 0; i < size; i += 16)
       key_xor(image + i);

    // mix columns
    for (i = 0;i < size;i += 16)
        inverse_mix_columns(image + i);

    // shift rows
    for (i = 0;i < size;i += 16)
        inverse_shift_rows(image + i);

    // byte substitution
    for (i = 0; i < size; i++)
        // index translation from Inverse S-BOX
        image[i] = inverse_sbox[image[i]];
    
}


/*
 * Main function
 *
 * Arguments: 
 *      ./aes_serial [path to image] [integer key] [path to encrypted output] [path to decrypted output]
 *
 */
int main(int argc, char* argv[]) {

    // argument variables
    char* image_path     = argv[1];
    int   key            = atoi(argv[2]);
    char* encrypted_path = argv[3];
    char* decrypted_path = argv[4];

    if (argc < 5 || argc > 5) {
        printf("Error... Needed Arguments: ./aes_serial [path to image] [integer key] [path to encrypted output] [path to decrypted output]\n");
        return -1;
    }

    BITMAPINFOHEADER bitmap_info;
    BITMAPFILEHEADER bitmap_file;

    printf("\n");
    printf("=== HOST Encryption/Decryption Results ===\n");
    printf("\n");

    // load original image
    unsigned char *image;
    image = LoadBitmapFile(image_path, &bitmap_info, &bitmap_file);
    printf("Size of Input Image: %d%s\n", bitmap_info.biSizeImage, " bytes");
    printf("Dimensions of Image in Pixels (x,y): (%d,%d)\n", bitmap_info.biWidth, bitmap_info.biHeight);


    double encode_elapsed_time, decode_elapsed_time;
    
    double tic = clock();
    aes_encrypt(image, bitmap_info.biSizeImage, key); // encrypt the image
    double toc = clock();
    encode_elapsed_time = (toc-tic)/CLOCKS_PER_SEC;

    printf("\n");
    printf("Image Encryption Time: %3.6f sec\n", encode_elapsed_time);
    printf("Encryption Throughput: %3.2f MB/s\n", (double)(bitmap_info.biSizeImage/1.e6)/(encode_elapsed_time));
    ReloadBitmapFile(encrypted_path, image, &bitmap_file, &bitmap_info);

    // load encrypted image
    image = LoadBitmapFile(encrypted_path, &bitmap_info, &bitmap_file);

    tic = clock();
    aes_decrypt(image, bitmap_info.biSizeImage, key); // decrypt the image
    toc = clock();
    decode_elapsed_time = (toc-tic)/CLOCKS_PER_SEC;

    printf("\nImage Decryption Time: %3.6f sec\n", decode_elapsed_time);
    printf("Decryption Throughput: %3.2f MB/s\n", (double)(bitmap_info.biSizeImage/1.e6)/(decode_elapsed_time));
    ReloadBitmapFile(decrypted_path, image, &bitmap_file, &bitmap_info);

    printf("\n");

    return 0;
}
