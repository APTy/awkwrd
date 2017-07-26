# awkwrd

The `awk` reverse shell. `checkrc.awk` runs on a target host, periodically requesting remote tasks from a command/control server.

## checkrc.awk

This file is run as a cronjob on a target host. It is disguised as a recurring task to take a shasum of some file (like a bashrc) to track when changes are made.

## server.awk

A test server that sends remote tasks to be executed on the target host upon request.

## install.sh

This file can be used to fully install the `checkrc.awk` and its cron component on a target host in a single command.

### Disclaimer

This project is for educational and research purposes only. The author is not
responsible for individuals who misuse these materials for illegal purposes.
