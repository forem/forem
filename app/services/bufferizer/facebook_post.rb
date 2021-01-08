module Bufferizer
  class FacebookPost
    def self.call(article, post, admin_id)
      return unless article && post && admin_id

      BufferUpdate.buff!(
        article.id,
        fb_buffer_text(post, article),
        social_service_name: "facebook",
        admin_id: admin_id,
      )

      BufferUpdate.buff!(
        article.id,
        fb_buffer_text(post, article) + social_tags(article),
        social_service_name: "linkedin",
        admin_id: admin_id,
      )

      article.update(facebook_last_buffered: Time.current)
    end

    def self.fb_buffer_text(post, article)
      "#{post} #{URL.article(article)}"
    end

    private_class_method :fb_buffer_text

    def self.social_tags(article)
      # for linkedin's followable tags
      tags = article.tag_list.map { |tag| "##{tag}" }.join(" ")
      " #programming #softwareengineering #{tags}"
    end

    private_class_method :social_tags
  end
end
