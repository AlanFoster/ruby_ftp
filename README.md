# RubyFtp

Simple ftp client written in Ruby to learn more about the protocol.
Definitely not production ready or feature complete.

Implemented following the spec: https://tools.ietf.org/html/rfc959

## Usage

Running a docker ftp server which serves files from the host machine's `/tmp/ftp` directory

```
docker run -it -e LOG_STDOUT=YES -e FTP_USER=ftpuser -e FTP_PASS=ftpuser -e PASV_ENABLE=YES -e PASV_MIN_PORT=30000 -e PASV_MAX_PORT=30009 -e FTP_USER_HOME=/home/vsftpd -p 30000-30009:30000-30009 -p 20:20 -p 21:21 -v $(pwd)/ftp:/home/vsftpd/ftpuser --rm fauria/vsftpd
```

Simple example:

```
$ ruby ./examples/example.rb
Connecting to 21 127.0.0.1
client.banner:
220 (vsFTPd 3.0.2)

client.help:
530 Please login with USER and PASS.

client.login:
230 Login successful.

client.pwd:
257 "/"

client.ls:
150 Here comes the directory listing.
226 Directory send OK.
-rw-r--r--    1 ftp      ftp             4 Apr 06 00:16 abc.txt

client.cat:
150 Opening BINARY mode data connection for abc.txt (4 bytes).
226 Transfer complete.
abc
```
