require "rails_helper"

RSpec.describe Search::ReadingListArticleSerializer do
  let(:reaction) { create(:reaction) }

  # article and users are workarounds to allow the serializer to work. The search uses a custom
  # query and select to build the associations to pass to the serializer. We need reaction_id,
  # reaction_user_id, and selected attributes. Since #select is an ActiveRecord method, we can't
  # call it on a FactoryBot object. So, instead, we query the same as we do in Search::ReadingList
  # to get what we need.
  let(:article) do
    Article
      .includes(:reactions)
      .where(id: reaction.reactable.id)
      .select(
        "articles.cached_tag_list",
        "articles.crossposted_at",
        "articles.path",
        "articles.published_at",
        "articles.reading_time",
        "articles.title",
        "articles.user_id",
        "reactions.id AS reaction_id",
        "reactions.user_id AS reaction_user_id",
      )
      .references(:reactions)
      .first
  end

  let(:users) do
    User
      .where(id: article.user_id)
      .select(:id, :name, :profile_image, :username)
      .index_by(&:id)
  end

  it "serializes an Article" do
    data_hash = described_class.new(article, params: { users: users }).serializable_hash.dig(:data, :attributes)
    expect(data_hash.keys).to include(:id, :user_id, :reactable)
  end

  it "serializes the reactable" do
    reactable = described_class.new(article, params: { users: users }).serializable_hash.dig(:data, :attributes,
                                                                                             :reactable)
    expect(reactable.keys).to include(:path, :readable_publish_date_string, :reading_time, :tag_list, :tags, :title,
                                      :user)
  end
end
