# frozen_string_literal: true

module ISO3166
  DEFAULT_COUNTRY_HASH = {
    'address_format' => nil,
    'alpha2' => nil,
    'alpha3' => nil,
    'continent' => nil,
    'country_code' => nil,
    'currency_code' => nil,
    'distance_unit' => nil,
    'gec' => nil,
    'geo' => {
      'latitude' => nil,
      'longitude' => nil,
      'max_latitude' => nil,
      'max_longitude' => nil,
      'min_latitude' => nil,
      'min_longitude' => nil,
      'bounds' => {
        'northeast' => {
          'lat' => nil,
          'lng' => nil
        },
        'southwest' => {
          'lat' => nil,
          'lng' => nil
        }
      }
    },
    'international_prefix' => nil,
    'ioc' => nil,
    'iso_long_name' => nil,
    'iso_short_name' => nil,
    'national_destination_code_lengths' => [],
    'national_number_lengths' => [],
    'national_prefix' => nil,
    'nanp_prefix' => nil,
    'nationality' => nil,
    'number' => nil,
    'languages_official' => [],
    'languages_spoken' => [],
    'translations' => {},
    'postal_code' => nil,
    'postal_code_format' => nil,
    'region' => nil,
    'unofficial_names' => [],
    'start_of_week' => 'monday',
    'subregion' => nil,
    'un_locode' => nil,
    'vat_rates' => {
      'standard' => nil,
      'reduced' => [nil, nil],
      'super_reduced' => nil,
      'parking' => nil
    },
    'world_region' => nil
  }.freeze

  DEFAULT_SUBDIVISION_HASH = {
    'name' => nil,
    'unofficial_names' => [],
    'translations' => {},
    'geo' => {
      'latitude' => nil,
      'longitude' => nil,
      'max_latitude' => nil,
      'max_longitude' => nil,
      'min_latitude' => nil,
      'min_longitude' => nil
    }
  }.freeze
end
