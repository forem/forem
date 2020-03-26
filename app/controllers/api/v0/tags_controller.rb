module Api
  module V0
    class TagsController < ApiController
      before_action :set_cache_control_headers, only: %i[index]

      def index
        page = params[:page]
        per_page = (params[:per_page] || 10).to_i
        num = [per_page, 1000].min

        @tags = Tag.select(ATTRIBUTES_FOR_SERIALIZATION).
          order(taggings_count: :desc).
          page(page).per(num)

        set_surrogate_key_header Tag.table_key, @tags.map(&:record_key)
      end

      ATTRIBUTES_FOR_SERIALIZATION = %i[id name bg_color_hex text_color_hex].freeze
      private_constant :ATTRIBUTES_FOR_SERIALIZATION
    end
  end
end
