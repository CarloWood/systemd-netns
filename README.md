# systemd-netns

This project enables you to
 * Run an application inside a named network namespace as a systemd service.
 * Configure the netns with possible network interfaces using configuration files in `/etc/conf.d/netns/`.

## Installation

Dependencies:
 * Recent version of systemd
 * iproute2

For installation, run `make [DESTDIR=/somepath...] install` with root privilege.

You can run `make [DESTDIR=/somepath...] uninstall` to remove the systemd units.
The configs located in `$DESTDIR/etc/conf.d/netns/` will not be removed.

## Usage

Below `NSTYPE` and `NSNAME` are arbitrary strings existing of alpha-numerical
characters. The latter might be used as part of a device name, so keep them
short as well. `NSNAME` is the instance of a service and will be used as the
netns (network namespace). `NSTYPE` must exist as `NSTYPE.conf` in `/etc/conf.d/netns`
which defines what it does.

To add a new `NSTYPE` create a configuration file `/etc/conf.d/netns/NSTYPE.conf`.
Optionally, create a file `/etc/conf.d/netns/NSTYPE-NSNAME.conf` that will only
be sourced for the network namespace `NSNAME`.

Run `/usr/sbin/netnsupdate`. This must be done every time you add (or remove)
a `/etc/conf.d/netns/NSTYPE.conf` file (not necessary if you just edit a `.conf` file).

The contents of both `.conf` files together must specify the following bash
functions. Normally these would be defined in `/etc/conf.d/netns/NSTYPE.conf`.

```shell
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
When starting a service, `configure_NSTYPE_up_outside` is called first then `configure_NSTYPE_up_inside`.
When stopping the service `configure_NSTYPE_down_inside` is called first and then `configure_NSTYPE_down_outside`.

All functions have the network namespace passed as the first argument.
It is recommended to use `NS_NAME="$1"` at the top of a function if
the network namespace name is required.

To start a service for network namespace `NSNAME`, run:
```shell
systemctl start netns-NSTYPE@NSNAME.service
```

As usual, use `systemctl enable netns-NSTYPE@NSNAME.service` to start it at boot.

### Network Namespaces (netns) must be managed by systemd

Note that `NSNAME` can not be an externally created netns; the netns must be created by
systemd using the unit `netns_name@NSNAME.service`, which is taken care of under the
hood by this package. Trying to use an already existing named network namespace will
result in a failure to start the service. For example,
```
$ ip netns add nsfoo
$ systemctl start netns-macvlan@nsfoo
A dependency job for netns-macvlan@nsfoo.service failed. See 'journalctl -xe' for details.
$ journalctl -e
May 04 01:20:41 daniel systemd[1]: Starting Create network namespace nsfoo...
May 04 01:20:41 daniel ip[113874]: Cannot create namespace file "/var/run/netns/nsfoo": File exists
May 04 01:20:41 daniel systemd[1]: netns_name@nsfoo.service: Main process exited, code=exited, status=1/FAILURE
May 04 01:20:41 daniel systemd[1]: netns_name@nsfoo.service: Failed with result 'exit-code'.
May 04 01:20:41 daniel systemd[1]: Failed to start Create network namespace nsfoo.
May 04 01:20:41 daniel systemd[1]: Dependency failed for Setup macvlan for, but outside, network namespace nsfoo.
May 04 01:20:41 daniel systemd[1]: Dependency failed for Setup macvlan inside network namespace nsfoo.
May 04 01:20:41 daniel systemd[1]: netns-macvlan@nsfoo.service: Job netns-macvlan@nsfoo.service/start failed with result 'dependency'.
May 04 01:20:41 daniel systemd[1]: netns_outside-macvlan@nsfoo.service: Job netns_outside-macvlan@nsfoo.service/start failed with result 'dependency'.
```

## Provided NSTYPE's

### MACVLAN (`netns-macvlan@NSNAME.service`)

A [MACVLAN Bridge](https://developers.redhat.com/blog/2018/10/22/introduction-to-linux-interfaces-for-virtual-networking/#macvlan)
allows you to create multiple interfaces with different Layer 2 (that is, Ethernet MAC)
addresses on top of a single NIC. MACVLAN is a bridge without an explicit bridge device. 

### VETH (`netns-veth@NSNAME.service`)

A Virtual Ethernet patch cable or [VETH](https://developers.redhat.com/blog/2018/10/22/introduction-to-linux-interfaces-for-virtual-networking/#veth)
for short, are a pair of devices where packets transmitted on one device are immediately received on the other device.

When using `netns-veth@NSNAME.service`, one device (called `${IFNAME_OUTSIDE}`, or if that isn't defined defaulting to `${VETH_IFNAME}-${NS_NAME}0`)
is put in the host namespace and the other (called `${IFNAME_INSIDE}`, or if that isn't defined defaulting to `${VETH_IFNAME}-${NS_NAME}1`) is put
in the netns `NSNAME`.

It is possible to put the first device also in a netns by defining `NSNAME_OUTSIDE` (in, for example, `/etc/conf.d/netns/veth-NSNAME.conf`)
but then one must assure that `netns_name@NSNAME_OUTSIDE.service` is active before `netns_outside-veth@NSNAME.service` is activated.
This can be done as follows:

```shell
$ sudo systemctl edit netns_outside-veth@NSNAME.service
```
and add
```
[Unit]
Requires=netns_name@NSNAME_OUTSIDE.service
```

