# encoding: utf-8
# frozen_string_literal: true

module Nokogiri
  class EncodingHandler
    # Popular encoding aliases not known by all iconv implementations that Nokogiri should support.
    USEFUL_ALIASES = {
      # alias_name => true_name
      "NOKOGIRI-SENTINEL" => "UTF-8", # indicating the Nokogiri has installed aliases
      "Windows-31J" => "CP932", # Windows-31J is the IANA registered name of CP932.
      "UTF-8" => "UTF-8", # for JRuby tests, this is a no-op in CRuby
    }

    class << self
      def install_default_aliases
        USEFUL_ALIASES.each do |alias_name, name|
          EncodingHandler.alias(name, alias_name) if EncodingHandler[alias_name].nil?
        end
      end
    end

    # :stopdoc:
    if Nokogiri.jruby?
      class << self
        def [](name)
          storage.key?(name) ? new(storage[name]) : nil
        end

        def alias(name, alias_name)
          storage[alias_name] = name
        end

        def delete(name)
          storage.delete(name)
        end

        def clear_aliases!
          storage.clear
        end

        private

        def storage
          @storage ||= {}
        end
      end

      def initialize(name)
        @name = name
      end

      attr_reader :name
    end
  end
end

Nokogiri::EncodingHandler.install_default_aliases
