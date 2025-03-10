# nimbus

bsky client written in [nim]

---

```
nimble run
```

```.env
PDSHOST=https://bsky.social
BLUESKY_HANDLE=foo.bar
APP_PASSWORD=letmein
```

> ref: https://bsky.app/settings/app-passwords

---

For **MacOS** If `openssl` is installed through brew:
``` 
brew install openssl
```
Then export `DY_LD_LIBRARY_PATH` explicitly:
```
export DYLD_LIBRARY_PATH=$(brew --prefix openssl)/lib:$DYLD_LIBRARY_PATH
```
Then run [nimbus]
```
nim -c -d:ssl -o:nimbus src/nimbus.nim
```
