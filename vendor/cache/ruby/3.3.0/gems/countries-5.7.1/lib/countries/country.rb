# frozen_string_literal: true

module ISO3166
  class Country
    extend CountryClassMethods
    extend CountryFinderMethods
    include Emoji
    include CountrySubdivisionMethods
    attr_reader :data

    ISO3166::DEFAULT_COUNTRY_HASH.each do |method_name, _type|
      define_method method_name do
        data[method_name.to_s]
      end
    end

    ISO3166::DEFAULT_COUNTRY_HASH['geo'].each do |method_name, _type|
      define_method method_name do
        data['geo'][method_name.to_s]
      end
    end

    def initialize(country_data)
      @country_data_or_code = country_data
      reload
    end

    def valid?
      !(data.nil? || data.empty?)
    end

    alias zip postal_code
    alias zip? postal_code
    alias postal_code? postal_code
    alias zip_format postal_code_format
    alias languages languages_official

    def ==(other)
      other.respond_to?(:alpha2) && other.alpha2 == alpha2
    end

    def eql?(other)
      self == other
    end

    def hash
      [alpha2, alpha3].hash
    end

    def <=>(other)
      to_s <=> other.to_s
    end

    # +true+ if this country is a member of the European Union.
    def in_eu?
      data['eu_member'].nil? ? false : data['eu_member']
    end

    # +true+ if this country is a member of the G7.
    def in_g7?
      data['g7_member'].nil? ? false : data['g7_member']
    end

    # +true+ if this country is a member of the G20.
    def in_g20?
      data['g20_member'].nil? ? false : data['g20_member']
    end

    # +true+ if this country is a member of the European Economic Area or it is UK
    def gdpr_compliant?
      data['eea_member'] || alpha2 == 'GB'
    end

    # +true+ if this country is a member of the European Economic Area.
    def in_eea?
      data['eea_member'].nil? ? false : data['eea_member']
    end

    # +true+ if this country is a member of the European Single Market.
    def in_esm?
      data['esm_member'].nil? ? in_eea? : data['esm_member']
    end

    # +true+ if this country is a member of the EU VAT Area.
    def in_eu_vat?
      data['euvat_member'].nil? ? in_eu? : data['euvat_member']
    end

    # @return [String] The regex for valid postal codes in this Country
    def postal_code_format
      "\\A#{data['postal_code_format']}\\Z" if postal_code
    end

    def to_s
      data['iso_short_name']
    end

    # @return [Array<String>] the list of names for this Country in all loaded locales.
    def translated_names
      data['translations'].values.compact
    end

    # @param locale [String] The locale to use for translations.
    # @return [String] the name of this Country in the selected locale.
    def translation(locale = 'en')
      data['translations'][locale.to_s.downcase]
    end

    # @return [String] the “common name” of this Country in English.
    def common_name
      ISO3166.configuration.locales = ISO3166.configuration.locales.append(:en).uniq
      translation('en')
    end

    # @return [Array<String>] TThe list of names for this Country, in this Country's locales.
    def local_names
      ISO3166.configuration.locales = (ISO3166.configuration.locales + languages.map(&:to_sym)).uniq
      reload

      @local_names ||= languages.map { |language| translations[language] }
    end

    # @return [String] The name for this Country, in this Country's locale.
    def local_name
      @local_name ||= local_names.first
    end

    # @!attribute alpha2
    #   @return [String] the ISO3166 alpha-2 code for this Country
    #
    # @!attribute alpha3
    #   @return [String] the ISO3166 alpha-3 code for this Country
    #
    # @!attribute address_format
    #   @return [String] a template for formatting addresses in this Country.
    #
    # @!attribute continent
    #   @return [String] the continent for this Country
    #
    # @!attribute country_code
    #   @return [String] the country calling code for this Country
    #
    # @!attribute currency_code
    #   @return [String] the ISO 4217 currency code for this Country
    #
    # @!attribute distance_unit
    #   @return [String] the unit for roading distance and speed for this Country
    #
    # @!attribute gec
    #   @return [String] the "Geopolitical Entities and Codes", formerly FIPS 10-4 code for this Country
    #
    # @!attribute geo
    #   @return [Hash] the hash of coordinates for this Country.
    #
    # @!attribute international_prefix
    #   @return [String] the phone prefix used in this Country for dialing international numbers
    #
    # @!attribute ioc
    #   @return [String] The International Olympic Committee code for for this Country
    #
    # @!attribute national_destination_code_lengths
    #   @return [Array<Integer>] Lengths of phone number destination codes
    #
    # @!attribute national_number_lengths
    #   @return [Array<Integer>] Lengths of phone numbers
    #
    # @!attribute national_prefix
    #   @return [String] the phone prefix used in this Country for dialing national numbers
    #
    # @!attribute nanp_prefix
    #   @return [String] the NANP prefix code
    #
    # @!attribute nationality
    #   @return [String] the nationality for this Country, in English
    #
    # @!attribute number
    #   @return [String] The ISO 3166-1 numeric code for this Country
    #
    # @!attribute languages_official
    #   @return [Array<String>] the list of official languages (locale codes) for this Country
    #
    # @!attribute languages_spoken
    #   @return [Array<String>] the list of spoken languages (locale codes) for this Country
    #
    # @!attribute translations
    #   @return [Hash] The hash of country name translations for this Country.
    #
    # @!attribute postal_code
    #   @return [Boolean] Does this Country uses postal codes in addresses
    #
    # @!attribute region
    #   @return [String] The Region this country is in. Approximately matches the United Nations geoscheme
    #
    # @!attribute unofficial_names
    #   @return [Array<String>] Array of unofficial, slang names or aliases for this Country
    #
    # @!attribute start_of_week
    # @return [String] The starting day of the week ( +'monday'+ or +'sunday'+ )
    #
    # @!attribute subregion
    #   @return [String] The Subegion this country is in. Approximately matches the United Nations geoscheme's Subregions
    #
    # @!attribute un_locode
    #   @return [String] The UN/LOCODE prefix for this Country
    #
    # @!attribute vat_rates
    #   @return [Hash] the hash of VAT Rates for this Country
    #
    # @!attribute world_region
    #   @return [String] The "World Region" this country is in: +"AMER"+ , +"APAC"+ or +"EMEA"+

    private

    def reload
      @data = if @country_data_or_code.is_a?(Hash)
                @country_data_or_code
              else
                ISO3166::Data.new(@country_data_or_code).call
              end
    end
  end
end
