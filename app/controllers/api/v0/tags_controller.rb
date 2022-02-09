module Api
  module V0
    class TagsController < ApiController
      before_action :set_cache_control_headers, only: %i[index]

      ATTRIBUTES_FOR_SERIALIZATION = %i[id name bg_color_hex text_color_hex short_summary badge_id].freeze
      private_constant :ATTRIBUTES_FOR_SERIALIZATION

      def index
        @tags = Tag.includes(:badge).select(ATTRIBUTES_FOR_SERIALIZATION)

        page = params[:page]
        per_page = (params[:per_page] || 10).to_i
        num = [per_page, 1000].min

        @tags = @tags.where(id: params[:tag_ids]) if params[:tag_ids].present?

        @tags = @tags.order(taggings_count: :desc).page(page).per(num)

        set_surrogate_key_header Tag.table_key, @tags.map(&:record_key)
      end
    end
  end
end
