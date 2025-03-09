import os
import strutils

proc loadEnvFile(filename: string) =
  if fileExists(filename):
    for line in lines(filename):
      let parts = line.split('=', 1)
      if parts.len == 2:
        putEnv(parts[0].strip(), parts[1].strip())

loadEnvFile(".env")

let PDSHOST = getEnv("PDSHOST", "https://bsky.social")
let BLUESKY_HANDLE = getEnv("BLUESKY_HANDLE", "")
let BLUESKY_PASSWORD = getEnv("BLUESKY_PASSWORD", "")

echo("Hello, bsky!")

echo "PDSHOST: ", PDSHOST
echo "BLUESKY_HANDLE: ", BLUESKY_HANDLE
echo "BLUESKY_PASSWORD: ", BLUESKY_PASSWORD