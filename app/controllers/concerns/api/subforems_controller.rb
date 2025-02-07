module Api
  module SubforemsController
    extend ActiveSupport::Concern

    def index
      @subforems = Subforem.where(discoverable: true)

      set_surrogate_key_header @subforems.map(&:record_key)
    end
  end
end
