module DataUpdateScripts
  class UpdateArticleFlagWithoutParsingArticle
    def run
      # Query cribbed from https://dev.to/admin/blazer/queries/545-articles-containing-a-given-string-in-the-markdown?substring=cover_image%3A+
      Article.where(main_image_from_frontmatter: false).find_each do |article|
        has_cover_image = false
        begin
          fixed_body_markdown = MarkdownProcessor::Fixer::FixAll.call(article.body_markdown || "")
          parsed = FrontMatterParser::Parser.new(:md).call(fixed_body_markdown)
          has_cover_image = parsed.front_matter.key?("cover_image")
        rescue StandardError
          # Piping this to /dev/null, because we can't assume this article is processible in our
          # current application state
          ForemStatsClient.increment "dus.update_article_flag_without_parsing_article.errors"
        end

        article.update_column(:main_image_from_frontmatter, true) if has_cover_image
      end
    end
  end
end
