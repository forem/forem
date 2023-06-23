require "rails_helper"

RSpec.describe DisplayAd do
  let(:organization) { build(:organization) }
  let(:display_ad) { build(:display_ad, organization: nil) }
  let(:audience_segment) { create(:audience_segment) }

  before { allow(FeatureFlag).to receive(:enabled?).with(:consistent_rendering, any_args).and_return(true) }

  it_behaves_like "Taggable"

  describe "validations" do
    describe "builtin validations" do
      subject { display_ad }

      it { is_expected.to belong_to(:organization).optional }
      it { is_expected.to have_many(:display_ad_events).dependent(:destroy) }

      it { is_expected.to validate_presence_of(:placement_area) }
      it { is_expected.to validate_presence_of(:body_markdown) }
      it { is_expected.to have_many(:tags) }
    end

    it "allows sidebar_right" do
      display_ad.placement_area = "sidebar_right"
      expect(display_ad).to be_valid
    end

    it "allows sidebar_left" do
      display_ad.placement_area = "sidebar_left"
      expect(display_ad).to be_valid
    end

    it "allows home_hero with in_house" do
      display_ad.placement_area = "home_hero"
      display_ad.type_of = "in_house"
      expect(display_ad).to be_valid
    end

    it "does not allow home_hero with community" do
      display_ad.placement_area = "home_hero"
      display_ad.type_of = "community"
      expect(display_ad).not_to be_valid
      expect(display_ad.errors[:type_of])
        .to include("must be in_house if display ad is a Home Hero")
    end

    it "disallows unacceptable placement_area" do
      display_ad.placement_area = "tsdsdsdds"
      expect(display_ad).not_to be_valid
    end

    it "returns human readable name" do
      display_ad.placement_area = "sidebar_left_2"
      expect(display_ad.human_readable_placement_area).to eq("Sidebar Left (Second Position)")
    end

    it "allows creator_id to be set" do
      display_ad.creator = build(:user)
      expect(display_ad).to be_valid
    end

    it "does not require creator to be valid" do
      display_ad.creator = nil
      expect(display_ad).to be_valid
    end

    it "requires organization_id for community-type ads" do
      expect(display_ad).to be_valid

      display_ad.type_of = "community"
      expect(display_ad).not_to be_valid
      expect(display_ad.errors[:organization]).not_to be_blank

      display_ad.organization = organization
      expect(display_ad).to be_valid
      expect(display_ad.errors[:organization]).to be_blank
    end

    it "allows clear audience segment" do
      display_ad.audience_segment_id = audience_segment.id
      expect(display_ad).to be_valid

      display_ad.audience_segment_id = audience_segment.id
      display_ad.audience_segment_type = audience_segment.type_of
      expect(display_ad).to be_valid
    end

    it "disallows invalid audience segment" do
      display_ad.audience_segment_id = audience_segment.id
      display_ad.audience_segment_type = "something_invalid_here"
      expect(audience_segment.type_of).not_to eq("something_invalid_here")
      expect(display_ad).not_to be_valid
    end

    it "disallows valid but ambiguous audience segment & id mismatch" do
      display_ad.audience_segment_id = audience_segment.id
      display_ad.audience_segment_type = "posted"
      expect(audience_segment.type_of).not_to eq("posted")
      expect(display_ad).not_to be_valid
    end

    it "disallows valid but imprecise manual audience segment type" do
      display_ad.audience_segment = nil
      display_ad.audience_segment_type = "manual"
      expect(display_ad).not_to be_valid
    end
  end

  context "when parsing liquid tags" do
    it "renders username embed" do
      user = create(:user)
      url = "#{URL.url}/#{user.username}"
      allow(UnifiedEmbed::Tag).to receive(:validate_link).with(any_args).and_return(url)
      username_ad = create(:display_ad, body_markdown: "Hello! {% embed #{url}} %}")
      expect(username_ad.processed_html).to include("/#{user.username}")
      expect(username_ad.processed_html).to include("ltag__user__link")
    end
  end

  context "when callbacks are triggered before save" do
    before { display_ad.save! }

    it "generates #processed_html from #body_markdown" do
      expect(display_ad.processed_html).to start_with("<p>Hello <em>hey</em> Hey hey")
    end

    it "does not render <div>" do
      div_html = "<div>Good morning, how are you?</div>"
      p_html = "<p>Good morning, how are you?</p>"
      display_ad.update(body_markdown: div_html)
      display_ad.reload
      expect(display_ad.processed_html).to eq(p_html)
    end

    it "does not render disallowed tags" do
      display_ad.update(body_markdown: "<style>body { color: black}</style> Hey hey")
      expect(display_ad.processed_html).to eq("<p>body { color: black} Hey hey</p>")
    end

    it "does not render disallowed attributes" do
      display_ad.update(body_markdown: "<p style='margin-top:100px'>Hello <em>hey</em> Hey hey</p>")
      expect(display_ad.processed_html).to start_with("<p>Hello <em>hey</em> Hey hey</p>")
    end
  end

  describe "#process_markdown" do
    # FastImage.size is called when synchronous_detail_detection: true is passed to Html::Parser#prefix_all_images
    # which should be the case for DisplayAd
    # Images::Optimizer is also called with widht
    it "calls Html::Parser#prefix_all_images with parameters" do
      # Html::Parser.new(html).prefix_all_images(prefix_width, synchronous_detail_detection: true).html
      image_url = "https://dummyimage.com/100x100"
      allow(FastImage).to receive(:size)
      allow(Images::Optimizer).to receive(:call).and_return(image_url)
      image_md = "![Image description](#{image_url})<p style='margin-top:100px'>Hello <em>hey</em> Hey hey</p>"
      create(:display_ad, body_markdown: image_md, placement_area: "post_comments")
      expect(FastImage).to have_received(:size).with(image_url, { timeout: 10 })
      # width is display_ad.prefix_width
      expect(Images::Optimizer).to have_received(:call).with(image_url, width: DisplayAd::POST_WIDTH)
      # Images::Optimizer.call(source, width: width)
    end

    it "uses sidebar width for sidebar location" do
      image_url = "https://dummyimage.com/100x100"
      allow(FastImage).to receive(:size)
      allow(Images::Optimizer).to receive(:call).and_return(image_url)
      image_md = "![Image description](#{image_url})<p style='margin-top:100px'>Hello <em>hey</em> Hey hey</p>"
      create(:display_ad, body_markdown: image_md, placement_area: "post_sidebar")
      expect(Images::Optimizer).to have_received(:call).with(image_url, width: DisplayAd::SIDEBAR_WIDTH)
    end

    it "uses post width for feed location" do
      image_url = "https://dummyimage.com/100x100"
      allow(FastImage).to receive(:size)
      allow(Images::Optimizer).to receive(:call).and_return(image_url)
      image_md = "![Image description](#{image_url})<p style='margin-top:100px'>Hello <em>hey</em> Hey hey</p>"
      create(:display_ad, body_markdown: image_md, placement_area: "feed_second")
      expect(Images::Optimizer).to have_received(:call).with(image_url, width: DisplayAd::POST_WIDTH)
    end

    it "keeps the same processed_html if markdown was not changed" do
      display_ad = create(:display_ad)
      html = display_ad.processed_html
      display_ad.update(name: "Sample display ad")
      display_ad.reload
      expect(display_ad.processed_html).to eq(html)
    end
  end

  describe "after_save callbacks" do
    let!(:display_ad) { create(:display_ad, name: nil) }

    it "generates a name when one does not exist" do
      display_ad_with_name = create(:display_ad, name: "Test")

      expect(display_ad.name).to eq("Display Ad #{display_ad.id}")
      expect(display_ad_with_name.name).to eq("Test")
    end
  end

  describe ".search_ads" do
    let!(:ad) { create(:display_ad, name: "This is an Ad", body_markdown: "Ad Body", placement_area: "post_comments") }

    it "finds via name" do
      expect(described_class.search_ads("this").ids).to contain_exactly(ad.id)
    end

    it "finds via body" do
      expect(described_class.search_ads("body").ids).to contain_exactly(ad.id)
    end

    it "finds via placement_area" do
      expect(described_class.search_ads("comment").ids).to contain_exactly(ad.id)
    end

    it "finds just one result via multiple criteria" do
      expect(described_class.search_ads("ad").ids).to contain_exactly(ad.id)
    end

    it "returns empty when no match" do
      expect(described_class.search_ads("foo")).to eq([])
    end
  end

  describe ".validate_tag" do
    it "rejects more than 10 tags" do
      eleven_tags = "one, two, three, four, five, six, seven, eight, nine, ten, eleven"
      expect(build(:display_ad,
                   name: "This is an Ad",
                   body_markdown: "Ad Body",
                   placement_area: "post_comments",
                   tag_list: eleven_tags).valid?).to be(false)
    end

    it "rejects tags with length > 30" do
      tags = "'testing tag length with more than 30 chars', tag"
      expect(build(:display_ad,
                   name: "This is an Ad",
                   body_markdown: "Ad Body",
                   placement_area: "post_comments",
                   tag_list: tags).valid?).to be(false)
    end

    it "rejects tag with non-alphanumerics" do
      expect do
        build(:display_ad,
              name: "This is an Ad",
              body_markdown: "Ad Body",
              placement_area: "post_comments",
              tag_list: "c++").validate!
      end.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "always downcase tags" do
      tags = "UPPERCASE, CAPITALIZE"
      display_ad = create(:display_ad,
                          name: "This is an Ad",
                          body_markdown: "Ad Body",
                          placement_area: "post_comments",
                          tag_list: tags)
      expect(display_ad.tag_list).to eq(tags.downcase.split(", "))
    end
  end

  describe "#exclude_articles_ids" do
    it "processes array of integer ids as expected" do
      display_ad.exclude_article_ids = ["11"]
      expect(display_ad.exclude_article_ids).to contain_exactly(11)

      display_ad.exclude_article_ids = %w[11 12 13 14]
      expect(display_ad.exclude_article_ids).to contain_exactly(11, 12, 13, 14)

      display_ad.exclude_article_ids = "11,12,13,14"
      expect(display_ad.exclude_article_ids).to contain_exactly(11, 12, 13, 14)

      display_ad.exclude_article_ids = ""
      expect(display_ad.exclude_article_ids).to eq([])

      display_ad.exclude_article_ids = []
      expect(display_ad.exclude_article_ids).to eq([])

      display_ad.exclude_article_ids = ["", "", ""]
      expect(display_ad.exclude_article_ids).to eq([])

      display_ad.exclude_article_ids = [nil]
      expect(display_ad.exclude_article_ids).to eq([])

      display_ad.exclude_article_ids = nil
      expect(display_ad.exclude_article_ids).to eq([])
    end

    it "round-trips to the database as expected" do
      display_ad.exclude_article_ids = [11]
      display_ad.save!
      expect(display_ad.exclude_article_ids).to contain_exactly(11)

      display_ad.update(exclude_article_ids: "11,12,13,14")
      expect(display_ad.exclude_article_ids).to contain_exactly(11, 12, 13, 14)

      display_ad.update(exclude_article_ids: nil)
      expect(display_ad.exclude_article_ids).to eq([])
    end
  end

  describe "when a stale audience segment is associated" do
    let(:audience_segment) do
      Timecop.travel(5.days.ago) do
        create(:audience_segment)
      end
    end

    before { allow(AudienceSegmentRefreshWorker).to receive(:perform_async) }

    it "refreshes audience segment as an asynchronous callback" do
      display_ad.save!
      expect(AudienceSegmentRefreshWorker).not_to have_received(:perform_async)

      display_ad.update audience_segment: audience_segment
      expect(AudienceSegmentRefreshWorker).to have_received(:perform_async)
        .with(audience_segment.id)
    end
  end

  describe "when a fresh audience segment is associated" do
    let(:audience_segment) { create(:audience_segment) }

    before { allow(AudienceSegmentRefreshWorker).to receive(:perform_async) }

    it "does not need to refresh audience segment" do
      display_ad.update audience_segment: audience_segment
      expect(AudienceSegmentRefreshWorker).not_to have_received(:perform_async)
    end
  end

  describe "seldom_seen scope" do
    let(:low_impression_count) { DisplayAd::LOW_IMPRESSION_COUNT }
    let!(:low_impression_ad) { create(:display_ad, impressions_count: low_impression_count - 1) }
    let!(:high_impression_ad) { create(:display_ad, impressions_count: low_impression_count + 1) }
    let!(:priority_ad) { create(:display_ad, priority: true, impressions_count: low_impression_count + 1) }

    it "includes ads with impressions count less than LOW_IMPRESSION_COUNT" do
      expect(described_class.seldom_seen).to include(low_impression_ad)
    end

    it "excludes ads with impressions count greater than or equal to LOW_IMPRESSION_COUNT" do
      expect(described_class.seldom_seen).not_to include(high_impression_ad)
    end

    it "includes ads with priority set to true" do
      expect(described_class.seldom_seen).to include(priority_ad)
    end

    it "includes both priority to be proper size when two qualifying ads exist" do
      expect(described_class.seldom_seen.size).to be 2
    end
  end
end
