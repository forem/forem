# This class is used for Postgres FTS spike only
module Search
  class Indices
    MULTISEARCH_CLASSES = [Article, Comment, PodcastEpisode].freeze

    def self.clear!(klass)
      PgSearch::Document.delete_by(searchable_type: klass.name)
    end

    def self.rebuild!(klass)
      PgSearch::Multisearch.rebuild(klass)
    end

    def self.rebuild_all!
      MULTISEARCH_CLASSES.each { |klass| PgSearch::Multisearch.rebuild(klass) }
      nil
    end
  end
end
