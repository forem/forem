require "rails_helper"

RSpec.describe "Api::V1::Tags" do
  describe "GET /api/tags" do
    let(:headers) { { "Accept" => "application/vnd.forem.api-v1+json" } }

    it "returns tags" do
      create(:tag, taggings_count: 10)

      get api_tags_path, headers: headers

      expect(response.parsed_body.size).to eq(1)
    end

    it "returns tags with the correct json representation" do
      badge = create(:badge)
      tag = create(:tag, taggings_count: 10)
      tag_with_badge = create(:tag, taggings_count: 5, badge: badge)

      get api_tags_path, headers: headers

      response_tag = response.parsed_body.first
      response_tag_with_badge = response.parsed_body.last
      expect_valid_json_body(response_tag, tag)
      expect_valid_json_body(response_tag_with_badge, tag_with_badge)
    end

    it "orders tags by taggings_count in a descending order" do
      tag = create(:tag, taggings_count: 10)
      other_tag = create(:tag, taggings_count: tag.taggings_count + 1)

      get api_tags_path, headers: headers

      expected_result = [other_tag.id, tag.id]
      expect(response.parsed_body.pluck("id")).to eq(expected_result)
    end

    it "supports pagination" do
      create_list(:tag, 3)

      get api_tags_path, params: { page: 1, per_page: 2 }, headers: headers
      expect(response.parsed_body.length).to eq(2)

      get api_tags_path, params: { page: 2, per_page: 2 }, headers: headers
      expect(response.parsed_body.length).to eq(1)
    end

    it "respects API_PER_PAGE_MAX limit set in ENV variable" do
      allow(ApplicationConfig).to receive(:[]).and_return(nil)
      allow(ApplicationConfig).to receive(:[]).with("APP_PROTOCOL").and_return("http://")
      allow(ApplicationConfig).to receive(:[]).with("API_PER_PAGE_MAX").and_return(2)

      create_list(:tag, 3)

      get api_tags_path, params: { per_page: 10 }, headers: headers
      expect(response.parsed_body.count).to eq(2)
    end

    it "sets the correct edge caching surrogate key for all tags" do
      tag = create(:tag, taggings_count: 10)

      get api_tags_path, headers: headers

      expected_key = ["tags", tag.record_key].to_set
      expect(response.headers["surrogate-key"].split.to_set).to eq(expected_key)
    end
  end

  describe "GET /api/tags/supported" do
    let(:headers) { { "Accept" => "application/vnd.forem.api-v1+json" } }

    it "returns only supported tags, unpaginated, ordered by taggings_count" do
      supported = create_list(:tag, 11, supported: true) # rubocop:disable FactoryBot/ExcessiveCreateList
      supported.first.update_column(:taggings_count, 50)
      create(:tag, supported: false, taggings_count: 100)

      get supported_api_tags_path, headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.pluck("id")).to match_array(supported.map(&:id))
      expect(response.parsed_body.first["id"]).to eq(supported.first.id)
      expect_valid_json_body(response.parsed_body.first, supported.first.reload)
    end

    it "is edge cacheable with a supported tags surrogate key" do
      tag = create(:tag, supported: true)

      get supported_api_tags_path, headers: headers

      expect(response.headers["surrogate-key"].split.to_set)
        .to eq([Tag::SUPPORTED_TAGS_SURROGATE_KEY, tag.record_key].to_set)
      expect(response.headers["surrogate-control"]).to include("max-age")
    end

    context "when on a non-root subforem" do
      let(:root_subforem) { create(:subforem, domain: "root.com", root: true) }
      let(:subforem) { create(:subforem, domain: "sub.com") }

      before do
        allow(Subforem).to receive_messages(cached_id_by_domain: subforem.id, cached_root_id: root_subforem.id,
                                            cached_default_id: root_subforem.id)
      end

      it "returns the tags supported by that subforem" do
        in_subforem = create(:tag, supported: true)
        unsupported_rel = create(:tag, supported: true)
        create(:tag, supported: true)
        TagSubforemRelationship.create!(tag: in_subforem, subforem: subforem, supported: true)
        TagSubforemRelationship.create!(tag: unsupported_rel, subforem: subforem, supported: false)

        get supported_api_tags_path, headers: headers

        expect(response.parsed_body.pluck("id")).to eq([in_subforem.id])
      end
    end
  end

  describe "PUT /api/tags/:id" do
    let(:v1_headers) { { "content-type" => "application/json", "Accept" => "application/vnd.forem.api-v1+json" } }
    let(:api_secret) { create(:api_secret) }
    let(:user) { api_secret.user }
    let(:auth_headers) { v1_headers.merge("api-key" => api_secret.secret) }
    let(:tag) { create(:tag, supported: false, pretty_name: "Old", short_summary: "Old summary") }
    let(:tag_params) do
      {
        pretty_name: "JavaScript",
        short_summary: "All about JS",
        wiki_body_markdown: "## About\n\nA tag wiki.",
        supported: true,
        bg_color_hex: "#123456",
        text_color_hex: "#ffffff",
        context_note_instructions: "Add context about the JS version."
      }
    end

    context "when the user is a super admin" do
      before { user.add_role(:super_admin) }

      it "updates the allowed fields and returns them so the caller can confirm the edit", :aggregate_failures do
        put api_tag_path(tag.id), params: tag_params.to_json, headers: auth_headers

        expect(response).to have_http_status(:ok)
        tag.reload
        expect(tag).to have_attributes(tag_params)
        expect(tag.wiki_body_html).to include("A tag wiki.")
        expect(response.parsed_body.keys).to match_array(%w[id name] + tag_params.keys.map(&:to_s))
        expect(response.parsed_body).to eq(tag_params.stringify_keys.merge("id" => tag.id, "name" => tag.name))
      end

      it "returns the current values of fields that were not sent" do
        tag.update!(wiki_body_markdown: "Existing wiki", context_note_instructions: "Existing note")

        put api_tag_path(tag.id), params: { short_summary: "New summary" }.to_json, headers: auth_headers

        expect(response.parsed_body).to include(
          "short_summary" => "New summary", "pretty_name" => "Old", "supported" => false,
          "wiki_body_markdown" => "Existing wiki", "context_note_instructions" => "Existing note"
        )
      end

      it "only changes the fields that are sent" do
        put api_tag_path(tag.id), params: { short_summary: "New summary" }.to_json, headers: auth_headers

        expect(response).to have_http_status(:ok)
        expect(tag.reload).to have_attributes(short_summary: "New summary", pretty_name: "Old", supported: false)
      end

      it "ignores fields outside the allowed list" do
        put api_tag_path(tag.id), params: { name: "renamed", alias_for: "other", short_summary: "x" }.to_json,
                                  headers: auth_headers

        expect(response).to have_http_status(:ok)
        expect(tag.reload).to have_attributes(name: tag.name, alias_for: nil, short_summary: "x")
      end

      it "enqueues the tag cache bust, which also purges the supported tags list" do
        sidekiq_assert_enqueued_with(job: Tags::BustCacheWorker, args: [tag.name]) do
          put api_tag_path(tag.id), params: { supported: true }.to_json, headers: auth_headers
        end
      end

      it "returns unprocessable entity for invalid values" do
        put api_tag_path(tag.id), params: { bg_color_hex: "not-a-color" }.to_json, headers: auth_headers

        expect(response).to have_http_status(:unprocessable_entity)
        expect(tag.reload.bg_color_hex).not_to eq("not-a-color")
      end

      it "returns not found for an unknown tag" do
        put api_tag_path(Tag.maximum(:id).to_i + 1), params: tag_params.to_json, headers: auth_headers

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when a super admin updates a tag with the admin API audit listener on" do
      before do
        user.add_role(:super_admin)
        Audit::Subscribe.listen :admin_api
      end

      after { Audit::Subscribe.forget :admin_api }

      it "creates an audit log of the update", :aggregate_failures do
        put api_tag_path(tag.id), params: { pretty_name: "JS" }.to_json, headers: auth_headers

        log = AuditLog.last
        expect(log.category).to eq(AuditLog::ADMIN_API_AUDIT_LOG_CATEGORY)
        expect(log.slug).to eq("api_tag_update")
        expect(log.data).to include("action" => "api_tag_update", "tag_id" => tag.id, "tag_name" => tag.name)
        expect(log.data["params"]).to eq("pretty_name" => "JS")
        expect(log.user_id).to eq(user.id)
      end
    end

    context "when the user is a single resource admin for Tag" do
      before { user.add_role(:single_resource_admin, Tag) }

      it "updates the tag" do
        put api_tag_path(tag.id), params: { pretty_name: "Scoped" }.to_json, headers: auth_headers

        expect(response).to have_http_status(:ok)
        expect(tag.reload.pretty_name).to eq("Scoped")
      end
    end

    context "when the user is a single resource admin for another resource" do
      before { user.add_role(:single_resource_admin, Billboard) }

      it "returns unauthorized" do
        put api_tag_path(tag.id), params: { pretty_name: "Nope" }.to_json, headers: auth_headers

        expect(response).to have_http_status(:unauthorized)
        expect(tag.reload.pretty_name).to eq("Old")
      end
    end

    context "when the user is a moderator of the tag" do
      before { user.add_role(:tag_moderator, tag) }

      it "returns unauthorized" do
        put api_tag_path(tag.id), params: { pretty_name: "Nope" }.to_json, headers: auth_headers

        expect(response).to have_http_status(:unauthorized)
        expect(tag.reload.pretty_name).to eq("Old")
      end
    end

    context "when the user is not an admin" do
      it "returns unauthorized" do
        put api_tag_path(tag.id), params: { pretty_name: "Nope" }.to_json, headers: auth_headers

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when no api key is given" do
      it "returns unauthorized" do
        put api_tag_path(tag.id), params: { pretty_name: "Nope" }.to_json, headers: v1_headers

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when the api key belongs to a suspended super admin" do
      before do
        user.add_role(:super_admin)
        user.add_role(:suspended)
      end

      it "returns unauthorized" do
        put api_tag_path(tag.id), params: { pretty_name: "Nope" }.to_json, headers: auth_headers

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when the V0 API is used" do
      it "does not route the request" do
        user.add_role(:super_admin)

        v0_headers = { "content-type" => "application/json", "api-key" => api_secret.secret }

        expect do
          put "/api/tags/#{tag.id}", params: { pretty_name: "Nope" }.to_json, headers: v0_headers
        end.to raise_error(ActionController::RoutingError)
        expect(tag.reload.pretty_name).to eq("Old")
      end
    end
  end

  private

  def expect_valid_json_body(body, tag)
    expect(body.keys).to match_array(%w[id name bg_color_hex text_color_hex short_summary])
    expect(body["id"]).to eq(tag.id)
    expect(body["name"]).to eq(tag.name)
    expect(body["bg_color_hex"]).to eq(tag.bg_color_hex)
    expect(body["text_color_hex"]).to eq(tag.text_color_hex)
  end
end
