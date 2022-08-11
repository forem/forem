require "rails_helper"

RSpec.describe Podcast, type: :model do
  let(:podcast) { create(:podcast) }

  it "has a creator" do
    user = build(:user)
    pod = create(:podcast, creator: user)
    expect(pod.creator).to eq(user)
  end

  context "when callbacks are triggered after save" do
    it "triggers cache busting on save" do
      sidekiq_assert_enqueued_with(job: Podcasts::BustCacheWorker, args: [podcast.path]) do
        podcast.save
      end
    end
  end

  describe "validations" do
    describe "builtin validations" do
      subject { podcast }

      it { is_expected.to belong_to(:creator).class_name("User").inverse_of(:created_podcasts).optional }

      it { is_expected.to have_many(:owners).through(:podcast_ownerships) }
      it { is_expected.to have_many(:podcast_episodes).dependent(:destroy) }
      it { is_expected.to have_many(:podcast_ownerships).dependent(:destroy) }

      it { is_expected.to validate_presence_of(:feed_url) }
      it { is_expected.to validate_presence_of(:image) }
      it { is_expected.to validate_presence_of(:main_color_hex) }
      it { is_expected.to validate_presence_of(:slug) }
      it { is_expected.to validate_presence_of(:title) }
    end

    # Couldn't use shoulda uniqueness matchers for these tests because:
    # Shoulda uses `save(validate: false)` which skips validations
    # So an invalid record is trying to be saved but fails because of the db constraints
    # https://github.com/thoughtbot/shoulda-matchers/blob/9f0def1/lib/shoulda/matchers/active_record/validate_uniqueness_of_matcher.rb#L549-L552

    it "validates slug uniqueness" do
      podcast2 = build(:podcast, slug: podcast.slug)

      expect(podcast2).not_to be_valid
      expect(podcast2.errors[:slug]).to be_present
    end

    it "validates feed_url uniqueness" do
      podcast2 = build(:podcast, feed_url: podcast.feed_url)

      expect(podcast2).not_to be_valid
      expect(podcast2.errors[:feed_url]).to be_present
    end

    it "validates feed_url format" do
      podcast2 = build(:podcast, feed_url: "example.com")

      expect(podcast2).not_to be_valid
      expect(podcast2.errors[:feed_url]).to be_present
    end

    it "validates main_color_hex" do
      podcast2 = build(:podcast, main_color_hex: "#FFFFFF")

      expect(podcast2).not_to be_valid
      expect(podcast2.errors[:main_color_hex]).to be_present
    end

    it "doesn't allow to create a podcast with a reserved word slug" do
      enter_podcast = build(:podcast, slug: "enter")
      expect(enter_podcast).not_to be_valid
      expect(enter_podcast.errors[:slug]).to be_present
    end

    it "is invalid when a user with a username equal to the podcast slug exists" do
      create(:user, username: "annabu")
      user_podcast = build(:podcast, slug: "annabu")
      expect(user_podcast).not_to be_valid
      expect(user_podcast.errors[:slug]).to be_present
    end

    it "is invalid when a page with a slug equal to the podcast slug exists" do
      create(:page, slug: "superpage")
      user_podcast = build(:podcast, slug: "superpage")
      expect(user_podcast).not_to be_valid
      expect(user_podcast.errors[:slug]).to be_present
    end

    it "is invalid when an org with a slug equal to the podcast slug exists" do
      create(:organization, slug: "superorganization")
      user_podcast = build(:podcast, slug: "superorganization")
      expect(user_podcast).not_to be_valid
      expect(user_podcast.errors[:slug]).to be_present
    end
  end

  describe ".reachable" do
    it "is reachable when it has a reachable episode" do
      expect do
        create(:podcast_episode, reachable: true)
        create(:podcast, published: true)
      end.to change(described_class.reachable, :count).by(1)
    end

    it "is reachable when it has a reachable episode even if it is unpublished" do
      expect do
        create(:podcast_episode, reachable: true)
        create(:podcast, published: false)
      end.to change(described_class.reachable, :count).by(1)
    end

    it "is not reachable when it has an unreachable episode" do
      expect do
        create(:podcast_episode, reachable: false)
        create(:podcast, published: true)
      end.not_to change(described_class.reachable, :count)
    end
  end

  describe ".available" do
    it "is available when it has a reachable episode and it is published" do
      expect do
        create(:podcast_episode, reachable: true)
        create(:podcast, published: true)
      end.to change(described_class.available, :count).by(1)
    end

    it "is not available when it has an unreachable episode" do
      expect do
        create(:podcast_episode, reachable: false)
        create(:podcast, published: true)
      end.not_to change(described_class.available, :count)
    end

    it "is not available when it is not published" do
      expect do
        create(:podcast, published: false)
      end.not_to change(described_class.available, :count)
    end
  end

  describe "#existing_episode" do
    let(:guid) { "<guid isPermaLink=\"false\">http://podcast.example/file.mp3</guid>" }
    let(:item_attributes) do
      {
        pubDate: "2019-06-19",
        enclosure_url: "https://audio.simplecast.com/2330f132.mp3",
        description: "yet another podcast",
        title: "lightalloy's podcast",
        guid: guid,
        itunes_subtitle: "hello",
        content_encoded: nil,
        itunes_summary: "world"
      }
    end
    let(:item) do
      build(:podcast_episode_rss_item, item_attributes.merge(link: "https://litealloy.ru"))
    end

    it "determines existing episode by media_url" do
      episode = create(:podcast_episode, podcast: podcast, media_url: "https://audio.simplecast.com/2330f132.mp3")
      expect(podcast.existing_episode(item)).to eq(episode)
    end

    it "determines existing episode by title" do
      episode = create(:podcast_episode, podcast: podcast, title: "lightalloy's podcast")
      expect(podcast.existing_episode(item)).to eq(episode)
    end

    it "determines existing episode by guid" do
      episode = create(:podcast_episode, podcast: podcast, guid: guid)
      expect(podcast.existing_episode(item)).to eq(episode)
    end

    it "determines existing episode by website_url" do
      episode = create(:podcast_episode, podcast: podcast, website_url: "https://litealloy.ru")
      expect(podcast.existing_episode(item)).to eq(episode)
    end

    it "doesn't determine existing episode if episode link is empty" do
      create(:podcast_episode, podcast: podcast, website_url: "")
      no_link_item = build(:podcast_episode_rss_item, item_attributes.merge(link: ""))
      expect(podcast.existing_episode(no_link_item)).to be_nil
    end

    it "doesn't determine existing episode by non-unique website_url" do
      podcast.update_attribute(:unique_website_url?, false)
      create(:podcast_episode, podcast: podcast, website_url: "https://litealloy.ru")
      expect(podcast.existing_episode(item)).to be_nil
    end
  end

  describe "#admins" do
    let(:user) { create(:user) }

    it "returns podcast admins" do
      user.add_role(:podcast_admin, podcast)
      expect(podcast.admins).to include(user)
    end

    it "does not return admins for other podcasts" do
      other_podcast = create(:podcast)
      user.add_role(:podcast_admin, other_podcast)
      expect(podcast.admins).to be_empty
    end
  end
end
