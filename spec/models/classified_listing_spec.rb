require "rails_helper"

RSpec.describe ClassifiedListing, type: :model do
  let_it_be(:user) { create(:user) }
  let_it_be(:organization) { create(:organization) }
  let(:classified_listing) { create(:classified_listing, user: user) }

  # TODO: Remove setting of default parser from a model's callback
  # This may apply default parser on area that should not use it.
  after { ActsAsTaggableOn.default_parser = ActsAsTaggableOn::DefaultParser }

  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_presence_of(:body_markdown) }
  it { is_expected.to have_many(:credits) }

  describe "valid associations" do
    it "is not valid w/o user and org" do
      cl = build(:classified_listing, user_id: nil, organization_id: nil)
      expect(cl).not_to be_valid
      expect(cl.errors[:user_id]).to be_truthy
      expect(cl.errors[:organization_id]).to be_truthy
    end

    it "is valid with user_id and without organization_id" do
      cl = build(:classified_listing, user_id: user.id, organization_id: nil)
      expect(cl).to be_valid
    end

    it "is valid with user_id and organization_id" do
      cl = build(:classified_listing, user_id: user.id, organization_id: organization.id)
      expect(cl).to be_valid
    end
  end

  describe "body html" do
    it "converts markdown to html" do
      expect(classified_listing.processed_html).to include("<p>")
    end

    it "accepts 8 tags or less" do
      classified_listing.tag_list = "a, b, c, d, e, f, g"
      expect(classified_listing.valid?).to eq(true)
    end

    it "cleans images" do
      classified_listing.body_markdown = "hello <img src='/dssdsdsd.jpg'> hey hey hey"
      classified_listing.save
      expect(classified_listing.processed_html).not_to include("<img")
    end

    it "doesn't accept more than 8 tags" do
      classified_listing.tag_list = "a, b, c, d, e, f, g, h, z, t, s, p"
      expect(classified_listing.valid?).to eq(false)
      expect(classified_listing.errors[:tag_list]).to be_truthy
    end

    it "parses away tag spaces" do
      classified_listing.tag_list = "the best, tag list"
      classified_listing.save
      expect(classified_listing.tag_list).to eq(%w[thebest taglist])
    end
  end

  describe "credits" do
    it "does not destroy associated credits if destroyed" do
      credit = create(:credit)
      classified_listing.credits << credit
      classified_listing.save!

      expect { classified_listing.destroy }.not_to change(Credit, :count)
      expect(credit.reload.purchase).to be_nil
    end
  end

  describe "#after_commit" do
    it "on update enqueues worker to index tag to elasticsearch" do
      classified_listing.save

      sidekiq_assert_enqueued_with(job: Search::IndexToElasticsearchWorker, args: [described_class.to_s, classified_listing.id]) do
        classified_listing.save
      end
    end

    it "on destroy enqueues job to delete classified_listing from elasticsearch" do
      classified_listing.save
      sidekiq_assert_enqueued_with(job: Search::RemoveFromElasticsearchIndexWorker, args: [described_class::SEARCH_CLASS.to_s, classified_listing.id]) do
        classified_listing.destroy
      end
    end
  end

  describe ".cost_by_category" do
    it "returns the cost per category" do
      expected_cost = described_class::CATEGORIES_AVAILABLE.dig("cfp", "cost")
      expect(described_class.cost_by_category("cfp")).to eq(expected_cost)
    end

    it "returns 0 with invalid category" do
      expect(described_class.cost_by_category("invalid")).to eq(0)
    end
  end
end
