class ReadingList < ApplicationRecord
  self.primary_key = :path

  include PgSearch::Model

  pg_search_scope :search_reading_list,
                  against: [],
                  using: {
                    tsearch: {
                      prefix: true,
                      tsvector_column: %w[document]
                    }
                  },
                  ignoring: :accents

  # copied from Article.readable_publish_date
  def readable_publish_date
    relevant_date = crossposted_at.presence || published_at
    if relevant_date && relevant_date.year == Time.current.year
      relevant_date&.strftime("%b %e")
    else
      relevant_date&.strftime("%b %e '%y")
    end
  end

  # [@rhymes] this is taking around 1.3 seconds in development, with 10k articles and 20k reactions
  def self.refresh
    Scenic.database.refresh_materialized_view(table_name, concurrently: true, cascade: false)
  end
end
