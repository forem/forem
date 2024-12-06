# frozen_string_literal: true

require 'uri'
require 'net/http'
require 'nokogiri'
require 'fileutils'
require 'json'

# Support code to allow updating subdivision data from the Unicode CLDR repository
module Sources
  # Support code to allow updating subdivision data from the Unicode CLDR repository
  module CLDR
    # Downloads data from the Unicode CLDR repository
    module Downloader
      module_function

      def subdivisions
        download_folder('subdivisions')
      end

      def download_folder(type)
        folder = File.join(ISO3166_ROOT_PATH, 'tmp', 'cldr', 'trunk', 'common', type)
        FileUtils.mkdir_p(folder)
        url = URI.parse("https://api.github.com/repos/unicode-org/cldr/contents/common/#{type}")
        path_listing = JSON.parse(Net::HTTP.get_response(url).body)
        path_listing.each do |path|
          next unless path['name'] =~ /\.xml$/

          File.open(File.join(folder, path['name']), 'w') do |f|
            raw_url = URI.parse(path['download_url'])
            f.write(Net::HTTP.get_response(raw_url).body)
          end
        end
      end
    end
  end
end
