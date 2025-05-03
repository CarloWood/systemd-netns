.PHONY: all install uninstall

LIBDIR ?= /usr/lib

all:
	

install:
	install --directory $(DESTDIR)/$(LIBDIR)/systemd/system $(DESTDIR)/etc/conf.d/netns $(DESTDIR)/usr/bin $(DESTDIR)/usr/sbin
	install --owner=root --group=root --mode=644 services/netns@.service $(DESTDIR)/$(LIBDIR)/systemd/system/
	install --owner=root --group=root --mode=644 services/netns_name@.service $(DESTDIR)/$(LIBDIR)/systemd/system/
	install --owner=root --group=root --mode=644 services/netns_outside@.service $(DESTDIR)/$(LIBDIR)/systemd/system/
	install --owner=root --group=root --mode=644 configs/default.conf $(DESTDIR)/etc/conf.d/netns/
	install --owner=root --group=root --mode=644 configs/nat.conf $(DESTDIR)/etc/conf.d/netns/
	install --owner=root --group=root --mode=755 scripts/netnsinit $(DESTDIR)/usr/sbin/
	install --owner=root --group=root --mode=755 scripts/netnsupdate $(DESTDIR)/usr/sbin/
	/usr/sbin/netnsupdate
	systemctl daemon-reload || true

uninstall:
	systemctl disable --now "netns@" || true
	systemctl disable --now "netns_outside@" || true
	systemctl disable --now "netns_name@" || true

	rm -f $(DESTDIR)/$(LIBDIR)/systemd/system/netns@.service
	rm -f $(DESTDIR)/$(LIBDIR)/systemd/system/netns_outside@.service
	rm -f $(DESTDIR)/$(LIBDIR)/systemd/system/netns_name@.service
	rm -f $(DESTDIR)/usr/sbin/netnsinit
	rm -f $(DESTDIR)/usr/sbin/netnsupdate
