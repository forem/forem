require "rails_helper"

RSpec.describe OrgPostsTag, type: :liquid_tag do
  let(:organization) { create(:organization) }
  let(:liquid_tag_options) { { source: organization, user: nil } }

  def parse_tag(input, options = liquid_tag_options)
    Liquid::Template.parse("{% org_posts #{input} %}", options)
  end

  def rendered_article_count(rendered)
    rendered.scan("data-feed-content-id").size
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
      expect(rendered).to include("ltag-org-posts")
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

  describe "limit option" do
    it "limits the number of posts returned" do
      create_list(:article, 8, organization: organization, published: true)
      liquid = parse_tag("#{organization.slug} limit=5")
      rendered = liquid.render
      expect(rendered_article_count(rendered)).to eq(5)
    end

    it "defaults to 8 posts" do
      create_list(:article, 10, organization: organization, published: true)
      liquid = parse_tag(organization.slug)
      rendered = liquid.render
      expect(rendered_article_count(rendered)).to eq(8)
    end

    it "raises an error for limit above 30" do
      expect do
        parse_tag("#{organization.slug} limit=31")
      end.to raise_error(StandardError, /Limit must be between 1 and 30/)
    end

    it "raises an error for limit of 0" do
      expect do
        parse_tag("#{organization.slug} limit=0")
      end.to raise_error(StandardError, /Limit must be between 1 and 30/)
    end

    it "raises an error for non-integer limit" do
      expect do
        parse_tag("#{organization.slug} limit=abc")
      end.to raise_error(StandardError, /Limit must be between 1 and 30/)
    end
  end

  describe "sort option" do
    let!(:low_reactions_article) do
      article = create(:article, organization: organization, published: true)
      article.update_columns(public_reactions_count: 1, comments_count: 1, score: 1)
      article
    end
    let!(:high_reactions_article) do
      article = create(:article, organization: organization, published: true)
      article.update_columns(public_reactions_count: 100, comments_count: 50, score: 200)
      article
    end

    it "sorts by reactions" do
      liquid = parse_tag("#{organization.slug} sort=reactions")
      rendered = liquid.render
      high_pos = rendered.index(high_reactions_article.title)
      low_pos = rendered.index(low_reactions_article.title)
      expect(high_pos).to be < low_pos
    end

    it "sorts by comments" do
      liquid = parse_tag("#{organization.slug} sort=comments")
      rendered = liquid.render
      high_pos = rendered.index(high_reactions_article.title)
      low_pos = rendered.index(low_reactions_article.title)
      expect(high_pos).to be < low_pos
    end

    it "sorts by score" do
      liquid = parse_tag("#{organization.slug} sort=score")
      rendered = liquid.render
      high_pos = rendered.index(high_reactions_article.title)
      low_pos = rendered.index(low_reactions_article.title)
      expect(high_pos).to be < low_pos
    end

    it "defaults to recent (published_at desc)" do
      # Make low_reactions_article more recent
      low_reactions_article.update_columns(published_at: 1.minute.ago)
      high_reactions_article.update_columns(published_at: 1.hour.ago)

      liquid = parse_tag(organization.slug)
      rendered = liquid.render
      low_pos = rendered.index(low_reactions_article.title)
      high_pos = rendered.index(high_reactions_article.title)
      expect(low_pos).to be < high_pos
    end

    it "raises an error for invalid sort value" do
      expect do
        parse_tag("#{organization.slug} sort=invalid")
      end.to raise_error(StandardError, /Sort must be one of/)
    end
  end

  describe "min_reactions option" do
    it "filters posts with fewer reactions" do
      low = create(:article, organization: organization, published: true)
      low.update_columns(public_reactions_count: 2)
      high = create(:article, organization: organization, published: true)
      high.update_columns(public_reactions_count: 10)

      liquid = parse_tag("#{organization.slug} min_reactions=5")
      rendered = liquid.render
      expect(rendered).to include(high.title)
      expect(rendered_article_count(rendered)).to eq(1)
    end
  end

  describe "min_comments option" do
    it "filters posts with fewer comments" do
      low = create(:article, organization: organization, published: true)
      low.update_columns(comments_count: 1)
      high = create(:article, organization: organization, published: true)
      high.update_columns(comments_count: 10)

      liquid = parse_tag("#{organization.slug} min_comments=3")
      rendered = liquid.render
      expect(rendered).to include(high.title)
      expect(rendered_article_count(rendered)).to eq(1)
    end
  end

  describe "since option" do
    it "filters posts older than relative duration" do
      old_article = create(:article, :past, organization: organization, published: true, past_published_at: 60.days.ago)
      recent_article = create(:article, :past, organization: organization, published: true, past_published_at: 10.days.ago)

      liquid = parse_tag("#{organization.slug} since=30d")
      rendered = liquid.render
      expect(rendered).to include(recent_article.title)
      expect(rendered).not_to include(old_article.title)
    end

    it "filters posts before an absolute date" do
      old_article = create(:article, :past, organization: organization, published: true, past_published_at: Date.new(2024, 6, 1))
      recent_article = create(:article, :past, organization: organization, published: true, past_published_at: Date.new(2025, 6, 1))

      liquid = parse_tag("#{organization.slug} since=2025-01-01")
      rendered = liquid.render
      expect(rendered).to include(recent_article.title)
      expect(rendered).not_to include(old_article.title)
    end

    it "raises an error for invalid since format" do
      expect do
        parse_tag("#{organization.slug} since=xyz")
      end.to raise_error(StandardError, /Since must be a relative duration/)
    end
  end

  describe "combined filters" do
    it "applies multiple filters together" do
      # Old article with high engagement -filtered by since
      old_popular = create(:article, :past, organization: organization, published: true, past_published_at: 120.days.ago)
      old_popular.update_columns(public_reactions_count: 20)

      # Recent article with low engagement -filtered by min_reactions
      recent_low = create(:article, :past, organization: organization, published: true, past_published_at: 5.days.ago)
      recent_low.update_columns(public_reactions_count: 1)

      # Recent article with high engagement -should be included
      matching = create(:article, :past, organization: organization, published: true, past_published_at: 5.days.ago)
      matching.update_columns(public_reactions_count: 15)

      liquid = parse_tag("#{organization.slug} limit=5 sort=reactions min_reactions=10 since=90d")
      rendered = liquid.render
      expect(rendered).to include(matching.title)
      expect(rendered).not_to include(old_popular.title)
      expect(rendered).not_to include(recent_low.title)
    end
  end

  describe "invalid options" do
    it "raises an error for unknown option key" do
      expect do
        parse_tag("#{organization.slug} foo=bar")
      end.to raise_error(StandardError, /Invalid option 'foo'/)
    end

    it "raises an error for malformed option" do
      expect do
        parse_tag("#{organization.slug} notanoption")
      end.to raise_error(StandardError, /Invalid option/)
    end
  end
end
