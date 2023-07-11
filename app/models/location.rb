class Location
  include ActiveModel::Validations

  attr_reader :country_code, :subdivision_code

  # TODO: Custom error messages maybe?
  validates :country_code, inclusion: { in: ISO3166::Country.codes }
  validates :subdivision_code, inclusion: {
    in: ->(location) { ISO3166::Country.new(location.country_code).subdivision_codes }
  }, allow_nil: true

  def initialize(country_code, subdivision_code = nil)
    @country_code = country_code
    @subdivision_code = subdivision_code
  end

  def as_geo_query_clause(geo_column)
    case geo_column
    when :geo_array
      "geo_array && #{as_sql_array}"
    when :geo_text
      "geo_text SIMILAR TO #{as_sql_regex}"
    end
  end

  private

  def as_sql_array
    patterns = [country_code]
    patterns << "#{country_code}-#{subdivision_code}" if subdivision_code

    "'{#{patterns.join(',')}}'"
  end

  def as_sql_regex
    # Match country at start of text OR after other text ending in a comma
    pattern = "(%,)?#{country_code}"
    # Match subdivision if specified
    pattern += "(-#{subdivision_code})?" if subdivision_code
    # Match end of text OR a comma followed by more text
    pattern += "(,%)?"

    "'#{pattern}'"
  end
end
