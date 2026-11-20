require "rails_helper"

RSpec.describe "Api::V1::Billboards" do
  let!(:v1_headers) { { "content-type" => "application/json", "Accept" => "application/vnd.forem.api-v1+json" } }

  let(:organization) { create(:organization) }
  let(:billboard_params) do
    {
      name: "This is new",
      organization_id: organization.id,
      display_to: "all",
      placement_area: "post_comments",
      body_markdown: "## This ad is a new ad.\n\nYay!",
      type_of: "community",
      published: true,
      approved: true,
      requires_cookies: false,
      target_geolocations: "US-WA, CA-BC"
    }
  end
  let(:billboard1) { create(:billboard, published: true, approved: true, type_of: "in_house") }

  shared_context "when user is authorized" do
    let(:api_secret) { create(:api_secret) }
    let(:user) { api_secret.user }
    let(:auth_header) { v1_headers.merge({ "api-key" => api_secret.secret }) }
    before { user.add_role(:admin) }
  end

  context "when authenticated and authorized and get to index" do
    include_context "when user is authorized"

    describe "GET /api/billboards" do
      it "returns json response" do
        billboard1
        get api_billboards_path, headers: auth_header
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq("application/json")
        expect(response.parsed_body.size).to eq(1)
      end
    end

    describe "POST /api/billboards" do
      it "creates a new billboard" do
        post api_billboards_path, params: billboard_params.to_json, headers: auth_header

        expect(response).to have_http_status(:created)
        expect(response.media_type).to eq("application/json")
        expect(response.parsed_body.keys).to \
          contain_exactly("approved", "body_markdown", "cached_tag_list",
                          "clicks_count", "created_at", "display_to", "id",
                          "impressions_count", "name", "organization_id",
                          "placement_area", "processed_html", "published",
                          "success_rate", "tag_list", "type_of", "updated_at", "color",
                          "creator_id", "exclude_article_ids", "dismissal_sku", "browser_context",
                          "audience_segment_type", "audience_segment_id", "page_id", "counts_tabulated_at",
                          "exclude_role_names", "target_role_names", "include_subforem_ids",
                          "prefer_paired_with_billboard_id", "custom_display_label", "template", "render_mode",
                          "preferred_article_ids", "priority", "weight", "target_geolocations",
                          "requires_cookies", "special_behavior", "expires_at",
                          "exclude_survey_completions", "exclude_survey_ids", "content_updated_at",
                          "tags_array", "event_id", "minimized_body_markdown", "minimized_processed_html",
                          "seconds_visible", "max_impressions_count", "max_clicks_count",
                          "billboard_campaign_id")
        expect(response.parsed_body["target_geolocations"]).to contain_exactly("US-WA", "CA-BC")
      end

      it "also accepts target geolocations as an array" do
        post api_billboards_path,
             params: billboard_params.merge(target_geolocations: %w[US-WA CA-BC]).to_json,
             headers: auth_header

        expect(response).to have_http_status(:created)
        expect(response.media_type).to eq("application/json")
        expect(response.parsed_body.keys).to \
          contain_exactly("approved", "body_markdown", "cached_tag_list",
                          "clicks_count", "created_at", "display_to", "id",
                          "impressions_count", "name", "organization_id",
                          "placement_area", "processed_html", "published", "counts_tabulated_at",
                          "success_rate", "tag_list", "type_of", "updated_at", "color",
                          "creator_id", "exclude_article_ids", "dismissal_sku", "browser_context",
                          "audience_segment_type", "audience_segment_id", "page_id", "prefer_paired_with_billboard_id",
                          "exclude_role_names", "target_role_names", "include_subforem_ids",
                          "custom_display_label", "template", "render_mode", "preferred_article_ids",
                          "priority", "weight", "target_geolocations", "requires_cookies",
                          "special_behavior", "expires_at", "exclude_survey_completions", "exclude_survey_ids",
                          "content_updated_at", "tags_array", "event_id",
                          "minimized_body_markdown", "minimized_processed_html", "seconds_visible",
                          "max_impressions_count", "max_clicks_count", "billboard_campaign_id")
        expect(response.parsed_body["target_geolocations"]).to contain_exactly("US-WA", "CA-BC")
      end

      it "returns a malformed response with invalid display_to" do
        post api_billboards_path, params: billboard_params.merge(display_to: "steve").to_json, headers: auth_header

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.media_type).to eq("application/json")
        expect(response.parsed_body.keys).to contain_exactly("error", "status")
        expect(response.parsed_body["error"]).to include("'steve' is not a valid display_to")
      end

      it "returns a malformed response with invalid geolocation" do
        expect do
          post api_billboards_path,
               params: billboard_params.merge(target_geolocations: "US-FAKE").to_json,
               headers: auth_header
        end.not_to change(Billboard, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.media_type).to eq("application/json")
        expect(response.parsed_body.keys).to contain_exactly("error", "status")
        expect(response.parsed_body["error"]).to include("US-FAKE is not an enabled target ISO 3166-2 code")
      end

      it "returns 422 when body_markdown contains an invalid liquid tag URL" do
        expect do
          post api_billboards_path,
               params: billboard_params.merge(body_markdown: "{% cta invalid-url %}Click here{% endcta %}").to_json,
               headers: auth_header
        end.not_to change(Billboard, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.media_type).to eq("application/json")
        expect(response.parsed_body.keys).to contain_exactly("error", "status")
        expect(response.parsed_body["error"]).to include("Invalid URL for 'link': only http and https URLs are allowed")
      end
    end

    describe "GET /api/billboards/:id" do
      it "returns json response" do
        get api_billboard_path(billboard1.id), headers: auth_header

        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq("application/json")
        expect(response.parsed_body).to include(
          "id" => billboard1.id,
          "published" => true,
          "approved" => true,
          "priority" => false,
          "weight" => 1.0,
          "type_of" => "in_house",
          "cached_tag_list" => "",
          "clicks_count" => 0,
        )
      end
    end

    describe "PUT /api/billboards/:id" do
      it "updates an existing billboard" do
        put api_billboard_path(billboard1.id),
            params: billboard_params.merge(name: "Updated!", type_of: "external").to_json,
            headers: auth_header

        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq("application/json")
        billboard1.reload
        expect(billboard1.name).to eq("Updated!")
        expect(billboard1.type_of).to eq("external")
        expect(response.parsed_body.keys).to \
          contain_exactly("approved", "body_markdown", "cached_tag_list",
                          "clicks_count", "created_at", "display_to", "id", "counts_tabulated_at",
                          "impressions_count", "name", "organization_id", "color",
                          "placement_area", "processed_html", "published", "dismissal_sku",
                          "success_rate", "tag_list", "type_of", "updated_at", "browser_context",
                          "creator_id", "exclude_article_ids", "requires_cookies", "page_id",
                          "audience_segment_type", "audience_segment_id", "special_behavior",
                          "exclude_role_names", "target_role_names", "include_subforem_ids",
                          "custom_display_label", "template", "render_mode", "preferred_article_ids",
                          "priority", "weight", "target_geolocations", "prefer_paired_with_billboard_id", "expires_at",
                          "exclude_survey_completions", "exclude_survey_ids", "content_updated_at",
                          "tags_array", "event_id", "minimized_body_markdown", "minimized_processed_html",
                          "seconds_visible", "max_impressions_count", "max_clicks_count",
                          "billboard_campaign_id")
      end

      it "also accepts target geolocations as an array" do
        put api_billboard_path(billboard1.id), params: { target_geolocations: %w[US-FL US-GA] }.to_json,
                                               headers: auth_header

        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq("application/json")
        billboard1.reload
        expect(billboard1.target_geolocations).to contain_exactly(
          Geolocation.from_iso3166("US-FL"),
          Geolocation.from_iso3166("US-GA"),
        )
      end

      it "returns a malformed response with invalid geolocation" do
        put api_billboard_path(billboard1.id), params: { target_geolocations: "US-FAKE" }.to_json, headers: auth_header

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.media_type).to eq("application/json")
        expect(response.parsed_body.keys).to contain_exactly("error", "status")
        expect(response.parsed_body["error"]).to include("US-FAKE is not an enabled target ISO 3166-2 code")
      end

      it "returns 422 when updated body_markdown contains an invalid liquid tag URL" do
        put api_billboard_path(billboard1.id),
            params: { body_markdown: "{% cta invalid-url %}Click here{% endcta %}" }.to_json,
            headers: auth_header

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.media_type).to eq("application/json")
        expect(response.parsed_body.keys).to contain_exactly("error", "status")
        expect(response.parsed_body["error"]).to include("Invalid URL for 'link': only http and https URLs are allowed")
      end
    end

    describe "PUT /api/billboards/:id/unpublish" do
      it "unpublishes the billboard" do
        put unpublish_api_billboard_path(billboard1.id), headers: auth_header

        expect(response).to have_http_status(:success)
        expect(billboard1.reload).not_to be_published
      end
    end

    describe "POST /api/billboards/preview" do
      it "renders processed_html and minimized_processed_html without saving a billboard" do
        expect do
          post preview_api_billboards_path,
               params: {
                 body_markdown: "## Billboard Headline\n\nCheck this out!",
                 minimized_body_markdown: "**Minimized copy**",
                 placement_area: "post_sidebar"
               }.to_json,
               headers: auth_header
        end.not_to change(Billboard, :count)

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["processed_html"]).to include("Billboard Headline")
        expect(response.parsed_body["minimized_processed_html"]).to include("<strong>Minimized copy</strong>")
      end

      it "returns 422 when markdown contains an invalid liquid tag" do
        post preview_api_billboards_path,
             params: { body_markdown: "{% link invalid_link_that_does_not_exist %}" }.to_json,
             headers: auth_header

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body["error"]).to be_present
      end
    end
  end

  context "when the API key's user is a Billboard admin with restricted sub-permissions" do
    let(:api_secret) { create(:api_secret) }
    let(:user) { api_secret.user }
    let(:auth_header) { v1_headers.merge({ "api-key" => api_secret.secret }) }
    let(:allowed) { [] }
    let(:draft_params) { billboard_params.merge(approved: false, published: false) }

    before do
      user.add_role(:single_resource_admin, Billboard)
      SubPermissions.update_grant(user: user, resource_type: "Billboard",
                                  sub_permissions: SubPermissions.build(allow: allowed))
    end

    it "can still list and read billboards", :aggregate_failures do
      get api_billboards_path, headers: auth_header
      expect(response).to have_http_status(:success)

      get api_billboard_path(billboard1.id), headers: auth_header
      expect(response).to have_http_status(:success)
    end

    it "creates an unapproved, unpublished billboard", :aggregate_failures do
      expect do
        post api_billboards_path, params: draft_params.to_json, headers: auth_header
      end.to change(Billboard, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(Billboard.last).to have_attributes(approved: false, published: false)
    end

    it "defaults to unapproved and unpublished when the flags are omitted" do
      post api_billboards_path, params: billboard_params.except(:approved, :published).to_json, headers: auth_header

      expect(response).to have_http_status(:created)
      expect(Billboard.last).to have_attributes(approved: false, published: false)
    end

    {
      "approved" => { approved: true, published: false, missing: "approve billboards" },
      "published" => { approved: false, published: true, missing: "publish billboards" },
      "live" => { approved: true, published: true, missing: "approve billboards and publish billboards" }
    }.each do |state, attrs|
      it "refuses to create a billboard #{state} and saves nothing", :aggregate_failures do
        expect do
          post api_billboards_path, params: billboard_params.merge(attrs.slice(:approved, :published)).to_json,
                                    headers: auth_header
        end.not_to change(Billboard, :count)

        expect(response).to have_http_status(:forbidden)
        expect(response.parsed_body).to eq(
          "error" => "Your Billboard admin access does not include: #{attrs[:missing]}.",
          "status" => 403,
        )
      end
    end

    it "accepts approval flags in any form Rails casts to true" do
      post api_billboards_path, params: billboard_params.merge(approved: "1", published: "true").to_json,
                                headers: auth_header

      expect(response).to have_http_status(:forbidden)
    end

    it "does not write an audit log for a refused write" do
      allow(Audit::Logger).to receive(:log)
      post api_billboards_path, params: billboard_params.to_json, headers: auth_header

      expect(Audit::Logger).not_to have_received(:log)
    end

    describe "updating an unapproved billboard" do
      let(:draft) { create(:billboard, approved: false, published: false) }

      it "edits its content" do
        put api_billboard_path(draft.id), params: { name: "Renamed", body_markdown: "New copy" }.to_json,
                                          headers: auth_header

        expect(response).to have_http_status(:success)
        expect(draft.reload).to have_attributes(name: "Renamed", body_markdown: "New copy")
      end

      it "refuses to approve or publish it and leaves it unchanged", :aggregate_failures do
        original_name = draft.name
        put api_billboard_path(draft.id), params: { name: "Renamed", approved: true }.to_json, headers: auth_header
        expect(response).to have_http_status(:forbidden)

        put api_billboard_path(draft.id), params: { published: true }.to_json, headers: auth_header
        expect(response).to have_http_status(:forbidden)

        expect(draft.reload).to have_attributes(name: original_name, approved: false, published: false)
      end
    end

    describe "updating an approved billboard" do
      it "refuses to change its content and leaves it unchanged", :aggregate_failures do
        original = billboard1.body_markdown
        put api_billboard_path(billboard1.id), params: { body_markdown: "Swapped after approval" }.to_json,
                                               headers: auth_header

        expect(response).to have_http_status(:forbidden)
        expect(response.parsed_body["error"]).to include("change or delete approved billboards")
        expect(billboard1.reload.body_markdown).to eq(original)
      end

      it "accepts a write that changes nothing" do
        put api_billboard_path(billboard1.id), params: { approved: true, published: true }.to_json,
                                               headers: auth_header

        expect(response).to have_http_status(:success)
      end

      it "takes it down by unapproving it" do
        put api_billboard_path(billboard1.id), params: { approved: false }.to_json, headers: auth_header

        expect(response).to have_http_status(:success)
        expect(billboard1.reload).not_to be_approved
      end

      it "takes it down through the unpublish endpoint" do
        put unpublish_api_billboard_path(billboard1.id), headers: auth_header

        expect(response).to have_http_status(:no_content)
        expect(billboard1.reload).not_to be_published
      end
    end

    describe "when another request approves the billboard first" do
      let(:draft) { create(:billboard, approved: false, published: false) }

      before do
        allow(Billboard).to receive(:find).and_wrap_original do |original, *args|
          original.call(*args).tap { |loaded| Billboard.where(id: loaded.id).update_all(approved: true) }
        end
      end

      it "decides against the locked, current row and refuses the edit", :aggregate_failures do
        put api_billboard_path(draft.id), params: { body_markdown: "Swapped after approval" }.to_json,
                                          headers: auth_header

        expect(response).to have_http_status(:forbidden)
        expect(draft.reload).to have_attributes(approved: true, body_markdown: draft.body_markdown)
      end

      it "reads the row with FOR UPDATE inside the transaction that writes it" do
        statements = []
        callback = ->(*, payload) { statements << payload[:sql] if payload[:sql].match?(/display_ads|BEGIN|COMMIT/) }
        ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
          put api_billboard_path(draft.id), params: { approved: false }.to_json, headers: auth_header
        end

        lock = statements.index { |sql| sql.include?("FOR UPDATE") }
        update = statements.rindex { |sql| sql.start_with?("UPDATE \"display_ads\"") }
        expect(lock).to be_present
        expect(update).to be > lock
        expect(statements[lock..update]).not_to include(a_string_matching(/\ACOMMIT|RELEASE SAVEPOINT/))
      end
    end

    describe "an Event's billboard" do
      let(:event) do
        create(:event, start_time: 5.minutes.ago, end_time: 1.hour.from_now, broadcast_config: "tagged_broadcast")
      end
      let!(:event_billboard) { create(:billboard, event: event, approved: false, published: true) }

      it "refuses to change content the broadcast worker would then approve", :aggregate_failures do
        original = event_billboard.body_markdown
        put api_billboard_path(event_billboard.id), params: { body_markdown: "Unreviewed" }.to_json,
                                                    headers: auth_header
        expect(response).to have_http_status(:forbidden)

        Events::ManageBroadcastBillboardsWorker.new.perform
        expect(event_billboard.reload).to have_attributes(approved: true, body_markdown: original)
      end

      it "lets it be taken down, and the worker does not bring it back live", :aggregate_failures do
        put unpublish_api_billboard_path(event_billboard.id), headers: auth_header
        expect(response).to have_http_status(:no_content)

        Events::ManageBroadcastBillboardsWorker.new.perform
        expect(Billboard.approved_and_published).not_to include(event_billboard)
      end
    end

    it "still renders previews" do
      post preview_api_billboards_path, params: { body_markdown: "## Preview" }.to_json, headers: auth_header

      expect(response).to have_http_status(:ok)
    end

    context "when the grant allows approving and publishing" do
      let(:allowed) { %w[approve publish] }

      it "creates a live billboard" do
        post api_billboards_path, params: billboard_params.to_json, headers: auth_header

        expect(response).to have_http_status(:created)
        expect(Billboard.last).to have_attributes(approved: true, published: true)
      end

      it "still cannot change an approved billboard" do
        put api_billboard_path(billboard1.id), params: { name: "Changed" }.to_json, headers: auth_header

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when the user is also an admin" do
      before { user.add_role(:admin) }

      it "ignores the restriction" do
        post api_billboards_path, params: billboard_params.to_json, headers: auth_header

        expect(response).to have_http_status(:created)
      end
    end

    context "with a campaign that has a live billboard" do
      let(:campaign) { BillboardCampaign.create!(name: "Live", max_impressions_count: 1_000) }
      let(:draft) { create(:billboard, approved: false, published: false) }

      before do
        create(:billboard, approved: true, published: true, billboard_campaign: campaign)
        draft.update_column(:impressions_count, 900)
      end

      it "refuses to attach a billboard to the campaign", :aggregate_failures do
        put api_billboard_path(draft.id), params: { billboard_campaign_id: campaign.id }.to_json, headers: auth_header

        expect(response).to have_http_status(:forbidden)
        expect(draft.reload.billboard_campaign_id).to be_nil
      end

      it "refuses to detach a billboard from the campaign", :aggregate_failures do
        draft.update_column(:billboard_campaign_id, campaign.id)
        put api_billboard_path(draft.id), params: { billboard_campaign_id: nil }.to_json, headers: auth_header

        expect(response).to have_http_status(:forbidden)
        expect(draft.reload.billboard_campaign_id).to eq(campaign.id)
      end
    end
  end

  context "when the API key's user is an unrestricted Billboard admin" do
    let(:api_secret) { create(:api_secret) }
    let(:auth_header) { v1_headers.merge({ "api-key" => api_secret.secret }) }

    before { api_secret.user.add_role(:single_resource_admin, Billboard) }

    it "keeps full access: creating live billboards and changing approved ones", :aggregate_failures do
      post api_billboards_path, params: billboard_params.to_json, headers: auth_header
      expect(response).to have_http_status(:created)
      expect(Billboard.last).to have_attributes(approved: true, published: true)

      put api_billboard_path(billboard1.id), params: { name: "Changed" }.to_json, headers: auth_header
      expect(response).to have_http_status(:success)
      expect(billboard1.reload.name).to eq("Changed")
    end
  end

  context "when unauthenticated and get to index" do
    it "returns unauthorized" do
      get api_billboards_path, headers: v1_headers
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "when unauthorized and get to show" do
    it "returns unauthorized" do
      get api_billboards_path, params: { id: billboard1.id },
                               headers: v1_headers.merge({ "api-key" => "invalid api key" })
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
