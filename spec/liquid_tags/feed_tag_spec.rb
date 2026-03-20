require "rails_helper"

RSpec.describe FeedTag, type: :liquid_tag do
  let(:user) { create(:user) }
  let(:organization) { create(:organization) }
  let(:tag1) { Tag.find_or_create_by!(name: "javascript") }
  let(:tag2) { Tag.find_or_create_by!(name: "ruby") }
  let(:tag3) { Tag.find_or_create_by!(name: "python") }

  def parse_tag(input)
    Liquid::Template.parse("{% feed #{input} %}", { user: user })
  end

  def rendered_article_count(rendered)
    rendered.scan("data-feed-content-id").size
  end

  before do
    Liquid::Template.register_tag("feed", described_class)
  end

  describe "tag source" do
    it "renders posts from a single tag" do
      article = create(:article, published: true)
      article.update_columns(cached_tag_list: tag1.name)

      other = create(:article, published: true)
      other.update_columns(cached_tag_list: "unrelated")

      liquid = parse_tag("tag=#{tag1.name}")
      rendered = liquid.render
      expect(rendered).to include(article.title)
      expect(rendered).not_to include(other.title)
    end

    it "renders posts from multiple tags" do
      js_article = create(:article, published: true)
      js_article.update_columns(cached_tag_list: tag1.name)

      ruby_article = create(:article, published: true)
      ruby_article.update_columns(cached_tag_list: tag2.name)

      other = create(:article, published: true)
      other.update_columns(cached_tag_list: "unrelated")

      liquid = parse_tag("tags=#{tag1.name},#{tag2.name}")
      rendered = liquid.render
      expect(rendered).to include(js_article.title)
      expect(rendered).to include(ruby_article.title)
      expect(rendered).not_to include(other.title)
    end
  end

  describe "org source" do
    it "renders posts from an organization" do
      org_article = create(:article, organization: organization, published: true)
      other = create(:article, published: true)

      liquid = parse_tag("org=#{organization.slug}")
      rendered = liquid.render
      expect(rendered).to include(org_article.title)
      expect(rendered).not_to include(other.title)
    end
  end

  describe "combined org + tags" do
    it "filters org posts by tag" do
      tagged = create(:article, organization: organization, published: true)
      tagged.update_columns(cached_tag_list: tag1.name)

      untagged = create(:article, organization: organization, published: true)
      untagged.update_columns(cached_tag_list: "other")

      liquid = parse_tag("org=#{organization.slug} tag=#{tag1.name}")
      rendered = liquid.render
      expect(rendered).to include(tagged.title)
      expect(rendered).not_to include(untagged.title)
    end

    it "filters org posts by multiple tags" do
      js_article = create(:article, organization: organization, published: true)
      js_article.update_columns(cached_tag_list: tag1.name)

      ruby_article = create(:article, organization: organization, published: true)
      ruby_article.update_columns(cached_tag_list: tag2.name)

      untagged = create(:article, organization: organization, published: true)
      untagged.update_columns(cached_tag_list: "other")

      liquid = parse_tag("org=#{organization.slug} tags=#{tag1.name},#{tag2.name}")
      rendered = liquid.render
      expect(rendered).to include(js_article.title)
      expect(rendered).to include(ruby_article.title)
      expect(rendered).not_to include(untagged.title)
    end
  end

  describe "filters" do
    it "applies limit" do
      5.times do
        article = create(:article, published: true)
        article.update_columns(cached_tag_list: tag1.name)
      end

      liquid = parse_tag("tag=#{tag1.name} limit=3")
      rendered = liquid.render
      expect(rendered_article_count(rendered)).to eq(3)
    end

    it "sorts by reactions" do
      low = create(:article, published: true)
      low.update_columns(cached_tag_list: tag1.name, public_reactions_count: 1)

      high = create(:article, published: true)
      high.update_columns(cached_tag_list: tag1.name, public_reactions_count: 100)

      liquid = parse_tag("tag=#{tag1.name} sort=reactions")
      rendered = liquid.render
      expect(rendered.index(high.title)).to be < rendered.index(low.title)
    end

    it "filters by min_reactions" do
      low = create(:article, published: true)
      low.update_columns(cached_tag_list: tag1.name, public_reactions_count: 2)

      high = create(:article, published: true)
      high.update_columns(cached_tag_list: tag1.name, public_reactions_count: 20)

      liquid = parse_tag("tag=#{tag1.name} min_reactions=10")
      rendered = liquid.render
      expect(rendered).to include(high.title)
      expect(rendered_article_count(rendered)).to eq(1)
    end

    it "filters by since with relative duration" do
      old = create(:article, :past, published: true, past_published_at: 60.days.ago)
      old.update_columns(cached_tag_list: tag1.name)

      recent = create(:article, :past, published: true, past_published_at: 5.days.ago)
      recent.update_columns(cached_tag_list: tag1.name)

      liquid = parse_tag("tag=#{tag1.name} since=30d")
      rendered = liquid.render
      expect(rendered).to include(recent.title)
      expect(rendered).not_to include(old.title)
    end
  end

  describe "validation errors" do
    it "raises an error when no source is provided" do
      expect do
        parse_tag("limit=5")
      end.to raise_error(StandardError, /requires at least one source/)
    end

    it "raises an error for unknown org" do
      expect do
        parse_tag("org=nonexistent")
      end.to raise_error(StandardError, /not found/)
    end

    it "renders empty for a non-existent tag" do
      liquid = parse_tag("tag=nonexistent")
      rendered = liquid.render
      expect(rendered).to include("ltag-feed")
      expect(rendered_article_count(rendered)).to eq(0)
    end

    it "renders only matching articles when some tags do not exist" do
      article = create(:article, published: true)
      article.update_columns(cached_tag_list: tag1.name)

      liquid = parse_tag("tags=#{tag1.name},nonexistent")
      rendered = liquid.render
      expect(rendered).to include(article.title)
    end

    it "raises an error for invalid option key" do
      expect do
        parse_tag("tag=#{tag1.name} foo=bar")
      end.to raise_error(StandardError, /Invalid option/)
    end

    it "raises an error for invalid limit" do
      expect do
        parse_tag("tag=#{tag1.name} limit=99")
      end.to raise_error(StandardError, /Limit must be between/)
    end

    it "raises an error for invalid sort" do
      expect do
        parse_tag("tag=#{tag1.name} sort=invalid")
      end.to raise_error(StandardError, /Sort must be one of/)
    end
  end
end
