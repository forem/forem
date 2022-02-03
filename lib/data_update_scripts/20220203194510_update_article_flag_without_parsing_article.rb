module DataUpdateScripts
  class UpdateArticleFlagWithoutParsingArticle
    def run
      # Query cribbed from https://dev.to/admin/blazer/queries/545-articles-containing-a-given-string-in-the-markdown?substring=cover_image%3A+
      Article
        .where.not(main_image: nil)
        .where(main_image_from_frontmatter: false)
        .where("body_markdown ILIKE ?", "---%cover_image:%---%")
        .update_all(main_image_from_frontmatter: true)
    end
  end
end
