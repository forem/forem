require "rails_helper"

RSpec.describe OrgPostsTag, type: :liquid_tag do
  let(:organization) { create(:organization) }
  let(:liquid_tag_options) { { source: organization, user: nil } }

  def parse_tag(slug, options = liquid_tag_options)
    Liquid::Template.parse("{% org_posts #{slug} %}", options)
  end

  before do
    Liquid::Template.register_tag("org_posts", described_class)
  end

  context "when given a valid organization slug" do
    it "renders published articles" do
      article = create(:article, organization: organization, published: true)
      liquid = parse_tag(organization.slug)
      rendered = liquid.render
      expect(rendered).to include(article.title)
    end

    it "renders without error when no articles exist" do
      liquid = parse_tag(organization.slug)
      rendered = liquid.render
      expect(rendered).to include("org-posts-liquid")
    end
  end

  context "when given an invalid slug" do
    it "raises an error" do
      expect do
        parse_tag("nonexistent-org-slug")
      end.to raise_error(StandardError, /Invalid organization slug/)
    end
  end

  context "when used outside Organization context" do
    let(:article_source) { create(:article) }

    it "raises an InvalidParseContext error" do
      expect do
        parse_tag(organization.slug, { source: article_source, user: nil })
      end.to raise_error(LiquidTags::Errors::InvalidParseContext)
    end
  end
end
