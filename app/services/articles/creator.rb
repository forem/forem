module Articles
  class Creator
    def self.call(...)
      new(...).call
    end

    # @param user [User]
    # @param article_params [Hash]
    # @option article_params [NilClass, String] :title
    # @option article_params [NilClass, String] :body_markdown
    # @option article_params [NilClass, String] :main_image
    # @option article_params [Boolean] :published
    # @option article_params [NilClass, String] :description
    # @option article_params [NilClass, String] :video_thumbnail_url
    # @option article_params [NilClass, String] :canonical_url
    # @option article_params [NilClass, String] :series series slug
    # @option article_params [Integer, NilClass] :collection_id
    # @option article_params [Boolean] :archived
    # @option article_params [String<Array>] :tags
    # @option article_params [NilClass, String, ActiveSupport::TimeWithZone] :published_at
    def initialize(user, article_params)
      @user = user
      @article_params = normalize_params(article_params)
    end

    def call
      rate_limit!

      create_article.tap do
        subscribe_author if article.persisted?
        refresh_auto_audience_segments if article.published?
      end
    end

    private

    attr_reader :article, :user, :article_params

    def normalize_params(original_params)
      original_params.except(:tags).tap do |params|
        # convert tags from array to a string
        if (tags = original_params[:tags]).present?
          params[:tag_list] = tags.join(", ")
        end
      end
    end

    def rate_limit!
      rate_limit_to_use = if user.decorate.considered_new?
                            :published_article_antispam_creation
                          else
                            :published_article_creation
                          end

      user.rate_limiter.check_limit!(rate_limit_to_use)
    end

    def refresh_auto_audience_segments
      user.refresh_auto_audience_segments
    end

    def create_article
      @article = Article.create(article_params) do |article|
        article.user_id = user.id
        article.show_comments = true
        article.collection = series if series.present?
      end
    end

    def series
      @series ||= if article_params[:series].blank?
                    []
                  else
                    Collection.find_series(article_params[:series], user)
                  end
    end

    # Subscribe author to notifications for all comments on their article.
    def subscribe_author
      NotificationSubscription.create(user: user,
                                      notifiable: article,
                                      config: "all_comments")
    end
  end
end
