# This is used for the Postgres FTS spike only
module Search
  class Multisearch
    def self.call(term)
      PgSearch.multisearch(term).includes(:searchable)
    end
  end
end
