require 'uri'

module CarrierWave
  module Utilities
    module Uri
    # based on Ruby < 2.0's URI.encode
    SAFE_STRING = URI::REGEXP::PATTERN::UNRESERVED + '\/'
    UNSAFE = Regexp.new("[^#{SAFE_STRING}]", false)

    private
      def encode_path(path)
        path.to_s.gsub(UNSAFE) do
          us = $&
          tmp = ''
          us.each_byte do |uc|
            tmp << sprintf('%%%02X', uc)
          end
          tmp
        end
      end
    end # Uri
  end # Utilities
end # CarrierWave
