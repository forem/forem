# namespace :db do
#
#   desc "Copy production database to local"
#
#   task :copy_production => :environment do
#     puts "FIRING UP!"
#     # Download latest dump
#     system("echo hey")
#     system("heroku pg:backups --remote heroku capture")
#     system("curl -o latest.dump `heroku pg:backups --remote heroku public-url`")
#
#
#     # get user and database name
#     # config   = Rails.configuration.database_configuration["development"]
#     # database = config["database"]
#     # user = config["username"]
#     #
#     # # import
#     # system("pg_restore --verbose --clean --no-acl --no-owner -h localhost -d #{database} #{Rails.root}/tmp/latest.dump")
#   end
#
# end
#
#
# heroku pg:backups --remote heroku capture
# curl -o latest.dump `heroku pg:backups --remote heroku public-url`
# rake db:reset
# pg_restore --verbose --no-acl --no-owner -t articles -t users -t podcasts -t podcast_episodes -t sponsors -t identities -t organizations -h localhost -d PracticalDeveloper_development latest.dump
# rake db:migrate
# pg_restore --verbose --clean --no-acl --no-owner -t articles -t users -t podcasts -t podcast_episodes -t sponsors -t identities -t organizations -h localhost -d PracticalDeveloper_development latest.dump
