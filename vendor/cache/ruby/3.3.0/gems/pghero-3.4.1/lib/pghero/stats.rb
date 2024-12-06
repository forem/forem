module PgHero
  class Stats < ActiveRecord::Base
    self.abstract_class = true
    establish_connection PgHero.stats_database_url if PgHero.stats_database_url
  end
end
