require "zip"

class ArticleExportService
  attr_reader :user

  def initialize(user)
    @user = user
  end

  def export(slug: nil)
    articles = user.articles
    articles = articles.where(slug: slug) if slug.present?
    zip_json_articles(jsonify_articles(articles))
  end

  def export_and_deliver_to_inbox(slug: nil)
    zipped_export = export(slug: slug)
    zipped_export.rewind
    NotifyMailer.articles_exported_email(user, zipped_export.read).deliver
  end

  private

  def blacklisted_attributes
    %i[
      id abuse_removal_reason allow_big_edits allow_small_edits
      amount_due amount_paid approved automatically_renew boost_states
      collection_id collection_position email_digest_eligible
      facebook_last_buffered featured featured_number hotness_score
      ids_for_suggested_articles job_opportunity_id last_buffered
      last_invoiced_at live_now main_tag_name_for_social
      name_within_collection organization_id paid password
      receive_notifications removed_for_abuse second_user_id
      spaminess_rating third_user_id user_id video_state
    ]
  end

  def jsonify_articles(articles)
    articles_to_jsonify = []
    # this is done to load articles in batches, we don't want to hog the DB
    # if a user has lots and lots of articles
    articles.find_each do |article|
      articles_to_jsonify << article
    end
    articles_to_jsonify.to_json(except: blacklisted_attributes)
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
