require "rails_helper"

RSpec.describe Billboard do
  let(:organization) { build(:organization) }
  let(:billboard) { build(:billboard, organization: nil) }
  let(:audience_segment) { create(:audience_segment) }

  before { allow(FeatureFlag).to receive(:enabled?).with(:consistent_rendering, any_args).and_return(true) }

  it_behaves_like "Taggable"

  describe "validations" do
    describe "builtin validations" do
      subject { billboard }

      it { is_expected.to belong_to(:organization).optional }
      it { is_expected.to have_many(:billboard_events).dependent(:destroy) }

      it { is_expected.to validate_presence_of(:placement_area) }
      it { is_expected.to validate_presence_of(:body_markdown) }
      it { is_expected.to have_many(:tags) }
    end

    it "allows sidebar_right" do
      billboard.placement_area = "sidebar_right"
      expect(billboard).to be_valid
    end

    it "allows sidebar_left" do
      billboard.placement_area = "sidebar_left"
      expect(billboard).to be_valid
    end

    it "allows home_hero with in_house" do
      billboard.placement_area = "home_hero"
      billboard.type_of = "in_house"
      expect(billboard).to be_valid
    end

    it "does not allow home_hero with community" do
      billboard.placement_area = "home_hero"
      billboard.type_of = "community"
      expect(billboard).not_to be_valid
      expect(billboard.errors[:type_of])
        .to include("must be in_house if billboard is a Home Hero")
    end

    it "disallows unacceptable placement_area" do
      billboard.placement_area = "tsdsdsdds"
      expect(billboard).not_to be_valid
    end

    it "returns human readable name" do
      billboard.placement_area = "sidebar_left_2"
      expect(billboard.human_readable_placement_area).to eq("Sidebar Left (Second Position)")
    end

    it "allows creator_id to be set" do
      billboard.creator = build(:user)
      expect(billboard).to be_valid
    end

    it "does not require creator to be valid" do
      billboard.creator = nil
      expect(billboard).to be_valid
    end

    it "requires organization_id for community-type ads" do
      expect(billboard).to be_valid

      billboard.type_of = "community"
      expect(billboard).not_to be_valid
      expect(billboard.errors[:organization]).not_to be_blank

      billboard.organization = organization
      expect(billboard).to be_valid
      expect(billboard.errors[:organization]).to be_blank
    end

    it "allows clear audience segment" do
      billboard.audience_segment_id = audience_segment.id
      expect(billboard).to be_valid

      billboard.audience_segment_id = audience_segment.id
      billboard.audience_segment_type = audience_segment.type_of
      expect(billboard).to be_valid
    end

    it "disallows invalid audience segment" do
      billboard.audience_segment_id = audience_segment.id
      billboard.audience_segment_type = "something_invalid_here"
      expect(audience_segment.type_of).not_to eq("something_invalid_here")
      expect(billboard).not_to be_valid
    end

    it "disallows valid but ambiguous audience segment & id mismatch" do
      billboard.audience_segment_id = audience_segment.id
      billboard.audience_segment_type = "posted"
      expect(audience_segment.type_of).not_to eq("posted")
      expect(billboard).not_to be_valid
    end

    it "disallows valid but imprecise manual audience segment type" do
      billboard.audience_segment = nil
      billboard.audience_segment_type = "manual"
      expect(billboard).not_to be_valid
    end
  end

  context "when range env var is set" do
    it "translates jiberrish to 0" do
      allow(ApplicationConfig).to receive(:[]).with("SELDOM_SEEN_MIN_FOR_SIDEBAR_LEFT").and_return("jibberish")
      expect(described_class.random_range_max("sidebar_left")).to eq 0
    end

    it "still performs query with number" do
      allow(ApplicationConfig).to receive(:[]).with("SELDOM_SEEN_MIN_FOR_SIDEBAR_LEFT").and_return("100")
      expect(described_class.random_range_max("sidebar_left")).to eq 100
    end

    it "falls back to broadly set range vars" do
      allow(ApplicationConfig).to receive(:[]).with("SELDOM_SEEN_MIN_FOR_SIDEBAR_LEFT").and_return(nil)
      allow(ApplicationConfig).to receive(:[]).with("SELDOM_SEEN_MIN").and_return("89")
      expect(described_class.random_range_max("sidebar_left")).to eq 89
    end
  end

  context "when parsing liquid tags" do
    it "renders username embed" do
      user = create(:user)
      url = "#{URL.url}/#{user.username}"
      allow(UnifiedEmbed::Tag).to receive(:validate_link).with(any_args).and_return(url)
      username_ad = create(:billboard, body_markdown: "Hello! {% embed #{url}} %}")
      expect(username_ad.processed_html).to include("/#{user.username}")
      expect(username_ad.processed_html).to include("ltag__user__link")
    end
  end

  context "when callbacks are triggered before save" do
    before { billboard.save! }

    it "generates #processed_html from #body_markdown" do
      expect(billboard.processed_html).to start_with("<p>Hello <em>hey</em> Hey hey")
    end

    it "does not render <div>" do
      div_html = "<div>Good morning, how are you?</div>"
      p_html = "<p>Good morning, how are you?</p>"
      billboard.update(body_markdown: div_html)
      billboard.reload
      expect(billboard.processed_html).to eq(p_html)
    end

    it "does not render disallowed tags" do
      billboard.update(body_markdown: "<style>body { color: black}</style> Hey hey")
      expect(billboard.processed_html).to eq("<p>body { color: black} Hey hey</p>")
    end

    it "does not render disallowed attributes" do
      billboard.update(body_markdown: "<p style='margin-top:100px'>Hello <em>hey</em> Hey hey</p>")
      expect(billboard.processed_html).to start_with("<p>Hello <em>hey</em> Hey hey</p>")
    end
  end

  describe "#process_markdown" do
    # FastImage.size is called when synchronous_detail_detection: true is passed to Html::Parser#prefix_all_images
    # which should be the case for Billboard
    # Images::Optimizer is also called with widht
    it "calls Html::Parser#prefix_all_images with parameters" do
      # Html::Parser.new(html).prefix_all_images(prefix_width, synchronous_detail_detection: true).html
      image_url = "https://dummyimage.com/100x100"
      allow(FastImage).to receive(:size)
      allow(Images::Optimizer).to receive(:call).and_return(image_url)
      image_md = "![Image description](#{image_url})<p style='margin-top:100px'>Hello <em>hey</em> Hey hey</p>"
      create(:billboard, body_markdown: image_md, placement_area: "post_comments")
      options = { http_header: { "User-Agent" => "DEV(local) (http://forem.test)" }, timeout: 10 }
      expect(FastImage).to have_received(:size).with(image_url, options)
      # width is billboard.prefix_width
      expect(Images::Optimizer).to have_received(:call).with(image_url, width: Billboard::POST_WIDTH)
      # Images::Optimizer.call(source, width: width)
    end

    it "uses sidebar width for sidebar location" do
      image_url = "https://dummyimage.com/100x100"
      allow(FastImage).to receive(:size)
      allow(Images::Optimizer).to receive(:call).and_return(image_url)
      image_md = "![Image description](#{image_url})<p style='margin-top:100px'>Hello <em>hey</em> Hey hey</p>"
      create(:billboard, body_markdown: image_md, placement_area: "post_sidebar")
      expect(Images::Optimizer).to have_received(:call).with(image_url, width: Billboard::SIDEBAR_WIDTH)
    end

    it "uses post width for feed location" do
      image_url = "https://dummyimage.com/100x100"
      allow(FastImage).to receive(:size)
      allow(Images::Optimizer).to receive(:call).and_return(image_url)
      image_md = "![Image description](#{image_url})<p style='margin-top:100px'>Hello <em>hey</em> Hey hey</p>"
      create(:billboard, body_markdown: image_md, placement_area: "feed_second")
      expect(Images::Optimizer).to have_received(:call).with(image_url, width: Billboard::POST_WIDTH)
    end

    it "keeps the same processed_html if markdown was not changed" do
      billboard = create(:billboard)
      html = billboard.processed_html
      billboard.update(name: "Sample billboard")
      billboard.reload
      expect(billboard.processed_html).to eq(html)
    end
  end

  describe "after_save callbacks" do
    let!(:billboard) { create(:billboard, name: nil) }

    it "generates a name when one does not exist" do
      billboard_with_name = create(:billboard, name: "Test")

      expect(billboard.name).to eq("Billboard #{billboard.id}")
      expect(billboard_with_name.name).to eq("Test")
    end
  end

  describe ".search_ads" do
    let!(:billboard) do
      create(:billboard, name: "This is a billboard", body_markdown: "Billboard Body", placement_area: "post_comments")
    end

    it "finds via name" do
      expect(described_class.search_ads("this").ids).to contain_exactly(billboard.id)
    end

    it "finds via body" do
      expect(described_class.search_ads("body").ids).to contain_exactly(billboard.id)
    end

    it "finds via placement_area" do
      expect(described_class.search_ads("comment").ids).to contain_exactly(billboard.id)
    end

    it "finds just one result via multiple criteria" do
      expect(described_class.search_ads("billboard").ids).to contain_exactly(billboard.id)
    end

    it "returns empty when no match" do
      expect(described_class.search_ads("foo")).to eq([])
    end
  end

  describe ".validate_tag" do
    it "rejects more than 10 tags" do
      twenty_six_tags = Array.new(26) { SecureRandom.alphanumeric(8) }.join(", ")
      expect(build(:billboard,
                   name: "This is a billboard",
                   body_markdown: "Billboard Body",
                   placement_area: "post_comments",
                   tag_list: twenty_six_tags).valid?).to be(false)
    end

    it "rejects tags with length > 30" do
      tags = "'testing tag length with more than 30 chars', tag"
      expect(build(:billboard,
                   name: "This is a billboard",
                   body_markdown: "Billboard Body",
                   placement_area: "post_comments",
                   tag_list: tags).valid?).to be(false)
    end

    it "rejects tag with non-alphanumerics" do
      expect do
        build(:billboard,
              name: "This is a billboard",
              body_markdown: "Billboard Body",
              placement_area: "post_comments",
              tag_list: "c++").validate!
      end.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "always downcase tags" do
      tags = "UPPERCASE, CAPITALIZE"
      billboard = create(:billboard, name: "This is a billboard",
                                     body_markdown: "Billboard Body",
                                     placement_area: "post_comments",
                                     tag_list: tags)
      expect(billboard.tag_list).to eq(tags.downcase.split(", "))
    end
  end

  describe ".validate_geolocations" do
    subject(:billboard) do
      build(
        :billboard,
        name: "This is a billboard",
        body_markdown: "Billboard Body",
        placement_area: "post_comments",
        target_geolocations: geo_input,
      )
    end

    let(:target_geolocations) do
      [
        Geolocation.new("US", "CA"),
        Geolocation.new("CA", "ON"),
        Geolocation.new("CA", "BC"),
      ]
    end

    context "with nil" do
      let(:geo_input) { nil }

      it "permits them" do
        expect(billboard).to be_valid
        expect(billboard.target_geolocations).to be_empty
      end
    end

    context "with empty string" do
      let(:geo_input) { "" }

      it "permits them" do
        expect(billboard).to be_valid
        expect(billboard.target_geolocations).to be_empty
      end
    end

    context "with empty array" do
      let(:geo_input) { [] }

      it "permits them" do
        expect(billboard).to be_valid
        expect(billboard.target_geolocations).to be_empty
      end
    end

    context "with comma-separated list of ISO 3166-2" do
      let(:geo_input) { "US-CA, CA-ON, CA-BC" }

      it "permits them" do
        expect(billboard).to be_valid
        expect(billboard.target_geolocations).to match_array(target_geolocations)
      end
    end

    context "with array of ISO 3166-2" do
      let(:geo_input) { %w[US-CA CA-ON CA-BC] }

      it "permits them" do
        expect(billboard).to be_valid
        expect(billboard.target_geolocations).to match_array(target_geolocations)
      end
    end

    context "with array of geolocations" do
      let(:geo_input) { [Geolocation.new("US", "CA"), Geolocation.new("CA", "ON"), Geolocation.new("CA", "BC")] }

      it "permits them" do
        expect(billboard).to be_valid
        expect(billboard.target_geolocations).to match_array(target_geolocations)
      end
    end

    context "with invalid comma-separated ISO 3166-2 codes" do
      let(:geo_input) { "US-CA, NOT-REAL" }

      it "does not permit them" do
        expect(billboard).not_to be_valid
        expect(billboard.errors_as_sentence).to include("NOT-REAL is not a supported ISO 3166-2 code")
      end
    end

    context "with invalid array of ISO 3166-2 codes" do
      let(:geo_input) { %w[CA-QC CA-FAKE] }

      it "does not permit them" do
        expect(billboard).not_to be_valid
        expect(billboard.errors_as_sentence).to include("CA-FAKE is not a supported ISO 3166-2 code")
      end
    end
  end

  describe "#exclude_articles_ids" do
    it "processes array of integer ids as expected" do
      billboard.exclude_article_ids = ["11"]
      expect(billboard.exclude_article_ids).to contain_exactly(11)

      billboard.exclude_article_ids = %w[11 12 13 14]
      expect(billboard.exclude_article_ids).to contain_exactly(11, 12, 13, 14)

      billboard.exclude_article_ids = "11,12,13,14"
      expect(billboard.exclude_article_ids).to contain_exactly(11, 12, 13, 14)

      billboard.exclude_article_ids = ""
      expect(billboard.exclude_article_ids).to eq([])

      billboard.exclude_article_ids = []
      expect(billboard.exclude_article_ids).to eq([])

      billboard.exclude_article_ids = ["", "", ""]
      expect(billboard.exclude_article_ids).to eq([])

      billboard.exclude_article_ids = [nil]
      expect(billboard.exclude_article_ids).to eq([])

      billboard.exclude_article_ids = nil
      expect(billboard.exclude_article_ids).to eq([])
    end

    it "round-trips to the database as expected" do
      billboard.exclude_article_ids = [11]
      billboard.save!
      expect(billboard.exclude_article_ids).to contain_exactly(11)

      billboard.update(exclude_article_ids: "11,12,13,14")
      expect(billboard.exclude_article_ids).to contain_exactly(11, 12, 13, 14)

      billboard.update(exclude_article_ids: nil)
      expect(billboard.exclude_article_ids).to eq([])
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
      billboard.save!
      expect(AudienceSegmentRefreshWorker).not_to have_received(:perform_async)

      billboard.update audience_segment: audience_segment
      expect(AudienceSegmentRefreshWorker).to have_received(:perform_async)
        .with(audience_segment.id)
    end
  end

  describe "when a fresh audience segment is associated" do
    let(:audience_segment) { create(:audience_segment) }

    before { allow(AudienceSegmentRefreshWorker).to receive(:perform_async) }

    it "does not need to refresh audience segment" do
      billboard.update audience_segment: audience_segment
      expect(AudienceSegmentRefreshWorker).not_to have_received(:perform_async)
    end
  end

  describe "seldom_seen scope" do
    let(:low_impression_count) { Billboard::LOW_IMPRESSION_COUNT }
    let!(:low_impression_ad) { create(:billboard, impressions_count: low_impression_count - 1) }
    let!(:high_impression_ad) { create(:billboard, impressions_count: low_impression_count + 1) }

    before { create(:billboard, priority: true, impressions_count: low_impression_count + 1) }

    it "includes ads with impressions count less than LOW_IMPRESSION_COUNT" do
      expect(described_class.seldom_seen("sidebar_left")).to include(low_impression_ad)
    end

    it "does not include ads with impression count more than env area override of LOW_IMPRESSION_COUNT" do
      allow(ApplicationConfig).to receive(:[]).with("LOW_IMPRESSION_COUNT_FOR_SIDEBAR_LEFT").and_return("990")
      expect(described_class.seldom_seen("sidebar_left")).not_to include(low_impression_ad)
    end

    it "includes ads with impression count less than than env area override of LOW_IMPRESSION_COUNT" do
      allow(ApplicationConfig).to receive(:[]).with("LOW_IMPRESSION_COUNT_FOR_SIDEBAR_LEFT").and_return("1010")
      expect(described_class.seldom_seen("sidebar_left")).to include(low_impression_ad)
    end

    it "does not include ads with impression count more than env GLOBAL override of LOW_IMPRESSION_COUNT" do
      allow(ApplicationConfig).to receive(:[]).with("LOW_IMPRESSION_COUNT").and_return("990")
      allow(ApplicationConfig).to receive(:[]).with("LOW_IMPRESSION_COUNT_FOR_SIDEBAR_LEFT").and_return(nil)
      expect(described_class.seldom_seen("sidebar_left")).not_to include(low_impression_ad)
    end

    it "includes ads with impression count less than than env GLOBAL override of LOW_IMPRESSION_COUNT" do
      allow(ApplicationConfig).to receive(:[]).with("LOW_IMPRESSION_COUNT").and_return("1010")
      allow(ApplicationConfig).to receive(:[]).with("LOW_IMPRESSION_COUNT_FOR_SIDEBAR_LEFT").and_return(nil)
      expect(described_class.seldom_seen("sidebar_left")).to include(low_impression_ad)
    end

    it "ignores override of LOW_IMPRESSION_COUNT to a different location" do
      allow(ApplicationConfig).to receive(:[]).with("LOW_IMPRESSION_COUNT_FOR_POST_COMMENTS").and_return("990")
      allow(ApplicationConfig).to receive(:[]).with("LOW_IMPRESSION_COUNT_FOR_SIDEBAR_LEFT").and_return(nil)
      allow(ApplicationConfig).to receive(:[]).with("LOW_IMPRESSION_COUNT").and_return(nil)
      expect(described_class.seldom_seen("sidebar_left")).to include(low_impression_ad)
    end

    it "excludes ads with impressions count greater than or equal to LOW_IMPRESSION_COUNT" do
      expect(described_class.seldom_seen("sidebar_left")).not_to include(high_impression_ad)
    end

    it "includes both priority to be proper size when two qualifying ads exist" do
      expect(described_class.seldom_seen("sidebar_left").size).to be 2
    end
  end
end
