// System Imports
#include <cuda.h>
#include <stdio.h>
#include <stdlib.h>

// Project Imports
#include "tools/bitmap.c"
#include "tools/helper_functions.cu"
#include "tools/round_keys.cu"
#include "tools/sbox.cu"

/*
 * Parallel implementation of Advanced Encryption Standard (AES)
 * Based on "aes.c" (serial version) by Dani Huertas
 *
 * Encryption/Decryption process simplified with integrated
 * byte substitution and additive key rounds
 *
 * @author      Camden Landis (craine)
 * @version     06.12.2021
 *              DD.MM.YYYY
 */
// =========================================================================

#define BLOCK_DIM  16
#define THREAD_NUM 512

// Number of columns (32-bit words) comprising the State.
// For this standard, num. of col. = 4.
__device__ static int col_num = 4;

/*
 * Transformation in the Cipher that processes the State by cyclically 
 * shifting the last three rows of the State by different offsets. 
 */
__device__ void shift_rows(unsigned char *state) {
    unsigned char i, j, k, state_update;
    for (i = 1; i < 4; i++) {
        k = 0;
        while (k < i) {
            state_update = state[col_num * i + 0];

            for (j = 1; j < col_num; j++) {
                state[col_num * i + j - 1] = state[col_num * i + j];
            }

            state[col_num * i + col_num - 1] = state_update;
            k++;
        }
    }
}

/*
 * Transformation in the Inverse Cipher that is the  
 * cryptographic inverse of shift_rows().
 */
__device__ void inverse_shift_rows(unsigned char *state) {
    unsigned char i, j, k, state_update;
    for (i = 1; i < 4; i++) {
        k = 0;
        while (k < i) {
            state_update = state[col_num * i + col_num - 1];

            for (j = col_num - 1; j > 0; j--) {
                state[col_num * i + j] = state[col_num * i + j - 1];
            }

            state[col_num * i + 0] = state_update;
            k++;
        }
    }
}

/*
 * Transformation in the Cipher that takes all of the columns of the 
 * State and mixes their data (independently of one another) to 
 * produce new columns.
 */
__device__ void mix_columns(unsigned char *state) {
               // a(x) =  {02} + {01}x + {01}x2 + {03}x3
    unsigned char a[] = {0x02,  0x01,   0x01,    0x03};
    unsigned char i, j, col[4], result[4];

    for (j = 0; j < col_num; j++) {
        for (i = 0; i < 4; i++) {
            col[i] = state[col_num * i + j];
        }

        coef_mult(a, col, result);

        for (i = 0; i < 4; i++) {
            state[col_num * i + j] = result[i];
        }
    }
}

/*
 * Transformation in the Inverse Cipher that is the 
 * cryptographic inverse of mix_columns().
 */
__device__ void inverse_mix_columns(unsigned char *state) {
               // a(x) =  {0e} + {09}x + {0d}x2 + {0b}x3
    unsigned char a[] = {0x0e,  0x09,   0x0d,    0x0b};
    unsigned char i, j, col[4], result[4];

    for (j = 0; j < col_num; j++) {
        for (i = 0; i < 4; i++) {
            col[i] = state[col_num * i + j];
        }

        coef_mult(a, col, result);

        for (i = 0; i < 4; i++) {
            state[col_num * i + j] = result[i];
        }
    }
}

/*
 * Performs the simplified AES encryption operation
 */
__global__ void aes_encrypt_naive(unsigned char *image, int size, int key) {
    int t = threadIdx.x;
    int b = blockIdx.x;
    int B = blockDim.x;
    int n = t + b*B;

    if (n < size) {
        // byte substitution
        // index translation from SBOX
        image[n] = sbox[image[n]];
        // shift rows
        shift_rows(image + n);
        // mix columns
        mix_columns(image + n);
        // Add round key
        key_xor(image + n);
    }

    __syncthreads();
}

/*
 * Performs the simplified AES decryption operation
 */
__global__ void aes_decrypt_naive(unsigned char *image, int size, int key) {
    int t = threadIdx.x;
    int b = blockIdx.x;
    int B = blockDim.x;
    int n = t + b*B;

    if (n < size) {
        // inverse add round key
        key_xor(image + n);
        // inverse mix columns
        inverse_mix_columns(image + n);
        // inverse shift rows
        inverse_shift_rows(image + n);
        // inverse byte substitution
        // index translation from Inverse SBOX
        image[n] = inverse_sbox[image[n]];
    }

    __syncthreads();
}


/*
 * Performs the simplified AES encryption operation with shared memory
 */
__global__ void aes_encrypt_shared(unsigned char *image, int size, int key) {
    int t = threadIdx.x;
    int b = blockIdx.x;
    // int B = blockDim.x;
    // int n = t + b*B;

    // shared memory array for state data
    __shared__ unsigned char s_state[THREAD_NUM * BLOCK_DIM];
    int i = 0;

    // shared memory code based on work by 
    // Mengxiao Lin, Jiemin Wu, Xiaorui Wang, Chuyuan Qu 
    // Computer Science @ UC Davis
    // copying image array data to shared memory
    for (int k = t * BLOCK_DIM; k < (t + 1) * BLOCK_DIM; k++) {
        int n_index = k + b * THREAD_NUM * BLOCK_DIM;
        if (n_index < size) {
            s_state[k] = image[n_index];
        }
    }
    __syncthreads();

    // byte substitution
    for (i = t * BLOCK_DIM; i < (t + 1) * BLOCK_DIM; i++) {
        s_state[i] = sbox[s_state[i]];
    }
    __syncthreads();

    // shift rows
    shift_rows(&s_state[t * BLOCK_DIM]);
    __syncthreads();

    // mix columns
    mix_columns(&s_state[t * BLOCK_DIM]);
    __syncthreads();

    // add round key
    key_xor(&s_state[t * BLOCK_DIM]);
    __syncthreads();

    // copying data back to original image array
    for (int k = t * BLOCK_DIM; k < (t + 1) * BLOCK_DIM; k++) {
        int n_index = k + b * THREAD_NUM * BLOCK_DIM;
        if (n_index < size) {
            image[n_index] = s_state[k];
        }
    }
    __syncthreads();
}


/*
 * Performs the simplified AES decryption operation with shared memory
 */
__global__ void aes_decrypt_shared(unsigned char *image, int size, int key) {
    int t = threadIdx.x;
    int b = blockIdx.x;
    int B = blockDim.x;
    int n = t + b*B;

    // shared memory array for state data
    __shared__ unsigned char s_state[THREAD_NUM * BLOCK_DIM];
    int i = 0;

    // shared memory code based on work by 
    // Mengxiao Lin, Jiemin Wu, Xiaorui Wang, Chuyuan Qu 
    // Computer Science @ UC Davis
    // copying encrypted image array data to shared memory
    for (int k = t * BLOCK_DIM; k < (t + 1) * BLOCK_DIM; k++) {
        int n_index = k + b * THREAD_NUM * BLOCK_DIM;
        if (n_index < size)
            s_state[k] = image[n_index];
    }
    __syncthreads();

    // add round key
    key_xor(&s_state[t * BLOCK_DIM]);
    __syncthreads();

    // inverse mix columns
    inverse_mix_columns(&s_state[t * BLOCK_DIM]);
    __syncthreads();

    // inverse byte substitution
    for (i = t * BLOCK_DIM; i < (t + 1) * BLOCK_DIM; i++) {
        s_state[i] = inverse_sbox[s_state[i]];
    }
    __syncthreads();

    // inverse shift rows
    if (n * BLOCK_DIM < size)
        inverse_shift_rows(&s_state[t * BLOCK_DIM]);
    __syncthreads();

    // copying data back to original image array
    for (int k = t * BLOCK_DIM; k < (t + 1) * BLOCK_DIM; k++) {
        int n_index = k + b * THREAD_NUM * BLOCK_DIM;
        if (n_index < size)
            image[n_index] = s_state[k];
    }
    __syncthreads();
}


/*
 * Main function
 *
 * Arguments: 
 *      ./aes_cuda [path to image] [integer key] [path to encrypted output] [path to decrypted output]
 *
 */
int main(int argc, char *argv[]) {
    cudaSetDevice(4);

    // argument variables
    char *image_path = argv[1];
    int key = atoi(argv[2]);
    char *encrypted_path = argv[3];
    char *decrypted_path = argv[4];

    if (argc < 5 || argc > 5) {
        printf("Error... Needed Arguments: ./aes_serial [path to image] [integer key] [path to encrypted output] [path to decrypted output]\n");
        return -1;
    }

    printf("\n");
    printf("=== DEVICE Encryption/Decryption Results ===\n");
    printf("\n");

    BITMAPINFOHEADER bitmap_info;
    BITMAPFILEHEADER bitmap_file;

    // load original HOST image
    unsigned char *h_image;
    h_image = LoadBitmapFile(image_path, &bitmap_info, &bitmap_file);
    printf("Size of Input Image: %d%s\n", bitmap_info.biSizeImage, " bytes");
    printf("Dimensions of Image in Pixels (x,y): (%d,%d)\n", bitmap_info.biWidth, bitmap_info.biHeight);

    float encode_elapsed_time, decode_elapsed_time;

    cudaEvent_t tic, toc;
    cudaEventCreate(&tic);
    cudaEventCreate(&toc);

    // store image data in device
    unsigned char *c_image;
    // allocate image in device memory
    cudaMalloc((void **)&c_image, bitmap_info.biSizeImage);

    //Copy data from host to device
    cudaMemcpy(c_image, h_image, bitmap_info.biSizeImage, cudaMemcpyHostToDevice);

    // standard image processing thread-block structure
    // number of thread-blocks B
    int B = ceil(bitmap_info.biSizeImage/(THREAD_NUM*BLOCK_DIM));
    // number of threads T
    int T = THREAD_NUM;

    // dim3 G(ceil((float)bitmap_info.biWidth / (BLOCK_SIZE)), ceil((float)bitmap_info.biHeight / (BLOCK_SIZE)));
    // dim3 B(BLOCK_SIZE, BLOCK_SIZE, 1);

    cudaEventRecord(tic);
    // aes_encrypt_naive<<<B, T>>> (c_image, bitmap_info.biSizeImage, key); // encrypt the image
    aes_encrypt_shared<<<B, T>>>(c_image, bitmap_info.biSizeImage, key);
    cudaEventRecord(toc);

    printf("\n");
    cudaEventSynchronize(toc);
    cudaEventElapsedTime(&encode_elapsed_time, tic, toc);
    encode_elapsed_time /= 1.e3;
    printf("Encryption Time: %3.6f sec \n", encode_elapsed_time);
    printf("Encryption Throughput: %3.2f MB/s\n", (double)(bitmap_info.biSizeImage/1.e6)/(encode_elapsed_time));
    printf("\n");

    // Copy encrypted image from device to host
    cudaMemcpy(h_image, c_image, bitmap_info.biSizeImage, cudaMemcpyDeviceToHost);
    ReloadBitmapFile(encrypted_path, h_image, &bitmap_file, &bitmap_info);

    // load encrypted image
    h_image = LoadBitmapFile(encrypted_path, &bitmap_info, &bitmap_file);

    // Copy encrypted image from host to device
    cudaMemcpy(c_image, h_image, bitmap_info.biSizeImage, cudaMemcpyHostToDevice);

    cudaEventRecord(tic);
    // aes_decrypt_naive<<<B, T>>> (c_image, bitmap_info.biSizeImage, key); // decrypt the image
    aes_decrypt_shared<<<B, T>>>(c_image, bitmap_info.biSizeImage, key);
    cudaEventRecord(toc);

    cudaEventSynchronize(toc);
    cudaEventElapsedTime(&decode_elapsed_time, tic, toc);
    decode_elapsed_time /= 1000;
    printf("Decryption Time: %3.6f sec\n", decode_elapsed_time);
    printf("Decryption Throughput: %3.2f MB/s", (double)(bitmap_info.biSizeImage/1.e6)/(decode_elapsed_time));
    printf("\n");

    // Copy decrypted image from device to host
    cudaMemcpy(h_image, c_image, bitmap_info.biSizeImage, cudaMemcpyDeviceToHost);
    ReloadBitmapFile(decrypted_path, h_image, &bitmap_file, &bitmap_info);

    cudaFree(c_image);
    free(h_image);

    printf("\n");

    return 0;
}
