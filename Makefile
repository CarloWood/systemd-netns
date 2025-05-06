.PHONY: all install uninstall

LIBDIR ?= /usr/lib

# Define the destination directory for clarity
DEST_CONF_DIR = $(DESTDIR)/etc/conf.d/netns

all:

install_configs:
	@echo "Installing configuration files to $(DEST_CONF_DIR)..."
	# Ensure the destination directory exists. Use quotes.
	install -d --owner=root --group=root "$(DEST_CONF_DIR)"
	# Run over all .conf files in configs/ and install files that do not already exist in the destination.
	@find configs -maxdepth 1 -name '*.conf' -exec sh -c ' \
	    src_file="$$1"; \
	    dest_dir="$$2"; \
	    if [ -z "$$dest_dir" ]; then \
	        echo "ERROR: Destination directory argument is empty!" >&2; \
	        exit 1; \
	    fi; \
	    filename=$$(basename "$$src_file"); \
	    dest_file="$$dest_dir/$$filename"; \
	    if [ ! -e "$$dest_file" ]; then \
	        echo "Installing '\''$$src_file'\'' to '\''$$dest_file'\'' (new)"; \
	        install --owner=root --group=root --mode=644 "$$src_file" "$$dest_file"; \
	    else \
	        echo "Skipping '\''$$src_file'\'' ('\''$$dest_file'\'' already exists)"; \
	    fi \
	' _ {} "$(DEST_CONF_DIR)" \; # Pass $(DEST_CONF_DIR) as the second argument

install: install_configs
	install --directory $(DESTDIR)/$(LIBDIR)/systemd/system $(DESTDIR)/etc/conf.d/netns $(DESTDIR)/usr/bin $(DESTDIR)/usr/sbin
	install --owner=root --group=root --mode=644 services/netns@.service $(DESTDIR)/$(LIBDIR)/systemd/system/
	install --owner=root --group=root --mode=644 services/netns_name@.service $(DESTDIR)/$(LIBDIR)/systemd/system/
	install --owner=root --group=root --mode=644 services/netns_outside@.service $(DESTDIR)/$(LIBDIR)/systemd/system/
	install --owner=root --group=root --mode=755 scripts/netnsinit $(DESTDIR)/usr/sbin/
	install --owner=root --group=root --mode=755 scripts/netnsupdate $(DESTDIR)/usr/sbin/
	/usr/sbin/netnsupdate --daemon-reload

uninstall:
	systemctl disable --now "netns@" || true
	systemctl disable --now "netns_outside@" || true
	systemctl disable --now "netns_name@" || true

	/usr/sbin/netnsupdate --clean
	rm -f $(DESTDIR)/$(LIBDIR)/systemd/system/netns@.service
	rm -f $(DESTDIR)/$(LIBDIR)/systemd/system/netns_outside@.service
	rm -f $(DESTDIR)/$(LIBDIR)/systemd/system/netns_name@.service
	rm -f $(DESTDIR)/usr/sbin/netnsinit
	rm -f $(DESTDIR)/usr/sbin/netnsupdate
