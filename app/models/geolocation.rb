require Rails.root.join("lib/ISO3166/country")

class Geolocation
  class ArrayType < ActiveRecord::Type::Value
    include ActiveModel::Type::Helpers::Mutable

    def cast(codes)
      return [] if codes.blank?

      # Allows setting comma-separated string
      codes = codes.split(/[\s,]+/) unless codes.is_a?(Array)

      codes.map { |code| Geolocation.from_iso3166(code) }
    end

    def serialize(geo_locations)
      PG::TextEncoder::Array.new.encode(geo_locations.map(&:to_ltree))
    end

    def deserialize(geo_ltrees)
      PG::TextDecoder::Array.new.decode(geo_ltrees).map { |geo_ltree| Geolocation.from_ltree(geo_ltree) }
    end
  end

  include ActiveModel::Validations

  ISO3166_SEPARATOR = "-".freeze
  LTREE_SEPARATOR = ".".freeze

  attr_reader :country_code, :region_code

  def self.from_iso3166(iso_3166)
    parse(iso_3166, separator: ISO3166_SEPARATOR)
  end

  def self.from_ltree(ltree)
    parse(ltree, separator: LTREE_SEPARATOR)
  end

  def self.parse(code, separator:)
    return if code.blank?
    return code if code.is_a?(Geolocation)

    country, subdivision = code.split(separator)

    new(country, subdivision)
  end

  def initialize(country_code, region_code = nil)
    @country_code = country_code
    @region_code = region_code
  end

  validates :country_code, inclusion: { in: ISO3166::Country.codes }
  validates :region_code, inclusion: {
    in: ->(geolocation) { ISO3166::Country.new(geolocation.country_code).region_codes }
  }, allow_nil: true

  def to_iso3166
    [country_code, region_code].compact.join("-")
  end

  def to_ltree
    [country_code, region_code].compact.join(".")
  end

  def to_sql_query(column_name = :target_geolocations)
    return unless valid?

    lquery = country_code
    # Match region if specified
    lquery += ".#{region_code}{,}" if region_code

    "'#{lquery}' ~ #{column_name}"
  end

  def errors_as_sentence
    errors.full_messages.to_sentence
  end
end
