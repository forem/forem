# frozen_string_literal: true

# Feedjira::Configuration
module Feedjira
  # Provides global configuration options for Feedjira
  #
  # @example Set configuration options using a block
  #   Feedjira.configure do |config|
  #     config.strip_whitespace = true
  #   end
  module Configuration
    attr_accessor(
      :logger,
      :parsers,
      :strip_whitespace
    )

    # Modify Feedjira's current configuration
    #
    # @yieldparam [Feedjria] config current Feedjira config
    # @example
    #   Feedjira.configure do |config|
    #     config.strip_whitespace = true
    #   end
    def configure
      yield self
    end

    # Reset Feedjira's configuration to defaults
    #
    # @example
    #   Feedjira.reset_configuration!
    def reset_configuration!
      set_default_configuration
    end

    # @private
    def self.extended(base)
      base.set_default_configuration
    end

    # @private
    def set_default_configuration
      self.logger = default_logger
      self.parsers = default_parsers
      self.strip_whitespace = false
    end

    private

    # @private
    def default_logger
      Logger.new($stdout).tap do |logger|
        logger.progname = "Feedjira"
        logger.level = Logger::WARN
      end
    end

    # @private
    def default_parsers
      [
        Feedjira::Parser::ITunesRSS,
        Feedjira::Parser::RSSFeedBurner,
        Feedjira::Parser::GoogleDocsAtom,
        Feedjira::Parser::AtomYoutube,
        Feedjira::Parser::AtomFeedBurner,
        Feedjira::Parser::AtomGoogleAlerts,
        Feedjira::Parser::Atom,
        Feedjira::Parser::RSS,
        Feedjira::Parser::JSONFeed
      ]
    end
  end
end
