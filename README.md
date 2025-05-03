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

To add an `NSTYPE`, create a configuration file `/etc/conf.d/netns/NSTYPE.conf`.
Optionally, create a file `/etc/conf.d/netns/NSTYPE-NSNAME.conf` that will only
be sourced for the network namespace `NSNAME`.

Run `/usr/sbin/netnsupdate`. This must be done every time you add (or remove)
a `/etc/conf.d/netns/NSTYPE.conf` file.

The contents of both `.conf` files together must specify the following bash
functions:

```
function configure_NSTYPE_up_outside() {
}

function configure_NSTYPE_up_inside() {
}

function configure_NSTYPE_down_inside() {
}

function configure_NSTYPE_down_outside() {
}
```

The `_outside` functions are called while outside the network namespace,
the `_inside` functions are called while inside the network namespace.
When starting a service, `configure_NSTYPE_up_outside` is called first
then `configure_NSTYPE_up_inside`. When stopping the service `configure_NSTYPE_down_inside`
is called first and then `configure_NSTYPE_down_outside`.

All functions have the network namespace passed as the first argument.
It is recommended to use `NS_NAME="$1"` at the top of a function if
the network namespace name is required.

To start a service for network namespace `NSNAME` do, run:
```
systemctl start netns-NSTYPE@NSNAME.service
```

As usual, use `systemctl enable netns-NSTYPE@NSNAME.service` to start it at boot.

Note that `NSNAME` can not be an externally created netns; the netns must be created by
systemd using the unit `netns_name@NSNAME.service`, which is taken care of under the
hood by this package. Trying to use an already existing named network namespace will
result in a failure to start the service. For example,
```shell
$ ip netns add nstor
$ systemctl start netns-macvlan@nstor
A dependency job for netns-macvlan@nstor.service failed. See 'journalctl -xe' for details.
$ journalctl -e
May 04 01:20:41 daniel systemd[1]: Starting Create network namespace nstor...
May 04 01:20:41 daniel ip[113874]: Cannot create namespace file "/var/run/netns/nstor": File exists
May 04 01:20:41 daniel systemd[1]: netns_name@nstor.service: Main process exited, code=exited, status=1/FAILURE
May 04 01:20:41 daniel systemd[1]: netns_name@nstor.service: Failed with result 'exit-code'.
May 04 01:20:41 daniel systemd[1]: Failed to start Create network namespace nstor.
May 04 01:20:41 daniel systemd[1]: Dependency failed for Setup macvlan for, but outside, network namespace nstor.
May 04 01:20:41 daniel systemd[1]: Dependency failed for Setup macvlan inside network namespace nstor.
May 04 01:20:41 daniel systemd[1]: netns-macvlan@nstor.service: Job netns-macvlan@nstor.service/start failed with result 'dependency'.
May 04 01:20:41 daniel systemd[1]: netns_outside-macvlan@nstor.service: Job netns_outside-macvlan@nstor.service/start failed with result 'dependency'.
```

## NS Types

### MACVLAN (`netns-macvlan@NSNAME.service`)

A [MACVLAN Bridge](https://developers.redhat.com/blog/2018/10/22/introduction-to-linux-interfaces-for-virtual-networking/#macvlan)
allows you to create multiple interfaces with different Layer 2 (that is, Ethernet MAC)
addresses on top of a single NIC. MACVLAN is a bridge without an explicit bridge device. 
