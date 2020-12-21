# This class is used for Postgres FTS spike only
module Search
  class Indices
    def self.clear!(klass)
      PgSearch::Document.delete_by(searchable_type: klass.name)
    end

    def self.rebuild!(klass)
      PgSearch::Multisearch.rebuild(klass)
    end
  end
end
