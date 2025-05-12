# No configuration file(s) required.
NO_CONFIG_REQUIRED=1

# --- Bring lo up ---

function configure_lo_up_inside() {
  NS_NAME="$1"

  echo "Bringing interface lo UP inside namespace ${NS_NAME}..."
  /usr/sbin/ip link set dev lo up
}

# --- Bring lo down ---

function configure_lo_down_inside() {
  NS_NAME="$1"
   
  echo "Bringing interface lo DOWN inside namespace ${NS_NAME}..."
  /usr/sbin/ip link set dev lo down
}
