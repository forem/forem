module Articles
  class Unpublish
    def self.call(article)
      if article.has_frontmatter?
        article.body_markdown.sub!(/\npublished:\s*true\s*\n/, "\npublished: false\n")
      else
        article.published = false
      end

      article.save
    end
  end
end
