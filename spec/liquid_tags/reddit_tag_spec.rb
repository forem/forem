require "rails_helper"

RSpec.describe RedditTag, type: :liquid_tag do
  context "when it is an image post" do
    describe "#render" do
      let(:image_post) do
        "https://www.reddit.com/r/aww/comments/ag3s4b/ive_waited_28_years_to_finally_havr_my_first_pet"
      end
      let(:response) do
        {
          "author" => "Miaogua007",
          "title" => "I've waited 28 years to …Everyone, meet Mycroft.",
          "post_url" => "https://www.reddit.com/r/aww/comments/ag3s4b/ive_waited_28_years_to_finally_havr_my_first_pet",
          "created_utc" => 1_547_520_425,
          "post_hint" => "image",
          "image_url" => "https://i.redd.it/jpqodmc83ia21.jpg",
          "thumbnail" => "https://b.thumbs.redditm…ge_mn1MHd6uirdou8H3o.jpg",
          "selftext" => "",
          "selftext_html" => nil
        }
      end

      def generate_reddit_liquid(url)
        Liquid::Template.register_tag("reddit", RedditTag)
        Liquid::Template.parse("{% reddit #{url} %}")
      end

      before do
        allow(HTTParty).to receive(:get).and_return([
                                                      {
                                                        "data" => {
                                                          "children" => [
                                                            { "data" => response },
                                                          ]
                                                        }
                                                      },
                                                    ])
      end

      it "renders reddit content" do
        reddit_liquid = generate_reddit_liquid(image_post)
        expect(reddit_liquid.render).to include("ltag__reddit")
        expect(reddit_liquid.render).to include(response["author"])
        expect(reddit_liquid.render).to include(response["thumbnail"])
      end
    end
  end

  context "when it is a text post" do
    describe "#render" do
      let(:text_post) do
        "https://www.reddit.com/r/IAmA/comments/afvl2w/im_scott_from_scotts_cheap_flights_my_profession"
      end

      let(:response) do
        post_url = "https://www.reddit.com/r/IAmA/comments/afvl2w/im_scott_from_scotts_cheap_flights_my_profession"

        {
          "author" => "scottkeyes",
          "title" => "I'm Scott from Scott's C…r the next 8 hours. AMA",
          "post_url" => post_url,
          "created_utc" => 1_547_470_871,
          "post_hint" => "self",
          "image_url" => "",
          "thumbnail" => "self",
          "selftext" => "I may have the world’s b…year for cheap flights!!",
          "selftext_html" => ""
        }
      end

      def generate_reddit_liquid(url)
        Liquid::Template.register_tag("reddit", RedditTag)
        Liquid::Template.parse("{% reddit #{url} %}")
      end

      before do
        allow(HTTParty).to receive(:get).and_return([
                                                      {
                                                        "data" => {
                                                          "children" => [
                                                            { "data" => response },
                                                          ]
                                                        }
                                                      },
                                                    ])
      end

      it "renders reddit content" do
        reddit_liquid = generate_reddit_liquid(text_post)
        expect(reddit_liquid.render).to include("ltag__reddit")
        expect(reddit_liquid.render).to include(response["author"])
      end
    end
  end
end
