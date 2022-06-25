# AES Image Encryption with CUDA C

Advanced Encryption Standard (AES) image encryption with CUDA C. Final project for CMDA 4984 SS: Scientific Computing at Scale (Fall 2021) at Virginia Tech.

## Getting Started

### Dependencies

* CUDA-suppoted NVIDIA GPU
    * It is recommended for the in-class live demo to use the Pascal cluster at Virginia Tech.
* CUDA toolkit (nvcc, nvprof, etc.)

### Getting the Source

Simply clone this repository:

```
git clone https://code.vt.edu/craine/aes-image-encryption.git
```

### Executing program

* Change directory into either __device/__ or __host/__
* Following the makefile design:

Compiles main program:
```
make
```

Runs an image test based on some of the images contained in the __.../images/__ directory:
```
make [altitude, baboon, peppers, etc.]
```

Removes CUDA executable:
```
make clean
```

Removes all bitmap images from __.../image_output/__:
```
make clean_images
```

Run an nvprof example and sends the output into a text file:
```
make nvprof_example
```

## Known Issues

* Depending on the device architecture, this software may not operate correctly.
* The naive implementation of the parallel DEVICE encryption kernel does not encode the entire image; shared memory kernels are used instead.

## Author

Camden Landis (craine@vt.edu)
