# frozen_string_literal: true

# rubocop:disable Layout/TrailingWhitespace
class ArticleWithVideoCreationService
  VIDEO_SERVICE_URL = "https://dw71fyauz7yz9.cloudfront.net"

  def initialize(article_params, current_user)
    @article_params = article_params
    @current_user = current_user
  end

  def create!
    Article.create! do |article|
      article = initial_article_with_params(article)
      article.processed_html = ""
      article.user_id = @current_user.id
      article.show_comments = true

      if @article_params[:video].present?
        article.video = @article_params[:video]
        article.video_state = "PROGRESSING"

        video_code = article.video.split("dev-to-input-v0/")[1]
        article.video_code = video_code
        article.video_source_url = "#{VIDEO_SERVICE_URL}/#{video_code}/#{video_code}.m3u8"

        thumb_name = "thumbs-#{video_code}-00001"
        article.video_thumbnail_url = "#{VIDEO_SERVICE_URL}/#{video_code}/#{thumb_name}.png"
      end
    end
  end

  def initial_article_with_params(article)
    if @current_user.editor_version == "v1"
      article.body_markdown = <<~BODY
        ---
        title: Unpublished Video ~ #{rand(100_000).to_s(26)}
        published: false
        description:
        tags:
        ---
        
      BODY
    else
      article.body_markdown = ""
      article.title = "Unpublished Video ~ #{rand(100_000).to_s(26)}"
      article.published = false
    end
    article
  end
end
# rubocop:enable Layout/TrailingWhitespace
