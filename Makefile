fnx6809test: fnx6809test.asm
	lwasm --pragma=pcaspcr,nosymbolcase,condundefzero,undefextern,dollarnotlocal,noforwardrefmax $^ -o$@ --raw
	os9 padrom 8192 $@

clean:
	-rm fnx6809test

upload: fnx6809test
	upload $^ e000

flash: fnx6809test
	flash_sector $3f $^