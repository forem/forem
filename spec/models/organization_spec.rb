require "rails_helper"

RSpec.describe Organization, type: :model do
  let(:user)         { create(:user) }
  let(:organization) { create(:organization) }

  it { is_expected.to have_many(:sponsorships) }
  it { is_expected.to have_many(:organization_memberships).dependent(:delete_all) }

  describe "#name" do
    it "rejects names with over 50 characters" do
      organization.name = Faker::Lorem.characters(51)
      expect(organization).not_to be_valid
    end

    it "accepts names with 50 or less characters" do
      expect(organization).to be_valid
    end
  end

  describe "#summary" do
    it "rejects summaries with over 1000 characters" do
      organization.summary = Faker::Lorem.characters(1001)
      expect(organization).not_to be_valid
    end

    it "accepts summaries with 1000 or less characters" do
      expect(organization).to be_valid
    end
  end

  describe "#text_color_hex" do
    it "accepts hex color codes" do
      organization.text_color_hex = Faker::Color.hex_color
      expect(organization).to be_valid
    end

    it "rejects color names" do
      organization.text_color_hex = Faker::Color.color_name
      expect(organization).not_to be_valid
    end

    it "rejects RGB colors" do
      organization.text_color_hex = Faker::Color.rgb_color
      expect(organization).not_to be_valid
    end

    it "rejects wrong color format" do
      organization.text_color_hex = "##{Faker::Lorem.words(4)}"
      expect(organization).not_to be_valid
    end
  end

  describe "#slug" do
    it "accepts properly formatted slug" do
      organization.slug = "heyho"
      expect(organization).to be_valid
    end

    it "accepts properly formatted slug with numbers" do
      organization.slug = "HeyHo2"
      expect(organization).to be_valid
    end

    it "rejects slug with spaces" do
      organization.slug = "hey ho"
      expect(organization).not_to be_valid
    end

    it "rejects slug with unacceptable character" do
      organization.slug = "Hey&Ho"
      expect(organization).not_to be_valid
    end

    it "downcases slug" do
      organization.slug = "HaHaHa"
      organization.save
      expect(organization.slug).to eq("hahaha")
    end

    it "rejects reserved slug" do
      organization = build(:organization, slug: "settings")
      expect(organization).not_to be_valid
      expect(organization.errors[:slug].to_s.include?("reserved")).to be true
    end

    it "takes organization slug into account " do
      create(:user, username: "lightalloy")
      organization = build(:organization, slug: "lightalloy")
      expect(organization).not_to be_valid
      expect(organization.errors[:slug].to_s.include?("taken")).to be true
    end

    it "takes podcast slug into account" do
      create(:podcast, slug: "devpodcast")
      organization = build(:organization, slug: "devpodcast")
      expect(organization).not_to be_valid
      expect(organization.errors[:slug].to_s.include?("taken")).to be true
    end

    it "takes page slug into account" do
      create(:page, slug: "needed_info_for_site")
      organization = build(:organization, slug: "needed_info_for_site")
      expect(organization).not_to be_valid
      expect(organization.errors[:slug].to_s.include?("taken")).to be true
    end

    it "triggers cache busting on save" do
      expect { build(:organization).save }.to have_enqueued_job.on_queue("organizations_bust_cache")
    end
  end

  describe "#url" do
    it "accepts valid http url" do
      organization.url = "http://ben.com"
      expect(organization).to be_valid
    end

    it "accepts valid secure http url" do
      organization.url = "https://ben.com"
      expect(organization).to be_valid
    end

    it "rejects invalid http url" do
      organization.url = "ben.com"
      expect(organization).not_to be_valid
    end
  end

  describe "#check_for_slug_change" do
    def create_article_for_organization
      user.update(organization_id: organization.id, org_admin: true)
      create(:article, organization_id: organization.id, user_id: user.id)
    end

    it "properly updates the slug/username" do
      random_new_slug = "slug_#{rand(10_000)}"
      organization.update(slug: random_new_slug)
      expect(organization.slug).to eq random_new_slug
    end

    it "updates old_slug to original slug if slug was changed" do
      original_slug = organization.slug
      organization.update(slug: "slug_#{rand(10_000)}")
      expect(organization.old_slug).to eq original_slug
    end

    it "updates old_old_slug properly if slug was changed and there was an old_slug" do
      original_slug = organization.slug
      organization.update(slug: "something_else")
      organization.update(slug: "another_slug")
      expect(organization.old_old_slug).to eq original_slug
    end

    it "updates the paths of the organization's articles" do
      create_article_for_organization
      new_slug = "slug_#{rand(10_000)}"
      organization.update(slug: new_slug)
      article = Article.find_by(organization_id: organization.id)
      expect(article.path).to include new_slug
    end

    it "updates article cached_organizations" do
      create_article_for_organization
      new_slug = "slug_#{rand(10_000)}"
      organization.update(slug: new_slug)
      article = Article.find_by(organization_id: organization.id)
      expect(article.cached_organization.slug).to eq new_slug
    end
  end
end
