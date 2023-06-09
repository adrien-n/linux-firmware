# This file implements the GNOME Build API:
# http://people.gnome.org/~walters/docs/build-api.txt

FIRMWAREDIR = /lib/firmware

all:

check:
	@./check_whence.py
	@./check_duplicates.sh

install:
	install -d $(DESTDIR)$(FIRMWAREDIR)
	./copy-firmware.sh $(DESTDIR)$(FIRMWAREDIR)
