# Setup your application with PostgreSQL -
Follow these links for detailed the installation guide.
1. Mac OS - [setup](https://postgresapp.com/)
2. Linux / Ubuntu -
   - Ubuntu `14.04` - [setup](https://www.digitalocean.com/community/tutorials/how-to-install-and-use-postgresql-on-ubuntu-14-04)
   - Ubuntu `16.04 and higher` - [setup](https://www.digitalocean.com/community/tutorials/how-to-install-and-use-postgresql-on-ubuntu-16-04)
3. Windows - [setup](https://www.postgresql.org/download/windows/)

##### You can find all installation packages for different operating systems [here](https://www.postgresql.org/download/).

##### After installation -
1. If your Rails app is unable to connect to the PostgreSQL, then update your `database.yml` file with `username` and `password`.
```ruby
development:
    <<: *default
    username: POSTGRESSQL_USERNAME
    password: POSTGRESSQL_PASSWORD
test:
    <<: *default
    username: POSTGRESSQL_USERNAME
    password: POSTGRESSQL_PASSWORD
```
2. While running test cases, if you get an error message `postgresql connection timeout`. Go to your `spec/support/database_cleaner.rb` file. And rename `:truncation` with `:deletion`.

##### Note -
1. Don't forget to set up your PostgreSQL with `username` and `password`.
2. Don't commit your `database.yml` or `database_cleaner.rb` files. Or PostgreSQL `username` and `password` to any repository.
3. You can use environment variables for storing `username` and `password`. You can define them inside the `application.yml` file.
