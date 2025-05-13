# No configuration file(s) required.
NO_CONFIG_REQUIRED=1

# --- Bring nft up ---

function configure_nft_up_inside() {
  NS_NAME="$1"
  RULES_FILE="/etc/conf.d/netns/nft-${NS_NAME}.rules"

  if [[ -f "${RULES_FILE}" ]]; then
    # Load the namespace specific nftables rule set.
    nft -f "${RULES_FILE}"
  else
    echo "No netns specific rule set found (${RULES_FILE}), using the default /etc/conf.d/netns/nft.rules."
    nft -f /etc/conf.d/netns/nft.rules
  fi
}

# --- Bring nft down ---

function configure_nft_down_inside() {
  NS_NAME="$1"
  RULES_FILE="/etc/conf.d/netns/nft-${NS_NAME}.rules"

  # One can create a nft-${NS_NAME}.conf file with `NFT_AUTO_SAVE=yes` (not really recommended).
  if [[ "${NFT_AUTO_SAVE}" == "yes" ]]; then
    echo "Automatically saving current nftables rule set to ${RULES_FILE}!"
    netns-nft-save "${NS_NAME}"
  fi
}
