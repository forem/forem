require "rails_helper"

RSpec.describe Stories::FeedSerializer do
  let(:view_context) do
    Class.new do
      def cloud_cover_url(url, _subforem_id = nil)
        "https://cdn.example/cover/#{url}"
      end
    end.new
  end

  let(:reaction_categories) do
    [
      ReactionCategory.new(slug: :like, name: "Like", icon: "heart", position: 1),
      ReactionCategory.new(slug: :unicorn, name: "Unicorn", icon: "unicorn", position: 2),
      ReactionCategory.new(slug: :fire, name: "Fire", icon: "fire", position: 3),
    ]
  end

  let(:cached_user) do
    Articles::CachedEntity.new(
      "Alice <Dev>",
      "alice",
      "alice",
      "https://img.example/alice-90.png",
      "https://img.example/alice.png",
      true,
      false,
    )
  end

  let(:cached_org) do
    Articles::CachedEntity.new(
      "Forem Org",
      "forem",
      "forem",
      "https://img.example/org-90.png",
      "https://img.example/org.png",
      false,
      true,
    )
  end

  let(:comment_user_class) do
    Struct.new(:username, :name, :profile_image_90)
  end

  let(:comment_class) do
    Struct.new(:id, :user_id, :created_at, :safe_processed_html, :path, :user)
  end

  let(:flare_tag_class) do
    Struct.new(:name, :bg_color_hex, :text_color_hex)
  end

  let(:context_note_class) do
    Struct.new(:processed_html)
  end

  let(:article_class) do
    Class.new do
      attr_accessor :id, :title, :path, :user_id, :comments_count, :public_reactions_count,
                    :organization_id, :reading_time, :video_thumbnail_url, :video, :edited_at,
                    :experience_level_rating, :experience_level_rating_distribution,
                    :main_image_height, :type_of, :subforem_id, :favorited_by_user_id,
                    :ai_disclosure_level, :cached_user, :cached_organization, :main_image,
                    :cached_tag_list, :body_preview, :title_finalized_for_feed, :title_for_metadata,
                    :published, :published_at, :crossposted_at, :main_image_background_hex_color,
                    :video_duration_in_seconds, :context_notes, :updated_at, :last_comment_at,
                    :top_comments_list

      def initialize(**attrs)
        attrs.each { |k, v| public_send(:"#{k}=", v) }
      end

      def object
        self
      end

      def persisted?
        true
      end

      def cached_organization?
        !cached_organization.nil?
      end

      def main_image?
        main_image.present?
      end

      def class_name
        "Article"
      end

      def displayable_published_at
        crossposted_at || published_at
      end

      def readable_publish_date
        return unless displayable_published_at

        I18n.l(displayable_published_at, format: :short)
      end

      def more_inclusive_recent_good_comments
        top_comments_list || []
      end
    end
  end

  def build_article(overrides = {})
    pub_time = Time.utc(2026, 11, 20, 12, 0, 0)
    article = article_class.new(
      id: 42,
      title: "Fast Rust & Ruby",
      path: "/alice/fast-rust-ruby-42",
      user_id: 7,
      comments_count: 1,
      public_reactions_count: 10,
      organization_id: 3,
      reading_time: 5,
      video_thumbnail_url: nil,
      video: nil,
      edited_at: Time.utc(2026, 11, 21, 8, 30, 0),
      experience_level_rating: 5.0,
      experience_level_rating_distribution: 4.5,
      main_image_height: 420,
      type_of: "full_post",
      subforem_id: 1,
      favorited_by_user_id: nil,
      ai_disclosure_level: "no_ai",
      cached_user: cached_user,
      cached_organization: cached_org,
      main_image: "hero.png",
      cached_tag_list: "rust, ruby, discuss",
      body_preview: nil,
      title_finalized_for_feed: nil,
      title_for_metadata: nil,
      published: true,
      published_at: pub_time,
      crossposted_at: nil,
      main_image_background_hex_color: "#dddddd",
      video_duration_in_seconds: 125.7,
      context_notes: [context_note_class.new("<p>Note</p>")],
      updated_at: pub_time,
      last_comment_at: pub_time,
      top_comments_list: [
        comment_class.new(
          101,
          8,
          pub_time,
          "<p>Awesome!</p>".html_safe,
          "/bob/comment/abc",
          comment_user_class.new("bob", "Bob", "https://img.example/bob.png"),
        ),
      ],
      **overrides,
    )
    article.instance_variable_set(
      :@preloaded_reaction_counts_for_reactable,
      [{ category: "like", count: 8 }, { category: "fire", count: 2 }],
    )
    article
  end

  before do
    allow(PinnedArticle).to receive(:id).and_return(42)
    allow(ReactionCategory).to receive(:for_view).and_return(reaction_categories)
    allow(Images::Optimizer).to receive_messages(
      imgproxy_enabled?: false,
      cloudinary_enabled?: false,
      cloudflare_enabled?: false,
    )
    allow(URL).to receive(:article) { |story| "https://dev.to#{story.path}" }
    allow(FlareTag).to receive(:tags_by_article_id).and_return(
      42 => flare_tag_class.new("discuss", "#000000", "#ffffff"),
    )
  end

  it "returns an empty JSON array string for an empty stories list" do
    result = described_class.call(
      stories: [],
      comments_variant: "more_inclusive_recent_good_comments",
      user_signed_in: false,
      feed_config_id: nil,
      view_context: view_context,
    )
    expect(result).to eq("[]")
  end

  it "serializes uncached stories, splices cached fragments, and batch-writes misses via write_multi",
     :aggregate_failures do
    cached_story = build_article(id: 1, path: "/alice/cached-1")
    uncached_story = build_article(id: 42)
    cached_key = described_class.cache_key_for(cached_story)
    uncached_key = described_class.cache_key_for(uncached_story)
    cache_store = ActiveSupport::Cache::MemoryStore.new
    cache_store.write(cached_key, '{"id":1,"title":"Cached Story"}')
    allow(Rails).to receive(:cache).and_return(cache_store)
    allow(cache_store).to receive(:write_multi).and_call_original

    json = described_class.call(
      stories: [cached_story, uncached_story],
      comments_variant: "more_inclusive_recent_good_comments",
      user_signed_in: true,
      feed_config_id: 99,
      view_context: view_context,
      cached_story_fragments: { cached_key => cache_store.read(cached_key) },
      story_cache_keys: { 1 => cached_key, 42 => uncached_key },
      cache_writes_enabled: true,
      cached_subforem_logo: "https://img.example/logo.png",
    )

    parsed = JSON.parse(json)
    expect(parsed.size).to eq(2)
    expect(parsed[0]).to eq(
      "id" => 1,
      "title" => "Cached Story",
      "url" => "https://dev.to/alice/cached-1",
      "current_user_signed_in" => true,
      "feed_config" => 99,
    )

    story_json = parsed[1]
    expect(story_json["id"]).to eq(42)
    expect(story_json["pinned"]).to be(true)
    expect(story_json["main_image"]).to eq("https://cdn.example/cover/hero.png")
    expect(story_json["tag_list"]).to eq(%w[rust ruby discuss])
    expect(story_json["user"]["cached_base_subscriber"]).to be(true)
    expect(story_json["user"]["cached_base_subscriber?"]).to be(true)
    expect(story_json["organization"]["slug"]).to eq("forem")
    expect(story_json["flare_tag"]).to eq(
      "name" => "discuss", "bg_color_hex" => "#000000", "text_color_hex" => "#ffffff",
    )
    expect(story_json["video_duration_in_minutes"]).to eq("02:05")
    expect(story_json["top_comments"].size).to eq(1)
    expect(story_json["top_comments"][0]["comment_id"]).to eq(101)
    expect(story_json["context_note"]).to eq("<p>Note</p>")
    expect(story_json["url"]).to eq("https://dev.to/alice/fast-rust-ruby-42")
    expect(story_json["current_user_signed_in"]).to be(true)
    expect(story_json["feed_config"]).to eq(99)

    expect(cache_store).to have_received(:write_multi).once
    cached_fragment = cache_store.read(uncached_key)
    expect(cached_fragment).to be_a(String)
    expect(JSON.parse(cached_fragment)).not_to have_key("url")
  end

  it "returns nil on out-of-domain inputs so the controller falls back to Jbuilder", :aggregate_failures do
    non_utc_story = build_article(edited_at: Time.new(2026, 11, 21, 8, 30, 0, "+02:00"))
    expect(
      described_class.call(
        stories: [non_utc_story],
        comments_variant: "more_inclusive_recent_good_comments",
        user_signed_in: false,
        feed_config_id: nil,
        view_context: view_context,
      ),
    ).to be_nil

    nan_story = build_article(experience_level_rating: Float::NAN)
    expect(
      described_class.call(
        stories: [nan_story],
        comments_variant: "more_inclusive_recent_good_comments",
        user_signed_in: false,
        feed_config_id: nil,
        view_context: view_context,
      ),
    ).to be_nil
  end

  it "includes RAILS_CACHE_ID in cache keys when configured" do
    story = build_article(id: 42)
    base_key = described_class.cache_key_for(story)
    prev = ENV.fetch("RAILS_CACHE_ID", nil)
    ENV["RAILS_CACHE_ID"] = "gen-2026"
    gen_key = described_class.cache_key_for(story)

    expect(gen_key).to start_with("#{described_class::CACHE_KEY_PREFIX}/gen-2026-")
    expect(gen_key).not_to eq(base_key)
  ensure
    ENV["RAILS_CACHE_ID"] = prev
  end

  it "preserves the article's local readable_publish_date when its timestamp has a non-UTC DST offset" do
    bst_time = Time.new(2026, 7, 2, 0, 30, 0, "+01:00")
    story = build_article(id: 42, published_at: bst_time, edited_at: nil)

    json = described_class.call(
      stories: [story],
      comments_variant: "more_inclusive_recent_good_comments",
      user_signed_in: false,
      feed_config_id: nil,
      view_context: view_context,
      cached_subforem_logo: "https://img.example/logo.png",
    )

    parsed = JSON.parse(json)
    expect(parsed[0]["readable_publish_date"]).to eq(story.readable_publish_date)
    expect(parsed[0]["readable_publish_date"]).to include("Jul")
    expect(parsed[0]["readable_publish_date"]).to include("2")
  end
end
