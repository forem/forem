require "rails_helper"
require Rails.root.join("lib/data_update_scripts/20200723070918_update_articles_cached_entities.rb")

describe DataUpdateScripts::UpdateArticlesCachedEntities do
  def make_ostruct(object)
    # rubocop:disable Performance/OpenStruct
    OpenStruct.new(
      name: object.name,
      userame: object.username,
      slug: object.respond_to?(:slug) ? object.slug : object.username,
      profile_image_90: object.profile_image_90,
      profile_image_url: object.profile_image_url,
    )
    # rubocop:enable Performance/OpenStruct
  end

  it "changes cached organizations from OpenStructs to Structs" do
    org = create(:organization)
    article = create(:article, organization: org)
    article.update_column(:cached_organization, make_ostruct(org))

    expect do
      described_class.new.run
    end.to change { article.reload.cached_organization.class }.from(OpenStruct).to(Articles::CachedEntity)
  end

  it "changes cached users from OpenStructs to Structs" do
    article = create(:article)
    # NOTE: this uses `update_column` in order to skip the `set_caches` callback
    # which would always change the serialized object's class
    article.update_column(:cached_user, make_ostruct(article.user))

    expect do
      described_class.new.run
    end.to change { article.reload.cached_user.class }.from(OpenStruct).to(Articles::CachedEntity)
  end
end
