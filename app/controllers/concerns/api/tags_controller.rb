module Api
  module TagsController
    extend ActiveSupport::Concern

    ATTRIBUTES_FOR_SERIALIZATION = %i[id name bg_color_hex text_color_hex short_summary].freeze
    private_constant :ATTRIBUTES_FOR_SERIALIZATION

    def index
      page = params[:page]
      per_page = (params[:per_page] || 10).to_i
      per_page_max = (ApplicationConfig["API_PER_PAGE_MAX"] || 1000).to_i
      num = [per_page, per_page_max].min

      @tags = Tag.select(ATTRIBUTES_FOR_SERIALIZATION)
        .from_subforem
        .order(taggings_count: :desc)
        .page(page).per(num)

      set_surrogate_key_header Tag.table_key, @tags.map(&:record_key)
    end

    # Unpaginated list of every tag supported in the current subforem.
    # On the root subforem (or with no subforem context) this is every tag
    # flagged as supported; on other subforems it's the tags with a
    # supported relationship to that subforem.
    def supported
      @tags = supported_tags_scope.select(ATTRIBUTES_FOR_SERIALIZATION).order(taggings_count: :desc, id: :asc)

      set_surrogate_key_header Tag::SUPPORTED_TAGS_SURROGATE_KEY, @tags.map(&:record_key)
      render :index
    end

    private

    def supported_tags_scope
      subforem_id = RequestStore.store[:subforem_id]
      if subforem_id.present? && subforem_id != RequestStore.store[:root_subforem_id]
        Tag.joins(:subforem_relationships)
          .where(subforem_relationships: { subforem_id: subforem_id, supported: true })
      else
        Tag.supported
      end
    end
  end
end
