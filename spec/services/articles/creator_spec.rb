require "rails_helper"

RSpec.describe Articles::Creator, type: :service do
  let(:user) { create(:user) }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("ENABLE_REFRESH_SEGMENT_WORKERS").and_return("true")
    allow(SegmentedUserRefreshWorker).to receive(:perform_async)
  end

  context "when valid attributes" do
    let(:valid_attributes) { attributes_for(:article) }

    it "creates an article" do
      expect do
        described_class.call(user, valid_attributes)
      end.to change(Article, :count).by(1)
    end

    it "returns a non decorated, persisted article" do
      article = described_class.call(user, valid_attributes)

      expect(article.decorated?).to be(false)
      expect(article).to be_persisted
    end

    it "creates a notification subscription" do
      expect do
        described_class.call(user, valid_attributes)
      end.to change(NotificationSubscription, :count).by(1)
    end
  end

  context "when invalid attributes" do
    let(:invalid_body_attributes) { attributes_for(:article) }

    before do
      invalid_body_attributes[:title] = Faker::Book.title
      invalid_body_attributes[:body_markdown] = nil
    end

    it "doesn't create an invalid article" do
      expect do
        described_class.call(user, invalid_body_attributes)
      end.not_to change(Article, :count)
    end

    it "returns a non decorated, non persisted article" do
      article = described_class.call(user, invalid_body_attributes)

      expect(article.decorated?).to be(false)
      expect(article).not_to be_persisted
      expect(article.errors.size).to eq(1)
    end

    it "doesn't create a notification subscription" do
      expect do
        described_class.call(user, invalid_body_attributes)
      end.not_to change(NotificationSubscription, :count)
    end
  end

  context "when invalid enum for type_of is passed" do
    let(:invalid_enum_attributes) { attributes_for(:article).merge(type_of: "invalid_type") }

    it "doesn't create an article and returns an invalid article object with errors" do
      expect do
        article = described_class.call(user, invalid_enum_attributes)
        expect(article).not_to be_persisted
        expect(article.errors[:type_of]).to include("is invalid")
      end.not_to change(Article, :count)
    end
  end

  context "when creating a published article" do
    let(:article_params) { attributes_for(:article, published: true) }

    it "refreshes user segments" do
      described_class.call(user, article_params)
      expect(SegmentedUserRefreshWorker).to have_received(:perform_async).with(user.id)
    end
  end

  context "when creating a not-yet-published article" do
    let(:article_params) { attributes_for(:article, published: false, published_at: 5.days.from_now) }

    it "does not refresh user segments" do
      described_class.call(user, article_params)
      expect(SegmentedUserRefreshWorker).not_to have_received(:perform_async)
    end
  end

  context "when creating a non-published article" do
    let(:article_params) { attributes_for(:article, published: false) }

    it "does not refresh user segments" do
      described_class.call(user, article_params)
      expect(SegmentedUserRefreshWorker).not_to have_received(:perform_async)
    end
  end

  context "with organization collections" do
    let(:organization) { create(:organization) }
    let(:org_member) { create(:user) }

    before do
      create(:organization_membership, user: org_member, organization: organization, type_of_user: "member")
    end

    it "creates an organization collection when series and organization_id are provided" do
      article_params = attributes_for(:article).merge(series: "org-series", organization_id: organization.id)
      article = described_class.call(org_member, article_params)
      expect(article.persisted?).to be true
      collection = article.collection
      expect(collection).to be_present
      expect(collection.organization).to eq(organization)
      expect(collection.slug).to eq("org-series")
    end

    it "creates a personal collection when series is provided but no organization_id" do
      article_params = attributes_for(:article).merge(series: "personal-series", organization_id: nil)
      article = described_class.call(org_member, article_params)
      expect(article.persisted?).to be true
      collection = article.collection
      expect(collection).to be_present
      expect(collection.organization).to be_nil
      expect(collection.slug).to eq("personal-series")
    end

    it "finds existing organization collection when series already exists" do
      existing_collection = create(:collection, user: org_member, organization: organization, slug: "existing-series")
      article_params = attributes_for(:article).merge(series: "existing-series", organization_id: organization.id)
      article = described_class.call(org_member, article_params)
      expect(article.collection).to eq(existing_collection)
    end

    it "finds existing organization collection regardless of user_id" do
      # Create collection with one user
      original_user = create(:user)
      create(:organization_membership, user: original_user, organization: organization, type_of_user: "member")
      existing_collection = create(:collection, user: original_user, organization: organization, slug: "shared-series")
      
      # Try to use same series with different user in same organization
      different_member = create(:user)
      create(:organization_membership, user: different_member, organization: organization, type_of_user: "member")
      article_params = attributes_for(:article).merge(series: "shared-series", organization_id: organization.id)
      article = described_class.call(different_member, article_params)
      
      # Should find the existing collection, not create a new one
      expect(article.collection).to eq(existing_collection)
      expect(Collection.where(slug: "shared-series", organization: organization).count).to eq(1)
    end
  end

  describe "onboarding checklist" do
    before { allow(Settings::General).to receive(:display_sidebar_onboarding_checklist).and_return(true) }

    let(:checklist_user) { create(:user) }

    it "completes made_first_post when a published article is created" do
      described_class.call(checklist_user, attributes_for(:article, published: true))
      expect(checklist_user.onboarding_checklist.reload.items["made_first_post"]).to be_present
    end

    it "does not complete made_first_post when a draft is created" do
      described_class.call(checklist_user, attributes_for(:article, published: false))
      expect(checklist_user.onboarding_checklist.reload.items["made_first_post"]).to be_nil
    end

    it "does not query or complete made_first_post if the user registered more than 28 days ago" do
      checklist_user.update_column(:registered_at, 29.days.ago)
      # Assert database is not hit for checklist
      expect(checklist_user).not_to receive(:onboarding_checklist)
      
      described_class.call(checklist_user, attributes_for(:article, published: true))
    end
  end
end
