require "rails_helper"

RSpec.describe DisplayAds::FilteredAdsQuery, type: :query do
  let(:placement_area) { "post_sidebar" }
  let(:article) { build(:article).decorate }

  def create_display_ad(**options)
    defaults = {
      approved: true,
      published: true,
      placement_area: placement_area,
      display_to: :all
    }
    create(:display_ad, **options.reverse_merge(defaults))
  end

  def filter_ads(**options)
    defaults = {
      display_ads: DisplayAd, area: placement_area, user_signed_in: false
    }
    described_class.call(**options.reverse_merge(defaults))
  end

  context "when ads are not approved or published" do
    let!(:unapproved) { create_display_ad approved: false }
    let!(:unpublished) { create_display_ad published: false }
    let!(:display_ad) { create_display_ad }

    it "does not display unapproved or unpublished ads" do
      filtered = filter_ads
      expect(filtered).not_to include(unapproved)
      expect(filtered).not_to include(unpublished)
      expect(filtered).to include(display_ad)
    end
  end

  context "when considering article_tags" do
    let!(:no_tags) { create_display_ad cached_tag_list: "" }
    let!(:mismatched) { create_display_ad cached_tag_list: "career" }

    it "will show no-tag display ads if the article tags do not contain matching tags" do
      allow(article).to receive(:cached_tag_list_array).and_return(%w[javascript])
      filtered = filter_ads(article: article)
      expect(filtered).not_to include(mismatched)
      expect(filtered).to include(no_tags)
    end

    it "will show display ads with no tags set if there are no article tags" do
      allow(article).to receive(:cached_tag_list_array).and_return([])
      filtered = filter_ads(article: article)
      expect(filtered).not_to include(mismatched)
      expect(filtered).to include(no_tags)
    end

    context "when available ads have matching tags" do
      let!(:matching) { create_display_ad cached_tag_list: "linux, git, go" }

      it "will show the display ads that contain tags that match any of the article tags" do
        allow(article).to receive(:cached_tag_list_array).and_return(%w[linux productivity])
        filtered = filter_ads(article: article)
        expect(filtered).not_to include(mismatched)
        expect(filtered).to include(matching)
        expect(filtered).to include(no_tags)
      end
    end
  end

  context "when considering users_signed_in" do
    let!(:for_logged_in) { create_display_ad display_to: :logged_in }
    let!(:for_logged_out) { create_display_ad display_to: :logged_out }
    let!(:for_all_users) { create_display_ad display_to: :all }

    it "always shows :all, only shows -in/-out appropriately" do
      filtered = filter_ads user_signed_in: true
      expect(filtered).to contain_exactly(for_logged_in, for_all_users)

      filtered = filter_ads user_signed_in: false
      expect(filtered).to contain_exactly(for_logged_out, for_all_users)
    end
  end

  context "when considering article_exclude_ids" do
    let!(:exclude_article1) { create_display_ad exclude_article_ids: "11,12" }
    let!(:exclude_article2) { create_display_ad exclude_article_ids: "12,13" }
    let!(:no_excludes) { create_display_ad }

    it "will show display ads that exclude articles appropriately" do
      allow(article).to receive(:id).and_return(11)
      filtered = filter_ads article: article
      expect(filtered).to contain_exactly(exclude_article2, no_excludes)

      allow(article).to receive(:id).and_return(12)
      filtered = filter_ads article: article
      expect(filtered).to contain_exactly(no_excludes)

      allow(article).to receive(:id).and_return(13)
      filtered = filter_ads article: article
      expect(filtered).to contain_exactly(exclude_article1, no_excludes)

      allow(article).to receive(:id).and_return(14)
      filtered = filter_ads article: article
      expect(filtered).to contain_exactly(exclude_article1, exclude_article2, no_excludes)
    end
  end

  context "when considering ads with organization_id" do
    let!(:in_house_ad) { create_display_ad type_of: :in_house }

    let(:organization) { create(:organization) }
    let(:other_org) { create(:organization) }
    let!(:community_ad) { create_display_ad organization_id: organization.id, type_of: :community }
    let!(:other_community) { create_display_ad organization_id: other_org.id, type_of: :community }

    let!(:external_ad) { create_display_ad organization_id: organization.id, type_of: :external }
    let!(:other_external) { create_display_ad organization_id: other_org.id, type_of: :external }

    it "always shows :community ad if matching, otherwise shows in_house/external" do
      allow(article).to receive(:organization_id).and_return(organization.id)
      filtered = filter_ads article: article
      expect(filtered).to contain_exactly(community_ad)
      expect(filtered).not_to include(other_community)

      allow(article).to receive(:organization_id).and_return(123)
      filtered = filter_ads article: article
      expect(filtered).to contain_exactly(in_house_ad)
      expect(filtered).not_to include(other_community)

      allow(article).to receive(:organization_id).and_return(nil)
      filtered = filter_ads article: article
      expect(filtered).to contain_exactly(in_house_ad, external_ad, other_external)
      expect(filtered).not_to include(community_ad, other_community)
    end

    it "suppresses external ads when permit_adjacent_sponsors is false" do
      allow(article).to receive(:organization_id).and_return(organization.id)
      allow(article).to receive(:permit_adjacent_sponsors?).and_return(false)
      filtered = filter_ads article: article
      expect(filtered).to contain_exactly(community_ad)
      expect(filtered).not_to include(other_community)

      allow(article).to receive(:organization_id).and_return(nil)
      allow(article).to receive(:permit_adjacent_sponsors?).and_return(false)
      filtered = filter_ads article: article
      expect(filtered).to contain_exactly(in_house_ad)
      expect(filtered).not_to include(other_community)
    end
  end
end
