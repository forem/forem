class BufferUpdate < ApplicationRecord
  belongs_to :article
  validate :validate_body_text_recent_uniqueness
  validates :status, inclusion: { in: %w[pending sent_direct confirmed dismissed] }

  def self.buff!(article_id, text, buffer_profile_id_code, social_service_name = "twitter", tag_id = nil)
    buffer_response = send_to_buffer(text, buffer_profile_id_code)
    create(
      article_id: article_id,
      tag_id: tag_id,
      body_text: text,
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
      buffer_update.update!(buffer_response: buffer_response, status: status, approver_user_id: admin_id, body_text: body_text)
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

  private

  def validate_body_text_recent_uniqueness
    return if persisted?

    if BufferUpdate.where(body_text: body_text, article_id: article_id, tag_id: tag_id, social_service_name: social_service_name).
        where("created_at > ?", 2.minutes.ago).any?
      errors.add(:body_text, "\"#{body_text}\" has already been submitted very recently")
    end
  end
end
