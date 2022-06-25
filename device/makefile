SHELL = /bin/sh

default:
	nvcc -o aes_device aes_device.cu
	
boats:
	./aes_device images/boats_bw.bmp 10010011 image_output/encrypted_boats_bw.bmp image_output/decrypted_boats_bw.bmp
	
peppers:
	./aes_device images/peppers.bmp 96 image_output/encrypted_peppers.bmp image_output/decrypted_peppers.bmp
	
lena:
	./aes_device images/lena.bmp 96 image_output/encrypted_lena.bmp image_output/decrypted_lena.bmp
	
roses:
	./aes_device images/roses.bmp 96 image_output/encrypted_roses.bmp image_output/decrypted_roses.bmp
	
dude:
	./aes_device images/dude_bw.bmp 420 image_output/encrypted_dude.bmp image_output/decrypted_dude_bw.bmp

altitude:
	./aes_device images/altitude.bmp 123456 image_output/encrypted_altitude.bmp image_output/decrypted_altitude.bmp

small_test:
	./aes_device images/small.bmp 123456 image_output/encrypted_small.bmp image_output/decrypted_small.bmp

medium_test:
	./aes_device images/medium.bmp 123456 image_output/encrypted_medium.bmp image_output/decrypted_medium.bmp

large_test:
	./aes_device images/large.bmp 123456 image_output/encrypted_large.bmp image_output/decrypted_large.bmp

x_large_test:
	./aes_device images/x-large.bmp 123456 image_output/encrypted_x-large.bmp image_output/decrypted_x-large.bmp

nvprof_example:
	nvprof --metrics all --log-file nvprof_sample.txt  ./aes_device images/peppers.bmp 96 image_output/encrypted_peppers.bmp image_output/decrypted_lena.bmp

	
clean:
	rm aes_device

clean_images:
	rm image_output/*.bmp

clean_samples:
	rm nvprof_sample.txt 
