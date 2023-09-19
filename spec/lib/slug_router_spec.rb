require "rails_helper"

RSpec.describe SlugRouter, type: :lib do
  def fake_request(parameters_as_hash)
    instance_double(ActionDispatch::Request,
                    parameters: parameters_as_hash)
  end

  def mapping_for(path)
    _root, handle, slug = path.split("/")
    hash = {"handle" => handle}
    hash["slug"] = slug if slug.present?
    req = fake_request(hash)

    described_class[req].map_without_cache
  end

  let!(:an_article) { create :article, user: a_user, slug: "an_article" }
  let!(:an_episode) { create :podcast_episode, podcast: a_podcast, slug: "an_episode" }
  let!(:an_org) { create :organization, username: "an_org" }
  let!(:a_page) { create :page, slug: "a_page", is_top_level_path: false }
  let!(:a_podcast) { create :podcast, slug: "a_podcast" }
  let!(:a_top_page) { create :page, slug: "a_top_page", is_top_level_path: true }
  let!(:a_user) { create :user, username: "a_user" }

  it "returns nil if everything misses" do
    expect(mapping_for("/nothing_to_see")).to be_nil
  end

  it "should find the PodcastEpisode if it exists" do
    expect(mapping_for("/a_podcast/an_episode")).to eq('podcast_episodes#show')
    expect(mapping_for("/wrong_podcast/an_episode")).to be_nil
    expect(mapping_for("/a_podcast/wrong_episode")).to be_nil
  end

  it "can use :handle or :username to find things" do
    handle_request = fake_request("handle" => "a_user")
    expect(described_class[handle_request].map_without_cache).to \
      eq('users#show')
    username_request = fake_request("username" => "an_org")
    expect(described_class[username_request].map_without_cache).to \
      eq('organizations#show')
  end

  it "should find the Page if it exists" do
    expect(mapping_for("/a_top_page")).to eq('pages#show')
    # expect(mapping_for("/pages/a_page")).to eq('pages#show')
    expect(mapping_for("/pages/a_top_page")).to be_nil
    expect(mapping_for("/wrong_page")).to be_nil
  end

  it "should find the Organization if it exists" do
    expect(mapping_for("/an_org")).to eq('organizations#show')
    expect(mapping_for("/an_org/wrong_article")).to be_nil
    expect(mapping_for("/wrong_org")).to be_nil
  end

  it "should find the User if it exists" do
    expect(mapping_for("/a_user")).to eq('users#show')
    expect(mapping_for("/a_user/wrong_article")).to be_nil
    expect(mapping_for("/wrong_user")).to be_nil
  end

  it "should find the Article if it exists" do
    expect(mapping_for("/a_user/an_article")).to eq('articles#show')
    expect(mapping_for("/wrong_user/an_article")).to be_nil
  end

  context "when caching" do
    let(:memory_store) { ActiveSupport::Cache.lookup_store(:memory_store) }

    before do
      allow(Page).to receive(:exists?).and_return(true)
      allow(Rails).to receive(:cache).and_return(memory_store)
      Rails.cache.clear
    end

    it "only checks once" do
      req = fake_request({ "handle" => "a_page" })

      50.times do
        expect(described_class[req].map).to eq('pages#show')
      end

      expect(Page).to have_received(:exists?).once
    end
  end
end
