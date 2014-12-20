EFIFILES = HelloWorld.efi LockDown.efi Loader.efi ReadVars.efi UpdateVars.efi \
	KeyTool.efi HashTool.efi PreLoader.efi SetNull.efi
BINARIES = cert-to-efi-sig-list sig-list-to-certs sign-efi-sig-list \
	hash-to-efi-sig-list efi-readvar efi-updatevar

MSGUID = 77FA9ABD-0359-4D32-BD60-28F4E78F784B

export TOPDIR	:= $(shell pwd)/

include Make.rules

EFISIGNED = $(patsubst %.efi,%-signed.efi,$(EFIFILES))

all: $(EFISIGNED) $(BINARIES) $(MANPAGES) noPK.auth KEK-update.auth \
	DB-update.auth ms-uefi-update.auth DB-pkupdate.auth \
	ms-uefi-pkupdate.auth DB-blacklist.auth ms-uefi-blacklist.auth \
	DB-pkblacklist.auth ms-uefi-pkblacklist.auth \
	ms-kek-pkupdate.auth


install: all
	$(INSTALL) -m 755 -d $(MANDIR)
	$(INSTALL) -m 644 $(MANPAGES) $(MANDIR)
	$(INSTALL) -m 755 -d $(EFIDIR)
	$(INSTALL) -m 755 $(EFIFILES) $(EFIDIR)
	$(INSTALL) -m 755 -d $(BINDIR)
	$(INSTALL) -m 755 $(BINARIES) $(BINDIR)
	$(INSTALL) -m 755 mkusb.sh $(BINDIR)/efitool-mkusb
	$(INSTALL) -m 755 -d $(DOCDIR)
	$(INSTALL) -m 644 README COPYING $(DOCDIR)

lib/lib.a lib/lib-efi.a: FORCE
	$(MAKE) -C lib $(notdir $@)

lib/asn1/libasn1.a lib/asn1/libasn1-efi.a: FORCE
	$(MAKE) -C lib/asn1 $(notdir $@)

.SUFFIXES: .crt

.KEEP: PK.crt KEK.crt DB.crt PK.key KEK.key DB.key PK.esl DB.esl KEK.esl \
	$(EFIFILES)

LockDown.o: PK.h KEK.h DB.h
PreLoader.o: hashlist.h

PK.h: PK.auth

KEK.h: KEK.auth

DB.h: DB.auth

noPK.esl:
	> noPK.esl

noPK.auth: noPK.esl PK.crt sign-efi-sig-list
	./sign-efi-sig-list -t "$(shell date --date='1 second' +'%Y-%m-%d %H:%M:%S')" -c PK.crt -k PK.key PK $< $@

ms-%.esl: ms-%.crt cert-to-efi-sig-list
	./cert-to-efi-sig-list -g $(MSGUID) $< $@

hashlist.h: HashTool.hash
	cat $^ > /tmp/tmp.hash
	./xxdi.pl /tmp/tmp.hash > $@
	rm -f /tmp/tmp.hash


Loader.so: lib/lib-efi.a
ReadVars.so: lib/lib-efi.a lib/asn1/libasn1-efi.a
UpdateVars.so: lib/lib-efi.a
LockDown.so: lib/lib-efi.a
KeyTool.so: lib/lib-efi.a lib/asn1/libasn1-efi.a
HashTool.so: lib/lib-efi.a
PreLoader.so: lib/lib-efi.a
HelloWorld.so: lib/lib-efi.a

cert-to-efi-sig-list: cert-to-efi-sig-list.o lib/lib.a
	$(CC) -o $@ $< -lcrypto lib/lib.a

sig-list-to-certs: sig-list-to-certs.o lib/lib.a
	$(CC) -o $@ $< -lcrypto lib/lib.a

sign-efi-sig-list: sign-efi-sig-list.o lib/lib.a
	$(CC) -o $@ $< -lcrypto lib/lib.a

hash-to-efi-sig-list: hash-to-efi-sig-list.o lib/lib.a
	$(CC) -o $@ $< lib/lib.a

efi-keytool: efi-keytool.o lib/lib.a
	$(CC) -o $@ $< lib/lib.a

efi-readvar: efi-readvar.o lib/lib.a
	$(CC) -o $@ $< -lcrypto lib/lib.a

efi-updatevar: efi-updatevar.o lib/lib.a
	$(CC) -o $@ $< -lcrypto lib/lib.a

clean:
	rm -f PK.* KEK.* DB.* $(EFIFILES) $(EFISIGNED) $(BINARIES) *.o *.so
	rm -f noPK.*
	rm -f doc/*.1
	$(MAKE) -C lib clean

FORCE:



