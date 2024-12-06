# frozen_string_literal: true

module ISO3166
  class << self
    attr_writer :configuration
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.reset
    @configuration = Configuration.new
    Data.reset
  end

  def self.configure
    yield(configuration)
  end

  class Configuration
    attr_accessor :locales, :loaded_locales

    def initialize
      @locales = default_locales
      @loaded_locales = []
    end

    # Enables the integration with the {Money}[https://github.com/RubyMoney/money] gem
    #
    # Please note that it requires you to add "money" gem to your gemfile.
    #
    #   gem "money", "~> 6.9"
    #
    # *WARNING* if you have a top level class named +Money+ you will conflict with this gem.
    #
    # @example
    #   c = ISO3166::Country['us']
    #   c.currency.iso_code # => 'USD'
    #   c.currency.name # => 'United States Dollar'
    #   c.currency.symbol # => '$'
    def enable_currency_extension!
      require 'countries/country/currency_methods'
      ISO3166::Country.prepend(ISO3166::CountryCurrencyMethods)
    end

    private

    def default_locales
      locales = if Object.const_defined?('I18n') && I18n.respond_to?(:available_locales)
                  I18n.available_locales.dup
                else
                  [:en]
                end

      locales.empty? ? [:en] : locales
    end
  end
end
