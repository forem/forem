class BufferUpdate < ApplicationRecord
  
  belongs_to :article

  def initialize(article_id, text, buffer_profile_id_code, social_service_name="twitter", tag_id=nil)
    
  end

  def self.buff!
    buffer_response = send_to_buffer
    self.create!(
      article_id: article_id,
      tag_id: tag_id,
      body_text: text,
      buffer_profile_id_code: buffer_profile_id_code,
      social_service_name: social_service_name,
      buffer_response: buffer_response,
    )
  end

  def send_to_buffer
    client = Buffer::Client.new(ApplicationConfig["BUFFER_ACCESS_TOKEN"])
    client.create_update(
      body: {
        text:
          twitter_buffer_text,
        profile_ids: [
          buffer_profile_id_code,
        ],
      },
    )
  end
end