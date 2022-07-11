module Articles
  module Unpublish
    module_function

    def call(user, article)
      attributes = {}
      if article.has_frontmatter?
        body_markdown = article.body_markdown.sub(/\npublished:\s*true\s*\n/, "\npublished: false\n")
        attributes[:body_markdown] = body_markdown
      else
        attributes[:published] = false
      end

      Articles::Updater.call(user, article, attributes)
    end
  end
end
