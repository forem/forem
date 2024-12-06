module Algolia
  class RuleIterator < PaginatorIterator
    # Creates the endpoint on which to fetch rules
    #
    def get_endpoint
      path_encode('1/indexes/%s/rules/search', @index_name)
    end
  end
end
