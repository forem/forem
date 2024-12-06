# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext/hash/deep_merge'
require 'nokogiri'
require 'pry'

module Sources
  module CLDR
    # Updates local subdivision files with data from the Unicode CLDR repository
    class SubdivisionUpdater
      def call
        d = Dir['./tmp/cldr/trunk/common/subdivisions/*.xml']
        @loader = Sources::Local::CachedLoader.new(Sources::Local::Subdivision)
        d.each { |file_path| update_locale(file_path) }
      end

      def update_locale(file_path)
        language_data = Nokogiri::XML(File.read(file_path))
        language_code = File.basename(file_path, '.*')
        subdivisions = language_data.css('subdivision')
        return if subdivisions.empty?

        last_country_code_seen = nil

        subdivisions.each_with_index do |subdivision, index|
          subdivision = Sources::CLDR::Subdivision.new(language_code: language_code, xml: subdivision)
          data = @loader.load(subdivision.country_code)
          data[subdivision.code] ||= {}
          data[subdivision.code] = data[subdivision.code].deep_merge(subdivision.to_h)
          if (last_country_code_seen && last_country_code_seen != subdivision.country_code) ||
             index == subdivisions.size - 1
            puts "Updated #{subdivision.country_code} with language_code #{language_code}"
            @loader.save(subdivision.country_code, data)
          end
          last_country_code_seen = subdivision.country_code
        end
      end
    end
  end
end
