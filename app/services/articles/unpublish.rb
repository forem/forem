module Articles
  module Unpublish
    module_function

    def call(article)
      if article.has_frontmatter?
        article.body_markdown.sub!(/\npublished:\s*true\s*\n/, "\npublished: false\n")
      else
        article.published = false
      end

      article.save
    end
  end
end
