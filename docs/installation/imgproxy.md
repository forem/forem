---
title: Imgproxy
---

# Imgproxy

Imgproxy is a standalone server for resizing images. It is optional and you do
not need it to start Forem locally. We are currently only using it in Forem
Cloud.

## Installation

- MacOS: install via homebrew with `brew install imgproxy`.
- Windows: please install
  [via docker](https://docs.imgproxy.net/#/installation?id=docker).
- Linux: you can either use
  [docker installation](https://docs.imgproxy.net/#/installation?id=docker) or
  [build from source](https://docs.imgproxy.net/#/installation?id=from-the-source).

For more options not covered here, please take a look at the
[official installation documentation](https://docs.imgproxy.net/#/installation).

## Usage

1. Generate a key/salt pair by running the following in your terminal twice.
   Copy those values to your `.env` in the next step

   ```
   echo $(xxd -g 2 -l 64 -p /dev/random | tr -d '\n')
   ```

1. In your `.env`, add the following.

   ```
   export IMGPROXY_ENDPOINT='http://localhost:8080'
   export IMGPROXY_KEY='1b1c9aae804e070b0864f2547fba7ce8ff31bf7..........'
   export IMGPROXY_SALT='8c6d449d4fc2cada5bab538826cae709d2ade9f.........'
   ```

1. Start the Forem app server normally.

1. Start Imgproxy in a terminal with the key and salt.

   ```
   # If you installed via homebrew or using the binary.
   > IMGPROXY_KEY='your key' IMGPROXY_SALT='your salt' imgproxy

   # If you are using Docker or Podman. The commands are identical for both
   > docker run -p 8080:8080 \
      -e IMGPROXY_KEY="your key" \
      -e IMGPROXY_SALT="your salt" \
      -it darthsim/imgproxy
   ```

1. That's it :)

You should verify it's working by starting the Forem app locally and see that
each image is loaded properly, or run the following command while the Forem app
is running:

```
> curl -I http://localhost:8080/unsafe/aHR0cDovL2xvY2Fs/aG9zdDozMDAwL2Fz/c2V0cy8xLnBuZw

HTTP/1.1 200 OK
Server: imgproxy
X-Request-Id: GYvCGXb98JUwL3ujwpjzh
Date: Tue, 27 Oct 2020 16:11:37 GMT
```

## Sidenote

- Because Imgproxy is a standalone server of its own, all image URLs given to it
  need to be absolute URLs.
- When working with Docker or Podman on Linux, provide the host network option
  (`--network="host"`) so Imgproxy can properly access the localhost.
