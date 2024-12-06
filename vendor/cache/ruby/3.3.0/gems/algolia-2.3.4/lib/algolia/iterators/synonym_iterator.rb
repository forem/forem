module Algolia
  class SynonymIterator < PaginatorIterator
    # Creates the endpoint on which to fetch synonyms
    #
    def get_endpoint
      path_encode('1/indexes/%s/synonyms/search', @index_name)
    end
  end
end
