RSpec.shared_examples "GET /api/analytics/:endpoint authorization examples" do |endpoint, params|
  let(:user)              { create(:user, :without_profile, profile_image: nil) }
  let(:api_token)         { create(:api_secret, user: user) }
  let(:org)               { create(:organization) }
  let(:org_member) do
    create(:user, :without_profile, profile_image: nil).tap do |member|
      create(:organization_membership, user: member, organization: org, type_of_user: "member")
    end
  end
  let(:org_member_token)  { create(:api_secret, user: org_member) }
  let(:article)           { create(:article, user: user, organization: org, with_tags: false, with_main_image: false) }
  let(:user_article)      { article }
  let(:org_article)       { article }

  it "enforces API token, session, organization membership, and article ownership authorization",
     :aggregate_failures do
    get "/api/analytics/#{endpoint}?#{params}", headers: { "api-key" => "abadskajdlsak" }
    expect(response.parsed_body).to include("error" => "unauthorized")
    expect(response).to have_http_status(:unauthorized)

    get "/api/analytics/#{endpoint}?article_id=#{article.id}#{params}"
    expect(response).to have_http_status(:unauthorized)

    get "/api/analytics/#{endpoint}?#{params}", headers: { "api-key" => api_token.secret }
    expect(response.media_type).to eq "application/json"

    get "/api/analytics/#{endpoint}?organization_id=#{org.id}#{params}", headers: { "api-key" => api_token.secret }
    expect(response.parsed_body).to include("error" => "unauthorized")
    expect(response).to have_http_status(:unauthorized)

    get "/api/analytics/#{endpoint}?organization_id=#{org_member.organization_ids.first}#{params}",
        headers: { "api-key" => org_member_token.secret }
    expect(response.media_type).to eq "application/json"

    other_org = create(:organization)
    get "/api/analytics/#{endpoint}?organization_id=#{other_org.id}#{params}",
        headers: { "api-key" => org_member_token.secret }
    expect(response).to have_http_status(:unauthorized)

    sign_in user
    get "/api/analytics/#{endpoint}?#{params}"
    expect(response).to have_http_status(:ok)

    get "/api/analytics/#{endpoint}?article_id=#{user_article.id}#{params}"
    expect(response).to have_http_status(:ok)

    org_param = "&organization_id=#{org_article.organization.id}"
    sign_in org_member
    get "/api/analytics/#{endpoint}?article_id=#{org_article.id}#{params}#{org_param}"
    expect(response).to have_http_status(:ok)
  end
end
