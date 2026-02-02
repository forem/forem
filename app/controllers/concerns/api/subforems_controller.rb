module Api
  module SubforemsController
    extend ActiveSupport::Concern

    def index
      @subforems = Subforem.where(discoverable: true).or(Subforem.where(root: true)).order(score: :desc)

      set_surrogate_key_header @subforems.map(&:record_key)
      set_cache_control_headers(5.minutes.to_i, stale_while_revalidate: 300, stale_if_error: 1.day.to_i)
    end
  end
end
