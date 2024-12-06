require 'twitter/creatable'
require 'twitter/identity'

module Twitter
  class SavedSearch < Twitter::Identity
    include Twitter::Creatable
    # @return [String]
    attr_reader :name, :position, :query
  end
end
