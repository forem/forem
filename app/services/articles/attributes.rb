module Articles
  class Attributes
    ATTRIBUTES = %i[archived body_markdown canonical_url description
                    edited_at main_image organization_id user_id published
                    title video_thumbnail_url published_at].freeze

    attr_reader :attributes, :article_user

    def initialize(attributes, article_user)
      @attributes = attributes
      @article_user = article_user
    end

    def for_update(update_edited_at: false)
      hash = attributes.slice(*ATTRIBUTES)
      # don't reset the collection when no series was passed
      hash[:collection] = collection if attributes.key?(:series)
      hash[:tag_list] = tag_list
      hash[:edited_at] = Time.current if update_edited_at
      hash[:published_at] = hash[:published_at].to_datetime if hash[:published_at]
      hash
    end

    private

    def collection
      Collection.find_series(attributes[:series], article_user) if attributes[:series].present?
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
