module Articles
  class CreateWithVideo
    VIDEO_SERVICE_URL = "https://dw71fyauz7yz9.cloudfront.net".freeze

    def self.call(key, user)
      new(key, user).create!
    end

    def initialize(key, user)
      @key = key
      @user = user
    end

    def create!
      Article.create! do |article|
        article = initial_article_with_params(article)
        article.processed_html = ""
        article.user_id = @user.id
        article.show_comments = true

        if @key.present?
          article.video = @key
          article.video_state = "PROGRESSING"

          # TODO: citizen428 - Change this to match the new structure
          video_code = article.video.split("dev-to-input-v0/")[1]
          article.video_code = video_code
          article.video_source_url = "#{VIDEO_SERVICE_URL}/#{video_code}/#{video_code}.m3u8"

          thumb_name = "thumbs-#{video_code}-00001"
          article.video_thumbnail_url = "#{VIDEO_SERVICE_URL}/#{video_code}/#{thumb_name}.png"
        end
      end
    end

    def initial_article_with_params(article)
      if @user.setting.editor_version == "v1"
        title = "Unpublished Video ~ #{rand(100_000).to_s(26)}"
        article.body_markdown = "---\ntitle: #{title}\npublished: false\ndescription: \ntags: \n---\n\n"
      else
        article.body_markdown = ""
        article.title = "Unpublished Video ~ #{rand(100_000).to_s(26)}"
        article.published = false
      end
      article
    end
  end
end
