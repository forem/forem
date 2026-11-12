# Modifications to the `countries` gem for clearer application code.
# In the future, we might want to modify the gem's dataset here (e.g. to include
# a mapping of the relationship between hierarchical subdivisions)
module ISO3166
  class Country
    REGION_CODES_BY_ALPHA2 = Concurrent::Map.new

    def self.code_from_name(name)
      find_country_by_any_name(name).alpha2
    end

    def self.region_codes_if_exists(alpha2_code)
      return [] if alpha2_code.blank?

      key = alpha2_code.to_s
      REGION_CODES_BY_ALPHA2.fetch_or_store(key) do
        (new(key)&.region_codes || []).freeze
      end
    end

    def region_codes
      @region_codes ||= subdivisions.keys
    end
  end
end
