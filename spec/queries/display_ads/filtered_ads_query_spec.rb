require "rails_helper"

RSpec.describe DisplayAds::FilteredAdsQuery, type: :query do
  let(:placement_area) { "post_sidebar" }

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
      filtered = filter_ads(article_tags: %w[javascript])
      expect(filtered).not_to include(mismatched)
      expect(filtered).to include(no_tags)
    end

    it "will show display ads with no tags set if there are no article tags" do
      filtered = filter_ads(article_tags: [])
      expect(filtered).not_to include(mismatched)
      expect(filtered).to include(no_tags)
    end

    context "when available ads have matching tags" do
      let!(:matching) { create_display_ad cached_tag_list: "linux, git, go" }

      it "will show the display ads that contain tags that match any of the article tags" do
        filtered = filter_ads article_tags: %w[linux productivity]
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

  context "when considering ads with organization_id" do
    let!(:in_house_ad) { create_display_ad type_of: :in_house }

    let(:organization) { create(:organization) }
    let(:other_org) { create(:organization) }
    let!(:community_ad) { create_display_ad organization_id: organization.id, type_of: :community }
    let!(:other_community) { create_display_ad organization_id: other_org.id, type_of: :community }

    let!(:external_ad) { create_display_ad organization_id: organization.id, type_of: :external }
    let!(:other_external) { create_display_ad organization_id: other_org.id, type_of: :external }

    it "always shows :in_house, only shows community/external appropriately" do
      filtered = filter_ads organization_id: organization.id
      expect(filtered).to contain_exactly(community_ad, in_house_ad, other_external)
      expect(filtered).not_to include(other_community)

      filtered = filter_ads organization_id: nil
      expect(filtered).to contain_exactly(in_house_ad, external_ad, other_external)
      expect(filtered).not_to include(other_community)
    end

    it "suppresses external ads when permit_adjacent_sponsors is false" do
      filtered = filter_ads organization_id: organization.id, permit_adjacent_sponsors: false
      expect(filtered).to contain_exactly(community_ad, in_house_ad)
      expect(filtered).not_to include(other_community)

      filtered = filter_ads organization_id: nil, permit_adjacent_sponsors: false
      expect(filtered).to contain_exactly(in_house_ad)
      expect(filtered).not_to include(other_community)
    end
  end
end
