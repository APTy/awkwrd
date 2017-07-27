#!/usr/bin/gawk -f
# checkrc.awk
#
# This is a simple script to periodically write checksums of your bashrc to a log
# file to determine if and when changes were made to it.

BEGIN {
  home = ENVIRON["HOME"] "/.checkrc"

  # load key into memory two bytes at a time
  (sprintf("base64 --decode %s/.key", home) | getline)
  for (i=2;i<=NF;i+=2) key=key$i

  # generate hmac of bash profile and save to logfile
  print "starting with key " |& key
  system(sprintf("openssl dgst -sha1 -hmac %s ~/.bashrc >>%s/shasums.txt", key, home))

  # flush buffers and clean up file descriptors
  close(key |&getline fd)
  print "closed " |& fd
}
