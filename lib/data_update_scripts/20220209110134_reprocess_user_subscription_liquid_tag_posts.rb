module DataUpdateScripts
  class ReprocessUserSubscriptionLiquidTagPosts
    def run
      Article.where("body_markdown ILIKE ?", "%{\% user_subscription%").find_each do |article|
        user = User.find_by(id: article.user_id)
        if user.user_subscription_tag_available?
          fixed_body_markdown = MarkdownProcessor::Fixer::FixAll.call(article.body_markdown)
          parsed = FrontMatterParser::Parser.new(:md).call(fixed_body_markdown)
          parsed_markdown = MarkdownProcessor::Parser.new(parsed.content, source: Article.new, user: user)

          processed_html = parsed_markdown.finalize
          article.update_column(:processed_html, processed_html)
        end
      end
    end
  end
end
