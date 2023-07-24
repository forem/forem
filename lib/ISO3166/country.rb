# Modifications to the `countries` gem for clearer application code.
# In the future, we might want to modify the gem's dataset here (e.g. to include
# a mapping of the relationship between hierarchical subdivisions)
module ISO3166
  class Country
    def region_codes
      @region_codes ||= subdivisions.keys
    end
  end
end
