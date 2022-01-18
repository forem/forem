require "rails_helper"

RSpec.describe TwitterTimelineTag, type: :lyquid_tag do
  describe "#link" do
    let(:valid_twitter_timeline_links) do
      [
        "https://twitter.com/FreyaHolmer/timelines/1215413954505297922",
        "https://twitter.com/FreyaHolmer/timelines/1215413954505297922 ",
      ]
    end
    let(:invalid_twitter_timeline_links) do
      [
        "https://twitter.com/username/status/1315726429640773632",
        "https://twitter.com/FreyaHolmer/1215413954505297922",
        "https://codepen.io/FreyaHolmer/timelines/1215413954505297922",
      ]
    end

    def generate_new_liquid(link)
      Liquid::Template.register_tag("twitter_timeline", TwitterTimelineTag)
      Liquid::Template.parse("{% twitter_timeline #{link} %}")
    end

    it "accepts a valid link" do
      valid_twitter_timeline_links.each do |valid_link|
        liquid = generate_new_liquid(valid_link)
        expect(liquid.render).to include("<a class=\"twitter-timeline")
      end
    end

    it "rejects bad link" do
      invalid_twitter_timeline_links.each do |invalid_link|
        expect { generate_new_liquid(invalid_link) }
          .to raise_error(StandardError, "Invalid Twitter Timeline URL")
      end
    end
  end
end
