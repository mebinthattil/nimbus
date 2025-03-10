import os
import strutils
import httpclient, json
import times
import dotenv

load()

# TODO: Baseless methods??
type 
  Nimbus = object
    PdsHost: string
    BlueskyHandle: string
    AppPassword: string
    AccessJwt: string
    Editor: string

method editor(n: Nimbus): bool = 
  return n.Editor != ""

method setState(n: var Nimbus, PdsHost, BlueskyHandle, AppPassword, 
  Editor: string): bool =
  if BlueskyHandle == "" or AppPassword == "":
    echo "[ERROR]: BLUESKY_HANDLE or APP_PASSWORD is missing from .env file"
    return false

  n.PdsHost = PdsHost
  n.BlueskyHandle = BlueskyHandle
  n.AppPassword = AppPassword
  n.Editor = Editor

  return true

# Fetch access token
method authenticate(n: var Nimbus, client: var HttpClient): bool =
  let authPayload = %*{
    "identifier": n.BlueskyHandle,
    "password": n.AppPassword
  }

  let authResponse = client.request(
    n.PdsHost & "/xrpc/com.atproto.server.createSession",
    httpMethod = HttpPost,
    body = authPayload.pretty
  )

  if authResponse.code != Http200:
    echo "[ERROR]: Failed to authenticate. Response: " & authResponse.body
    return false

  let authJson = parseJson(authResponse.body)

  n.AccessJwt = authJson["accessJwt"].getStr()
  return true

method clearState(n: Nimbus): bool = 
  return true

# Get required environment variables
proc getCredentials(): (string, string, string, string) =
  let PDSHOST = getEnv("PDSHOST", "https://bsky.social")
  let BLUESKY_HANDLE = getEnv("BLUESKY_HANDLE", "")
  let APP_PASSWORD = getEnv("APP_PASSWORD", "")
  let EDITOR = getEnv("EDITOR", "");

  return (PDSHOST, BLUESKY_HANDLE, APP_PASSWORD, EDITOR)

# Prompt user for a message
proc promptForMessage(): string =
  stdout.write("[INFO]: Enter your message: ")
  return readLine(stdin).strip()

# Create a post on Bluesky and display the post link
method createPost(n: Nimbus, client: var HttpClient, message: string) =
  client.headers["Authorization"] = "Bearer " & n.AccessJwt

  let postPayload = %*{
    "repo": n.BlueskyHandle,
    "collection": "app.bsky.feed.post",
    "record": %*{
      "text": message,
      "createdAt": format(now(), "yyyy-MM-dd'T'HH:mm:ss'Z'")
    }
  }

  let postResponse = client.request(
    n.PdsHost & "/xrpc/com.atproto.repo.createRecord",
    httpMethod = HttpPost,
    body = postPayload.pretty
  )

  if postResponse.code != Http200:
    quit("[ERROR]: Failed to create post. Response: " & postResponse.body, 1)

  let postJson = parseJson(postResponse.body)
  let uri = postJson["uri"].getStr()
  let postId = uri.split("/")[^1]

  echo "[INFO]: Post successful: https://bsky.app/profile/" & n.BlueskyHandle &
      "/post/" & postId

# Main function
proc main() =
  let (PDSHOST, BLUESKY_HANDLE, APP_PASSWORD, EDITOR) = getCredentials()

  if EDITOR == "":
    echo "[INFO]: No Editor set, defaulting to STDIN"

  var client = newHttpClient()
  client.headers = newHttpHeaders({"Content-Type": "application/json"})

  var nimbus: Nimbus 
  if not nimbus.setState(PDSHOST, BLUESKY_HANDLE, APP_PASSWORD, EDITOR):
    quit("[ERROR]: Failed to intialize Nimbus state!", 1)

  try:
    if not nimbus.authenticate(client):
      #quit("[ERROR]: Failed to authenticate. Response: " & authResponse.body, 1)
      quit("[ERROR]: Failed to authenticate. Response: ", 1)

    let message = promptForMessage()
    if message == "":
      quit("[ERROR]: Message cannot be empty.", 1)

    nimbus.createPost(client, message)
  finally:
    client.close()

main()
