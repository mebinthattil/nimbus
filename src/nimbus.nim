import os
import strutils
import dotenv
load()

echo("Hello, bsky!")
let PDSHOST=getEnv("PDSHOST", "https://bsky.social")
let BLUESKY_PASSWORD=getEnv("BLUESKY_PASSWORD", "")
let BLUESKY_HANDLE=getEnv("BLUESKY_HANDLE", "")

echo "PDSHOST: ", PDSHOST
echo "BLUESKY_HANDLE: ", BLUESKY_HANDLE
echo "BLUESKY_PASSWORD: ", BLUESKY_PASSWORD