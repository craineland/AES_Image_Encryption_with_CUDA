#include <stdio.h>
#include <stdlib.h>

/*
 * bitmap image data processing
 * BMP Support Functions
 * @author Linus Torvalds
 *
 * Based on the original bitmap.c
 */

// =========================================================================

typedef short WORD;
typedef int   DWORD;
typedef int   LONG;

/*
 * structs from original bitmap.c
 */
#pragma pack(push, 1)
typedef struct tagBITMAPFILEHEADER {
    WORD  bfType;  		//specifies the file type
    DWORD bfSize;  		//specifies the size in bytes of the bitmap file
    WORD  bfReserved1;  //reserved; must be 0
    WORD  bfReserved2;  //reserved; must be 0
    DWORD bOffBits;  	//species the offset in bytes from the bitmapfileheader to the bitmap bits
} BITMAPFILEHEADER;
#pragma pack(pop)

#pragma pack(push, 1)
typedef struct tagBITMAPINFOHEADER {
    DWORD biSize;  		   // specifies the number of bytes required by the struct
    LONG  biWidth;  	   // specifies width in pixels
    LONG  biHeight;  	   // species height in pixels
    WORD  biPlanes; 	   // specifies the number of color planes, must be 1
    WORD  biBitCount; 	   // specifies the number of bit per pixel
    DWORD biCompression;   // spcifies the type of compression
    DWORD biSizeImage;     // size of image in bytes
    LONG  biXPelsPerMeter; // number of pixels per meter in x axis
    LONG  biYPelsPerMeter; // number of pixels per meter in y axis
    DWORD biClrUsed;  	   // number of colors used by th ebitmap
    DWORD biClrImportant;  // number of colors that are important
} BITMAPINFOHEADER;
#pragma pack(pop)


/*
 * LoadBitmapFile from original bitmap.c
 */
unsigned char *LoadBitmapFile(char *filename, 
							  BITMAPINFOHEADER *bitmapInfoHeader, 
							  BITMAPFILEHEADER *bitmapFileHeader) {

    FILE 	      *fp;      
    unsigned char *bitmapImage;  
    int 		   imageIdx = 0;
    unsigned char  rgb_swap;  

    fp = fopen(filename,"rb");
    if (fp == NULL) {
    	printf("\nERROR: Cannot open file %s\n", filename);
        return NULL;
    }

    fread(bitmapFileHeader, sizeof(BITMAPFILEHEADER),1,fp);
    
    // conditional check for bitmap file type
    if (bitmapFileHeader->bfType !=0x4D42) {
        fclose(fp);
        return NULL;
    }
    
    // read the bitmap info header
    fread(bitmapInfoHeader, sizeof(BITMAPINFOHEADER),1,fp); // small edit. forgot to add the closing bracket at sizeof

    // move file point to the begging of bitmap data
    fseek(fp, bitmapFileHeader->bOffBits, SEEK_SET);

    // allocate enough memory for the bitmap image data
    bitmapImage = (unsigned char*)malloc(bitmapInfoHeader->biSizeImage);

    // conditional check for memory allocation
    if (!bitmapImage) {
        free(bitmapImage);
        fclose(fp);
        return NULL;
    }

    // read bitmap image data
    fread(bitmapImage,1,bitmapInfoHeader->biSizeImage,fp);

    // conditional check for image data
    if (bitmapImage == NULL) {
        fclose(fp);
        return NULL;
    }

    // swap r and b values to get RGB (bitmap is BGR)
    for (imageIdx = 0; imageIdx < bitmapInfoHeader->biSizeImage; imageIdx+=3) {
        rgb_swap = bitmapImage[imageIdx];
        bitmapImage[imageIdx] = bitmapImage[imageIdx + 2];
        bitmapImage[imageIdx + 2] = rgb_swap;
    }

    fclose(fp);
    return bitmapImage;
}


/*
 * ReloadBitmapFile from original bitmap.c
 */
void ReloadBitmapFile(char *filename, 
					  unsigned char *bitmapImage, 
					  BITMAPFILEHEADER *bitmapFileHeader, 
					  BITMAPINFOHEADER *bitmapInfoHeader) {

    FILE 	      *fp;      
    int 		   imageIdx = 0;
    unsigned char  rgb_swap; 

    // open image
    fp = fopen(filename,"wb");

    // conditional check 
    if (fp == NULL) {
        printf("\nERROR: Cannot open file %s\n", filename);
        exit(1);
    }
    
    // write the bitmap file header
    fwrite(bitmapFileHeader, sizeof(BITMAPFILEHEADER), 1, fp);

    // write the bitmap info header
    fwrite(bitmapInfoHeader, sizeof(BITMAPINFOHEADER), 1, fp);

    // swap r and b values to get RGB (bitmap is BGR)
    for (imageIdx = 0; imageIdx < bitmapInfoHeader->biSizeImage; imageIdx+=3) {
        rgb_swap = bitmapImage[imageIdx];
        bitmapImage[imageIdx] = bitmapImage[imageIdx + 2];
        bitmapImage[imageIdx + 2] = rgb_swap;
    }

    // write image data
    fwrite(bitmapImage, bitmapInfoHeader->biSizeImage, 1, fp);

    fclose(fp);
}