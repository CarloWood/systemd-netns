# systemd-netns

This project enables you to:
 * Run an application inside a named network namespace as a systemd service.
 * Configure the netns using configuration files in /etc/conf.d/netns/.

## Installation

Dependencies:
 * Recent version of systemd
 * iproute2

For installation, run `make install` with root privilege.

You can run `make uninstall` to remove the systemd units, but the configs located in `/etc/conf.d/netns/` will not be removed.

## Usage

To add an NSTYPE, create a configuration file `/etc/conf.d/netns/NSTYPE.conf`.
Optionally, create a file `/etc/conf.d/netns/NSTYPE-NSNAME.conf` that will only
be sourced for the network namespace `NSNAME`.

Run `/usr/sbin/netnsupdate`. This must be done every time you add (or remove)
a `/etc/conf.d/netns/NSTYPE.conf` file.

The contents of both `.conf` files together must specify the following bash
functions:

```
function configure_macvlan_up_outside() {
}

function configure_macvlan_up_inside() {
}

function configure_macvlan_down_inside() {
}

function configure_macvlan_down_outside() {
}
```

The `_outside` functions are called while outside the network namespace,
the `_inside` functions are called while inside the network namespace.
When starting a service, `configure_macvlan_up_outside` is called first
then `configure_macvlan_up_inside`. When stopping the service `configure_macvlan_down_inside`
is called first and then `configure_macvlan_down_outside`.

All functions have the network namespace passed as only argument.
It is recommended to use `NS_NAME="$1"` at the top of a function if
the network namespace name is required.

To start a service for network namespace NSNAME do, run:
```
systemctl start netns-NSTYPE@NSNAME.service
```

As usual, use `systemctl enable netns-NSTYPE@NSNAME.service` to start it at boot.

Note that NSNAME can not be an externally created netns; the netns must be created by
systemd using the unit `netns_name@NSNAME.service`, which is taken care of under the
hood by this package. Trying to use an already existing named network namespace will
result in a failure to start the service. For example,
```shell
FIXME
```

## NS Types

### MACVLAN (`netns-macvlan@NSNAME.service`)

A [MACVLAN Bridge](https://developers.redhat.com/blog/2018/10/22/introduction-to-linux-interfaces-for-virtual-networking/#macvlan)
allows you to create multiple interfaces with different Layer 2 (that is, Ethernet MAC)
addresses on top of a single NIC. MACVLAN is a bridge without an explicit bridge device. 
