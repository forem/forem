module Articles
  class Attributes
    ATTRIBUTES = %i[archived body_markdown canonical_url description edited_at main_image organization_id published series title tags video_thumbnail_url user_id].freeze

    attr_reader :attributes, :article_user

    def initialize(attributes, article_user)
      @attributes = attributes
      @article_user = article_user
    end

    # если nil, то не должно назначаться!
    def for_update
      hash = {}
      %i[archived body_markdown canonical_url description edited_at main_image organization_id published title video_thumbnail_url].each do |attr|
        hash[attr] = attributes[attr] if attributes[attr]
      end
      hash[:collection] = collection
      hash[:tag_list] = tag_list
      hash
    end

    def collection
      if attributes[:series].present?
        Collection.find_series(attributes[:series], article_user)
      elsif attributes[:series] == "" # reset collection?
        nil
      end
    end

    def tag_list
      return attributes[:tag_list] if attributes[:tag_list]

      return attributes[:tags].join(", ") if attributes[:tags]
    end

    def to_h
      {

      }
    end
  end
end
