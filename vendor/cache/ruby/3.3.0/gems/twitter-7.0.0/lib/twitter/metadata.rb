require 'twitter/base'

module Twitter
  class Metadata < Twitter::Base
    # @return [String]
    attr_reader :iso_language_code, :result_type
  end
end
