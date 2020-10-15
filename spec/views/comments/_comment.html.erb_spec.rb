require "rails_helper"

RSpec.describe "rendering locals in a partial", type: :view do
  context "when comment is low-quality" do
    it "renders the comment with low-quality marker" do
      SiteConfig.mascot_image_url = "https://i.imgur.com/fKYKgo4.png"
      comment = build_stubbed(:comment, processed_html: "hi", score: CommentDecorator::LOW_QUALITY_THRESHOLD - 100)
      article = build_stubbed(:article)

      render "comments/comment",
             comment: comment,
             commentable: article,
             is_view_root: true,
             is_childless: true,
             subtree_html: ""

      expect(rendered).to match(/low-quality-comment-marker/)
        .and match(/low-quality-comment/)
        .and match(/sloan/)
        .and match(%r{Comment marked as low quality/non-constructive by the community})
      expect(rendered).to have_link "View code of conduct", href: "/code-of-conduct"
    end
  end
end
