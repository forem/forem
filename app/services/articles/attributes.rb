module Articles
  class Attributes
    ATTRIBUTES = %i[archived body_markdown canonical_url description
                    edited_at main_image organization_id published
                    title video_thumbnail_url].freeze

    attr_reader :attributes, :article_user, :update_edited_at

    def initialize(attributes, article_user, update_edited_at = false)
      @attributes = attributes
      @article_user = article_user
      @update_edited_at = update_edited_at
    end

    def for_update
      hash = {}
      ATTRIBUTES.each do |attr|
        hash[attr] = attributes[attr] if attributes[attr]
      end
      hash[:collection] = collection
      hash[:tag_list] = tag_list
      hash[:edited_at] = Time.current if update_edited_at
      hash
    end

    private

    def collection
      if attributes[:series].present?
        Collection.find_series(attributes[:series], article_user)
      elsif attributes[:series] == "" # reset collection?
        nil
      end
    end

    def tag_list
      if attributes[:tag_list]
        attributes[:tag_list]
      elsif attributes[:tags]
        attributes[:tags].join(", ")
      end
    end
  end
end
