SHELL = /bin/sh

default:
	nvcc -o aes_host aes_host.cu
	
boats:
	./aes_host images/boats.bmp 10010011 image_output/encrypted_boats.bmp image_output/decrypted_boats.bmp
	
peppers:
	./aes_host images/peppers.bmp 96 image_output/encrypted_peppers.bmp image_output/decrypted_peppers.bmp
	
dude:
	./aes_host images/dude.bmp 420 image_output/encrypted_dude.bmp image_output/decrypted_dude.bmp
	
scorn:
	./aes_host images/scorn.bmp 666 image_output/encrypted_scorn.bmp image_output/decrypted_scorn.bmp

baboon:
	./aes_host images/baboon.bmp 848008 image_output/encrypted_baboon.bmp image_output/decrypted_baboon.bmp
	
altitude:
	./aes_host images/altitude.bmp 123456 image_output/encrypted_altitude.bmp image_output/decrypted_altitude.bmp

small_test:
	./aes_host images/small.bmp 123456 image_output/encrypted_small.bmp image_output/decrypted_small.bmp
	
medium_test:
	./aes_host images/medium.bmp 123456 image_output/encrypted_medium.bmp image_output/decrypted_medium.bmp

large_test:
	./aes_host images/large.bmp 123456 image_output/encrypted_large.bmp image_output/decrypted_large.bmp

x_large_test:
	./aes_host images/x-large.bmp 123456 image_output/encrypted_x-large.bmp image_output/decrypted_x-large.bmp

clean:
	rm aes_host

clean_images:
	rm image_output/*.bmp
