# --- Helper functions ---

# Function to clean up the namespace if it exists.
function cleanup_veth_up_outside() {
  echo "Executing cleanup due to script failure or exit signal..." >&2
  if /usr/sbin/ip link show "${VETH_IFNAME_OUTSIDE}" > /dev/null 2>&1; then
    echo "Attempting to delete VETH interface ${VETH_IFNAME_OUTSIDE} (and its peer ${VETH_IFNAME_INSIDE})..." >&2
    /usr/sbin/ip link delete "${VETH_IFNAME_OUTSIDE}" || true
  fi
}

function set_ifnames() {
  # Use "ve-" as prefix by default if VETH_IFNAME isn't already set. Note that you are allowed to set it to an empty string.
  if ! [[ -v VETH_IFNAME ]]; then
    VETH_IFNAME="ve-"
  fi

  # Allow these to be already set from /etc/conf.d/netns/veth-NSNAME.conf
  if [[ -z "${VETH_IFNAME_OUTSIDE}" ]]; then
    VETH_IFNAME_OUTSIDE="${VETH_IFNAME}${NS_NAME}0"
  fi
  if [[ -z "${VETH_IFNAME_INSIDE}" ]]; then
    VETH_IFNAME_INSIDE="${VETH_IFNAME}${NS_NAME}1"
  fi
}

# --- Bring veth up ---

function configure_veth_up_outside() {
  NS_NAME="$1"

  # This variable must be set in /etc/conf.d/netns/veth-NSNAME.conf.
  assert_non_empty VETH_IFADDR_OUTSIDE

  # Make sure VETH_IFNAME_OUTSIDE and VETH_IFNAME_INSIDE are set.
  set_ifnames

  local result=0
  export -f cleanup_veth_up_outside

  (
    trap cleanup_veth_up_outside ERR
    set -e

    # Create a pair of virtual network interfaces that act like a direct virtual patch cable.
    chnetns_outside=""
    if [[ -n "${VETH_NSNAME_OUTSIDE}" ]]; then
      echo "Creating a VETH pair with interfaces ${VETH_IFNAME_OUTSIDE} (in netns ${VETH_NSNAME_OUTSIDE}) and ${VETH_IFNAME_INSIDE} (in netns ${NS_NAME})..."
      /usr/sbin/ip link add "${VETH_IFNAME_OUTSIDE}" netns "${VETH_NSNAME_OUTSIDE}" type veth peer name "${VETH_IFNAME_INSIDE}" netns "${NS_NAME}"
      chnetns_outside="/usr/sbin/ip netns exec ${VETH_NSNAME_OUTSIDE}"
    else
      echo "Creating a VETH pair with interfaces ${VETH_IFNAME_OUTSIDE} and ${VETH_IFNAME_INSIDE} (in netns ${NS_NAME})..."
      /usr/sbin/ip link add "${VETH_IFNAME_OUTSIDE}" type veth peer name "${VETH_IFNAME_INSIDE}" netns "${NS_NAME}"
    fi

    # Apply MAC address if specified.
    if [[ -n "${VETH_MAC_OUTSIDE:-}" ]]; then
      eval ${chnetns_outside} /usr/sbin/ip link set "${VETH_IFNAME_OUTSIDE}" address "${VETH_MAC_OUTSIDE}"
    fi

    echo "Bringing interface ${VETH_IFNAME_OUTSIDE} UP..."
    eval ${chnetns_outside} /usr/sbin/ip link set dev "${VETH_IFNAME_OUTSIDE}" up

    echo "Adding address ${VETH_IFADDR_OUTSIDE} to ${VETH_IFNAME_OUTSIDE}..."
    eval ${chnetns_outside} /usr/sbin/ip address add "${VETH_IFADDR_OUTSIDE}" dev "${VETH_IFNAME_OUTSIDE}"
  )

  result=$?
  return $result
}

function configure_veth_up_inside() {
  NS_NAME="$1"

  # This variable must be set in /etc/conf.d/netns/veth-NSNAME.conf.
  assert_non_empty VETH_IFADDR_INSIDE

  # Make sure VETH_IFNAME_INSIDE is set.
  set_ifnames

  # Remove a potential Queuing Discipline added by the kernel.
  ! tc qdisc del dev "${VETH_IFNAME_INSIDE}" root

  # Apply MAC address if specified.
  if [[ -n "${VETH_MAC_INSIDE:-}" ]]; then
    /usr/sbin/ip link set "${VETH_IFNAME_INSIDE}" address "${VETH_MAC_INSIDE}"
  fi
   
  echo "Bringing interface ${VETH_IFNAME_INSIDE} UP inside namespace ${NS_NAME}..."
  /usr/sbin/ip link set dev "${VETH_IFNAME_INSIDE}" up

  echo "Adding address ${VETH_IFADDR_INSIDE} to ${VETH_IFNAME_INSIDE} inside namespace ${NS_NAME}..."
  /usr/sbin/ip address add ${VETH_IFADDR_INSIDE} dev "${VETH_IFNAME_INSIDE}"
}

# --- Bring veth down ---

function configure_veth_down_outside() {
  NS_NAME="$1"

  # Make sure VETH_IFNAME_OUTSIDE is set.
  set_ifnames

  chnetns_outside=""
  if [[ -n "${VETH_NSNAME_OUTSIDE}" ]]; then
    chnetns_outside="/usr/sbin/ip netns exec ${VETH_NSNAME_OUTSIDE}"
  fi

  echo "Deleting interface ${VETH_IFNAME_OUTSIDE}..."
  eval ${chnetns_outside} /usr/sbin/ip link delete ${VETH_IFNAME_OUTSIDE}
}
