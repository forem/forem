module DataUpdateScripts
  class UpdateArticleCachedAttributeAroundMainImage
    # @note This is a re-runniing of an earlier version of
    #       `lib/data_update_scripts/20220120052641_backfill_column_main_image_from_frontmatter.rb`

    # @see https://github.com/forem/forem/blob/9a11beec50f93dee1bbd58331028236205026084/lib/data_update_scripts/20220120052641_backfill_column_main_image_from_frontmatter.rb
    # for original version.
    def run
      Article.where(main_image_from_frontmatter: false).find_each do |article|
        fixed_body_markdown = MarkdownProcessor::Fixer::FixAll.call(article.body_markdown || "")
        parsed = FrontMatterParser::Parser.new(:md).call(fixed_body_markdown)
        article.update_column(:main_image_from_frontmatter, true) if parsed.front_matter&.key?("cover_image")
      end
    end
  end
end
