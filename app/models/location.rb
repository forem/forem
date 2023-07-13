class Location
  include ActiveModel::Validations

  attr_reader :country_code, :subdivision_code

  # TODO: Custom error messages maybe?
  validates :country_code, inclusion: { in: ISO3166::Country.codes }
  # TODO: Stronger validation to only allow nil if the country has no subdivisions?
  validates :subdivision_code, inclusion: {
    in: ->(location) { ISO3166::Country.new(location.country_code).subdivision_codes }
  }, allow_nil: true

  def self.from_client_geo(client_geo)
    country, subdivision = client_geo.split("-")

    new(country, subdivision)
  end

  # Method to quickly spin up a bunch of records to test against
  def self.create_test_records(org_id, area: "feed_first", count: 500)
    geo_targets = [
      nil,
      # Quebec (Canada) and France
      %w[CA-QC FR],
      # Canada, UK, Australia
      %w[CA GB AU],
      # California (US) and Netherlands
      %w[US-CA NL],
      # Maine (US), Newfoundland (NL) and Greenland (GL)
      %w[US-ME CA-NL GL],
    ]

    result = DisplayAd.insert_all(Array.new(count) do |index|
      geo = geo_targets[index % 5]
      {
        organization_id: org_id,
        body_markdown: "<h1>Lorem ipsum dolor sit amet</h1>",
        placement_area: area,
        name: "Test Billboard ##{index}",
        cached_tag_list: "",
        published: true,
        approved: true,
        geo_array: geo,
        geo_ltree: geo&.map { |code| code.tr("-", ".") },
        geo_text: geo&.join(",")
      }
    end)
    result.rows.flatten
  end

  def self.benchmark_query_methods(area: "feed_first", client_geo: "CA-NL")
    ActiveRecord::Base.logger.silence do
      %i[geo_array geo_ltree geo_text].each do |geo_column|
        callback = lambda do |*args|
          event = ActiveSupport::Notifications::Event.new(*args)
          # rubocop:disable Rails/Output
          puts "Query time: #{event.duration} (using column #{geo_column})"
          # rubocop:enable Rails/Output
        end

        ActiveSupport::Notifications.subscribed(callback, "sql.active_record", monotonic: true) do
          10.times do
            DisplayAds::FilteredAdsQuery.call(
              area: area,
              user_signed_in: false,
              location: Location.from_client_geo(client_geo),
              geo_column: geo_column,
            ).count
          end
        end
      end
    end
  end

  def initialize(country_code, subdivision_code = nil)
    @country_code = country_code
    @subdivision_code = subdivision_code
  end

  def as_geo_query_clause(geo_column)
    case geo_column
    when :geo_array
      "geo_array && #{as_sql_array}"
    when :geo_ltree
      "#{as_sql_lquery} ~ geo_ltree"
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

  def as_sql_lquery
    pattern = country_code
    # Match subdivision if specified
    pattern += ".#{subdivision_code}{,}" if subdivision_code

    "'#{pattern}'"
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
