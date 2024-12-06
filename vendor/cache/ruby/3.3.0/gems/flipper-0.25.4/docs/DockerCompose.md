# Docker Compose for contributors

This gem includes different adapters which require specific tools instaled
on local machine. With docker this could be achieved inside container and
new contributor could start working on code with a minumum efforts.

## Steps:

1. Install Docker Compose https://docs.docker.com/compose/install
1. Build the app container `docker-compose build`
1. Install gems `docker-compose run --rm app bundle install`
1. Run specs `docker-compose run --rm app bundle exec rspec`
1. Run tests `docker-compose run --rm app bundle exec rake test`
1. Optional: log in to container an using a `bash` shell for running specs
```sh
docker-compose run --rm app bash
bundle exec rspec
```
