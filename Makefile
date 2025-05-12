.PHONY: all install uninstall

LIBDIR ?= /usr/lib
BINDIR ?= /usr/sbin

# Define the destination directories for clarity.
DEST_CONF_DIR = $(DESTDIR)/etc/conf.d/netns
DEST_DATADIR = $(DESTDIR)/usr/share/systemd-netns

all:

install_configs:
	@echo "Installing configuration files to $(DEST_CONF_DIR)..."
	# Ensure the destination directory exists. Use quotes.
	install -d --owner=root --group=root "$(DEST_CONF_DIR)"
	# Run over all .conf files in configs/ and install files that do not already exist in the destination.
	@find configs -maxdepth 1 \( -name '*.conf' -o -name 'nft.rules' \) -exec sh -c ' \
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
	install --directory $(DESTDIR)$(LIBDIR)/systemd/system $(DEST_CONF_DIR) $(DESTDIR)$(BINDIR) $(DEST_DATADIR)
	install --owner=root --group=root --mode=644 services/netns@.service $(DESTDIR)$(LIBDIR)/systemd/system/
	install --owner=root --group=root --mode=644 services/netns_name@.service $(DESTDIR)$(LIBDIR)/systemd/system/
	install --owner=root --group=root --mode=644 services/netns_outside@.service $(DESTDIR)$(LIBDIR)/systemd/system/
	install --owner=root --group=root --mode=644 configs/lo.sh $(DEST_DATADIR)/
	install --owner=root --group=root --mode=644 configs/veth.sh $(DEST_DATADIR)/
	install --owner=root --group=root --mode=644 configs/macvlan.sh $(DEST_DATADIR)/
	install --owner=root --group=root --mode=644 configs/nft.sh $(DEST_DATADIR)/
	install --owner=root --group=root --mode=755 scripts/netnsinit $(DESTDIR)$(BINDIR)
	install --owner=root --group=root --mode=755 scripts/netns-update $(DESTDIR)$(BINDIR)
	install --owner=root --group=root --mode=755 scripts/netns-nft-save $(DESTDIR)$(BINDIR)
	[[ -n "$(DESTDIR)" || "$(LIBDIR)" != "/usr/lib" ]] || $(BINDIR)/netns-update --daemon-reload

uninstall:
	systemctl disable --now "netns@" || true
	systemctl disable --now "netns_outside@" || true
	systemctl disable --now "netns_name@" || true

	[[ -n "$(DESTDIR)" || "$(LIBDIR)" != "/usr/lib" ]] || $(BINDIR)/netns-update --clean
	rm -f $(DESTDIR)$(LIBDIR)/systemd/system/netns@.service
	rm -f $(DESTDIR)$(LIBDIR)/systemd/system/netns_outside@.service
	rm -f $(DESTDIR)$(LIBDIR)/systemd/system/netns_name@.service
	rm -f $(DEST_DATADIR)/lo.sh
	rm -f $(DEST_DATADIR)/veth.sh
	rm -f $(DEST_DATADIR)/macvlan.sh
	rm -f $(DEST_DATADIR)/nft.sh
	rm -f $(DESTDIR)$(BINDIR)/netnsinit
	rm -f $(DESTDIR)$(BINDIR)/netns-update
	rm -f $(DESTDIR)$(BINDIR)/netns-nft-save
