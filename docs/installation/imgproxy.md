---
title: Imgproxy
---

Imgproxy is a standalone server for resizing images. It is optional and you do
not need it to start Forem. We are currently only it using Forem-cloud's
application.

## Installation

On macOS, use homebrew with `brew install imgproxy`. For others, please see the
[official documentation](https://docs.imgproxy.net/#/installation)

## Usage

1. To enable Imgproxy in development, first add
   `export IMGPROXY_ENDPOINT="http://localhost:8080"` to your `.env`
1. Startup Imgproxy in a terminal. If you installed via homebrew, it's
   `imgproxy`.
1. Startup the Forem app.
1. That's it :)

You should verify it's working by checking a user's profile image. It should
have a structure similar to
`http://localhost:8080/unsafe/rs:fill:320:320/aHR0cDovL2xvY2Fs/aG9zdD.......`.
You should also see activities from Imgproxy terminal and all the images should
load.

## Sidenote.

- Because Imgproxy is a standalone server of its own, all images URL given to it
  needs to be an absolute URL.
- When working with docker/podman on Linux, provide the host network option, ie
  `docker run -p 8080:8080 --network="host" -it darthsim/imgproxy` so Imgproxy
  can properly access the localhost.
