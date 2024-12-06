module Cloudinary::CarrierWave
  class UploadError < StandardError
    attr_reader :http_code
    def initialize(message, http_code)
      super(message)
      @http_code = http_code
    end
  end
end