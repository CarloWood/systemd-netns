.PHONY: all install uninstall

LIBDIR ?= /usr/lib

all:
	

install:
	install --directory $(DESTDIR)/$(LIBDIR)/systemd/system $(DESTDIR)/etc/conf.d/netns $(DESTDIR)/usr/bin $(DESTDIR)/usr/sbin
	install --owner=root --group=root --mode=644 services/netns@.service $(DESTDIR)/$(LIBDIR)/systemd/system/
	install --owner=root --group=root --mode=644 services/netns-new@.service $(DESTDIR)/$(LIBDIR)/systemd/system/
	install --owner=root --group=root --mode=644 services/netns-outside@.service $(DESTDIR)/$(LIBDIR)/systemd/system/
	install --owner=root --group=root --mode=644 configs/raw.conf $(DESTDIR)/etc/conf.d/netns/
	install --owner=root --group=root --mode=644 configs/nat.conf $(DESTDIR)/etc/conf.d/netns/
	install --owner=root --group=root --mode=755 scripts/chnetns $(DESTDIR)/usr/bin/
	install --owner=root --group=root --mode=755 scripts/netnsinit $(DESTDIR)/usr/sbin/
	systemctl daemon-reload || true

uninstall:
	systemctl disable --now "netns@" || true
	systemctl disable --now "netns-outside@" || true
	systemctl disable --now "netns-new@" || true

	rm -f $(DESTDIR)/$(LIBDIR)/systemd/system/netns@.service
	rm -f $(DESTDIR)/$(LIBDIR)/systemd/system/netns-outside@.service
	rm -f $(DESTDIR)/$(LIBDIR)/systemd/system/netns-new@.service
	rm -f $(DESTDIR)/usr/bin/chnetns
	rm -f $(DESTDIR)/usr/sbin/netnsinit
