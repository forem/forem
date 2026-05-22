require "rails_helper"

describe ArticlesHelper do
  describe ".get_host_without_www" do
    it "drops the www off of a valid url" do
      host = helper.get_host_without_www("https://www.example.com")
      expect(host).to eq "example.com"
    end

    it "lowercases the host name in general" do
      host = helper.get_host_without_www("https://www.EXAMPLE.COM")
      expect(host).to eq "example.com"
    end

    it "titlecases the host for medium.com and drops .com" do
      host = helper.get_host_without_www("https://www.medium.com")
      expect(host).to eq "Medium"
    end

    it "can handle urls without schemes" do
      host = helper.get_host_without_www("www.example.com")
      expect(host).to eq "example.com"
    end

    it "can handle URLs with leading and trailing whitespace" do
      host = helper.get_host_without_www(" www.example.com ")
      expect(host).to eq "example.com"
    end
  end

  describe "#image_tag_or_inline_svg_tag" do
    helper do
      def internal_navigation?
        true
      end
    end
    subject { helper.image_tag_or_inline_svg_tag("twitter") }

    it { is_expected.to start_with("<img") }

    context "with a width and height" do
      subject { helper.image_tag_or_inline_svg_tag("twitter", width: 18, height: 18) }

      it { is_expected.to include('width="18" height="18"') }
    end

    context "with #internal_navigation? set to false" do
      before { allow(helper).to receive(:internal_navigation?).and_return(false) }

      it { is_expected.to start_with('<svg xmlns="http://www.w3.org/2000/svg"') }
    end

    context "with width and height arguments, and with #internal_navigation? set to false" do
      subject { helper.image_tag_or_inline_svg_tag("twitter", width: 18, height: 18) }

      before { allow(helper).to receive(:internal_navigation?).and_return(false) }

      it { is_expected.to include('width="18" height="18"') }
    end
  end

  describe "#utc_iso_timestamp" do
    it "correctly formats the date when present" do
      expect(helper.utc_iso_timestamp(Time.current))
        .to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/)
    end

    it "returns nil if there is no timestamp" do
      expect(helper.utc_iso_timestamp(nil)).to be_nil
    end
  end

  describe ".comment_cue_message" do
    it "returns the zero-comment copy when count is 0" do
      expect(helper.comment_cue_message(0))
        .to eq(I18n.t("views.articles.comment_cue.zero"))
    end

    it "returns the few-comments copy for 1..10" do
      [1, 5, 10].each do |count|
        expect(helper.comment_cue_message(count))
          .to eq(I18n.t("views.articles.comment_cue.few"))
      end
    end

    it "returns the many-comments copy when count exceeds 10" do
      [11, 50, 999].each do |count|
        expect(helper.comment_cue_message(count))
          .to eq(I18n.t("views.articles.comment_cue.many"))
      end
    end

    it "treats nil as zero comments" do
      expect(helper.comment_cue_message(nil))
        .to eq(I18n.t("views.articles.comment_cue.zero"))
    end
  end
end
