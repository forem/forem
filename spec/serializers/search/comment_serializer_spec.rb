require "rails_helper"

RSpec.describe Search::CommentSerializer do
  let(:comment) do
    # This block is a workaround to allow the serializer to work. The search uses a custom query and
    # select to build the associations to pass to the serializer. We need commentable_published and
    # commentable_title. Since #select is an ActiveRecord method, we can't call it on a FactoryBot
    # object. So, instead, we query the same as we do in Search::Comment to get what we need.
    c = create(:comment)

    Comment
      .includes(:user)
      .where(
        deleted: false,
        hidden_by_commentable_user: false,
        commentable_type: "Article",
        id: c.id,
      )
      .joins("join articles on articles.id = comments.commentable_id")
      .where("articles.published": true)
      .select(
        "COALESCE(articles.published, false) AS commentable_published",
        "COALESCE(articles.title, '') AS commentable_title",
        "comments.body_markdown",
        "comments.commentable_id",
        "comments.commentable_type",
        "comments.created_at",
        "comments.id AS id",
        "comments.public_reactions_count",
        "comments.score",
        "comments.user_id",
      )
      .first
  end

  it "serializes a Comment" do
    data_hash = described_class.new(comment).serializable_hash.dig(:data, :attributes)
    expect(data_hash.keys).to include(
      :id, :path, :public_reactions_count, :body_text, :class_name, :highlight, :hotness_score,
      :published, :published_at, :readable_publish_date_string, :title, :user
    )
  end

  it "serializes the comment path" do
    path = described_class.new(comment).serializable_hash.dig(:data, :attributes, :path)
    expect(path).to eq(comment.path)
  end

  it "serializes highlight" do
    highlight_hash = described_class.new(comment).serializable_hash.dig(:data, :attributes, :highlight)
    expect(highlight_hash.keys).to include(:body_text)
  end

  it "serializes the user" do
    user_hash = described_class.new(comment).serializable_hash.dig(:data, :attributes, :user)
    expect(user_hash.keys).to include(:name, :profile_image_90, :username)
    user = comment.user
    expect(user_hash[:name]).to eq(user.name)
    expect(user_hash[:username]).to eq(user.username)
    expect(user_hash[:profile_image_90]).to eq(user.profile_image_90)
  end
end
