require "base64"

module Imgproxy
  module OptionsCasters
    # Casts string option to base64
    module Base64
      def self.cast(raw)
        ::Base64.urlsafe_encode64(raw.to_s).tr("=", "") unless raw.nil?
      end
    end
  end
end
