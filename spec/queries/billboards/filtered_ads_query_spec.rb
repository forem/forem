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
    defaults[:organization] = nil unless options.key?(:organization) || options.key?(:organization_id)
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
    let!(:in_segment) { create(:user, :without_profile, profile_image: nil) }
    let!(:audience_segment) { create(:audience_segment, type_of: :no_posts_yet) }
    let!(:targets_segment) { create_billboard audience_segment: audience_segment }
    let!(:no_targets) { create_billboard display_to: :all }
    let!(:not_in_segment) { create(:user, :without_profile, profile_image: nil) } # won't be in any segment

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

  context "when the placement area is fully cached" do
    let!(:untargeted) { create_billboard }

    it "only offers billboards that don't target anything about the individual request" do
      tagged = create_billboard(cached_tag_list: "ruby")
      excludes_article = create_billboard(exclude_article_ids: "11")
      for_segment = create_billboard(audience_segment: create(:audience_segment))
      for_page = create_billboard(page_id: create(:page).id)
      for_role = create_billboard(target_role_names: ["editor"])
      excludes_role = create_billboard(exclude_role_names: ["editor"])
      excludes_survey_takers = create_billboard(exclude_survey_completions: true, exclude_survey_ids: [1])
      desktop_only = create_billboard(browser_context: :desktop)

      expect(filter_billboards(user_signed_in: true, fully_cached: true)).to contain_exactly(untargeted)

      # Without that filtering, a response shared by every signed-in visitor would include these
      expect(filter_billboards(user_signed_in: true)).to include(
        tagged, excludes_article, for_page, excludes_role, excludes_survey_takers, desktop_only
      )
      expect(filter_billboards(user_signed_in: true)).not_to include(for_segment, for_role)
    end

    it "still respects whether the visitor is signed in" do
      logged_out_only = create_billboard(display_to: :logged_out)

      expect(filter_billboards(user_signed_in: true, fully_cached: true)).not_to include(logged_out_only)
      expect(filter_billboards(user_signed_in: false, fully_cached: true)).to include(logged_out_only)
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

    it "checks for matching community ads within the single billboards query" do
      no_ads_org_id = no_ads_org.id
      queries = []
      callback = ->(*, payload) { queries << payload[:sql] unless payload[:name] == "SCHEMA" }
      with_community = nil
      without_community = nil
      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        with_community = filter_billboards(organization_id: organization.id).to_a
        without_community = filter_billboards(organization_id: no_ads_org_id).to_a
      end

      expect(with_community).to contain_exactly(community_ad)
      expect(without_community).to contain_exactly(in_house_ad, external_ad, other_external)
      expect(queries.grep(/FROM "display_ads"/).size).to eq(2)
      expect(queries.grep(/SELECT 1 AS one FROM "display_ads"/)).to be_empty
    end

    it "does not preload organizations for every candidate billboard" do
      queries = []
      callback = ->(*, payload) { queries << payload[:sql] }
      filtered = nil
      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        filtered = filter_billboards(organization_id: nil).to_a
      end

      expect(filtered).to contain_exactly(in_house_ad, external_ad, other_external)
      expect(queries.grep(/FROM "organizations"/)).to be_empty
      expect(filtered.detect { |bb| bb.id == external_ad.id }.organization).to eq(organization)
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

      it "filters billboards by no location, region match, country match, and unsupported country",
         :aggregate_failures do
        expect(filter_billboards).to include(no_targets).and exclude(
          targets_canada, targets_new_york_and_canada, targets_california_and_texas,
          targets_quebec_and_newfoundland, targets_maine_alberta_and_ontario
        )

        # User is in Newfoundland, Canada
        expect(filter_billboards(location: "CA-NL")).to include(
          no_targets, targets_canada, targets_new_york_and_canada, targets_quebec_and_newfoundland
        ).and exclude(targets_california_and_texas, targets_maine_alberta_and_ontario)

        # User is in California, USA
        expect(filter_billboards(location: "US-CA")).to include(
          no_targets, targets_california_and_texas
        ).and exclude(
          targets_canada, targets_new_york_and_canada,
          targets_quebec_and_newfoundland, targets_maine_alberta_and_ontario
        )

        # User is in "Canada" (country only, no region)
        expect(filter_billboards(location: "CA")).to include(
          no_targets, targets_canada, targets_new_york_and_canada
        ).and exclude(
          targets_california_and_texas, targets_quebec_and_newfoundland, targets_maine_alberta_and_ontario
        )

        # User is in an unsupported country
        expect(filter_billboards(location: "FR-BRE")).to include(no_targets).and exclude(
          targets_canada, targets_new_york_and_canada, targets_california_and_texas,
          targets_quebec_and_newfoundland, targets_maine_alberta_and_ontario
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

    it "includes cookie-requiring ads only when cookies are allowed", :aggregate_failures do
      expect(filter_billboards(cookies_allowed: true)).to include(requires_cookies_ad, no_cookies_required_ad)
      expect(filter_billboards(cookies_allowed: false)).to include(no_cookies_required_ad)
        .and exclude(requires_cookies_ad)
    end
  end

  context "when considering browser context" do
    let!(:all_browsers_ad) { create_billboard browser_context: :all_browsers }
    let!(:mobile_in_app_ad) { create_billboard browser_context: :mobile_in_app }
    let!(:mobile_web_ad) { create_billboard browser_context: :mobile_web }
    let!(:desktop_ad) { create_billboard browser_context: :desktop }

    it "filters ads based on user_agent string across mobile in-app, mobile web, desktop, and unknown contexts",
       :aggregate_failures do
      %w[DEV-Native-ios DEV-Native-android].each do |ua|
        filtered = filter_billboards(user_agent: ua)
        expect(filtered).to include(all_browsers_ad, mobile_in_app_ad)
        expect(filtered).not_to include(mobile_web_ad, desktop_ad)
      end

      mobile_web_filtered = filter_billboards(user_agent: "Mobile Safari")
      expect(mobile_web_filtered).to include(all_browsers_ad, mobile_web_ad)
      expect(mobile_web_filtered).not_to include(mobile_in_app_ad, desktop_ad)

      desktop_filtered = filter_billboards(user_agent: "Windows NT 10.0; Win64; x64")
      expect(desktop_filtered).to include(all_browsers_ad, desktop_ad)
      expect(desktop_filtered).not_to include(mobile_in_app_ad, mobile_web_ad)

      unknown_filtered = filter_billboards(user_agent: "SomeUnknownBrowser/1.0")
      expect(unknown_filtered).to include(all_browsers_ad, mobile_in_app_ad, mobile_web_ad, desktop_ad)
    end
  end

  context "when considering subforem ads" do
    let(:subforem) { create(:subforem) }
    let(:subforem_2) { create(:subforem) }
    let(:subforem_3) { create(:subforem) }
    let!(:no_subforem) { create_billboard(include_subforem_ids: nil) }
    let!(:subforem_first) { create_billboard(include_subforem_ids: [subforem.id]) }
    let!(:subforem_2_and_3) { create_billboard(include_subforem_ids: [subforem_2.id, subforem_3.id]) }

    before do
      RequestStore.store[:subforem_id] = nil
    end

    it "filters billboards by explicit subforem_id, missing subforem_id, or RequestStore fallback",
       :aggregate_failures do
      expect(filter_billboards(subforem_id: subforem.id)).to include(no_subforem, subforem_first)
        .and exclude(subforem_2_and_3)

      expect(filter_billboards(subforem_id: 9_999)).to include(no_subforem)
        .and exclude(subforem_first, subforem_2_and_3)

      expect(filter_billboards(subforem_id: subforem_3.id)).to include(no_subforem, subforem_2_and_3)
        .and exclude(subforem_first)

      expect(filter_billboards).to include(no_subforem)
        .and exclude(subforem_first, subforem_2_and_3)

      RequestStore.store[:subforem_id] = subforem_2.id
      expect(filter_billboards).to include(no_subforem, subforem_2_and_3)
        .and exclude(subforem_first)
    end
  end

  context "when considering paused promotional billboards" do
    let(:paused_organization) { create(:organization) }
    let(:active_organization) { create(:organization) }
    # Use let! to ensure billboards are created before filter_billboards is called
    # This prevents issues with ActiveRecord::Relation caching results
    let!(:no_org_billboard) { create_billboard organization: nil }
    let!(:paused_org_billboard) { create_billboard organization: paused_organization }
    let!(:active_org_billboard) { create_billboard organization: active_organization }

    let(:memory_store) { ActiveSupport::Cache::MemoryStore.new }

    before do
      # Use memory store for tests to ensure cache operations work
      # Store in a variable so the same instance is returned for all calls
      allow(Rails).to receive(:cache).and_return(memory_store)
      memory_store.clear
    end

    context "when no organizations are paused" do
      before do
        # Ensure cache is empty or has no paused orgs
        Rails.cache.write(
          Organizations::TrackPromotionalBillboardImpressionsWorker::CACHE_KEY,
          [],
          expires_in: 15.minutes,
        )
      end

      it "includes all billboards regardless of organization" do
        filtered = filter_billboards
        expect(filtered).to include(no_org_billboard, paused_org_billboard, active_org_billboard)
      end
    end

    context "when an organization is paused" do
      before do
        # Set paused organization in cache
        Rails.cache.write(
          Organizations::TrackPromotionalBillboardImpressionsWorker::CACHE_KEY,
          [paused_organization.id],
          expires_in: 15.minutes,
        )
      end

      it "excludes billboards from paused organizations" do
        filtered = filter_billboards
        expect(filtered).not_to include(paused_org_billboard)
        expect(filtered).to include(no_org_billboard, active_org_billboard)
      end
    end

    context "when multiple organizations are paused" do
      let(:another_paused_organization) { create(:organization) }
      let(:another_paused_billboard) { create_billboard organization: another_paused_organization }

      before do
        # Set multiple paused organizations in cache
        Rails.cache.write(
          Organizations::TrackPromotionalBillboardImpressionsWorker::CACHE_KEY,
          [paused_organization.id, another_paused_organization.id],
          expires_in: 15.minutes,
        )
      end

      it "excludes billboards from all paused organizations" do
        filtered = filter_billboards
        expect(filtered).not_to include(paused_org_billboard, another_paused_billboard)
        expect(filtered).to include(no_org_billboard, active_org_billboard)
      end
    end

    context "when cache is empty or nil" do
      before do
        Rails.cache.delete(Organizations::TrackPromotionalBillboardImpressionsWorker::CACHE_KEY)
      end

      it "includes all billboards" do
        filtered = filter_billboards
        expect(filtered).to include(no_org_billboard, paused_org_billboard, active_org_billboard)
      end
    end
  end

  context "when considering active event broadcasts" do
    let(:memory_store) { ActiveSupport::Cache::MemoryStore.new }
    let!(:standard_bb) { create_billboard(placement_area: "feed_first", event_id: nil) }

    before do
      allow(Rails).to receive(:cache).and_return(memory_store)
      memory_store.clear
    end

    context "with an active global broadcast" do
      let(:event) do
        create(:event, start_time: 5.minutes.ago, end_time: 1.hour.from_now,
                       broadcast_config: "global_broadcast", published: true)
      end
      let!(:event_bb) { create_billboard(placement_area: "feed_first", event: event) }

      it "overrides feed_first placements while leaving sidebar placements untouched", :aggregate_failures do
        filtered = filter_billboards(area: "feed_first")
        expect(filtered).to include(event_bb)
        expect(filtered).not_to include(standard_bb)

        expect(filter_billboards(area: "sidebar_left")).not_to include(event_bb)
      end
    end

    context "with an active tagged broadcast" do
      let(:event) do
        create(:event, start_time: 5.minutes.ago, end_time: 1.hour.from_now,
                       broadcast_config: "tagged_broadcast", published: true, tags_array: ["javascript"])
      end
      let!(:event_bb) { create_billboard(placement_area: "feed_first", event: event) }

      it "overrides feed only when user tags overlap the event tags", :aggregate_failures do
        filtered = filter_billboards(area: "feed_first", user_tags: %w[ruby javascript])
        expect(filtered).to include(event_bb)
        expect(filtered).not_to include(standard_bb)

        non_overlapping = filter_billboards(area: "feed_first", user_tags: %w[ruby python])
        expect(non_overlapping).not_to include(event_bb)
        expect(non_overlapping).to include(standard_bb)
      end
    end
  end

  context "when considering survey completion exclusion" do
    let(:user) { create(:user, :without_profile, profile_image: nil) }
    let(:survey) { create(:survey) }
    let!(:survey_bb) do
      create_billboard(exclude_survey_completions: true, exclude_survey_ids: [survey.id])
    end

    it "excludes the billboard when the signed-in user completed a matching survey" do
      create(:survey_completion, user: user, survey: survey)
      expect(filter_billboards(user_signed_in: true, user_id: user.id)).not_to include(survey_bb)
    end

    it "includes the billboard when the signed-in user has not completed a matching survey" do
      expect(filter_billboards(user_signed_in: true, user_id: user.id)).to include(survey_bb)
    end

    it "executes a single SQL query for signed-in users without extra pre-queries" do
      uid = user.id
      queries = []
      callback = lambda do |*, payload|
        sql = payload[:sql].to_s
        if !payload[:cached] && sql.match?(/FROM "(display_ads|segmented_users|survey_completions)"/)
          queries << sql
        end
      end

      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        expect(filter_billboards(user_signed_in: true, user_id: uid).to_a).to include(survey_bb)
      end

      expect(queries.size).to eq(1)
    end
  end
end
