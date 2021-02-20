module Articles
  class Attributes
    ATTRIBUTES = %i[archived body_markdown canonical_url description main_image organization_id published series title tags video_thumbnail_url].freeze

    attr_reader :attributes, :article_user

    def initialize(attributes, article_user)
      @attributes = attributes
      @article_user = article_user
    end

    # если nil, то не должно назначаться!
    def for_update
      {
        title: attributes[:title],
        body_markdown: attributes[:body_markdown],
        published: attributes[:published],
        description: attributes[:description],
        main_image: attributes[:main_image],
        canonical_url: attributes[:canonical_url],
        video_thumbnail_url: attributes[:video_thumbnail_url],
        collection: collection,
        tag_list: tag_list,
        archived: attributes[:archived],
        organization_id: attributes[:organization_id]
      }
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
