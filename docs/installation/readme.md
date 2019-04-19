---
items:
  - linux.md
  - path: mac-os.md
    title: macOS
  - windows.md
---

# Installation Guides For macOS, Linux, and Windows

Below are the guides for installing the app on different operating systems.

These guides could be incorrect or outdated. If you come across anything that needs to be changed, make a PR! Thanks!

# GitPod

You can also [spin up a "local" instance of DEV in the cloud with GitPod (It's incredibly simple)](https://dev.to/ben/spin-up-a-local-instance-of-dev-in-the-cloud-with-gitpod-it-s-incredibly-simple-pij): https://gitpod.io/#https://github.com/thepracticaldev/dev.to

# Docker [Beta]

Our docker implementation is incomplete and may not work smoothly. Please kindly report any issues and any contribution is welcomed!

1. Install `docker` and `docker-compose`
1. `git clone git@github.com:thepracticaldev/dev.to.git`
1. Set environment variables above as described in the "Basic Installation"
1. run `docker-compose build`
1. run `docker-compose run web rails db:setup`
1. run `docker-compose run web yarn install`
1. run `docker-compose up`
1. That's it! Navigate to `localhost:3000`
