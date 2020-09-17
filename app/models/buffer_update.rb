class BufferUpdate < ApplicationRecord
  SOCIAL_MEDIA = {
    "twitter" => ApplicationConfig["BUFFER_TWITTER_ID"],
    "facebook" => ApplicationConfig["BUFFER_FACEBOOK_ID"],
    "linkedin" => ApplicationConfig["BUFFER_LINKEDIN_ID"]
  }.freeze

  DEFAULT_SOCIAL_MEDIA = "twitter".freeze

  resourcify

  belongs_to :article
  validate :validate_body_text_recent_uniqueness, :validate_suggestion_limit
  validates :status, inclusion: { in: %w[pending sent_direct confirmed dismissed] }

  def self.buff!(article_id, text, **kwargs)
    social_service_name = kwargs.fetch(:social_service_name, DEFAULT_SOCIAL_MEDIA)
    buffer_profile_id_code = kwargs.fetch(:buffer_profile_id_code, SOCIAL_MEDIA.fetch(social_service_name))
    tag_id = kwargs[:tag_id]
    admin_id = kwargs[:admin_id]

    buffer_response = send_to_buffer(text, buffer_profile_id_code)
    create(
      article_id: article_id,
      tag_id: tag_id,
      body_text: text,
      approver_user_id: admin_id,
      buffer_profile_id_code: buffer_profile_id_code,
      social_service_name: social_service_name,
      buffer_response: buffer_response,
      status: "sent_direct",
    )
  end

  def self.upbuff!(buffer_update_id, admin_id, body_text, status)
    buffer_update = BufferUpdate.find(buffer_update_id)
    if status == "confirmed"
      buffer_response = send_to_buffer(body_text, buffer_update.buffer_profile_id_code)
      buffer_update.update!(buffer_response: buffer_response, status: status, approver_user_id: admin_id,
                            body_text: body_text)
    else
      buffer_update.update!(status: status, approver_user_id: admin_id)
    end
  end

  def self.send_to_buffer(text, buffer_profile_id_code)
    client = Buffer::Client.new(ApplicationConfig["BUFFER_ACCESS_TOKEN"])
    client.create_update(
      body: {
        text:
        text,
        profile_ids: [
          buffer_profile_id_code,
        ]
      },
    )
  end

  def self.twitter_default_text(article)
    [
      article.title,
      "\n\n",
      ("{ author: @#{article.user.twitter_username} } " if article.user.twitter_username?),
      SiteConfig.twitter_hashtag.presence,
    ].compact.join.strip
  end

  private

  def validate_body_text_recent_uniqueness
    return if persisted?

    relation = BufferUpdate
      .where(body_text: body_text, article_id: article_id, tag_id: tag_id, social_service_name: social_service_name)
      .where("created_at > ?", 2.minutes.ago)

    return unless relation.any?

    errors.add(:body_text, "\"#{body_text}\" has already been submitted very recently")
  end

  def validate_suggestion_limit
    return unless BufferUpdate.where(article_id: article_id, tag_id: tag_id,
                                     social_service_name: social_service_name).count > 2

    errors.add(:article_id, "already has multiple suggestions for #{social_service_name}")
  end
end
