class ReadingList < ApplicationRecord
  # [@rhymes] this is taking around 1.3 seconds in development, with 10k articles and 20k reactions
  def self.refresh
    Scenic.database.refresh_materialized_view(table_name, concurrently: true, cascade: false)
  end
end
