module DataUpdateScripts
  class BackfillColumnMainImageFromFrontmatter
    def run
      Article.where(main_image_from_frontmatter: false).find_each do |article|
        fixed_body_markdown = MarkdownProcessor::Fixer::FixAll.call(article.body_markdown || "")
        parsed = FrontMatterParser::Parser.new(:md).call(fixed_body_markdown)
        article.update!(main_image_from_frontmatter: true) if parsed.front_matter&.key?("cover_image")
      end
    end
  end
end
