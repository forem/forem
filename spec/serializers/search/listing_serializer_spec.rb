require "rails_helper"

RSpec.describe Search::ListingSerializer do
  let(:listing) { create(:listing) }

  it "serializes a Listing" do
    data_hash = described_class.new(listing).serializable_hash.dig(:data, :attributes)
    expect(data_hash.keys).to include(
      :id, :body_markdown, :bumped_at, :category, :contact_via_connect, :expires_at,
      :originally_published_at, :location, :processed_html, :published, :slug, :title, :user_id,
      :tags, :author
    )
  end

  it "serializes tags" do
    tags = described_class.new(listing).serializable_hash.dig(:data, :attributes, :tags)
    expect(tags).to eq(listing.cached_tag_list.to_s.split(", "))
  end

  it "serializes a ListingAuthor" do
    author_hash = described_class.new(listing).serializable_hash.dig(:data, :attributes, :author)
    expect(author_hash.keys).to include(:username, :name, :profile_image_90)
    user = listing.user
    expect(author_hash[:username]).to eq(user.username)
    expect(author_hash[:name]).to eq(user.name)
    expect(author_hash[:profile_image_90]).to eq(user.profile_image_90)
  end
end
