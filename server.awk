#!/usr/bin/gawk -f
# server.awk
#
# A simple TCP server that listens on a port and issues commands to
# anyone that connects to it. Used for testing the checkrc.awk client.

function logger(str) {
  printf "%s: %s\n", strftime("%T"), str
}

BEGIN {
  port = 8888
  listener = sprintf("/inet/tcp/%d/0/0", port)
  logger(sprintf("starting tcp reverse shell server on port %d", port))

  # main loop
  while (1) {

    # listen for connections
    listener |& getline
    logger("received connection")

    # send the remote execution command
    print "echo hello >file.txt" |& listener

    # close the connection
    close(listener)
    logger("sent command")

  }
}
