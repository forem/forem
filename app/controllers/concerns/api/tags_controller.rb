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

      # An exact name lookup finds the tag whether or not it is supported.
      base_scope = params.key?(:name) ? Tag.where(name: params[:name].to_s.downcase) : Tag.from_subforem
      relation = base_scope.order(taggings_count: :desc).page(page).per(num)

      if render_tags_natively(relation, Tag.table_key)
        return
      end

      @tags = relation.select(ATTRIBUTES_FOR_SERIALIZATION)
      set_surrogate_key_header Tag.table_key, @tags.map(&:record_key)
    end

    # Unpaginated list of every tag supported in the current subforem.
    # On the root subforem (or with no subforem context) this is every tag
    # flagged as supported; on other subforems it's the tags with a
    # supported relationship to that subforem.
    def supported
      relation = supported_tags_scope.order(taggings_count: :desc, id: :asc)

      if render_tags_natively(relation, Tag::SUPPORTED_TAGS_SURROGATE_KEY)
        return
      end

      @tags = relation.select(ATTRIBUTES_FOR_SERIALIZATION)
      set_surrogate_key_header Tag::SUPPORTED_TAGS_SURROGATE_KEY, @tags.map(&:record_key)
      render :index
    end

    private

    def native_tags_serializable?
      ForemNative.available? &&
        (request.format.json? || request.format.api_v0? || request.format.api_v1?)
    end

    def render_tags_natively(relation, base_surrogate_key)
      return false unless native_tags_serializable?

      rows = relation.pluck(*ATTRIBUTES_FOR_SERIALIZATION)
      json_body = ForemNative.serialize_api_tags_json(
        rows.flatten(1),
        escape_html: ActiveSupport::JSON::Encoding.escape_html_entities_in_json,
      )
      return false unless json_body

      prefix = "#{Tag.table_key}/"
      set_surrogate_key_header(base_surrogate_key, rows.map { |row| "#{prefix}#{row[0]}" })
      render json: json_body
      true
    end

    def supported_tags_scope
      return Tag.supported if Subforem.disabled_by_env?

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
