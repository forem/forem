require 'twitter/base'

module Twitter
  class Language < Twitter::Base
    # @return [String]
    attr_reader :code, :name, :status
  end
end
