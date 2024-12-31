require "rails_helper"

RSpec.describe Billboards::FilteredAdsQuery, type: :query do
  let(:placement_area) { "post_sidebar" }

  def create_billboard(**options)
    defaults = {
      approved: true,
      published: true,
      placement_area: placement_area,
      display_to: :all
    }
    create(:billboard, **options.reverse_merge(defaults))
  end

  def filter_billboards(**options)
    defaults = {
      billboards: Billboard, area: placement_area, user_signed_in: false
    }
    described_class.call(**options.reverse_merge(defaults))
  end

  context "when ads are not approved or published" do
    let!(:unapproved) { create_billboard approved: false }
    let!(:unpublished) { create_billboard published: false }
    let!(:billboard) { create_billboard }

    it "does not display unapproved or unpublished ads" do
      filtered = filter_billboards
      expect(filtered).not_to include(unapproved)
      expect(filtered).not_to include(unpublished)
      expect(filtered).to include(billboard)
    end
  end

  context "when considering article_tags" do
    let!(:no_tags) { create_billboard cached_tag_list: "" }
    let!(:mismatched) { create_billboard cached_tag_list: "career" }

    it "shows no-tag billboards if the article tags do not contain matching tags" do
      filtered = filter_billboards(article_id: 11, article_tags: %w[javascript])
      expect(filtered).not_to include(mismatched)
      expect(filtered).to include(no_tags)
    end

    it "shows billboards with no tags set if there are no article tags" do
      filtered = filter_billboards(article_id: 11, article_tags: [])
      expect(filtered).not_to include(mismatched)
      expect(filtered).to include(no_tags)
    end

    context "when available ads have matching tags" do
      let!(:matching) { create_billboard cached_tag_list: "linux, git, go" }

      it "shows the billboards that contain tags that match any of the article tags" do
        filtered = filter_billboards article_id: 11, article_tags: %w[linux productivity]
        expect(filtered).not_to include(mismatched)
        expect(filtered).to include(matching)
        expect(filtered).to include(no_tags)
      end
    end
  end

  context "when considering user_tags" do
    let!(:no_tags) { create_billboard placement_area: "feed_first", cached_tag_list: "" }
    let!(:mismatched) { create_billboard placement_area: "feed_first", cached_tag_list: "career" }

    it "shows no-tag billboards if the user tags do not contain matching tags" do
      filtered = filter_billboards(area: "feed_first", user_tags: %w[javascript])
      expect(filtered).not_to include(mismatched)
      expect(filtered).to include(no_tags)
    end

    it "shows billboards with no tags set if there are no user tags" do
      filtered = filter_billboards(area: "feed_first", user_tags: [])
      expect(filtered).not_to include(mismatched)
      expect(filtered).to include(no_tags)
    end

    context "when available ads have matching tags" do
      let!(:matching) { create_billboard placement_area: "feed_first", cached_tag_list: "linux, git, go" }

      it "shows the billboards that contain tags that match any of the user tags" do
        filtered = filter_billboards area: "feed_first", user_tags: %w[linux productivity]
        expect(filtered).not_to include(mismatched)
        expect(filtered).to include(matching)
        expect(filtered).to include(no_tags)
      end
    end
  end

  context "when considering users_signed_in" do
    let!(:for_logged_in) { create_billboard display_to: :logged_in }
    let!(:for_logged_out) { create_billboard display_to: :logged_out }
    let!(:for_all_users) { create_billboard display_to: :all }

    it "always shows :all, only shows -in/-out appropriately" do
      filtered = filter_billboards user_signed_in: true
      expect(filtered).to contain_exactly(for_logged_in, for_all_users)

      filtered = filter_billboards user_signed_in: false
      expect(filtered).to contain_exactly(for_logged_out, for_all_users)
    end
  end

  context "when considering article_exclude_ids" do
    let!(:ex_article1) { create_billboard exclude_article_ids: "11,12" }
    let!(:another_ex_article2) { create_billboard exclude_article_ids: "12,13" }
    let!(:no_excludes) { create_billboard }

    it "shows billboards that exclude articles appropriately" do
      filtered = filter_billboards article_id: 11
      expect(filtered).to contain_exactly(another_ex_article2, no_excludes)

      filtered = filter_billboards article_id: 12
      expect(filtered).to contain_exactly(no_excludes)

      filtered = filter_billboards article_id: 13
      expect(filtered).to contain_exactly(ex_article1, no_excludes)

      filtered = filter_billboards article_id: 14
      expect(filtered).to contain_exactly(ex_article1, another_ex_article2, no_excludes)
    end
  end

  context "when considering audience segmentation" do
    let!(:in_segment) { create(:user) }
    let!(:audience_segment) { create(:audience_segment, type_of: :no_posts_yet) }
    let!(:targets_segment) { create_billboard audience_segment: audience_segment }
    let!(:no_targets) { create_billboard display_to: :all }
    let!(:not_in_segment) { create(:user) } # won't be in any segment

    before do
      _targets_other = create_billboard audience_segment: create(:audience_segment)
    end

    it "targets users in/out of segment appropriately" do
      filtered = filter_billboards user_signed_in: true, user_id: in_segment
      expect(filtered).to contain_exactly(targets_segment, no_targets)

      filtered = filter_billboards user_signed_in: true, user_id: not_in_segment
      expect(filtered).to contain_exactly(no_targets)

      filtered = filter_billboards user_signed_in: false
      expect(filtered).to contain_exactly(no_targets)
    end
  end

  context "when considering page_id" do
    let(:page) { create(:page) }
    let(:page_bb) { create_billboard page_id: page.id }
    let(:non_page_bb) { create_billboard page_id: nil }

    it "shows page billboard if page is passed" do
      filtered = filter_billboards page_id: page.id
      expect(filtered).to contain_exactly(page_bb)
      expect(filtered).not_to include(non_page_bb)
    end
  end

  context "when considering ads with organization_id" do
    let!(:in_house_ad) { create_billboard type_of: :in_house }

    let(:organization) { create(:organization) }
    let(:other_org) { create(:organization) }
    let(:no_ads_org) { create(:organization) }
    let!(:community_ad) { create_billboard organization_id: organization.id, type_of: :community }
    let!(:other_community) { create_billboard organization_id: other_org.id, type_of: :community }

    let!(:external_ad) { create_billboard organization_id: organization.id, type_of: :external }
    let!(:other_external) { create_billboard organization_id: other_org.id, type_of: :external }

    it "always shows :community ad if matching, otherwise shows in_house/external", :aggregate_failure do
      filtered = filter_billboards organization_id: organization.id
      expect(filtered).to contain_exactly(community_ad)
      expect(filtered).not_to include(other_community)

      filtered = filter_billboards organization_id: no_ads_org.id
      expect(filtered).to contain_exactly(in_house_ad, external_ad, other_external)
      expect(filtered).not_to include(other_community)

      filtered = filter_billboards organization_id: nil
      expect(filtered).to contain_exactly(in_house_ad, external_ad, other_external)
      expect(filtered).not_to include(community_ad, other_community)
    end

    it "suppresses external ads when permit_adjacent_sponsors is false" do
      filtered = filter_billboards organization_id: organization.id, permit_adjacent_sponsors: false
      expect(filtered).to contain_exactly(community_ad)
      expect(filtered).not_to include(other_community)

      filtered = filter_billboards organization_id: nil, permit_adjacent_sponsors: false
      expect(filtered).to contain_exactly(in_house_ad)
      expect(filtered).not_to include(other_community)
    end
  end

  context "when considering home hero ads" do
    let!(:in_house_ad) { create_billboard placement_area: "home_hero", type_of: :in_house }

    let(:organization) { create(:organization) }
    let(:other_org) { create(:organization) }
    let!(:community_ad) { create_billboard organization_id: organization.id, type_of: :community }
    let!(:other_community) { create_billboard organization_id: other_org.id, type_of: :community }

    it "always shows home hero ads only" do
      filtered = filter_billboards(area: "home_hero")
      expect(filtered).to contain_exactly(in_house_ad)
      expect(filtered).not_to include(other_community)
      expect(filtered).not_to include(community_ad)
    end
  end

  context "with target geolocations" do
    let!(:no_targets) { create_billboard }
    let!(:targets_canada) { create_billboard(target_geolocations: "CA") }
    let!(:targets_new_york_and_canada) { create_billboard(target_geolocations: "US-NY, CA") }
    let!(:targets_california_and_texas) { create_billboard(target_geolocations: "US-CA, US-TX") }
    let!(:targets_quebec_and_newfoundland) { create_billboard(target_geolocations: "CA-QC, CA-NL") }
    let!(:targets_maine_alberta_and_ontario) { create_billboard(target_geolocations: "US-ME, CA-AB, CA-ON") }

    context "when location targeting feature is not enabled" do
      before do
        allow(FeatureFlag).to receive(:enabled?).with(:billboard_location_targeting).and_return(false)
      end

      it "ignores the target geolocations" do
        filtered = filter_billboards(location: "CA-NL") # User is in Newfoundland, Canada

        expect(filtered).to include(
          no_targets,
          targets_canada,
          targets_new_york_and_canada,
          targets_california_and_texas,
          targets_quebec_and_newfoundland,
          targets_maine_alberta_and_ontario,
        )
      end
    end

    context "when location targeting feature is enabled" do
      before do
        allow(FeatureFlag).to receive(:enabled?).with(:billboard_location_targeting).and_return(true)
      end

      it "shows only billboards with no targeting if no location is provided" do
        filtered = filter_billboards
        expect(filtered).to include(no_targets)
        expect(filtered).not_to include(
          targets_canada,
          targets_new_york_and_canada,
          targets_california_and_texas,
          targets_quebec_and_newfoundland,
          targets_maine_alberta_and_ontario,
        )
      end

      it "shows only billboards whose target location includes the specified location" do
        filtered = filter_billboards(location: "CA-NL") # User is in Newfoundland, Canada

        expect(filtered).to include(
          no_targets,
          targets_canada,
          targets_new_york_and_canada,
          targets_quebec_and_newfoundland,
        )
        expect(filtered).not_to include(
          targets_california_and_texas,
          targets_maine_alberta_and_ontario,
        )

        filtered = filter_billboards(location: "US-CA") # User is in California, USA
        expect(filtered).to include(
          no_targets,
          targets_california_and_texas,
        )
        expect(filtered).not_to include(
          targets_canada,
          targets_new_york_and_canada,
          targets_quebec_and_newfoundland,
          targets_maine_alberta_and_ontario,
        )
      end

      it "shows only billboards targeting the country specifically if no region is provided" do
        filtered = filter_billboards(location: "CA") # User is in "Canada"

        expect(filtered).to include(
          no_targets,
          targets_canada,
          targets_new_york_and_canada,
        )
        expect(filtered).not_to include(
          targets_california_and_texas,
          targets_quebec_and_newfoundland,
          targets_maine_alberta_and_ontario,
        )
      end

      it "shows only billboards with no targeting if the user's location is an unsupported country" do
        filtered = filter_billboards(location: "FR-BRE")
        expect(filtered).to include(no_targets)
        expect(filtered).not_to include(
          targets_canada,
          targets_new_york_and_canada,
          targets_california_and_texas,
          targets_quebec_and_newfoundland,
          targets_maine_alberta_and_ontario,
        )
      end

      it "correctly shows targeted billboards if country but not region targeting is enabled" do
        allow(Settings::General).to receive(:billboard_enabled_countries).and_return(
          "FR" => :without_regions,
          "US" => :with_regions,
          "CA" => :with_regions,
        )

        targets_france_and_canada = create_billboard(target_geolocations: "CA, FR")

        filtered = filter_billboards(location: "FR-BRE")
        expect(filtered).to include(no_targets, targets_france_and_canada)
        expect(filtered).not_to include(
          targets_canada,
          targets_new_york_and_canada,
          targets_california_and_texas,
          targets_quebec_and_newfoundland,
          targets_maine_alberta_and_ontario,
        )
      end
    end
  end

  context "when considering cookie requirements" do
    let!(:requires_cookies_ad) { create_billboard(requires_cookies: true) }
    let!(:no_cookies_required_ad) { create_billboard(requires_cookies: false) }

    context "when cookies are allowed" do
      it "includes ads that require cookies" do
        filtered = filter_billboards(cookies_allowed: true)
        expect(filtered).to include(requires_cookies_ad)
        expect(filtered).to include(no_cookies_required_ad)
      end
    end

    context "when cookies are not allowed" do
      it "excludes ads that require cookies" do
        filtered = filter_billboards(cookies_allowed: false)
        expect(filtered).not_to include(requires_cookies_ad)
        expect(filtered).to include(no_cookies_required_ad)
      end
    end
  end

  context "when considering browser context" do
    let!(:all_browsers_ad) { create_billboard browser_context: :all_browsers }
    let!(:mobile_in_app_ad) { create_billboard browser_context: :mobile_in_app }
    let!(:mobile_web_ad) { create_billboard browser_context: :mobile_web }
    let!(:desktop_ad) { create_billboard browser_context: :desktop }

    it "filters ads based on user_agent string for mobile in-app context" do
      filtered = filter_billboards(user_agent: "DEV-Native-ios")
      expect(filtered).to include(all_browsers_ad, mobile_in_app_ad)
      expect(filtered).not_to include(mobile_web_ad, desktop_ad)

      filtered = filter_billboards(user_agent: "DEV-Native-android")
      expect(filtered).to include(all_browsers_ad, mobile_in_app_ad)
      expect(filtered).not_to include(mobile_web_ad, desktop_ad)
    end

    it "filters ads based on user_agent string for mobile web context" do
      filtered = filter_billboards(user_agent: "Mobile Safari")
      expect(filtered).to include(all_browsers_ad, mobile_web_ad)
      expect(filtered).not_to include(mobile_in_app_ad, desktop_ad)
    end

    it "filters ads based on user_agent string for desktop context" do
      filtered = filter_billboards(user_agent: "Windows NT 10.0; Win64; x64")
      expect(filtered).to include(all_browsers_ad, desktop_ad)
      expect(filtered).not_to include(mobile_in_app_ad, mobile_web_ad)
    end

    it "includes all ads for unknown user_agent contexts" do
      filtered = filter_billboards(user_agent: "SomeUnknownBrowser/1.0")
      expect(filtered).to include(all_browsers_ad, mobile_in_app_ad, mobile_web_ad, desktop_ad)
    end
  end

  context "when considering subforem ads" do
    let(:subforem) { create(:subforem, domain: "#{rand(1000)}.com") }
    let(:subforem_2) { create(:subforem, domain: "#{rand(1000)}.com") }
    let(:subforem_3) { create(:subforem, domain: "#{rand(1000)}.com") }
    let!(:no_subforem) { create_billboard(include_subforem_ids: nil) }
    let!(:subforem_first) { create_billboard(include_subforem_ids: [subforem.id]) }
    let!(:subforem_2_and_3) { create_billboard(include_subforem_ids: [subforem_2.id, subforem_3.id]) }

    before do
      RequestStore.store[:subforem_id] = nil
    end

    it "includes only ads that either have no subforem or explicitly list the requested subforem_id" do
      filtered = filter_billboards(subforem_id: subforem.id)
      expect(filtered).to include(no_subforem, subforem_first)
      expect(filtered).not_to include(subforem_2_and_3)
    end

    it "falls back to no-subforem ads if the requested subforem_id is not in include_subforem_ids" do
      filtered = filter_billboards(subforem_id: 9_999)
      expect(filtered).to include(no_subforem)
      expect(filtered).not_to include(subforem_first, subforem_2_and_3)
    end

    it "includes subforem_2_and_3 if subforem_id = 3" do
      filtered = filter_billboards(subforem_id: subforem_3.id)
      expect(filtered).to include(no_subforem, subforem_2_and_3)
      expect(filtered).not_to include(subforem_first)
    end

    # Also test the scenario when subforem_id is not passed at all.
    it "includes only no_subforem billboard if no subforem_id was provided" do
      filtered = filter_billboards
      expect(filtered).to include(no_subforem)
      expect(filtered).not_to include(subforem_first, subforem_2_and_3)
    end

    it "Falls back to request store if subforem_id is not passed" do
      RequestStore.store[:subforem_id] = subforem_2.id
      filtered = filter_billboards
      expect(filtered).to include(no_subforem, subforem_2_and_3)
      expect(filtered).not_to include(subforem_first)
    end
  end
end
