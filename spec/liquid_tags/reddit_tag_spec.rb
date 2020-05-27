require "rails_helper"

RSpec.describe RedditTag, type: :liquid_tag do
  context "when it is an image post" do
    describe "#render" do
      let(:image_post) { "https://www.reddit.com/r/aww/comments/ag3s4b/ive_waited_28_years_to_finally_havr_my_first_pet" }
      let(:json_from_url_service) { instance_double("RedditJsonFromUrlService") }
      let(:response) do
        {
          author: "Miaogua007",
          title: "I've waited 28 years to …Everyone, meet Mycroft.",
          post_url: "https://www.reddit.com/r/aww/comments/ag3s4b/ive_waited_28_years_to_finally_havr_my_first_pet",
          created_at: "Jan 15 '19",
          post_hint: "image",
          image_url: "https://i.redd.it/jpqodmc83ia21.jpg",
          thumbnail: "https://b.thumbs.redditm…ge_mn1MHd6uirdou8H3o.jpg",
          selftext: "",
          selftext_html: nil
        }
      end

      def generate_reddit_liquid(url)
        Liquid::Template.register_tag("reddit", RedditTag)
        Liquid::Template.parse("{% reddit #{url} %}")
      end

      before do
        allow(RedditJsonFromUrlService).to receive(:new).with(image_post).and_return(json_from_url_service)
        allow(json_from_url_service).to receive(:parse).and_return(response)
      end

      it "renders reddit content" do
        reddit_liquid = generate_reddit_liquid(image_post)
        expect(reddit_liquid.render).to include("ltag__reddit")
        expect(reddit_liquid.render).to include(response[:author])
        expect(reddit_liquid.render).to include(response[:thumbnail])
      end
    end
  end

  context "when it is a text post" do
    describe "#render" do
      let(:text_post) { "https://www.reddit.com/r/IAmA/comments/afvl2w/im_scott_from_scotts_cheap_flights_my_profession" }
      let(:json_from_url_service) { instance_double("RedditJsonFromUrlService") }
      let(:response) do
        {
          author: "scottkeyes",
          title: "I'm Scott from Scott's C…r the next 8 hours. AMA",
          post_url: "https://www.reddit.com/r/IAmA/comments/afvl2w/im_scott_from_scotts_cheap_flights_my_profession",
          created_at: "Jan 14 '19",
          post_hint: "self",
          image_url: "",
          thumbnail: "self",
          selftext: "I may have the world’s b…year for cheap flights!!",
          selftext_html: ""
        }
      end

      def generate_reddit_liquid(url)
        Liquid::Template.register_tag("reddit", RedditTag)
        Liquid::Template.parse("{% reddit #{url} %}")
      end

      before do
        allow(RedditJsonFromUrlService).to receive(:new).with(text_post).and_return(json_from_url_service)
        allow(json_from_url_service).to receive(:parse).and_return(response)
      end

      it "renders reddit content" do
        reddit_liquid = generate_reddit_liquid(text_post)
        expect(reddit_liquid.render).to include("ltag__reddit")
        expect(reddit_liquid.render).to include(response[:author])
      end
    end
  end
end
