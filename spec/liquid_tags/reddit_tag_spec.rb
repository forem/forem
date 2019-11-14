require "rails_helper"

vcr_option = {
  cassette_name: "reddit",
  allow_playback_repeats: "true",
  record: :new_episodes
}

RSpec.describe RedditTag, type: :liquid_template, vcr: vcr_option do
  context "when it is an image post" do
    describe "#render" do
      let(:image_post) { "https://www.reddit.com/r/aww/comments/ag3s4b/ive_waited_28_years_to_finally_havr_my_first_pet" }

      def generate_reddit_liquid(url)
        Liquid::Template.register_tag("reddit", RedditTag)
        Liquid::Template.parse("{% reddit #{url} %}")
      end

      it "renders reddit content" do
        reddit_liquid = generate_reddit_liquid(image_post)
        expect(reddit_liquid.render).to include("ltag__reddit")
      end
    end
  end

  context "when it is a text post" do
    describe "#render" do
      let(:text_post) { "https://www.reddit.com/r/IAmA/comments/afvl2w/im_scott_from_scotts_cheap_flights_my_profession" }

      def generate_reddit_liquid(url)
        Liquid::Template.register_tag("reddit", RedditTag)
        Liquid::Template.parse("{% reddit #{url} %}")
      end

      it "renders reddit content" do
        reddit_liquid = generate_reddit_liquid(text_post)
        expect(reddit_liquid.render).to include("ltag__reddit")
      end
    end
  end
end
