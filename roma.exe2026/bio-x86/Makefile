NASM = nasm

all: bio-db.com bio-fd.com

bio-db.com: bio.asm
	$(NASM) -ddosbox -o $@ $<

bio-fd.com: bio.asm
	$(NASM) -dfreedos -o $@ $<

clean:
	rm bio-db.com bio-fd.com

cleaner: clean
	rm -f *~
