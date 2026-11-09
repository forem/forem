require "rails_helper"

RSpec.describe Organization do
  let(:organization) { create(:organization) }

  describe "validations" do
    describe "builtin validations" do
      it { is_expected.to have_many(:articles).dependent(:nullify) }
      it { is_expected.to have_many(:collections).dependent(:nullify) }
      it { is_expected.to have_many(:credits).dependent(:restrict_with_error) }
      it { is_expected.to have_many(:billboards).dependent(:destroy) }
      it { is_expected.to have_many(:listings).dependent(:destroy) }
      it { is_expected.to have_many(:notifications).dependent(:delete_all) }
      it { is_expected.to have_many(:organization_memberships).dependent(:delete_all) }
      it { is_expected.to have_many(:profile_pins).dependent(:destroy) }
      it { is_expected.to have_many(:unspent_credits).class_name("Credit") }
      it { is_expected.to have_many(:users).through(:organization_memberships) }

      it { is_expected.to validate_length_of(:company_size).is_at_most(7) }
      it { is_expected.to validate_length_of(:cta_body_markdown).is_at_most(256) }
      it { is_expected.to validate_length_of(:cta_button_text).is_at_most(20) }
      it { is_expected.to validate_length_of(:cta_button_url).is_at_most(255) }
      it { is_expected.to validate_length_of(:email).is_at_most(64) }
      it { is_expected.to validate_length_of(:github_username).is_at_most(50) }
      it { is_expected.to validate_length_of(:location).is_at_most(64) }
      it { is_expected.to validate_length_of(:name).is_at_most(50) }
      it { is_expected.to validate_length_of(:proof).is_at_most(1500) }
      it { is_expected.to validate_length_of(:secret).is_equal_to(100) }
      it { is_expected.to validate_length_of(:slug).is_at_least(2).is_at_most(30) }
      it { is_expected.to validate_length_of(:story).is_at_most(640) }
      it { is_expected.to validate_length_of(:summary).is_at_most(250) }
      it { is_expected.to validate_length_of(:tag_line).is_at_most(60) }
      it { is_expected.to validate_length_of(:tech_stack).is_at_most(640) }
      it { is_expected.to validate_length_of(:twitter_username).is_at_most(15) }
      it { is_expected.to validate_length_of(:url).is_at_most(200) }
      it { is_expected.to validate_presence_of(:articles_count) }
      it { is_expected.to validate_presence_of(:credits_count) }
      it { is_expected.to validate_presence_of(:name) }
      it { is_expected.to validate_presence_of(:profile_image) }
      it { is_expected.to validate_presence_of(:slug) }
      it { is_expected.to validate_presence_of(:spent_credits_count) }
      it { is_expected.to validate_presence_of(:unspent_credits_count) }

      it "validates uniqueness of secret and slug", :aggregate_failures do
        expect(organization).to validate_uniqueness_of(:secret).allow_nil
        expect(organization).to validate_uniqueness_of(:slug).case_insensitive
      end

      it { is_expected.not_to allow_value("#xyz").for(:bg_color_hex) }
      it { is_expected.not_to allow_value("#xyz").for(:text_color_hex) }
      it { is_expected.to allow_value("#aabbcc").for(:bg_color_hex) }
      it { is_expected.to allow_value("#aabbcc").for(:text_color_hex) }
      it { is_expected.to allow_value("#abc").for(:bg_color_hex) }
      it { is_expected.to allow_value("#abc").for(:text_color_hex) }
      it { is_expected.not_to allow_value("3.0").for(:company_size) }
      it { is_expected.to allow_value("3").for(:company_size) }

      it { is_expected.to allow_value("1345abc").for(:slug) }
      it { is_expected.to allow_value("just_non_digit_characters").for(:slug) }
      it { is_expected.to allow_value("123_4").for(:slug) }
      it { is_expected.not_to allow_value("1234").for(:slug) }
    end

    # rubocop:disable RSpec/NestedGroups
    describe "custom validations" do
      let(:organization) { build_stubbed(:organization) }

      describe "#validate_header_cta" do
        it "allows valid HTTP and HTTPS urls" do
          organization.header_cta = { "text" => "Click Here", "url" => "https://example.com" }
          expect(organization).to be_valid
        end

        it "rejects javascript pseudo-protocols to prevent Stored XSS" do
          organization.header_cta = { "text" => "Click Here", "url" => "javascript:alert(1)//" }
          expect(organization).not_to be_valid
          expect(organization.errors[:header_cta]).to include("Link must be a valid HTTP, HTTPS, or Mailto URL")
        end

        it "rejects javascript pseudo-protocols in dropdown links to prevent Stored XSS" do
          organization.header_cta = {
            "text" => "Dropdown",
            "links" => [{ "text" => "Malicious", "url" => "javascript:alert(1)//" }]
          }
          expect(organization).not_to be_valid
          expect(organization.errors[:header_cta]).to include("Link must be a valid HTTP, HTTPS, or Mailto URL")
        end
      end

      describe "#validate_social_links" do
        it "allows valid domains matching the platform" do
          organization.social_links = { "youtube" => "https://youtube.com/c/forem" }
          expect(organization).to be_valid
        end

        it "allows valid alternate domains designed for the platform" do
          organization.social_links = { "youtube" => "https://youtu.be/forem" }
          expect(organization).to be_valid
        end

        it "rejects cross-platform domain spoofing" do
          organization.social_links = { "youtube" => "https://evildomain.com/youtube" }
          expect(organization).not_to be_valid
          expect(organization.errors[:social_links]).to include("URL domain must match the selected platform (Youtube)")
        end

        it "rejects javascript pseudo-protocols to prevent XSS" do
          organization.social_links = { "youtube" => "javascript:alert(1)//https://youtube.com" }
          expect(organization).not_to be_valid
          expect(organization.errors[:social_links]).to include("must be valid HTTP or HTTPS URLs")
        end
      end
    end
    # rubocop:enable RSpec/NestedGroups
  end

  context "when callbacks are triggered before save" do
    it "generates a secret if set to empty string or nil", :aggregate_failures do
      organization.secret = ""
      organization.save
      expect(organization.reload.secret).not_to eq("")

      organization.secret = nil
      organization.save
      expect(organization.reload.secret).not_to be_nil
    end
  end

  describe "#name" do
    let(:organization) { build_stubbed(:organization) }

    it "rejects names with over 50 characters" do
      organization.name = "x" * 51
      expect(organization).not_to be_valid
    end

    it "accepts names with 50 or less characters" do
      organization.name = "x" * 50
      expect(organization).to be_valid
    end
  end

  describe "#summary" do
    let(:organization) { build_stubbed(:organization) }

    it "rejects summaries with over 250 characters" do
      organization.summary = "x" * 251
      expect(organization).not_to be_valid
    end

    it "accepts summaries with 250 or less characters" do
      organization.summary = "x" * 250
      expect(organization).to be_valid
    end
  end

  describe "#text_color_hex" do
    let(:organization) { build_stubbed(:organization) }

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
      organization.text_color_hex = "#FOOBAR"
      expect(organization).not_to be_valid
    end
  end

  describe "#slug" do
    let(:organization) { build(:organization) }

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

    it "takes organization slug into account" do
      create(:user, :without_profile, username: "lightalloy", profile_image: nil)
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

    it "takes sitemap into account" do
      organization = build(:organization, slug: "sitemap-yo")
      expect(organization).not_to be_valid
      expect(organization.errors[:slug].to_s.include?("taken")).to be true
    end

    context "when callbacks are triggered after save" do
      let(:organization) { build(:organization) }

      before do
        allow(Organizations::BustCacheWorker).to receive(:perform_async)
      end

      it "triggers cache busting on save" do
        organization.save
        expect(Organizations::BustCacheWorker).to have_received(:perform_async).with(organization.id, organization.slug)
      end
    end
  end

  describe "#url" do
    let(:organization) { build_stubbed(:organization) }

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
    let(:user) { create(:user, :without_profile, profile_image: nil) }

    it "updates slug, old_slug, and old_old_slug across successive changes", :aggregate_failures do
      original_slug = organization.slug
      first_slug = "slug_#{rand(10_000)}"
      organization.update(slug: first_slug)
      expect(organization.slug).to eq(first_slug)
      expect(organization.old_slug).to eq(original_slug)

      organization.update(slug: "another_slug")
      expect(organization.slug).to eq("another_slug")
      expect(organization.old_slug).to eq(first_slug)
      expect(organization.old_old_slug).to eq(original_slug)
    end

    context "when dealing with organization articles" do
      before do
        create(:organization_membership, user: user, organization: organization, type_of_user: "admin")
        article = create(:article, organization: organization, user: user, with_tags: false, with_main_image: false)
        organization.articles << article
        organization.save
      end

      it "updates the paths and cached_organizations of the organization's articles", :aggregate_failures do
        new_slug = "slug_#{rand(10_000)}"

        sidekiq_perform_enqueued_jobs(only: Organizations::UpdateOrganizationArticlesPathsWorker) do
          organization.update(slug: new_slug)
        end

        article = Article.find_by(organization_id: organization.id)
        expect(article.path).to include(new_slug)
        expect(article.cached_organization.slug).to eq(new_slug)
      end

      it "updates article's cached_organization profile image", :aggregate_failures do
        # tl;dr - verifying fix for https://github.com/forem/forem/issues/17041
        article = Article.find_by(organization_id: organization.id)
        expect(article.cached_organization.profile_image_url).to eq(organization.profile_image_url)

        create(:article, organization: organization, user: user, with_tags: false, with_main_image: false)

        # A foible of CarrierWave is that I can't re-upload for the same model in memory.  I need to
        # refind the record.  #reload does not work either.
        reloaded_org = described_class.find(organization.id)

        expect do
          reloaded_org.profile_image = File.open(Rails.root.join("app/assets/images/2.png"))
          reloaded_org.save!
        end.to change { reloaded_org.reload.profile_image_url }

        sidekiq_perform_enqueued_jobs

        articles_profile_image_urls = reloaded_org.articles
          .map { |art| art.reload.cached_organization.profile_image_url }.uniq

        expect(articles_profile_image_urls).to eq([reloaded_org.profile_image_url])
      end

      # these tests rely on `Organization.update_articles_cached_organization` callback,
      # which will eventually invoke the trigger
      # rubocop:disable RSpec/NestedGroups
      context "when callbacks eventually invoke the trigger on Article.reading_list_document" do
        it "updates reading_list_document when updating name but not company_size", :aggregate_failures do
          article = Article.find_by(organization_id: organization.id)
          old_reading_list_document = article.reading_list_document

          organization.update(company_size: "200")
          expect(article.reload.reading_list_document).to eq(old_reading_list_document)

          organization.update(name: "ACME Org")
          sidekiq_perform_enqueued_jobs
          expect(article.reload.reading_list_document).not_to eq(old_reading_list_document)
        end
      end
      # rubocop:enable RSpec/NestedGroups
    end
  end

  describe ".find_by_slug_or_legacy" do
    it "finds an organization by its current, old, or old-old slug" do
      original_slug = organization.slug
      organization.update(slug: "second_slug")
      organization.update(slug: "third_slug")

      # rubocop:disable Rails/DynamicFindBy
      expect(described_class.find_by_slug_or_legacy("third_slug")).to eq(organization)
      expect(described_class.find_by_slug_or_legacy("second_slug")).to eq(organization)
      expect(described_class.find_by_slug_or_legacy(original_slug)).to eq(organization)
      expect(described_class.find_by_slug_or_legacy("missing_slug")).to be_nil
      # rubocop:enable Rails/DynamicFindBy
    end

    it "uses indexes on the legacy slug columns" do
      indexed_columns = described_class.connection.indexes(:organizations).map(&:columns)
      expect(indexed_columns).to include(["old_slug"], ["old_old_slug"])
    end
  end

  describe "#enough_credits?" do
    it "returns false if the user has less unspent credits than neeed" do
      expect(organization.enough_credits?(1)).to be(false)
    end

    it "returns true if the user has the exact amount of unspent credits" do
      create(:credit, organization: organization, spent: false)
      expect(organization.enough_credits?(1)).to be(true)
    end

    it "returns true if the user has more unspent credits than needed" do
      create_list(:credit, 2, organization: organization, spent: false)
      expect(organization.enough_credits?(1)).to be(true)
    end
  end

  describe "#public_articles_count" do
    it "returns 0 when no articles are published and counts only published articles", :aggregate_failures do
      user = create(:user, :without_profile, profile_image: nil)
      create(:article, organization: organization, user: user, published: false,
                       with_tags: false, with_main_image: false)
      expect(organization.public_articles_count).to eq(0)

      published_articles = create_list(:article, 2, organization: organization, user: user, published: true,
                                                    with_tags: false, with_main_image: false)
      expect(organization.public_articles_count).to eq(published_articles.count)
    end
  end

  describe ".simple_name_match" do
    before do
      create(:organization, name: "Not Matching")
      create(:organization, name: "For Fans of Books")
      create(:organization, name: "Boo! A Ghost")
    end

    it "finds them by simple ilike match and returns all orgs on empty query", :aggregate_failures do
      query = "boo"
      results = described_class.simple_name_match(query)
      expect(results.pluck(:name)).to eq(["Boo! A Ghost", "For Fans of Books"])

      query = "book"
      results = described_class.simple_name_match(query)
      expect(results.pluck(:name)).to eq(["For Fans of Books"])

      query = "  BOOK  "
      results = described_class.simple_name_match(query)
      expect(results.pluck(:name)).to eq(["For Fans of Books"])

      query = nil
      results = described_class.simple_name_match(query)
      expect(results.size).to eq(3)

      query = ""
      results = described_class.simple_name_match(query)
      expect(results.size).to eq(3)

      query = "        "
      results = described_class.simple_name_match(query)
      expect(results.size).to eq(3)
    end
  end

  describe "#generate_social_images" do
    before do
      organization
      allow(Images::SocialImageWorker).to receive(:perform_async)
    end

    it "enqueues SocialImageWorker only when displayed primary details change", :aggregate_failures do
      organization.update!(story: "Our long story", company_size: "50", twitter_username: "orgtwitter")
      expect(Images::SocialImageWorker).not_to have_received(:perform_async)

      organization.update!(name: "New name for this org!")
      expect(Images::SocialImageWorker).to have_received(:perform_async).with(organization.id, "Organization").once

      organization.update!(summary: "Updated org summary")
      expect(Images::SocialImageWorker).to have_received(:perform_async).with(organization.id, "Organization").twice
    end
  end

  describe "#bust_cache" do
    context "when a new user is added to the organization" do
      let(:user) { create(:user, :without_profile, profile_image: nil) }

      it "calls BustCachePathWorker after creating an organization membership" do
        org_membership = OrganizationMembership.create(user: user, organization: organization, type_of_user: "admin")

        allow(org_membership).to receive(:bust_cache)
        org_membership.save
        expect(org_membership).to have_received(:bust_cache)
      end
    end
  end

  context "when indexing with Algolia", :algolia do
    it "indexes the organization on create" do
      search_index_worker = AlgoliaSearch::SearchIndexWorker
      allow(search_index_worker).to receive(:perform_async)
      create(:organization)
      expect(search_index_worker).to have_received(:perform_async).with("Organization", kind_of(Integer), false).once
    end
  end

  describe "#readme_page?" do
    it "returns true when organization has a page" do
      create(:page, organization: organization, body_markdown: "# Hello",
                    title: organization.name, description: "desc", slug: "#{organization.slug}-page")
      expect(organization.readme_page?).to be(true)
    end

    it "returns false when organization has no pages" do
      expect(organization.readme_page?).to be(false)
    end
  end

  describe "#ordered_pages" do
    it "orders pages by position and uses creation order as a stable fallback when positions are equal" do
      first_page = create(:page, organization: organization, position: 0, created_at: 2.hours.ago)
      second_page = create(:page, organization: organization, position: 0, created_at: 1.hour.ago)
      promoted_page = create(:page, organization: organization, position: -1, created_at: Time.current)

      expect(organization.ordered_pages).to eq([promoted_page, first_page, second_page])
    end
  end

  describe "#flipper_id" do
    let(:organization) { build_stubbed(:organization) }

    it "returns a string with Organization prefix and id" do
      expect(organization.flipper_id).to eq("Organization;#{organization.id}")
    end
  end

  describe "#fully_trusted?" do
    let(:organization) { build_stubbed(:organization) }

    it "returns true when fully_trusted is true" do
      organization.fully_trusted = true
      expect(organization.fully_trusted?).to be true
    end

    it "returns false when fully_trusted is false" do
      organization.fully_trusted = false
      expect(organization.fully_trusted?).to be false
    end
  end

  describe "#active_users" do
    let(:user1) { create(:user, :without_profile, profile_image: nil) }
    let(:user2) { create(:user, :without_profile, profile_image: nil) }
    let(:user3) { create(:user, :without_profile, profile_image: nil) }

    before do
      create(:organization_membership, organization: organization, user: user1, type_of_user: "admin")
      create(:organization_membership, organization: organization, user: user2, type_of_user: "member")
      create(:organization_membership, organization: organization, user: user3, type_of_user: "pending")
    end

    it "returns only active (non-pending) users and excludes pending members", :aggregate_failures do
      active_users = organization.active_users
      expect(active_users.count).to eq(2)
      expect(active_users.ids).to contain_exactly(user1.id, user2.id)
      expect(active_users.ids).not_to include(user3.id)
    end
  end

  describe "recompiling organization pages on update" do
    let(:organization) { create(:organization) }

    before do
      allow(Organizations::RecompilePagesWorker).to receive(:perform_async)
      allow(FeatureFlag).to receive(:enabled?).and_call_original
      allow(FeatureFlag).to receive(:enabled?).with(:org_readme, anything).and_return(true)
    end

    it "enqueues recompilation when name, slug, or summary changes, but not other attributes", :aggregate_failures do
      organization.update!(company_size: "50")
      expect(Organizations::RecompilePagesWorker).not_to have_received(:perform_async)

      organization.update!(name: "New Name")
      expect(Organizations::RecompilePagesWorker).to have_received(:perform_async).with(organization.id).once

      organization.update!(slug: "new-slug")
      expect(Organizations::RecompilePagesWorker).to have_received(:perform_async).with(organization.id).twice

      organization.update!(summary: "New Summary")
      expect(Organizations::RecompilePagesWorker)
        .to have_received(:perform_async).with(organization.id).exactly(3).times
    end
  end

  describe "#set_baseline_score_on_verification_change" do
    let(:organization) { create(:organization, verified: false, baseline_score: 0) }

    before do
      allow(Settings::UserExperience).to receive(:index_minimum_score).and_return(15)
    end

    it "updates baseline_score on verification changes and preserves manual updates otherwise", :aggregate_failures do
      organization.update!(verified: true)
      expect(organization.baseline_score).to eq(15)

      organization.update!(baseline_score: 45)
      expect(organization.baseline_score).to eq(45)

      organization.update!(name: "Updated Org Name")
      expect(organization.baseline_score).to eq(45)

      organization.update!(verified: false)
      expect(organization.baseline_score).to eq(0)
    end
  end
end
