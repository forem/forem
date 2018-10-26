require "zip"

class ArticleExportService
  attr_reader :user

  def initialize(user)
    @user = user
  end

  def export(slug: nil, send_email: false)
    articles = user.articles
    articles = articles.where(slug: slug) if slug.present?
    zipped_export = zip_json_articles(jsonify_articles(articles))

    send_articles_exported_email(zipped_export) if send_email

    user.update!(export_requested: false, exported_at: Time.current)

    zipped_export.rewind
    zipped_export
  end

  private

  def send_articles_exported_email(zipped_export)
    zipped_export.rewind
    NotifyMailer.articles_exported_email(user, zipped_export.read).deliver
  end

  def whitelisted_attributes
    %i[
      body_html
      body_markdown
      cached_tag_list
      cached_user_name
      cached_user_username
      canonical_url
      comments_count
      created_at
      crossposted_at
      description
      edited_at
      feed_source_url
      language
      last_comment_at
      lat
      long
      main_image
      main_image_background_hex_color
      path
      positive_reactions_count
      processed_html
      published
      published_at
      published_from_feed
      reactions_count
      show_comments
      slug
      social_image
      title
      updated_at
      video
      video_closed_caption_track_url
      video_code
      video_source_url
      video_thumbnail_url
    ]
  end

  def jsonify_articles(articles)
    articles_to_jsonify = []
    # this is done to load articles in batches, we don't want to hog the DB
    # if a user has lots and lots of articles
    articles.find_each do |article|
      articles_to_jsonify << article
    end
    articles_to_jsonify.to_json(only: whitelisted_attributes)
  end

  def zip_json_articles(json_articles)
    buffer = StringIO.new
    Zip::OutputStream.write_buffer(buffer) do |stream|
      stream.put_next_entry(
        "articles.json",
        nil, # comment
        nil, # extra
        Zip::Entry::DEFLATED,
        Zlib::BEST_COMPRESSION,
      )
      stream.write json_articles
    end
    buffer
  end
end
