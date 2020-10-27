---
title: Imgproxy
---

Imgproxy is a standalone server for resizing images. It is optional and you do
not need it to start Forem locally. We are currently only it using Forem Cloud.

## Installation

- MacOS: use homebrew with `brew install imgproxy`.
- Window: please install
  [via docker](https://docs.imgproxy.net/#/installation?id=docker).
- Linux: you can either use
  [docker installation](https://docs.imgproxy.net/#/installation?id=docker) or
  [build from source](https://docs.imgproxy.net/#/installation?id=from-the-source).

For more options not covered here, please take a look at the
[official installation documentation](https://docs.imgproxy.net/#/installation).

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
  need to be an absolute URLs.
- When working with docker/podman on Linux, provide the host network option, ie
  `{docker|podman} run -p 8080:8080 --network="host" -it darthsim/imgproxy` so
  Imgproxy can properly access the localhost.
