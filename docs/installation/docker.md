# Installing DEV with Docker [Beta]

## Installing prerequisites

_These prerequisites assume you're working on an operating system supported by Docker._

### Docker and Docker Compose

Docker is available for many different operating systems. We recommend you follow the [Docker CE install guide](https://docs.docker.com/install/) which illustrates multiple installation options for each OS.

You're also going to need Docker Compose, to start multiple containers. We recommend you follow the [Docker Compose install guide](https://docs.docker.com/compose/install/) as well.

## Installing DEV

1. Fork DEV's repository, eg. <https://github.com/thepracticaldev/dev.to/fork>
1. Clone your forked repository, eg. `git clone https://github.com/<your-username>/dev.to.git`
1. Set up your environment variables/secrets

   - Take a look at `Envfile`. This file lists all the `ENV` variables we use and provides a fake default for any missing keys. You'll need to get your own free [Algolia credentials](/backend/algolia) to get your development environment running.
   - The [backend guide](/backend) will show you how to get free API keys for additional services that may be required to run certain parts of the app.
   - For any key that you wish to enter/replace:

     1. Create `config/application.yml` by copying from the provided template (ie. with bash: `cp config/sample_application.yml config/application.yml`). This is a personal file that is ignored in git.
     1. Obtain the development variable and apply the key you wish to enter/replace. ie:

     ```shell
     GITHUB_KEY: "SOME_REAL_SECURE_KEY_HERE"
     GITHUB_SECRET: "ANOTHER_REAL_SECURE_KEY_HERE"
     ```

   - You do not need "real" keys for basic development. Some features require certain keys, so you may be able to add them as you go.

## Running the Docker app (basic)

1. run `docker-compose build`
1. run `docker-compose run web rails db:setup`
1. run `docker-compose run web yarn install`
1. run `docker-compose up`
1. That's it! Navigate to <http://localhost:3000>

## Running the Docker app (advanced)

DEV provides a `docker-run.sh` script which can be used to run the Docker app with custom options.

Please execute the script itself to view all additional options:

```shell
./docker-run.sh
```
