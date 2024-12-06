namespace :strong_migrations do
  # https://www.pgrs.net/2008/03/12/alphabetize-schema-rb-columns/
  task :alphabetize_columns do
    $stderr.puts "Dumping schema"
    ActiveRecord::Base.logger.level = Logger::INFO

    StrongMigrations.alphabetize_schema = true
  end
end
