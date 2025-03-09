import os
import strutils
import httpclient, json
import times
import dotenv

load()

# Get required environment variables
proc getCredentials(): (string, string, string) =
  let PDSHOST = getEnv("PDSHOST", "https://bsky.social")
  let BLUESKY_HANDLE = getEnv("BLUESKY_HANDLE", "")
  let APP_PASSWORD = getEnv("APP_PASSWORD", "")
  if BLUESKY_HANDLE == "" or APP_PASSWORD == "":
    quit("[ERROR]: BLUESKY_HANDLE or APP_PASSWORD is missing from .env file", 1)
  return (PDSHOST, BLUESKY_HANDLE, APP_PASSWORD)

# Fetch access token
proc authenticate(client: var HttpClient, PDSHOST, BLUESKY_HANDLE,
    APP_PASSWORD: string): string =
  let authPayload = %*{
    "identifier": BLUESKY_HANDLE,
    "password": APP_PASSWORD
  }

  let authResponse = client.request(
    PDSHOST & "/xrpc/com.atproto.server.createSession",
    httpMethod = HttpPost,
    body = authPayload.pretty
  )

  if authResponse.code != Http200:
    quit("[ERROR]: Failed to authenticate. Response: " & authResponse.body, 1)

  let authJson = parseJson(authResponse.body)
  return authJson["accessJwt"].getStr()

# Prompt user for a message
proc promptForMessage(): string =
  stdout.write("[INFO]: Enter your message: ")
  return readLine(stdin).strip()

# Create a post on Bluesky and display the post link
proc createPost(client: var HttpClient, PDSHOST, BLUESKY_HANDLE, accessJwt,
    message: string) =
  client.headers["Authorization"] = "Bearer " & accessJwt

  let postPayload = %*{
    "repo": BLUESKY_HANDLE,
    "collection": "app.bsky.feed.post",
    "record": %*{
      "text": message,
      "createdAt": format(now(), "yyyy-MM-dd'T'HH:mm:ss'Z'")
    }
  }

  let postResponse = client.request(
    PDSHOST & "/xrpc/com.atproto.repo.createRecord",
    httpMethod = HttpPost,
    body = postPayload.pretty
  )

  if postResponse.code != Http200:
    quit("[ERROR]: Failed to create post. Response: " & postResponse.body, 1)

  let postJson = parseJson(postResponse.body)
  let uri = postJson["uri"].getStr()
  let postId = uri.split("/")[^1]

  echo "[INFO]: Post successful: https://bsky.app/profile/" & BLUESKY_HANDLE &
      "/post/" & postId

# Main function
proc main() =
  let (PDSHOST, BLUESKY_HANDLE, APP_PASSWORD) = getCredentials()
  var client = newHttpClient()
  client.headers = newHttpHeaders({"Content-Type": "application/json"})

  try:
    let accessJwt = authenticate(client, PDSHOST, BLUESKY_HANDLE, APP_PASSWORD)
    echo "[AUTH]: Access token received."

    let message = promptForMessage()
    if message == "":
      quit("[ERROR]: Message cannot be empty.", 1)

    createPost(client, PDSHOST, BLUESKY_HANDLE, accessJwt, message)
  finally:
    client.close()

main()
