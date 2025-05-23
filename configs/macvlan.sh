# --- Helper functions ---

# Function to clean up the namespace if it exists.
function cleanup_macvlan_up_outside() {
  echo "Executing cleanup due to script failure or exit signal..." >&2
  if /usr/sbin/ip netns list | grep -q -E "^${NS_NAME}(\s|$)"; then
    if /usr/sbin/ip netns exec "${NS_NAME}" /usr/sbin/ip link show "${MACVLAN_IFNAME}" > /dev/null 2>&1; then
      echo "Attempting to move ${MACVLAN_IFNAME} back to default ns during cleanup..." >&2
      /usr/sbin/ip netns exec "${NS_NAME}" /usr/sbin/ip link set dev "${MACVLAN_IFNAME}" netns 1 || true
    fi
  else
     echo "Namespace ${NS_NAME} not found during cleanup." >&2
  fi
  if /usr/sbin/ip link show "${MACVLAN_IFNAME}" > /dev/null 2>&1; then
    echo "Attempting to delete ${MACVLAN_IFNAME}..."
    /usr/sbin/ip link delete ${MACVLAN_IFNAME} || true
  fi
}

# --- Bring macvlan up ---

function configure_macvlan_up_outside() {
  NS_NAME="$1"

  assert_non_empty MACVLAN_PARENT_IFNAME
  assert_non_empty MACVLAN_IFNAME
  assert_non_empty MACVLAN_MODE

  local result=0
  export -f cleanup_macvlan_up_outside

  (
    trap cleanup_macvlan_up_outside ERR
    set -e

    echo "Creating MACVLAN interface ${MACVLAN_IFNAME} with parent ${MACVLAN_IFNAME} and mode ${MACVLAN_MODE}..."
    # Check if MAC address is specified.
    if [[ -n "${MACVLAN_MAC:-}" ]]; then
      /usr/sbin/ip link add link "${MACVLAN_PARENT_IFNAME}" name "${MACVLAN_IFNAME}" address "${MACVLAN_MAC}" type macvlan mode "${MACVLAN_MODE}"
    else
      /usr/sbin/ip link add link "${MACVLAN_PARENT_IFNAME}" name "${MACVLAN_IFNAME}" type macvlan mode "${MACVLAN_MODE}"
    fi

    echo "Moving interface ${MACVLAN_IFNAME} to namespace ${NS_NAME}..."
    /usr/sbin/ip link set dev "${MACVLAN_IFNAME}" netns "${NS_NAME}"
  )

  result=$?
  return $result
}

function configure_macvlan_up_inside() {
  NS_NAME="$1"

  assert_non_empty MACVLAN_IFADDR
  assert_non_empty MACVLAN_GATEWAY
   
  echo "Bringing interface ${MACVLAN_IFNAME} UP inside namespace ${NS_NAME}..."
  /usr/sbin/ip link set dev "${MACVLAN_IFNAME}" up

  echo "Adding address ${MACVLAN_IFADDR} to ${MACVLAN_IFNAME} inside namespace ${NS_NAME}..."
  /usr/sbin/ip address add ${MACVLAN_IFADDR} dev "${MACVLAN_IFNAME}"
   
  echo "Adding default route via ${MACVLAN_GATEWAY} inside namespace ${NS_NAME}..."
  /usr/sbin/ip route add default via "${MACVLAN_GATEWAY}" dev "${MACVLAN_IFNAME}"
}

# --- Bring macvlan down ---

function configure_macvlan_down_inside() {
  NS_NAME="$1"
   
  echo "Bringing interface ${MACVLAN_IFNAME} DOWN inside namespace ${NS_NAME}..."
  /usr/sbin/ip link set dev "${MACVLAN_IFNAME}" down
}

function configure_macvlan_down_outside() {
  NS_NAME="$1"

  echo "Moving interfacec ${MACVLAN_IFNAME} back to global namespace..."
  /usr/sbin/ip netns exec ${NS_NAME} /usr/sbin/ip link set dev "${MACVLAN_IFNAME}" netns 1

  echo "Deleting interface ${MACVLAN_IFNAME}..."
  /usr/sbin/ip link delete ${MACVLAN_IFNAME}
}
