require "rails_helper"
require Rails.root.join("lib/data_update_scripts/20200723070918_update_articles_cached_organization.rb")

describe DataUpdateScripts::UpdateArticlesCachedOrganization do
  it "changes cached organizations from OpenStrucs to Structs" do
    org = create(:organization)
    cached_org = {
      name: org.name,
      username: org.username,
      slug: org.slug,
      profile_image_90: org.profile_image_90,
      profile_image_url: org.profile_image_url
    }

    # rubocop:disable Performance/OpenStruct
    article = create(:article, cached_organization: OpenStruct.new(cached_org))
    # rubocop:enable Performance/OpenStruct

    expect do
      described_class.new.run
    end.to change { article.reload.cached_organization.class }.from(OpenStruct).to(Organization::CachedOrganization)
  end
end
