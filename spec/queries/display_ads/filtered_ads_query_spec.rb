require "rails_helper"

RSpec.describe DisplayAds::FilteredAdsQuery, type: :query do
  let(:organization) { create(:organization) }

  context "when updating the published and approved values" do
    let!(:display_ad) { create(:display_ad, organization_id: organization.id) }

    it "does not return unpublished ads" do
      display_ad.update!(published: false, approved: true)
      expect(described_class.call(display_ads: DisplayAd.all, area: display_ad.placement_area,
                                  organization_id: nil, user_signed_in: false)).to be_nil
    end

    it "does not return unapproved ads" do
      display_ad.update!(published: true, approved: false)
      expect(described_class.call(display_ads: DisplayAd.all, area: display_ad.placement_area,
                                  organization_id: nil, user_signed_in: false)).to be_nil
    end

    it "returns published and approved ads" do
      display_ad.update!(published: true, approved: true)
      expect(described_class.call(display_ads: DisplayAd.all, area: display_ad.placement_area,
                                  organization_id: nil, user_signed_in: false)).to eq(display_ad)
    end
  end

  context "when considering article_tags" do
    it "will show the display ads that contain tags that match any of the article tags" do
      display_ad = create(:display_ad, organization_id: organization.id,
                                       placement_area: "post_comments",
                                       published: true,
                                       approved: true,
                                       cached_tag_list: "linux, git, go")

      create(:display_ad, organization_id: organization.id,
                          placement_area: "post_comments",
                          published: true,
                          approved: true,
                          cached_tag_list: "career")

      article_tags = %w[linux productivity]
      expect(described_class.call(display_ads: DisplayAd.all, area: "post_comments", user_signed_in: false,
                                  organization_id: nil, article_tags: article_tags)).to eq(display_ad)
    end

    it "will show display ads that have no tags set" do
      display_ad = create(:display_ad, organization_id: organization.id,
                                       placement_area: "post_comments",
                                       published: true,
                                       approved: true,
                                       cached_tag_list: "")

      create(:display_ad, organization_id: organization.id,
                          placement_area: "post_comments",
                          published: true,
                          approved: true,
                          cached_tag_list: "career")

      article_tags = %w[productivity java]
      expect(described_class.call(display_ads: DisplayAd.all, area: "post_comments", user_signed_in: false,
                                organization_id: display_ad.organization.id, article_tags: article_tags)).to eq(display_ad)
    end

    it "will show no display ads if the available display ads have no tags set or do not contain matching tags" do
      create(:display_ad, organization_id: organization.id,
                          placement_area: "post_comments",
                          published: true,
                          approved: true,
                          cached_tag_list: "productivity")
      article_tags = %w[javascript]
      expect(described_class.call(display_ads: DisplayAd.all, area: "post_comments", user_signed_in: false,
                                  organization_id: nil, article_tags: article_tags)).to be_nil
    end

    it "will show display ads with no tags set if there are no article tags" do
      create(:display_ad, organization_id: organization.id,
                          placement_area: "post_comments",
                          published: true,
                          approved: true,
                          cached_tag_list: "productivity")

      display_ad_without_tags = create(:display_ad, organization_id: organization.id,
                                                    placement_area: "post_comments",
                                                    published: true,
                                                    approved: true,
                                                    cached_tag_list: "")

      expect(described_class.call(display_ads: DisplayAd.all, area: "post_comments",
                                organization_id: nil, user_signed_in: false)).to eq(display_ad_without_tags)
    end
  end

  context "when display_to is set to 'logged_in' or 'logged_out'" do
    let!(:display_ad2) do
      create(:display_ad, organization_id: organization.id, published: true, approved: true, display_to: "logged_in")
    end
    let!(:display_ad3) do
      create(:display_ad, organization_id: organization.id, published: true, approved: true, display_to: "logged_out")
    end

    it "shows ads that have a display_to of 'logged_in' if a user is signed in" do
      expect(described_class.call(display_ads: DisplayAd.all, area: display_ad2.placement_area,
                                organization_id: display_ad2.organization.id, user_signed_in: true)).to eq(display_ad2)
    end

    it "shows ads that have a display_to of 'logged_out' if a user is signed in" do
      expect(described_class.call(display_ads: DisplayAd.all, area: display_ad3.placement_area,
                                organization_id: display_ad3.organization.id, user_signed_in: false)).to eq(display_ad3)
    end
  end

  context "when display_to is set to 'all'" do
    let!(:display_ad) do
      create(:display_ad, organization_id: organization.id, published: true, approved: true, display_to: "all")
    end

    it "shows ads that have a display_to of 'all' if a user is signed in" do
      expect(described_class.call(display_ads: DisplayAd.all, area: display_ad.placement_area,
                                organization_id: display_ad.organization.id, user_signed_in: true)).to eq(display_ad)
    end

    it "shows ads that have a display_to of 'all' if a user is not signed in" do
      expect(described_class.call(display_ads: DisplayAd.all, area: display_ad.placement_area,
                                organization_id: display_ad.organization.id, user_signed_in: false)).to eq(display_ad)
    end
  end

  context "when organization is set on ad" do
    it "shows ads that have that are of type community and associated with the organization" do
      display_ad = create(:display_ad, organization_id: organization.id,
                                       published: true,
                                       approved: true,
                                       placement_area: "post_comments",
                                       type_of: "community",
                                       display_to: "all")

      expect(described_class.call(display_ads: DisplayAd.all, area: display_ad.placement_area,
                                organization_id: display_ad.organization.id, user_signed_in: false)).to eq(display_ad)
    end

    it "shows ads that have that are of type in house" do
      display_ad = create(:display_ad, organization_id: organization.id,
                                       published: true,
                                       approved: true,
                                       placement_area: "post_comments",
                                       type_of: "in_house",
                                       display_to: "all")

      expect(described_class.call(display_ads: DisplayAd.all, area: display_ad.placement_area,
                                  organization_id: display_ad.organization.id, user_signed_in: false)).to eq(display_ad)
    end
  end
end
