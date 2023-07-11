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
end
