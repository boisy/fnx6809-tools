fnx6809test: fnx6809test.asm
	lwasm $^ -o$@ --raw
	os9 padrom 8192 $@
          
clean:
	-rm fnx6809test
	
upload: fnx6809test
	upload $^ e000