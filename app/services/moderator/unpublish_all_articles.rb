module Moderator
  class UnpublishAllArticles
    include Sidekiq::Worker

    sidekiq_options queue: :medium_priority, retry: 10

    def perform(user_id)
      user = User.find_by(id: user_id)
      return unless user

      user.articles.published.find_each do |article|
        if article.has_frontmatter?
          article.body_markdown.sub!(/\npublished:\s*true\s*\n/, "\npublished: false\n")
        else
          article.published = false
        end
        article.save(validate: false)
      end
    end
  end
end
